--[[
  🛡 DEFENSAS CONSTRUIBLES - SERVIDOR (como 99 Noches, al estilo Avada)
  Pegar como "Script" en ServerScriptService. NO toca partida.

  Dentro de la partida, el jugador abre el panel CONSTRUIR (cliente)
  y levanta defensas delante de él, pagando con TABLAS (la madera de
  los árboles, molida en el molino de la fogata) y, la trampa, con
  1 diamante de la moneda:

  - MURO DE ZARZAS (4 tablas): barrera física de 10x5,5 que frena a
    los lobos; sus espinas los hieren si se pegan (6/s) y ellos la
    muerden hasta romperla (120 de vida).
  - TRAMPA RÚNICA (2 tablas + 1💎): círculo rúnico en el suelo;
    cuando un lobo lo pisa, estalla: 45 de daño en área y los deja
    clavados 1,6 s. Tiene 2 cargas y se consume.
  - FAROLILLO (3 tablas): luz cálida que quema a los lobos que
    entren en su radio (12/s): un pequeño refugio junto a la fogata.

  Las defensas se parentan al modelo del bosque de la sesión: cuando
  partida destruye el clon al terminar, desaparecen con él. Solo
  dañan a modelos "LoboSombrio" (los lobos de lobos, con su Humanoid
  de siempre): El Grande y cualquier otra criatura quedan fuera.
  Máximo 8 defensas vivas por jugador.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RE = RS:FindFirstChild("DefensasEvent")
if not RE then
	RE = Instance.new("RemoteEvent")
	RE.Name = "DefensasEvent"
	RE.Parent = RS
end

local COSTES = {
	Muro = { tablas = 4, diamantes = 0 },
	Trampa = { tablas = 2, diamantes = 1 },
	Farol = { tablas = 3, diamantes = 0 },
}
local MAX_POR_JUGADOR = 8
local RADIO_BOSQUE = 285

local defensas = {} -- { tipo, modelo, dueno, hp?, cargas?, centro (BasePart) }

--// ============ GEOGRAFÍA (molde y clones, como todo en Avada) ============
local function bosqueDe(pos)
	local mejor, mejorDist = nil, math.huge
	for _, m in ipairs(Workspace:GetChildren()) do
		if m:IsA("Model") and m.Name == "BosqueProhibido" then
			local ok, piv = pcall(function()
				return m:GetPivot().Position
			end)
			if ok then
				local d = (Vector3.new(piv.X, 0, piv.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
				if d < mejorDist then
					mejor, mejorDist = m, d
				end
			end
		end
	end
	if mejor and mejorDist <= RADIO_BOSQUE then
		return mejor
	end
	return nil
end

local function hrpDe(player)
	local ch = player and player.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function avisar(player, texto)
	pcall(function()
		RE:FireClient(player, "Aviso", texto)
	end)
end

--// ============ PAGO: tablas (atributo) + moneda Diamantes ============
local function tablasDe(player)
	return player:GetAttribute("Tablas") or 0
end

local function bfDiamantes()
	return game:GetService("ServerScriptService"):FindFirstChild("AvadaDiamantes")
end

local function saldoMoneda(player)
	local bf = bfDiamantes()
	if bf then
		local ok, n = pcall(function()
			return bf:Invoke("saldo", player)
		end)
		if ok and type(n) == "number" then
			return n
		end
	end
	return 0
end

local function pagar(player, coste)
	if tablasDe(player) < coste.tablas then
		return false, "tablas"
	end
	if coste.diamantes > 0 and saldoMoneda(player) < coste.diamantes then
		return false, "diamantes"
	end
	player:SetAttribute("Tablas", tablasDe(player) - coste.tablas)
	if coste.diamantes > 0 then
		local bf = bfDiamantes()
		local ok, hecho = bf and pcall(function()
			return bf:Invoke("gastar", player, coste.diamantes)
		end)
		if not (ok and hecho == true) then
			player:SetAttribute("Tablas", tablasDe(player) + coste.tablas) -- devolución
			return false, "diamantes"
		end
	end
	return true
end

--// ============ CONSTRUCCIÓN (piezas) ============
local function parte(padre, nombre, size, cf, color, material, collide, shape)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Wood
	p.Anchored = true
	p.CanCollide = collide == true
	p.CanQuery = false
	p.CanTouch = false
	if shape then
		p.Shape = shape
	end
	p.Parent = padre
	return p
end

local MADERA = Color3.fromRGB(84, 58, 36)
local MADERA_OSCURA = Color3.fromRGB(58, 40, 24)
local ZARZA = Color3.fromRGB(38, 84, 34)
local ZARZA_CLARA = Color3.fromRGB(64, 128, 52)
local RUNA = Color3.fromRGB(168, 110, 255)

local function construirMuro(bosque, cf)
	local m = Instance.new("Model")
	m.Name = "DefensaMuro"
	for _, x in ipairs({ -5, 0, 5 }) do
		parte(m, "Poste", Vector3.new(0.9, 5.6, 0.9), cf * CFrame.new(x, 2.8, 0), MADERA_OSCURA, Enum.Material.Wood, true)
	end
	for _, y in ipairs({ 1.6, 3.9 }) do
		parte(m, "Travesano", Vector3.new(11, 0.7, 0.55), cf * CFrame.new(0, y, 0), MADERA, Enum.Material.Wood, true)
	end
	for i = -2, 2 do
		parte(m, "Zarza", Vector3.new(2.3, 2.3, 2.3), cf * CFrame.new(i * 2.1, 2.9, 0.35), ZARZA, Enum.Material.Grass, false, Enum.PartType.Ball)
		parte(m, "ZarzaClara", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(i * 2.1 + 0.5, 4.1, 0.3), ZARZA_CLARA, Enum.Material.Grass, false, Enum.PartType.Ball)
	end
	m.Parent = bosque
	return m, m:FindFirstChild("Poste")
end

local function construirTrampa(bosque, cf)
	local m = Instance.new("Model")
	m.Name = "DefensaTrampa"
	local base = parte(m, "Circulo", Vector3.new(7, 0.3, 7), cf, Color3.fromRGB(30, 22, 48), Enum.Material.Slate, false, Enum.PartType.Cylinder)
	local anillo = parte(m, "Anillo", Vector3.new(4.8, 0.36, 4.8), cf * CFrame.new(0, 0.04, 0), RUNA, Enum.Material.Neon, false, Enum.PartType.Cylinder)
	anillo.Transparency = 0.25
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		parte(m, "Runa", Vector3.new(0.7, 0.4, 0.7), cf * CFrame.new(math.cos(a) * 2.9, 0.12, math.sin(a) * 2.9), RUNA, Enum.Material.Neon, false)
	end
	m.Parent = bosque
	return m, base, anillo
end

local function construirFarol(bosque, cf)
	local m = Instance.new("Model")
	m.Name = "DefensaFarol"
	parte(m, "Poste", Vector3.new(0.45, 5.4, 0.45), cf * CFrame.new(0, 2.7, 0), MADERA_OSCURA, Enum.Material.Wood, true)
	parte(m, "Brazo", Vector3.new(0.35, 0.35, 1.6), cf * CFrame.new(0, 5.3, 0.6), MADERA, Enum.Material.Wood, true)
	local orbe = parte(m, "Orbe", Vector3.new(1.35, 1.35, 1.35), cf * CFrame.new(0, 4.6, 1.3), Color3.fromRGB(255, 196, 92), Enum.Material.Neon, false, Enum.PartType.Ball)
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 178, 84)
	luz.Range = 20
	luz.Brightness = 2.2
	luz.Parent = orbe
	m.Parent = bosque
	return m, orbe
end

--// ============ COLOCAR ============
local function sueloEn(pos, excluir)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluir or {}
	local r = Workspace:Raycast(pos + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), params)
	if r then
		return r.Position
	end
	return pos
end

local function colocar(player, tipo)
	local hrp = hrpDe(player)
	if not hrp then
		return
	end
	local bosque = bosqueDe(hrp.Position)
	if not bosque then
		avisar(player, "Solo puedes construir dentro del bosque")
		return
	end
	local mias = 0
	for _, d in ipairs(defensas) do
		if d.dueno == player and d.modelo.Parent then
			mias += 1
		end
	end
	if mias >= MAX_POR_JUGADOR then
		avisar(player, "Ya tienes " .. MAX_POR_JUGADOR .. " defensas: no caben más")
		return
	end
	local coste = COSTES[tipo]
	if not coste then
		return
	end
	-- punto delante del jugador, apoyado en el suelo
	local look = hrp.CFrame.LookVector
	local frente = hrp.Position + Vector3.new(look.X, 0, look.Z).Unit * 9
	local suelo = sueloEn(frente, { player.Character })
	local cf = CFrame.new(Vector3.new(suelo.X, suelo.Y, suelo.Z), Vector3.new(hrp.Position.X, suelo.Y, hrp.Position.Z))
	local pagado, falta = pagar(player, coste)
	if not pagado then
		if falta == "tablas" then
			avisar(player, "Te faltan tablas: muele madera en el molino de la fogata")
		else
			avisar(player, "Te falta 1 diamante para la trampa rúnica")
		end
		return
	end
	local modelo, centro, extra
	if tipo == "Muro" then
		modelo, centro = construirMuro(bosque, cf)
		table.insert(defensas, { tipo = tipo, modelo = modelo, dueno = player, centro = centro, hp = 120 })
	elseif tipo == "Trampa" then
		modelo, centro, extra = construirTrampa(bosque, cf * CFrame.new(0, 0.18, 0))
		table.insert(defensas, { tipo = tipo, modelo = modelo, dueno = player, centro = centro, cargas = 2, anillo = extra })
	elseif tipo == "Farol" then
		modelo, centro = construirFarol(bosque, cf)
		table.insert(defensas, { tipo = tipo, modelo = modelo, dueno = player, centro = centro })
	end
	pcall(function()
		RE:FireClient(player, "Construido", tipo)
	end)
	print("[Defensas] " .. player.Name .. " construyó " .. tipo)
end

RE.OnServerEvent:Connect(function(player, accion, dato)
	if accion == "Construir" and type(dato) == "string" then
		colocar(player, dato)
	end
end)

--// ============ EFECTOS CONTRA LOS LOBOS (cada 0,5 s) ============
local function lobosVivos()
	local lista = {}
	for _, m in ipairs(Workspace:GetChildren()) do
		if m:IsA("Model") and m.Name == "LoboSombrio" then
			local hrp = m:FindFirstChild("HumanoidRootPart")
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				table.insert(lista, { hrp = hrp, hum = hum })
			end
		end
	end
	return lista
end

local function desvanecerYRomper(modelo)
	task.spawn(function()
		local partes = {}
		for _, d in ipairs(modelo:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(partes, { d, d.Transparency })
			end
		end
		for paso = 1, 8 do
			if not modelo.Parent then
				return
			end
			for _, par in ipairs(partes) do
				par[1].Transparency = par[2] + (1 - par[2]) * (paso / 8)
				par[1].CanCollide = false
			end
			task.wait(0.05)
		end
		pcall(function()
			modelo:Destroy()
		end)
	end)
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if #defensas > 0 then
			local lobos = lobosVivos()
		for i = #defensas, 1, -1 do
			local d = defensas[i]
			if not d.modelo or not d.modelo.Parent or not d.centro or not d.centro.Parent then
				table.remove(defensas, i) -- la sesión terminó o se rompió
			elseif #lobos > 0 then
				local c = d.centro.Position
				if d.tipo == "Muro" then
					local pegados = 0
					for _, l in ipairs(lobos) do
						if (l.hrp.Position - c).Magnitude <= 5 then
							l.hum:TakeDamage(3) -- las espinas: 6/s
							pegados += 1
						end
					end
					if pegados > 0 then
						d.hp -= pegados * 2 -- la muerden: 4/s por lobo
						if d.hp <= 0 then
							table.remove(defensas, i)
							desvanecerYRomper(d.modelo)
						end
					end
				elseif d.tipo == "Trampa" then
					local pisada = false
					for _, l in ipairs(lobos) do
						if (l.hrp.Position - c).Magnitude <= 4 then
							pisada = true
							break
						end
					end
					if pisada then
						d.cargas -= 1
						for _, l in ipairs(lobos) do
							if (l.hrp.Position - c).Magnitude <= 8 then
								l.hum:TakeDamage(45)
								local raiz = l.hrp
								raiz.Anchored = true -- clavado por la runa
								task.delay(1.6, function()
									if raiz and raiz.Parent then
										raiz.Anchored = false
									end
								end)
							end
						end
						if d.anillo then
							d.anillo.Transparency = d.cargas <= 0 and 0.9 or 0.55
						end
						if d.cargas <= 0 then
							table.remove(defensas, i)
							task.delay(0.6, function()
								if d.modelo and d.modelo.Parent then
									desvanecerYRomper(d.modelo)
								end
							end)
						end
					end
				elseif d.tipo == "Farol" then
					for _, l in ipairs(lobos) do
						if (l.hrp.Position - c).Magnitude <= 9.5 then
							l.hum:TakeDamage(6) -- la luz quema: 12/s
						end
					end
				end
			end
		end
		end
	end
end)

print("[Avada] DEFENSAS listas: muro de zarzas, trampa rúnica y farolillo")
-- FIN SERVER DEFENSAS
