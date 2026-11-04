-- LocalScript REVIVIR (pegar en StarterPlayer > StarterPlayerScripts)
-- La cara visible de serverscript_revivir.lua:
-- - Avisa al servidor si estoy en partida (relé de AvadaBosqueUI).
-- - Si caigo, me muestra el cartel de CAÍDO hasta que me reviven.
-- - Muestra los avisos: compañero caído, te están cargando, etc.
-- NO toca partida ni su interfaz: GUI propia y remotos propios.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local RE = RS:WaitForChild("RevivirEvent", 60)
local RE_UI = RS:WaitForChild("AvadaBosqueUI", 60)
if not RE then
	return
end

local FUENTE = Enum.Font.Kalam

--// ============ RELÉ DE PARTIDA ============
local ultimoEnPartida = nil
if RE_UI then
	RE_UI.OnClientEvent:Connect(function(st)
		if type(st) ~= "table" then
			return
		end
		local ep = st.enPartida == true
		if ep ~= ultimoEnPartida then
			ultimoEnPartida = ep
			pcall(function()
				RE:FireServer("EnPartida", ep)
			end)
		end
	end)
end

--// ============ CARTEL DE CAÍDO ============
local gui = Instance.new("ScreenGui")
gui.Name = "RevivirHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 85
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local fondo = Instance.new("Frame")
fondo.Size = UDim2.new(1, 0, 1, 0)
fondo.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
fondo.BackgroundTransparency = 0.55
fondo.BorderSizePixel = 0
fondo.Visible = false
fondo.Parent = gui

local function etiqueta(texto, size, yPos, alto, color, padre)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FUENTE
	l.Text = texto
	l.TextSize = size
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Position = UDim2.new(0.1, 0, 0, yPos)
	l.Size = UDim2.new(0.8, 0, 0, alto)
	l.TextWrapped = true
	l.Parent = padre
	local st = Instance.new("UIStroke")
	st.Color = Color3.new(0, 0, 0)
	st.Thickness = 1.6
	st.Parent = l
	return l
end

local titulo = etiqueta("ESTÁS CAÍDO", 40, 120, 56, Color3.fromRGB(255, 120, 120), fondo)
local detalle = etiqueta(
	"Un compañero puede revivirte con una Poción de Vida o cargarte hasta la Llama Mágica de la fogata.",
	20, 185, 60, Color3.new(1, 1, 1), fondo
)
-- cuenta atrás del derrumbe (solo si TODOS están caídos): se ve venir,
-- nadie muere ni sale de la partida «de repente»
local cuenta = etiqueta("", 22, 255, 40, Color3.fromRGB(255, 205, 110), fondo)

--// ============ AVISOS FLOTANTES ============
local function avisar(texto)
	local f = Instance.new("TextLabel")
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.new(0.5, 0, 0, 150)
	f.Size = UDim2.new(0, 440, 0, 44)
	f.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	f.BackgroundTransparency = 0.15
	f.Font = FUENTE
	f.TextSize = 19
	f.TextColor3 = Color3.new(1, 1, 1)
	f.Text = texto
	f.TextWrapped = true
	f.Parent = gui
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
	task.delay(3, function()
		pcall(function()
			f:Destroy()
		end)
	end)
end

--// ============ MENSAJES DEL SERVIDOR ============
RE.OnClientEvent:Connect(function(accion, dato)
	if accion == "Caido" then
		detalle.Text = "Un compañero puede revivirte con una Poción de Vida o cargarte hasta la Llama Mágica de la fogata."
		cuenta.Text = ""
		fondo.Visible = true
	elseif accion == "Cargando" then
		detalle.Text = "¡" .. tostring(dato) .. " te está cargando hasta la Llama Mágica!"
		fondo.Visible = true
	elseif accion == "CuentaAtras" then
		local n = tonumber(dato) or 0
		if n > 0 then
			fondo.Visible = true
			cuenta.Text = "Todos estáis caídos: la noche os reclama en " .. n .. " s"
		else
			cuenta.Text = ""
		end
	elseif accion == "Revivido" then
		fondo.Visible = false
		cuenta.Text = ""
		avisar("¡Has vuelto a la partida!")
	elseif accion == "CompaneroCaido" then
		avisar("⚠ " .. tostring(dato) .. " ha caído en el bosque: revívele o cárgale hasta la Llama")
	elseif accion == "Aviso" then
		avisar(tostring(dato))
	end
end)

--// ============ EL CARTEL NUNCA SE QUEDA PEGADO (v2) ============
-- Si respawneo (muerte real), el cartel se apaga con el personaje nuevo.
player.CharacterAdded:Connect(function()
	fondo.Visible = false
	cuenta.Text = ""
end)
-- Vigilante: si el cartel está visible pero mi personaje está de pie y
-- con vida (estoy bien), el cartel sobra: fuera en medio segundo.
task.spawn(function()
	while true do
		task.wait(0.5)
		if fondo.Visible then
			local ch = player.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 1 and not hum.PlatformStand then
				fondo.Visible = false
				cuenta.Text = ""
			end
		end
	end
end)

print("[Revivir] Cliente v2 listo")
-- FIN LOCAL REVIVIR
