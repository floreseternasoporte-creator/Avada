-- LocalScript MOLINO (pegar en StarterPlayer > StarterPlayerScripts)
-- El panel del molino de la fogata (como el del caldero): muestra la
-- madera que llevas y la muele a TABLAS con un toque. Las tablas son
-- el material de las DEFENSAS (botón Construir dentro de partida).
-- GUI propia; NO toca partida ni su interfaz.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local RE = RS:WaitForChild("MolinoEvent", 60)
if not RE then
	return
end

local FUENTE = Enum.Font.Kalam

local gui = Instance.new("ScreenGui")
gui.Name = "MolinoHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 84
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 400, 0, 300)
panel.BackgroundColor3 = Color3.fromRGB(18, 15, 28)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
local borde = Instance.new("UIStroke")
borde.Color = Color3.fromRGB(196, 132, 62)
borde.Transparency = 0.35
borde.Thickness = 1.6
borde.Parent = panel

local function etiqueta(texto, size, y, h, color, x, w)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.new(0, x or 20, 0, y)
	l.Size = UDim2.new(0, w or 360, 0, h)
	l.Font = FUENTE
	l.Text = texto
	l.TextSize = size
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.Parent = panel
	return l
end

etiqueta("🪵 MOLINO DE LA FOGATA", 24, 14, 32, Color3.fromRGB(255, 214, 150))
local conteo = etiqueta("Madera: 0 · Tablas: 0", 18, 52, 26, Color3.fromRGB(190, 235, 255))
etiqueta(
	"La madera cae de los árboles al cortarlos. Muélela a tablas y construye DEFENSAS con el botón Construir dentro de la partida.",
	14.5, 82, 52, Color3.fromRGB(205, 205, 220)
)

local function botonMoler(y, texto, cantidad)
	local b = Instance.new("TextButton")
	b.Position = UDim2.new(0, 20, 0, y)
	b.Size = UDim2.new(0, 360, 0, 40)
	b.BackgroundColor3 = Color3.fromRGB(122, 84, 48)
	b.BorderSizePixel = 0
	b.Font = FUENTE
	b.Text = texto
	b.TextSize = 18
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Parent = panel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	b.MouseButton1Click:Connect(function()
		pcall(function()
			RE:FireServer("Moler", cantidad)
		end)
	end)
	return b
end
botonMoler(142, "Moler 1 madera → 1 tabla", 1)
botonMoler(190, "Moler 5 maderas → 5 tablas", 5)
botonMoler(238, "Moler TODA la madera", -1)

local cerrar = Instance.new("TextButton")
cerrar.AnchorPoint = Vector2.new(1, 0)
cerrar.Position = UDim2.new(1, -12, 0, 10)
cerrar.Size = UDim2.new(0, 34, 0, 34)
cerrar.BackgroundColor3 = Color3.fromRGB(50, 44, 66)
cerrar.BorderSizePixel = 0
cerrar.Font = FUENTE
cerrar.Text = "✕"
cerrar.TextSize = 17
cerrar.TextColor3 = Color3.new(1, 1, 1)
cerrar.Parent = panel
Instance.new("UICorner", cerrar).CornerRadius = UDim.new(0, 9)
cerrar.MouseButton1Click:Connect(function()
	panel.Visible = false
end)

--// ============ AVISOS ============
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

RE.OnClientEvent:Connect(function(accion, dato)
	if accion == "Abrir" then
		panel.Visible = true
	elseif accion == "Estado" and type(dato) == "table" then
		conteo.Text = "🪵 Madera: " .. tostring(dato.madera or 0) .. "    🪚 Tablas: " .. tostring(dato.tablas or 0)
	elseif accion == "Aviso" then
		avisar(tostring(dato))
	end
end)

print("[Molino] Cliente listo")
-- FIN LOCAL MOLINO
