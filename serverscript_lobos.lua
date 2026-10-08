--[[
	🐺 LOBO SOMBRÍO - Script de Roblox (todo en uno)
	Colócalo como "Script" dentro de ServerScriptService.

	QUÉ HACE
	  • Construye el lobo completo por código: cuerpo facetado negro/gris, hombreras con
	    runas moradas brillantes, ojo púrpura que brilla, melena de picos, orejas, hocico,
	    mandíbula inferior con colmillos, patas de 3 articulaciones con garras y cola.
	  • Fuego morado/azul: decenas de "lenguas" de llama que ondean (lomo, cola, patas,
	    nuca) + partículas de fuego y brasas + luz morada que ilumina el suelo.
	  • Animación por código (sin assets):
	      - Reposo: respira, mira alrededor, mueve orejas y cola.
	      - Patrulla: camina al trote cerca de donde nació.
	      - Rugido: cuando detecta un jugador se agacha, abre la boca, tiembla y las llamas explotan.
	      - Persecución: galopa (patas, columna que se flexiona, boca jadeando, cola al viento).
	      - Mordida: se prepara, salta con la boca abierta y cierra de golpe haciendo daño.
	      - Muerte: se desploma, se apaga el fuego y desaparece (y reaparece si quieres).
	  • IA: detecta al jugador más cercano, lo persigue y lo muerde.

	Todo se ajusta en la tabla CONFIG de abajo.

	[Avada] Este archivo es del dueno del juego y va INTACTO. La unica
	diferencia con su version suelta: en vez de crear un lobo al final,
	registra el lanzador "AvadaLobos" para que PARTIDA lo invoque de
	noche dentro del Bosque Prohibido (crear / sinReaparicion /
	conReaparicion), y el lobo sigue siendo exactamente el mismo.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// CONFIGURACIÓN ---------------------------------------------------------
local CONFIG = {
	POSICION            = Vector3.new(-30, 0, 0), -- Dónde aparece el lobo
	ROTACION            = 0,                      -- Hacia dónde mira al aparecer (grados)
	ESCALA              = 1,                      -- 1 = lobo grande (~13 studs de largo)
	APOYAR_EN_SUELO     = true,                   -- Detecta el piso con raycast

	VIDA                = 400,
	DANO                = 20,                     -- Daño por mordida (0 = no hace daño)
	RANGO_DETECCION     = 70,                     -- A qué distancia ve a un jugador
	RANGO_ABANDONO      = 110,                    -- Si te alejas más que esto, te deja de perseguir
	RANGO_ATAQUE        = 7,                      -- A qué distancia empieza la mordida
	VEL_CAMINAR         = 9,
	VEL_CORRER          = 32,
	VEL_ESTOCADA        = 46,                     -- Velocidad del salto de la mordida
	TIEMPO_RUGIDO       = 1.3,                    -- Segundos que ruge antes de correr
	ENFRIAMIENTO_ATAQUE = 1.4,                    -- Segundos entre mordidas
	RADIO_PATRULLA      = 30,                     -- Cuánto se aleja caminando cuando está tranquilo

	REAPARECER          = true,                   -- Reaparece al morir
	TIEMPO_REAPARICION  = 20,
	MATERIAL            = Enum.Material.SmoothPlastic, -- Prueba Enum.Material.Slate para más textura
}

--// COLORES ----------------------------------------------------------------
local NEGRO         = Color3.fromRGB(22, 20, 27)
local CARBON        = Color3.fromRGB(40, 38, 46)
local GRIS          = Color3.fromRGB(64, 62, 72)
local GRIS_CLARO    = Color3.fromRGB(82, 80, 91)
local COLOR_RUNA    = Color3.fromRGB(165, 75, 245)
local COLOR_OJO     = Color3.fromRGB(190, 100, 255)
local OJO_APAGADO   = Color3.fromRGB(50, 30, 70)
local INDIGO_GARRA  = Color3.fromRGB(44, 30, 118)
local VIOLETA_OSC   = Color3.fromRGB(56, 22, 86)
local DIENTE        = Color3.fromRGB(236, 230, 224)
local ENCIA         = Color3.fromRGB(72, 16, 36)
local COLORES_LLAMA = {
	Color3.fromRGB(112, 32, 168),
	Color3.fromRGB(88, 26, 140),
	Color3.fromRGB(36, 30, 118),
	Color3.fromRGB(28, 36, 132),
	Color3.fromRGB(58, 22, 92),
	Color3.fromRGB(140, 60, 205),
}

local ALTURA_CUERPO = 3.0 -- Altura del centro del cuerpo sobre el piso (antes de escalar)
local V = Vector3.new
local rad = math.rad
local PI2 = math.pi * 2

--// ESTADO DE CONSTRUCCIÓN (se reinicia en cada lobo) ----------------------
local RAIZ = CFrame.new()
local ESC = 1
local MAT = Enum.Material.SmoothPlastic
local RESTO = {}                                    -- CFrame de reposo de cada parte (en espacio del lobo)
local BASES = setmetatable({}, { __mode = "k" })    -- C0 original de cada Motor6D

--// UTILIDADES -------------------------------------------------------------
local function lerp(a, b, t)
	return a + (b - a) * t
end

local function suave(actual, objetivo, k, dt)
	return actual + (objetivo - actual) * (1 - math.exp(-k * dt))
end

-- Pega una parte a otra (soldadura fija)
local function unir(hijo, padre)
	local w = Instance.new("Weld")
	w.Part0 = padre
	w.Part1 = hijo
	w.C0 = RESTO[padre]:ToObjectSpace(RESTO[hijo])
	w.Parent = hijo
end

-- Crea una parte. "tam" y la posición de "resto" van SIN escalar (aquí se escalan).
local function crearParte(carpeta, nombre, tam, resto, color, material, padre, forma)
	local p = Instance.new("Part")
	p.Name = nombre
	if forma then
		p.Shape = forma
	end
	p.Size = tam * ESC
	local escalado = CFrame.new(resto.Position * ESC) * (resto - resto.Position)
	RESTO[p] = escalado
	p.CFrame = RAIZ * escalado
	p.Color = color
	p.Material = material or MAT
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = tam.Magnitude > 0.9
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = carpeta
	if padre then
		unir(p, padre)
	end
	return p
end

-- Bloque con rotación en grados (Vector3)
local function bloque(carpeta, nombre, tam, pos, rot, color, material, padre)
	local r = rot or V(0, 0, 0)
	local cf = CFrame.new(pos) * CFrame.Angles(rad(r.X), rad(r.Y), rad(r.Z))
	return crearParte(carpeta, nombre, tam, cf, color, material, padre)
end

-- Articulación (Motor6D) que gira alrededor de "pivote" (SIN escalar)
local function junta(nombre, padre, hijo, pivote)
	local pv = CFrame.new(pivote * ESC)
	local m = Instance.new("Motor6D")
	m.Name = nombre
	m.Part0 = padre
	m.Part1 = hijo
	m.C0 = RESTO[padre]:ToObjectSpace(pv)
	m.C1 = RESTO[hijo]:ToObjectSpace(pv)
	m.Parent = hijo
	BASES[m] = m.C0
	return m
end

-- Diente en dos escalones (base ancha + punta fina)
local function diente(carpeta, padre, x, yRaiz, z, sentido, largo)
	bloque(carpeta, "Diente", V(0.17, largo * 0.55, 0.17), V(x, yRaiz + sentido * largo * 0.275, z), nil, DIENTE, Enum.Material.SmoothPlastic, padre)
	bloque(carpeta, "PuntaDiente", V(0.09, largo * 0.5, 0.09), V(x, yRaiz + sentido * largo * 0.75, z), nil, DIENTE, Enum.Material.SmoothPlastic, padre)
end

-- Runa brillante hecha de líneas finas sobre una placa lateral
local function runa(carpeta, padre, x, cy, cz, segmentos)
	for _, s in ipairs(segmentos) do
		local a = V(x, cy + s[2], cz + s[1])
		local b = V(x, cy + s[4], cz + s[3])
		local largo = (b - a).Magnitude
		crearParte(carpeta, "Runa", V(0.13, 0.07, largo + 0.12),
			CFrame.lookAt((a + b) / 2, b, Vector3.xAxis), COLOR_RUNA, Enum.Material.Neon, padre)
	end
end

local RUNA_HOMBRO = { { 0, 1.0, 0, -1.0 }, { -0.4, 0.55, 0.4, -0.1 }, { 0.4, 0.55, -0.4, -0.1 }, { 0, -0.35, 0.45, -0.8 } }
local RUNA_CADERA = { { -0.25, 0.9, 0.25, 0.5 }, { 0.25, 0.5, -0.25, 0.1 }, { -0.25, 0.1, 0.25, -0.3 }, { 0.45, 0.95, 0.45, -0.7 }, { -0.1, -0.3, -0.45, -0.7 } }

--// CONSTRUCCIÓN DEL LOBO -----------------------------------------------------
local function crearLobo(posicionSuelo)
	ESC = CONFIG.ESCALA
	MAT = CONFIG.MATERIAL
	RESTO = {}
	RAIZ = CFrame.new(posicionSuelo + Vector3.new(0, ALTURA_CUERPO * ESC, 0)) * CFrame.Angles(0, rad(CONFIG.ROTACION), 0)

	local azar = Random.new(os.time() % 100000)

	local modelo = Instance.new("Model")
	modelo.Name = "LoboSombrio"

	local function carpeta(nombre)
		local f = Instance.new("Folder")
		f.Name = nombre
		f.Parent = modelo
		return f
	end
	local cCuerpo = carpeta("Cuerpo")
	local cCabeza = carpeta("Cabeza")
	local cPatas  = carpeta("Patas")
	local cCola   = carpeta("Cola")
	local cRunas  = carpeta("Runas")
	local cLlamas = carpeta("Llamas")

	local emisores = {}   -- partículas
	local llamasLista = {} -- lenguas de fuego animadas
	local luces = {}      -- luces de los ojos
	local ojosPartes = {}

	-- RAÍZ INVISIBLE (la que mueve el Humanoid) --------------------------------
	local raiz = crearParte(modelo, "HumanoidRootPart", V(2.6, 1.2, 5.4), CFrame.new(0, 0, 0.5), Color3.new(1, 1, 1))
	raiz.Transparency = 1
	raiz.CanCollide = true
	raiz.CanTouch = true
	raiz.Massless = false
	modelo.PrimaryPart = raiz

	-- TRASERO (parte trasera del torso) -----------------------------------------
	local trasero = bloque(cCuerpo, "Trasero", V(2.5, 2.4, 3.8), V(0, 0, 1.8), nil, CARBON)
	local mTrasero = junta("ColumnaTrasera", raiz, trasero, V(0, 0, 0.3))
	bloque(cCuerpo, "Grupa", V(2.2, 2.0, 0.9), V(0, 0.15, 3.5), nil, NEGRO, nil, trasero)
	bloque(cCuerpo, "LomoTrasero", V(2.0, 0.5, 3.4), V(0, 1.3, 1.9), nil, NEGRO, nil, trasero)
	for i = 1, 4 do
		bloque(cCuerpo, "PuaTrasera", V(0.45, 0.9 + (i % 2) * 0.3, 0.4), V((i % 2 == 0) and 0.3 or -0.3, 1.8, 0.5 + i * 0.7), V(24, 0, (i % 2 == 0) and 6 or -6), (i % 2 == 0) and CARBON or NEGRO, nil, trasero)
	end
	for _, s in ipairs({ -1, 1 }) do
		local placa = bloque(cCuerpo, "PlacaCadera", V(0.5, 2.2, 2.0), V(s * 1.52, 0.0, 2.5), V(0, 0, s * 4), GRIS, nil, trasero)
		runa(cRunas, trasero, s * 1.79, 0.0, 2.5, RUNA_CADERA)
		bloque(cCuerpo, "PlacaCaderaSup", V(0.45, 0.7, 1.4), V(s * 1.45, 1.05, 2.1), V(0, 0, s * 12), GRIS_CLARO, nil, trasero)
	end

	-- PECHO ---------------------------------------------------------------------
	local pecho = bloque(cCuerpo, "Pecho", V(3.0, 2.8, 3.0), V(0, 0.15, -1.55), nil, NEGRO)
	local mPecho = junta("ColumnaPecho", trasero, pecho, V(0, 0, -0.1))
	bloque(cCuerpo, "PlacaPecho", V(2.3, 1.3, 0.9), V(0, -0.65, -3.0), V(-8, 0, 0), GRIS, nil, pecho)
	bloque(cCuerpo, "Cuello", V(1.9, 1.7, 1.5), V(0, 0.55, -3.45), V(-8, 0, 0), CARBON, nil, pecho)
	bloque(cCuerpo, "CruzGris", V(2.2, 0.8, 1.6), V(0, 1.3, -2.0), V(-6, 0, 0), CARBON, nil, pecho)
	for _, s in ipairs({ -1, 1 }) do
		bloque(cCuerpo, "Hombrera", V(0.55, 2.6, 2.3), V(s * 1.8, -0.1, -1.5), V(-8, 0, s * 4), GRIS, nil, pecho)
		runa(cRunas, pecho, s * 2.09, -0.2, -1.5, RUNA_HOMBRO)
		bloque(cCuerpo, "HombreraSup", V(0.6, 0.8, 1.7), V(s * 1.6, 1.15, -1.6), V(-10, 0, s * 18), GRIS_CLARO, nil, pecho)
		bloque(cCuerpo, "Cruz", V(1.3, 0.45, 2.4), V(s * 0.75, 1.7, -1.6), V(6, s * 4, s * -6), CARBON, nil, pecho)
	end

	-- Melena de picos sobre los hombros
	local picos = {
		{ -0.9, -2.6, 1.5, 25, -10 }, { 0.2, -2.7, 1.9, 28, 8 }, { 0.95, -2.5, 1.4, 22, 12 },
		{ -0.5, -1.9, 1.8, 30, -8 }, { 0.6, -1.8, 2.1, 32, 10 }, { -1.0, -1.2, 1.3, 24, -14 },
		{ 0.1, -1.0, 1.6, 28, 2 }, { 1.0, -0.7, 1.2, 22, 14 }, { -0.3, -0.3, 1.1, 20, -5 },
	}
	for i, p in ipairs(picos) do
		bloque(cCuerpo, "PicoMelena", V(0.55, p[3], 0.5), V(p[1], 1.55 + p[3] * 0.42, p[2]), V(p[4], i * 17, p[5]), (i % 2 == 0) and CARBON or NEGRO, nil, pecho)
	end

	-- CABEZA ----------------------------------------------------------------------
	local cabeza = bloque(cCabeza, "Cabeza", V(2.0, 1.6, 1.7), V(0, 0.7, -4.55), nil, CARBON)
	local mCuello = junta("Cuello", pecho, cabeza, V(0, 0.5, -3.85))
	bloque(cCabeza, "Frente", V(2.05, 0.32, 0.55), V(0, 1.22, -5.15), V(-12, 0, 0), NEGRO, nil, cabeza)
	bloque(cCabeza, "Craneo", V(1.6, 0.5, 1.4), V(0, 1.45, -4.3), V(8, 0, 0), NEGRO, nil, cabeza)
	bloque(cCabeza, "HocicoBase", V(1.25, 1.0, 1.1), V(0, 0.3, -5.8), V(-5, 0, 0), GRIS, nil, cabeza)
	bloque(cCabeza, "HocicoPunta", V(0.95, 0.75, 0.9), V(0, 0.15, -6.55), V(-8, 0, 0), GRIS, nil, cabeza)
	bloque(cCabeza, "Nariz", V(0.55, 0.4, 0.4), V(0, 0.28, -7.0), V(-8, 0, 0), NEGRO, nil, cabeza)
	bloque(cCabeza, "Paladar", V(0.85, 0.12, 1.9), V(0, -0.2, -5.95), nil, ENCIA, nil, cabeza)
	for _, s in ipairs({ -1, 1 }) do
		bloque(cCabeza, "Pomulo", V(0.35, 1.0, 1.1), V(s * 1.05, 0.35, -4.75), V(0, s * 15, 0), GRIS, nil, cabeza)
		bloque(cCabeza, "LabioSup", V(0.14, 0.32, 1.7), V(s * 0.66, -0.12, -5.95), nil, NEGRO, nil, cabeza)
		bloque(cCabeza, "Mejilla", V(0.5, 0.8, 0.9), V(s * 0.9, 0.25, -5.2), V(0, s * -10, 0), CARBON, nil, cabeza)
	end

	-- Ojos brillantes con cicatriz
	for _, s in ipairs({ -1, 1 }) do
		local ojo = bloque(cCabeza, "Ojo", V(0.55, 0.28, 0.12), V(s * 0.62, 0.78, -5.43), V(0, 0, s * 20), COLOR_OJO, Enum.Material.Neon, cabeza)
		local centro = bloque(cCabeza, "OjoCentro", V(0.3, 0.14, 0.14), V(s * 0.62, 0.78, -5.47), V(0, 0, s * 20), Color3.fromRGB(235, 190, 255), Enum.Material.Neon, cabeza)
		local cicatriz = bloque(cCabeza, "Cicatriz", V(0.07, 0.8, 0.07), V(s * 0.42, 0.98, -5.46), V(0, 0, s * -18), COLOR_OJO, Enum.Material.Neon, cabeza)
		table.insert(ojosPartes, ojo)
		table.insert(ojosPartes, cicatriz)
		local luz = Instance.new("PointLight")
		luz.Color = COLOR_OJO
		luz.Range = 14 * ESC
		luz.Brightness = 1.5
		luz.Shadows = false
		luz.Parent = ojo
		table.insert(luces, { luz = luz, base = 1.5 })
	end

	-- Orejas (se mueven)
	local orejas = {}
	for _, s in ipairs({ -1, 1 }) do
		local rot = V(12, 0, -s * 12)
		local oreja = bloque(cCabeza, "Oreja", V(0.8, 0.95, 0.38), V(s * 0.65, 1.8, -4.15), rot, NEGRO)
		bloque(cCabeza, "PuntaOreja", V(0.5, 0.8, 0.3), V(s * 0.7, 2.5, -4.05), rot, NEGRO, nil, oreja)
		bloque(cCabeza, "InteriorOreja", V(0.4, 0.8, 0.1), V(s * 0.66, 2.05, -4.36), rot, VIOLETA_OSC, nil, oreja)
		local m = junta("Oreja", cabeza, oreja, V(s * 0.65, 1.35, -4.15))
		table.insert(orejas, { m = m, lado = s })
	end

	-- Dientes de arriba
	local zArriba = { -5.45, -5.8, -6.15, -6.5, -6.8 }
	for i, z in ipairs(zArriba) do
		for _, s in ipairs({ -1, 1 }) do
			diente(cCabeza, cabeza, s * 0.52, -0.2, z, -1, (i == 3) and 0.6 or 0.3)
		end
	end

	-- MANDÍBULA (se abre y cierra) ---------------------------------------------
	local mandibula = bloque(cCabeza, "Mandibula", V(0.95, 0.45, 1.9), V(0, -0.42, -5.9), nil, NEGRO)
	local mMandibula = junta("Mandibula", cabeza, mandibula, V(0, -0.2, -4.95))
	bloque(cCabeza, "Menton", V(0.7, 0.32, 0.4), V(0, -0.46, -6.95), V(-8, 0, 0), NEGRO, nil, mandibula)
	bloque(cCabeza, "EnciaInferior", V(0.7, 0.1, 1.5), V(0, -0.2, -5.95), nil, ENCIA, nil, mandibula)
	bloque(cCabeza, "Barbilla", V(0.8, 0.3, 1.2), V(0, -0.7, -6.2), nil, CARBON, nil, mandibula)
	local zAbajo = { -5.5, -5.85, -6.2, -6.55, -6.85 }
	for i, z in ipairs(zAbajo) do
		for _, s in ipairs({ -1, 1 }) do
			diente(cCabeza, mandibula, s * 0.38, -0.22, z, 1, (i == 4) and 0.5 or 0.28)
		end
	end

	-- COLA (4 segmentos articulados) ---------------------------------------------
	local cola = {}
	local colaDatos = {
		{ V(0.8, 0.8, 1.3), 4.3, NEGRO, 3.65 },
		{ V(0.7, 0.7, 1.3), 5.6, VIOLETA_OSC, 4.95 },
		{ V(0.55, 0.55, 1.2), 6.85, Color3.fromRGB(38, 30, 120), 6.25 },
		{ V(0.4, 0.4, 1.1), 8.0, Color3.fromRGB(110, 34, 170), 7.45 },
	}
	local segPadre = trasero
	local segmentosCola = {}
	for i, d in ipairs(colaDatos) do
		local seg = bloque(cCola, "Cola" .. i, d[1], V(0, 0.4, d[2]), nil, d[3])
		local m = junta("Cola" .. i, segPadre, seg, V(0, 0.4, d[4]))
		table.insert(cola, m)
		table.insert(segmentosCola, seg)
		segPadre = seg
	end

	-- PATAS ------------------------------------------------------------------------
	local patas = {}
	local pataPies = {}

	local function crearPata(lado, frontal, nombre, faseTrote, faseGalope)
		local x, supPos, infPos, piePos, hombro, rodilla, tobillo, supTam, infTam, pieTam, padreSup, colorSup
		if frontal then
			x = lado * 1.2
			supTam, infTam, pieTam = V(0.95, 1.4, 1.15), V(0.78, 1.1, 0.9), V(1.0, 0.28, 1.5)
			supPos, infPos, piePos = V(x, -1.0, -1.55), V(x, -2.25, -1.6), V(x, -2.86, -1.9)
			hombro, rodilla, tobillo = V(x, -0.45, -1.55), V(x, -1.75, -1.55), V(x, -2.75, -1.6)
			padreSup, colorSup = pecho, GRIS
		else
			x = lado * 1.1
			supTam, infTam, pieTam = V(1.05, 1.5, 1.5), V(0.8, 1.15, 0.95), V(0.95, 0.28, 1.4)
			supPos, infPos, piePos = V(x, -0.95, 2.45), V(x, -2.25, 2.6), V(x, -2.86, 2.3)
			hombro, rodilla, tobillo = V(x, -0.3, 2.45), V(x, -1.75, 2.5), V(x, -2.75, 2.6)
			padreSup, colorSup = trasero, CARBON
		end

		local sup = bloque(cPatas, nombre .. "Superior", supTam, supPos, nil, colorSup)
		local m1 = junta(nombre .. "Hombro", padreSup, sup, hombro)
		local inf = bloque(cPatas, nombre .. "Inferior", infTam, infPos, nil, GRIS)
		local m2 = junta(nombre .. "Rodilla", sup, inf, rodilla)
		local pie = bloque(cPatas, nombre .. "Pata", pieTam, piePos, nil, CARBON)
		local m3 = junta(nombre .. "Tobillo", inf, pie, tobillo)

		-- Garras
		local zGarra = piePos.Z - pieTam.Z / 2 - 0.1
		for i = -1, 1 do
			bloque(cPatas, "Garra", V(0.14, 0.16, 0.6), V(x + i * 0.3, -2.92, zGarra), V(-12, 0, 0), INDIGO_GARRA, nil, pie)
		end

		table.insert(patas, { m1 = m1, m2 = m2, m3 = m3, frontal = frontal, faseTrote = faseTrote, faseGalope = faseGalope })
		table.insert(pataPies, pie)
	end

	crearPata(-1, true, "DelanteraIzq", 0.0, 0.0)
	crearPata(1, true, "DelanteraDer", 0.5, 0.12)
	crearPata(-1, false, "TraseraIzq", 0.5, 0.5)
	crearPata(1, false, "TraseraDer", 0.0, 0.62)

	-- LLAMAS (lenguas de fuego que ondean) ------------------------------------------
	local function llama(padre, base, alto, ancho)
		local giro = CFrame.Angles(0, rad(azar:NextNumber(0, 360)), 0) * CFrame.Angles(rad(azar:NextNumber(-22, 22)), 0, rad(azar:NextNumber(-22, 22)))
		local resto = CFrame.new(base) * giro * CFrame.new(0, alto / 2, 0)
		local indice = azar:NextInteger(1, #COLORES_LLAMA)
		local material = (indice == 6) and Enum.Material.Neon or Enum.Material.SmoothPlastic
		local p = crearParte(cLlamas, "Llama", V(ancho, alto, ancho * 0.22), resto, COLORES_LLAMA[indice], material)
		p.CastShadow = false

		local pivoteCF = RESTO[p] * CFrame.new(0, -alto * ESC / 2, 0)
		local m = Instance.new("Motor6D")
		m.Name = "Llama"
		m.Part0 = padre
		m.Part1 = p
		m.C0 = RESTO[padre]:ToObjectSpace(pivoteCF)
		m.C1 = CFrame.new(0, -alto * ESC / 2, 0)
		m.Parent = p

		local rotSolo = RESTO[p] - RESTO[p].Position
		table.insert(llamasLista, {
			motor = m, base = m.C0, rot = rotSolo, rotInv = rotSolo:Inverse(),
			sem = azar:NextNumber(0, 100), vel = azar:NextNumber(1.2, 2.6),
		})
		return p
	end

	-- Lomo (pecho)
	local lomoLlamas = {
		{ -0.7, 2.0, -2.5, 1.5, 0.55 }, { 0.1, 2.2, -2.2, 2.0, 0.7 }, { 0.8, 2.0, -1.9, 1.6, 0.6 },
		{ -0.5, 2.4, -1.4, 2.2, 0.75 }, { 0.4, 2.6, -1.1, 2.4, 0.8 }, { -0.9, 2.1, -0.8, 1.5, 0.55 },
		{ 0.9, 2.2, -0.5, 1.7, 0.6 }, { 0.0, 2.4, -0.2, 1.9, 0.65 },
	}
	for _, d in ipairs(lomoLlamas) do
		llama(pecho, V(d[1], d[2], d[3]), d[4], d[5])
	end
	-- Masas grandes de fuego morado sobre el lomo
	llama(pecho, V(0.2, 2.1, -1.9), 1.9, 1.5)
	llama(pecho, V(-0.4, 2.2, -1.2), 1.7, 1.3)
	llama(pecho, V(0.7, 2.0, -0.9), 1.6, 1.2)
	-- Lomo (trasero)
	for i = 1, 5 do
		llama(trasero, V(azar:NextNumber(-0.6, 0.6), 1.6, 0.5 + i * 0.6), azar:NextNumber(1.0, 1.8), azar:NextNumber(0.4, 0.7))
	end
	-- Detrás de las orejas
	for i = 1, 3 do
		llama(cabeza, V(azar:NextNumber(-0.7, 0.7), 1.5, -3.9), azar:NextNumber(0.8, 1.3), azar:NextNumber(0.35, 0.55))
	end
	-- Cola en llamas
	for i = 2, 4 do
		for _ = 1, 4 do
			llama(segmentosCola[i], V(azar:NextNumber(-0.3, 0.3), 0.55, colaDatos[i][2] + azar:NextNumber(-0.5, 0.5)), azar:NextNumber(1.0, 1.9), azar:NextNumber(0.4, 0.8))
		end
	end
	-- Fuego en las patas
	for _, pie in ipairs(pataPies) do
		local pos = RESTO[pie].Position / ESC
		for _ = 1, 4 do
			llama(pie, V(pos.X + azar:NextNumber(-0.4, 0.4), pos.Y + 0.15, pos.Z + azar:NextNumber(-0.5, 0.3)), azar:NextNumber(0.7, 1.3), azar:NextNumber(0.3, 0.5))
		end
	end

	-- PARTÍCULAS ------------------------------------------------------------------------
	local function emisor(parte, offset, tasa, tamano, textura, vida, brasas)
		local att = Instance.new("Attachment")
		att.Position = offset * ESC
		att.Parent = parte
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = textura or "rbxasset://textures/particles/fire_main.dds"
		pe.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 100, 255)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(112, 40, 190)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 20, 110)),
		})
		pe.LightEmission = brasas and 1 or 0.55
		pe.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, tamano * ESC),
			NumberSequenceKeypoint.new(0.6, tamano * 0.75 * ESC),
			NumberSequenceKeypoint.new(1, 0),
		})
		pe.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.7, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		pe.Lifetime = NumberRange.new(vida * 0.7, vida)
		pe.Speed = NumberRange.new(1.5 * ESC, 4.5 * ESC)
		pe.Acceleration = Vector3.new(0, 6 * ESC, 0)
		pe.SpreadAngle = Vector2.new(28, 28)
		pe.Rotation = NumberRange.new(0, 360)
		pe.RotSpeed = NumberRange.new(-90, 90)
		pe.EmissionDirection = Enum.NormalId.Top
		pe.Rate = tasa
		pe.Parent = att
		table.insert(emisores, { pe = pe, base = tasa })
		return pe
	end

	emisor(pecho, V(0, 2.3, -1.6), 22, 2.2, nil, 1.1)
	emisor(pecho, V(0, 2.3, -1.6), 10, 0.35, "rbxasset://textures/particles/sparkles_main.dds", 1.6, true)
	emisor(trasero, V(0, 1.8, 1.8), 16, 1.8, nil, 1.0)
	emisor(cabeza, V(0, 1.7, -3.9), 8, 1.2, nil, 0.9)
	emisor(segmentosCola[3], V(0, 0.4, 0), 16, 1.9, nil, 1.2)
	emisor(segmentosCola[4], V(0, 0.4, 0), 20, 2.2, nil, 1.4)
	emisor(segmentosCola[4], V(0, 0.4, 0), 8, 0.35, "rbxasset://textures/particles/sparkles_main.dds", 1.8, true)
	for _, pie in ipairs(pataPies) do
		emisor(pie, V(0, 0.4, -0.2), 12, 1.1, nil, 0.8)
	end

	-- Luz de aura morada sobre el lomo
	local aura = Instance.new("PointLight")
	aura.Color = Color3.fromRGB(120, 50, 210)
	aura.Range = 22 * ESC
	aura.Brightness = 1
	aura.Shadows = false
	aura.Parent = pecho

	-- HUMANOID (cerebro del movimiento) ------------------------------------------------
	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R15
	hum.HipHeight = (ALTURA_CUERPO - 0.6) * ESC
	hum.MaxHealth = CONFIG.VIDA
	hum.Health = CONFIG.VIDA
	hum.WalkSpeed = CONFIG.VEL_CAMINAR
	hum.JumpHeight = 7
	hum.AutoRotate = true
	hum.BreakJointsOnDeath = false
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	hum.Parent = modelo

	modelo.Parent = Workspace
	pcall(function()
		raiz:SetNetworkOwner(nil) -- el servidor controla la física (movimiento fluido para todos)
	end)

	--// ANIMACIÓN ---------------------------------------------------------------------
	local POSES = {
		Reposo      = { mandibula = 0.04, pitch = 0, yaw = 0, agache = 0, estocada = 0, llamas = 0.8, ojos = 1, orejas = 0, ocioso = 1, temblor = 0 },
		Patrulla    = { mandibula = 0.05, pitch = -0.05, yaw = 0, agache = 0, estocada = 0, llamas = 0.9, ojos = 1, orejas = 0.1, ocioso = 0.6, temblor = 0 },
		Rugido      = { mandibula = 0.75, pitch = -0.2, yaw = 0, agache = 1, estocada = -0.2, llamas = 2.6, ojos = 2.8, orejas = 1, ocioso = 0, temblor = 1 },
		Persecucion = { mandibula = 0.2, pitch = -0.15, yaw = 0, agache = 0, estocada = 0, llamas = 2.0, ojos = 2.2, orejas = 0.9, ocioso = 0, temblor = 0 },
		Muerte      = { mandibula = 0.5, pitch = -0.6, yaw = 0.2, agache = 2.2, estocada = 0, llamas = 0, ojos = 0, orejas = 1, ocioso = 0, temblor = 0 },
	}
	local obj, cur = {}, {}
	for k, v in pairs(POSES.Reposo) do
		obj[k] = v
		cur[k] = v
	end
	local velK = { pitch = 7, yaw = 5, agache = 7, estocada = 14, llamas = 3, ojos = 5, orejas = 8, ocioso = 4, temblor = 8 }
	local kMand = 10

	local function ponerPose(nombre)
		for k, v in pairs(POSES[nombre]) do
			obj[k] = v
		end
		kMand = 10
	end

	local fase, ampSuave, gSuave = 0, 0, 0
	local acumulador = 0
	local ultimoOjo = -1

	local function actualizar(dt)
		local t = os.clock()
		for k, v in pairs(obj) do
			cur[k] = suave(cur[k], v, (k == "mandibula") and kMand or velK[k] or 6, dt)
		end

		local v3 = raiz.AssemblyLinearVelocity
		local vel = Vector3.new(v3.X, 0, v3.Z).Magnitude
		ampSuave = suave(ampSuave, math.clamp(vel / 5, 0, 1), 10, dt)
		gSuave = suave(gSuave, math.clamp((vel - 14) / 14, 0, 1), 4, dt)
		local g, amp, ocioso = gSuave, ampSuave, cur.ocioso
		local zancada = lerp(6.5, 11, g) * ESC
		fase = (fase + dt * vel / zancada) % 1

		-- PATAS: oscilación + flexión de rodilla + tobillo compensado
		for _, pata in ipairs(patas) do
			local a = PI2 * (fase + lerp(pata.faseTrote, pata.faseGalope, g))
			local s, c = math.sin(a), math.cos(a)
			local amp1 = (pata.frontal and lerp(0.55, 0.9, g) or lerp(0.5, 0.8, g)) * amp
			local t1 = amp1 * s
			local t2 = -lerp(0.6, 1.05, g) * math.max(0, c) * amp
			if pata.frontal then
				t1 = t1 + 0.55 * cur.agache
				t2 = t2 - 0.9 * cur.agache
			else
				t1 = t1 + 0.1 + 0.35 * cur.agache
				t2 = t2 - 0.2 - 0.7 * cur.agache
			end
			local t3 = -(t1 + t2) * 0.85
			pata.m1.C0 = BASES[pata.m1] * CFrame.Angles(t1, 0, 0)
			pata.m2.C0 = BASES[pata.m2] * CFrame.Angles(t2, 0, 0)
			pata.m3.C0 = BASES[pata.m3] * CFrame.Angles(t3, 0, 0)
		end

		-- COLUMNA: rebote y flexión al galopar, respiración en reposo
		local respira = math.sin(t * 2.0) * 0.012
		local rebote = math.abs(math.sin(PI2 * fase)) * 0.12 * ESC * g * amp
		local pitchRear = -math.sin(PI2 * (fase + 0.25)) * 0.07 * g * amp
		local pitchPecho = math.sin(PI2 * (fase + 0.5)) * 0.09 * g * amp - 0.18 * cur.agache + respira + cur.estocada * 0.12
		local yawPecho = math.sin(PI2 * fase) * 0.05 * (1 - g) * amp
		mTrasero.C0 = BASES[mTrasero] * CFrame.new(0, rebote, 0) * CFrame.Angles(pitchRear, 0, 0)
		mPecho.C0 = BASES[mPecho] * CFrame.Angles(pitchPecho, yawPecho, 0)

		-- CABEZA
		local pitchCab = cur.pitch - 0.12 * g * amp + (-0.04 + math.sin(t * 0.9) * 0.05) * ocioso - pitchPecho * 0.5
		local yawCab = cur.yaw + math.sin(t * 0.45) * 0.28 * ocioso + math.sin(PI2 * fase) * 0.06 * amp * (1 - g)
		mCuello.C0 = BASES[mCuello] * CFrame.new(0, 0, -0.7 * ESC * cur.estocada) * CFrame.Angles(pitchCab, yawCab, 0)

		-- MANDÍBULA (jadeo al correr, temblor al rugir)
		local abre = cur.mandibula
			+ 0.1 * amp * g * (0.5 + 0.5 * math.sin(t * 14))
			+ cur.temblor * math.sin(t * 38) * 0.05
			+ 0.02 * math.sin(t * 2.0) * ocioso
		mMandibula.C0 = BASES[mMandibula] * CFrame.Angles(-math.clamp(abre, 0, 1.15), 0, 0)

		-- OREJAS
		for i, o in ipairs(orejas) do
			local twitch = math.noise(t * 1.7, i * 3.1, 0) * 0.5
			local ex = cur.orejas * 0.6 + twitch * 0.25 * ocioso
			local ez = o.lado * (0.08 + twitch * 0.2 * ocioso - cur.orejas * 0.15)
			o.m.C0 = BASES[o.m] * CFrame.Angles(ex, 0, ez)
		end

		-- COLA
		for i, m in ipairs(cola) do
			local giroY = math.sin(t * 2.2 - i * 0.7) * (0.1 + 0.12 * ocioso) + math.sin(t * 6 - i) * 0.05 * amp
			local pitch = -(0.24 - 0.14 * g) + math.sin(PI2 * fase - i * 0.6) * 0.07 * g * amp + cur.agache * 0.04
			m.C0 = BASES[m] * CFrame.Angles(pitch, giroY, 0)
		end

		-- EFECTOS (30 veces por segundo): llamas, luces y partículas
		acumulador += dt
		if acumulador >= 1 / 30 then
			acumulador = 0
			local viento = 0.12 + g * 0.75 * amp
			local fuerza = 0.55 + cur.llamas * 0.4
			for _, s in ipairs(llamasLista) do
				local n1 = math.noise(t * s.vel, s.sem, 0)
				local n2 = math.noise(t * s.vel * 0.8, s.sem, 7.3)
				local n3 = math.noise(t * s.vel * 1.1, s.sem, 3.1)
				local Rw = CFrame.Angles(viento + n1 * 0.9 * fuerza, n2 * 0.5, n3 * 0.9 * fuerza)
				s.motor.C0 = s.base * (s.rotInv * Rw * s.rot)
			end
			for _, e in ipairs(emisores) do
				e.pe.Rate = e.base * cur.llamas
			end
			for _, l in ipairs(luces) do
				l.luz.Brightness = l.base * cur.ojos
			end
			aura.Brightness = 0.5 + cur.llamas * 0.45
			if math.abs(cur.ojos - ultimoOjo) > 0.02 then
				ultimoOjo = cur.ojos
				local color = OJO_APAGADO:Lerp(COLOR_OJO, math.clamp(cur.ojos, 0, 1))
				for _, p in ipairs(ojosPartes) do
					p.Color = color
				end
			end
		end
	end

	local conexion
	conexion = RunService.Heartbeat:Connect(function(dt)
		if not modelo.Parent then
			conexion:Disconnect()
			return
		end
		actualizar(dt)
	end)

	--// INTELIGENCIA ARTIFICIAL ----------------------------------------------------------
	local estado = "Reposo"
	local muerto = false
	local proximoAtaque = 0
	local proximoPaseo = os.clock() + 2
	local destinoPaseo = nil
	local inicioPaseo = 0
	local rugidoFin = 0
	local tiempoAtasco = 0
	local posInicial = raiz.Position

	local function buscarJugador(rango)
		local mejorHRP, mejorDist, mejorHum
		for _, jugador in ipairs(Players:GetPlayers()) do
			local char = jugador.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local h = char and char:FindFirstChildOfClass("Humanoid")
			if hrp and h and h.Health > 0 then
				local d = (hrp.Position - raiz.Position).Magnitude
				if d <= rango and (not mejorDist or d < mejorDist) then
					mejorHRP, mejorDist, mejorHum = hrp, d, h
				end
			end
		end
		return mejorHRP, mejorDist, mejorHum
	end

	local function explosionDeFuego(cantidad)
		for _, e in ipairs(emisores) do
			e.pe:Emit(cantidad)
		end
	end

	local function atacar(hrp, h)
		estado = "Ataque"
		proximoAtaque = os.clock() + CONFIG.ENFRIAMIENTO_ATAQUE

		-- 1) Preparación: se agacha y abre la boca de par en par
		hum.WalkSpeed = 3
		hum:MoveTo(hrp.Position)
		ponerPose("Rugido")
		obj.agache, obj.pitch, obj.mandibula, obj.estocada, obj.temblor = 0.9, 0.3, 1.05, -0.5, 0
		kMand = 14
		task.wait(0.28)
		if muerto or not hrp.Parent then
			estado = "Persecucion"
			return
		end

		-- 2) Estocada hacia el jugador
		hum.WalkSpeed = CONFIG.VEL_ESTOCADA
		hum:MoveTo(hrp.Position + hrp.AssemblyLinearVelocity * 0.25)
		obj.estocada, obj.pitch, obj.agache = 1, -0.4, 0.2
		task.wait(0.14)
		if muerto then
			return
		end

		-- 3) Mordida: cierra la mandíbula de golpe
		kMand = 32
		obj.mandibula = 0
		explosionDeFuego(6)
		if CONFIG.DANO > 0 and hrp.Parent and h.Health > 0 and (hrp.Position - raiz.Position).Magnitude <= CONFIG.RANGO_ATAQUE + 3 then
			h:TakeDamage(CONFIG.DANO)
		end
		task.wait(0.12)

		-- 4) Recuperación
		hum.WalkSpeed = CONFIG.VEL_CAMINAR
		ponerPose("Persecucion")
		task.wait(0.3)
		if not muerto then
			estado = "Persecucion"
		end
	end

	task.spawn(function()
		while modelo.Parent and not muerto do
			local rango = (estado == "Reposo" or estado == "Patrulla") and CONFIG.RANGO_DETECCION or CONFIG.RANGO_ABANDONO
			local hrp, dist, h = buscarJugador(rango)

			if hrp then
				if estado == "Reposo" or estado == "Patrulla" then
					-- ¡Detectó a alguien! Ruge antes de correr
					estado = "Rugido"
					rugidoFin = os.clock() + CONFIG.TIEMPO_RUGIDO
					hum.WalkSpeed = 1.5
					ponerPose("Rugido")
					explosionDeFuego(12)
				end

				if estado == "Rugido" then
					hum:MoveTo(hrp.Position) -- se va girando hacia el jugador
					if os.clock() >= rugidoFin then
						estado = "Persecucion"
						hum.WalkSpeed = CONFIG.VEL_CORRER
						ponerPose("Persecucion")
					end
				elseif estado == "Persecucion" then
					hum.WalkSpeed = CONFIG.VEL_CORRER
					hum:MoveTo(hrp.Position)
					if dist <= CONFIG.RANGO_ATAQUE and os.clock() >= proximoAtaque then
						atacar(hrp, h)
					end
					-- Si se atasca contra algo, salta
					local v3 = raiz.AssemblyLinearVelocity
					if Vector3.new(v3.X, 0, v3.Z).Magnitude < 3 and dist > CONFIG.RANGO_ATAQUE + 2 then
						tiempoAtasco += 0.1
						if tiempoAtasco > 0.5 then
							hum.Jump = true
							tiempoAtasco = 0
						end
					else
						tiempoAtasco = 0
					end
				end
			else
				-- Nadie cerca: vuelve a la calma
				if estado == "Persecucion" or estado == "Rugido" or estado == "Ataque" then
					estado = "Reposo"
					hum.WalkSpeed = CONFIG.VEL_CAMINAR
					hum:MoveTo(raiz.Position)
					ponerPose("Reposo")
					proximoPaseo = os.clock() + 2
				end

				if estado == "Reposo" and os.clock() >= proximoPaseo then
					local ang = math.random() * PI2
					local dis = math.random(8, CONFIG.RADIO_PATRULLA)
					destinoPaseo = posInicial + Vector3.new(math.cos(ang) * dis, 0, math.sin(ang) * dis)
					estado = "Patrulla"
					inicioPaseo = os.clock()
					hum.WalkSpeed = CONFIG.VEL_CAMINAR
					hum:MoveTo(destinoPaseo)
					ponerPose("Patrulla")
				elseif estado == "Patrulla" and destinoPaseo then
					local plano = Vector3.new(raiz.Position.X - destinoPaseo.X, 0, raiz.Position.Z - destinoPaseo.Z)
					if plano.Magnitude < 4 or os.clock() - inicioPaseo > 10 then
						estado = "Reposo"
						hum:MoveTo(raiz.Position)
						ponerPose("Reposo")
						proximoPaseo = os.clock() + math.random(3, 7)
					end
				end
			end

			task.wait(0.1)
		end
	end)

	--// MUERTE ------------------------------------------------------------------------------
	hum.Died:Connect(function()
		muerto = true
		estado = "Muerto"
		ponerPose("Muerte")
		explosionDeFuego(20)

		task.delay(2.5, function()
			-- Se desvanece poco a poco
			local partes = {}
			for _, d in ipairs(modelo:GetDescendants()) do
				if d:IsA("BasePart") and d ~= raiz then
					table.insert(partes, { d, d.Transparency })
				end
			end
			for paso = 1, 30 do
				if not modelo.Parent then
					return
				end
				for _, par in ipairs(partes) do
					par[1].Transparency = lerp(par[2], 1, paso / 30)
				end
				task.wait(0.07)
			end
			modelo:Destroy()
		end)

		if CONFIG.REAPARECER then
			task.delay(CONFIG.TIEMPO_REAPARICION, function()
				crearLobo(posicionSuelo)
			end)
		end
	end)

	modelo.Destroying:Connect(function()
		muerto = true
		if conexion then
			conexion:Disconnect()
		end
	end)

	return modelo
end

--// POSICIÓN SOBRE EL SUELO ----------------------------------------------------
local function obtenerPosicion()
	local pos = CONFIG.POSICION
	if CONFIG.APOYAR_EN_SUELO then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ignorar = {}
		for _, nombre in ipairs({ "Hongo", "Saco", "ArbustoMoras", "LoboSombrio" }) do
			local obj = Workspace:FindFirstChild(nombre)
			if obj then
				table.insert(ignorar, obj)
			end
		end
		for _, jugador in ipairs(Players:GetPlayers()) do
			if jugador.Character then
				table.insert(ignorar, jugador.Character)
			end
		end
		params.FilterDescendantsInstances = ignorar
		local resultado = Workspace:Raycast(pos + Vector3.new(0, 100, 0), Vector3.new(0, -300, 0), params)
		if resultado then
			return resultado.Position
		end
	end
	return pos
end

--// LANZADOR AVADA (lo unico agregado: PARTIDA invoca al lobo de noche) ----
local bfLobosAvada = Instance.new("BindableFunction")
bfLobosAvada.Name = "AvadaLobos"
bfLobosAvada.Parent = game:GetService("ServerScriptService")
bfLobosAvada.OnInvoke = function(accion, a, b)
	if accion == "crear" then
		local opts = b or {}
		local esc0, vida0, dano0 = CONFIG.ESCALA, CONFIG.VIDA, CONFIG.DANO
		if opts.escala then
			CONFIG.ESCALA = opts.escala
		end
		if opts.vida then
			CONFIG.VIDA = opts.vida
		end
		if opts.dano then
			CONFIG.DANO = opts.dano
		end
		local modelo = crearLobo(a)
		CONFIG.ESCALA, CONFIG.VIDA, CONFIG.DANO = esc0, vida0, dano0
		if modelo then
			modelo:SetAttribute("LoboAvada", true)
		end
		return modelo
	elseif accion == "sinReaparicion" then
		CONFIG.REAPARECER = false
		return true
	elseif accion == "conReaparicion" then
		CONFIG.REAPARECER = true
		return true
	end
	return nil
end

print("[Avada] LOBOS listos: el lobo sombrio espera la noche")
-- FIN LOBOS
