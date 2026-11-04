-- LocalScript LOBOS (pegar en StarterPlayer > StarterPlayerScripts)
-- Sonidos de los lobos, reproducidos EN EL CLIENTE (vía fiable: la
-- misma que usan los poderes). El servidor (serverscript_lobos.lua)
-- avisa por el remoto LobosEvent cuando un lobo empieza su mordida, y
-- aquí el sonido 9120790555 suena en 3D en la posición del lobo: se
-- oye venir según la distancia, igual para todos los jugadores.

local RS = game:GetService("ReplicatedStorage")

local ID_ATAQUE = 9120790555 -- sonido pedido por el dueño

local remote = RS:WaitForChild("LobosEvent", 60)
if not remote then
	warn("[Lobos] No llegó el remoto LobosEvent: ¿está pegado serverscript_lobos.lua?")
	return
end

local avisoDado = false

local function sonarAtaque(pos)
	if typeof(pos) ~= "Vector3" then
		return
	end
	-- ancla invisible en la posición del lobo: el sonido sale de ahí
	local ancla = Instance.new("Part")
	ancla.Name = "SonidoLobo"
	ancla.Size = Vector3.new(1, 1, 1)
	ancla.Transparency = 1
	ancla.Anchored = true
	ancla.CanCollide = false
	ancla.CanQuery = false
	ancla.CanTouch = false
	ancla.CFrame = CFrame.new(pos)
	ancla.Parent = workspace

	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. ID_ATAQUE
	s.Volume = 0.9
	s.RollOffMaxDistance = 60
	s.Parent = ancla
	s:Play()
	s.Ended:Connect(function()
		ancla:Destroy()
	end)
	-- diagnóstico: si el audio no carga (TimeLength sigue en 0), el ID
	-- no es usable en este juego (permiso del asset) y se avisa UNA vez
	-- en el Output para saberlo en vez de fallar en silencio
	task.delay(4, function()
		if s.Parent and s.TimeLength == 0 and not avisoDado then
			avisoDado = true
			warn("[Lobos] El audio " .. ID_ATAQUE .. " no cargó: puede que ese asset no tenga permiso de uso en este juego (pasa con audios de otros creadores). Sube el sonido como tuyo o dame otro ID y lo cambio.")
		end
		if ancla.Parent then
			ancla:Destroy()
		end
	end)
end

remote.OnClientEvent:Connect(function(accion, pos)
	if accion == "Ataque" then
		sonarAtaque(pos)
	end
end)

print("[Lobos] Cliente de sonidos listo (ataque " .. ID_ATAQUE .. ")")
-- FIN LOCAL LOBOS
