--[[
  ✨ REVIVIR COMPAÑEROS - SERVIDOR (como 99 Noches, al estilo Avada)
  Pegar como "Script" en ServerScriptService. NO toca partida.

  En 99 Noches el caído no sale de la partida: un compañero lo revive
  o lo carga hasta la fogata. Aquí funciona igual, a la manera Avada:

  - Si un jugador EN PARTIDA va a morir (su vida llega a 0), no muere:
    queda CAÍDO en el suelo, vivo con 1 de vida, sin poder moverse.
    Para partida sigue "vivo" (su sesión no se entera ni se rompe).
  - Un compañero junto a él tiene dos botones (ProximityPrompt):
    * REVIVIR: consume una Poción de Vida que el compañero lleve
      (en la mano o en la mochila) y lo levanta con 60 de vida.
    * CARGAR: se lo echa a la espalda y, si lo lleva hasta la Llama
      Mágica de su fogata, el caído revive allí con 60 de vida.
  - Si TODOS los de una partida están caídos a la vez, corre una
    CUENTA ATRÁS visible de 30 s en el cartel de cada caído; si nadie
    se levanta antes, mueren de verdad y partida cierra la sesión
    como siempre. (v2, dueño 2026-11-03: el caído queda TUMBADO en
    el suelo boca arriba, nadie cae fuera del bosque —la posición
    manda, no el relé— y el cartel se limpia siempre al morir o
    respawnear: nada de teletransportes sorpresa al lobby.)
  - Si la partida termina con alguien caído, se levanta solo en el
    lobby con la vida llena.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RE = RS:FindFirstChild("RevivirEvent")
if not RE then
	RE = Instance.new("RemoteEvent")
	RE.Name = "RevivirEvent"
	RE.Parent = RS
end

local RADIO_BOSQUE = 285 -- radio de una sesión (como las zonas de partida)
local RADIO_LLAMA = 20 -- distancia a la fogata para revivir cargado
local VIDA_AL_REVIVIR = 60
local ESPERA_DERRUMBE = 30 -- s con todos caídos (cuenta atrás visible) antes de morir

local enPartida = {} -- relé del cliente (AvadaBosqueUI) por jugador
local sinSuelo = {} -- en el derrumbe se suelta el suelo: muere de verdad
local caidos = {} -- jugador -> { portador = jugador|nil, prompts = {} }
local portando = {} -- portador -> caído
local derrumbe = {} -- modelo del bosque -> os.clock() de inicio

--// ============ GEOGRAFÍA (molde y clones, como todo en Avada) ============
local function bosqueDe(pos)
	-- el modelo BosqueProhibido (molde o clon de sesión) que contiene pos
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

local function fogataCercana(pos)
	-- la base de la fogata más cercana (el FireAnchor cuelga 11 sobre ella)
	local mejor, mejorDist = nil, math.huge
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("Rol") == "FireAnchor" then
			local base = d.Position - Vector3.new(0, 11, 0)
			local dist = (base - pos).Magnitude
			if dist < mejorDist then
				mejor, mejorDist = base, dist
			end
		end
	end
	return mejor, mejorDist
end

local function hrpDe(player)
	local ch = player and player.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function humDe(player)
	local ch = player and player.Character
	return ch and ch:FindFirstChildOfClass("Humanoid")
end

local function estaEnPartida(player)
	-- LA VERDAD ES LA POSICIÓN: dentro del radio de un bosque (molde o
	-- clon de sesión). El relé del cliente NO decide esto: puede venir
	-- atrasado y llegó a tumbar a un jugador EN EL LOBBY (foto del
	-- dueño). El relé solo se usa para levantar al caído al terminar.
	local hrp = hrpDe(player)
	return hrp ~= nil and bosqueDe(hrp.Position) ~= nil
end

local function avisar(player, texto)
	pcall(function()
		RE:FireClient(player, "Aviso", texto)
	end)
end

--// ============ LEVANTAR / SOLTAR ============
local function limpiarPrompts(datos)
	if datos and datos.prompts then
		for _, p in ipairs(datos.prompts) do
			pcall(function()
				p:Destroy()
			end)
		end
		datos.prompts = {}
	end
end

local function soltarCarga(caido)
	local datos = caidos[caido]
	if datos and datos.portador then
		portando[datos.portador] = nil
		datos.portador = nil
	end
end

local function revivir(caido, donde, vida)
	local datos = caidos[caido]
	if not datos then
		return
	end
	local yawAlCaer = datos.yaw
	soltarCarga(caido)
	limpiarPrompts(datos)
	caidos[caido] = nil
	local hum = humDe(caido)
	local hrp = hrpDe(caido)
	if hum then
		hum.PlatformStand = false
		hum.WalkSpeed = 16
		hum.JumpPower = 50
		hum.Health = vida or VIDA_AL_REVIVIR
	end
	if hrp then
		if donde then
			hrp.CFrame = CFrame.new(donde + Vector3.new(0, 3, 0))
		else
			-- se levanta DONDE ESTÁ, de pie y mirando como al caer
			-- (antes quedaba tumbado en horizontal aunque reviviera)
			hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2.5, 0))
				* CFrame.Angles(0, yawAlCaer or 0, 0)
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	pcall(function()
		RE:FireClient(caido, "Revivido")
	end)
end

--// ============ CARGAR HASTA LA LLAMA ============
local function bucleCarga(caido, portador)
	while true do
		task.wait(0.12)
		local datos = caidos[caido]
		if not datos or datos.portador ~= portador then
			return -- revivido, soltado o cambiado de portador
		end
		local hrpC = hrpDe(portador)
		local hrpT = hrpDe(caido)
		local humC = humDe(portador)
		if not hrpC or not hrpT or not humC or humC.Health <= 0 or caidos[portador] then
			soltarCarga(caido) -- el portador cayó o desapareció: lo suelta
			return
		end
		-- el caído va tumbado sobre la espalda del portador
		hrpT.CFrame = hrpC.CFrame * CFrame.new(0, 2.3, 0.7) * CFrame.Angles(math.rad(80), 0, 0)
		hrpT.AssemblyLinearVelocity = Vector3.zero
		-- ¿llegó a la Llama Mágica?
		local base, dist = fogataCercana(hrpC.Position)
		if base and dist <= RADIO_LLAMA then
			avisar(portador, "La Llama revive a " .. caido.Name)
			revivir(caido, base)
			return
		end
	end
end

local function empezarCarga(caido, portador)
	local datos = caidos[caido]
	if not datos or datos.portador or portando[portador] or caidos[portador] then
		return
	end
	datos.portador = portador
	portando[portador] = caido
	avisar(portador, "Lleva a " .. caido.Name .. " hasta la Llama Mágica de la fogata")
	pcall(function()
		RE:FireClient(caido, "Cargando", portador.Name)
	end)
	task.spawn(bucleCarga, caido, portador)
end

--// ============ CAER ============
local function tumbar(player)
	-- Lo deja TUMBADO boca arriba en el suelo, como el cuerpo de un
	-- jugador muerto en Roblox: PlatformStand solo no bastaba (el
	-- avatar se quedaba de pie, foto del dueño); hay que girar la
	-- raíz a horizontal y matar velocidades. Se reafirma cada segundo
	-- en la red de seguridad para que la física no lo levante.
	local hrp = hrpDe(player)
	local hum = humDe(player)
	if not hrp or not hum then
		return
	end
	hum.PlatformStand = true
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	local _, yaw = hrp.CFrame:ToOrientation()
	local datos = caidos[player]
	if datos and datos.yaw == nil then
		datos.yaw = yaw
	end
	pcall(function()
		hrp.CFrame = CFrame.new(hrp.Position)
			* CFrame.Angles(0, (datos and datos.yaw) or yaw, 0)
			* CFrame.Angles(-math.rad(90), 0, 0)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)
end


local function crearPrompt(caido, hrp, accion, texto, espera)
	local p = Instance.new("ProximityPrompt")
	p.Name = "Revivir_" .. accion
	p.ActionText = texto
	p.ObjectText = caido.Name .. " está caído"
	p.MaxActivationDistance = 10
	p.HoldDuration = espera
	p.RequiresLineOfSight = false
	p.Parent = hrp
	p.Triggered:Connect(function(plr)
		if plr == caido or caidos[plr] or not caidos[caido] then
			return
		end
		if accion == "Revivir" then
			-- busca una Poción de Vida en la mano o la mochila del compañero
			local poc = nil
			local function mira(cont)
				if not cont then
					return
				end
				for _, t in ipairs(cont:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("Pocion") == "Vida" then
						poc = t
						return
					end
				end
			end
			mira(plr.Character)
			if not poc then
				mira(plr:FindFirstChildOfClass("Backpack"))
			end
			if not poc then
				avisar(plr, "Necesitas una Poción de Vida (se fabrica en el caldero)")
				return
			end
			poc:Destroy()
			avisar(plr, "Has revivido a " .. caido.Name)
			revivir(caido)
		elseif accion == "Cargar" then
			empezarCarga(caido, plr)
		end
	end)
	return p
end

local function entrarCaido(player)
	if caidos[player] then
		return
	end
	local hum = humDe(player)
	local hrp = hrpDe(player)
	if not hum or not hrp then
		return
	end
	caidos[player] = { portador = nil, prompts = {} }
	tumbar(player) -- queda TUMBADO en el suelo, boca arriba
	table.insert(caidos[player].prompts, crearPrompt(player, hrp, "Revivir", "Revivir (Poción de Vida)", 2.5))
	table.insert(caidos[player].prompts, crearPrompt(player, hrp, "Cargar", "Cargar hasta la Llama", 0.6))
	pcall(function()
		RE:FireClient(player, "Caido")
	end)
	-- aviso a los compañeros de su misma partida
	local miBosque = bosqueDe(hrp.Position)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local suHrp = hrpDe(p)
			if suHrp and miBosque and bosqueDe(suHrp.Position) == miBosque then
				pcall(function()
					RE:FireClient(p, "CompaneroCaido", player.Name)
				end)
			end
		end
	end
	print("[Revivir] " .. player.Name .. " ha caído en el bosque")
end

--// ============ EL SUELO DE VIDA (nadie muere en partida: cae) ============
local function vigilarVida(player, hum)
	hum.HealthChanged:Connect(function(salud)
		if salud > 0 then
			return
		end
		if sinSuelo[player] then
			return -- derrumbe total: esta vez sí muere (partida cierra)
		end
		if caidos[player] then
			hum.Health = 1 -- ya caído: los golpes no lo rematan
			return
		end
		if estaEnPartida(player) then
			hum.Health = 1
			entrarCaido(player)
		end
		-- fuera de partida: muere normal (lobby, duelos...)
	end)
	hum.Died:Connect(function()
		-- murió DE VERDAD (derrumbe o causa externa): limpiar todo y
		-- APAGAR el cartel en su cliente: sin esto el cartel se quedaba
		-- pegado en el lobby tras respawnear (foto del dueño)
		if portando[player] then
			soltarCarga(portando[player])
		end
		local datos = caidos[player]
		if datos then
			soltarCarga(player)
			limpiarPrompts(datos)
			caidos[player] = nil
			pcall(function()
				RE:FireClient(player, "Revivido")
			end)
		end
	end)
end

local function alPersonaje(player, char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		vigilarVida(player, hum)
	end
end

for _, p in ipairs(Players:GetPlayers()) do
	if p.Character then
		task.spawn(alPersonaje, p, p.Character)
	end
	p.CharacterAdded:Connect(function(char)
		alPersonaje(p, char)
	end)
end
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		alPersonaje(player, char)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- si cargaba a alguien, lo suelta; si estaba caído, se limpia
	if portando[player] then
		soltarCarga(portando[player])
	end
	local datos = caidos[player]
	if datos then
		limpiarPrompts(datos)
		caidos[player] = nil
	end
	enPartida[player] = nil
end)

--// ============ RELÉ DEL CLIENTE (¿sigue en partida?) ============
RE.OnServerEvent:Connect(function(player, accion, dato)
	if accion == "EnPartida" then
		enPartida[player] = dato == true
		if dato ~= true and caidos[player] then
			-- la partida terminó con él caído: se levanta en el lobby
			revivir(player, nil, 100)
		end
	end
end)

--// ============ DERRUMBE Y RED DE SEGURIDAD (cada segundo) ============
task.spawn(function()
	while true do
		task.wait(1)
		-- red: caído fuera del bosque (lo sacó el fin de partida) -> se levanta
		for caido in pairs(caidos) do
			local hrp = hrpDe(caido)
			if not hrp then
				caidos[caido] = nil -- su personaje ya no existe
			elseif not bosqueDe(hrp.Position) then
				revivir(caido, nil, 100)
			elseif not caidos[caido].portador then
				tumbar(caido) -- reafirma la pose: TUMBADO, que la física no lo levante
			end
		end
		-- derrumbe: si TODOS los de un bosque están caídos, mueren de verdad
		local porBosque = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local hrp = hrpDe(p)
			if hrp then
				local b = bosqueDe(hrp.Position)
				if b then
					porBosque[b] = porBosque[b] or { total = 0, caidosN = 0, lista = {} }
					porBosque[b].total += 1
					if caidos[p] then
						porBosque[b].caidosN += 1
						table.insert(porBosque[b].lista, p)
					end
				end
			end
		end
		for b, g in pairs(porBosque) do
			if g.total > 0 and g.caidosN == g.total then
				if not derrumbe[b] then
					derrumbe[b] = os.clock()
					for _, p in ipairs(g.lista) do
						avisar(p, "Todos han caído: la noche os reclama en " .. ESPERA_DERRUMBE .. " s si nadie se levanta")
					end
				end
				-- CUENTA ATRÁS VISIBLE cada segundo en el cartel de cada
				-- caído: nadie muere «de repente» ni sale teletransportado
				-- sin saber por qué (queja del dueño)
				local restan = math.max(0, math.ceil(ESPERA_DERRUMBE - (os.clock() - derrumbe[b])))
				for _, p in ipairs(g.lista) do
					pcall(function()
						RE:FireClient(p, "CuentaAtras", restan)
					end)
				end
				if restan <= 0 then
					for _, p in ipairs(g.lista) do
						local hum = humDe(p)
						-- se suelta el suelo de vida y muere normal:
						-- partida lo marca muerto y cierra como siempre
						local datos = caidos[p]
						if datos then
							limpiarPrompts(datos)
							caidos[p] = nil
						end
						sinSuelo[p] = true
						pcall(function()
							RE:FireClient(p, "Revivido") -- apaga el cartel ya
						end)
						if hum then
							hum.PlatformStand = false
							hum.Health = 0
						end
						task.delay(5, function()
							sinSuelo[p] = nil
						end)
					end
					derrumbe[b] = nil
				end
			else
				if derrumbe[b] then
					-- alguien se levantó: se apaga la cuenta atrás
					for _, p in ipairs(g.lista) do
						pcall(function()
							RE:FireClient(p, "CuentaAtras", 0)
						end)
					end
				end
				derrumbe[b] = nil
			end
		end
	end
end)

print("[Avada] REVIVIR v2 listo: el caído queda TUMBADO y la muerte lleva cuenta atrás visible")
-- FIN SERVER REVIVIR
