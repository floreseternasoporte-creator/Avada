-- LocalScript MUSICA (pegar en StarterPlayer > StarterPlayerScripts)
-- Música del juego pedida por el dueño (IDs de Roblox que él dio):
-- - Lobby:           99564723333346
-- - Bosque de día:   139767023947424
-- - Bosque de noche: 179507208
-- Archivo SEPARADO a propósito: no toca PARTIDA ni la interfaz del
-- bosque (la lección del viejo sistema AvadaSonidos). Solo ESCUCHA el
-- remoto AvadaBosqueUI que PARTIDA ya manda (enPartida + fase) y, si
-- ese dato no llega, decide por la posición del jugador y la hora del
-- mundo. Cambia de tema con fundido suave; suena uno solo a la vez.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local TEMAS = {
	lobby = { id = 99564723333346, volumen = 0.5 },
	dia = { id = 139767023947424, volumen = 0.45 },
	noche = { id = 179507208, volumen = 0.55 },
}

--// ============ LOS TRES TEMAS (en bucle, en SoundService) ============
local sonidos = {}
for nombre, def in pairs(TEMAS) do
	local s = Instance.new("Sound")
	s.Name = "Musica_" .. nombre
	s.SoundId = "rbxassetid://" .. def.id
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	sonidos[nombre] = s
end

local estadoActual = nil
local cambioId = 0 -- token: si llega otro cambio, el anterior no apaga nada

local function cambiarA(nuevo)
	if nuevo == estadoActual then
		return
	end
	estadoActual = nuevo
	cambioId += 1
	local miCambio = cambioId
	-- fundido de salida de los demás temas
	for nombre, s in pairs(sonidos) do
		if nombre ~= nuevo and s.IsPlaying then
			TweenService:Create(s, TweenInfo.new(1.2), { Volume = 0 }):Play()
			task.delay(1.25, function()
				if cambioId == miCambio and estadoActual ~= nombre and s.IsPlaying then
					s:Stop()
					s.Volume = 0
				end
			end)
		end
	end
	-- fundido de entrada del tema nuevo
	local s = sonidos[nuevo]
	if s then
		if not s.IsPlaying then
			s.Volume = 0
			s:Play()
		end
		TweenService:Create(s, TweenInfo.new(1.2), { Volume = TEMAS[nuevo].volumen }):Play()
	end
end

--// ============ SEÑAL 1: el remoto de PARTIDA (la verdad por jugador) ============
local ultimoUI = 0
task.spawn(function()
	local RE_UI = RS:WaitForChild("AvadaBosqueUI", 60)
	if not RE_UI then
		return -- sin remoto, manda el respaldo por posición
	end
	RE_UI.OnClientEvent:Connect(function(st)
		if type(st) ~= "table" then
			return
		end
		ultimoUI = os.clock()
		if st.enPartida then
			cambiarA(st.fase == "noche" and "noche" or "dia")
		else
			cambiarA("lobby")
		end
	end)
end)

--// ============ SEÑAL 2 (respaldo): posición + hora del mundo ============
local function temaPorPosicion()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return "lobby"
	end
	-- el bosque MOLDE y los CLONES de cada partida se llaman igual:
	-- vale estar dentro de cualquiera (radio de partida ~260)
	for _, modelo in ipairs(workspace:GetChildren()) do
		if modelo:IsA("Model") and modelo.Name == "BosqueProhibido" then
			local ok, pos = pcall(function()
				return modelo:GetPivot().Position
			end)
			if ok and (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude < 280 then
				local ct = Lighting.ClockTime
				return (ct >= 6.2 and ct < 17.8) and "dia" or "noche"
			end
		end
	end
	return "lobby"
end

task.spawn(function()
	while true do
		task.wait(1)
		-- si el dato de PARTIDA está fresco (<4 s), él manda y no se toca
		if os.clock() - ultimoUI > 4 then
			cambiarA(temaPorPosicion())
		end
	end
end)

print("[Música] Temas listos: lobby / bosque de día / bosque de noche")
-- FIN LOCAL MUSICA
