-- LocalScript DEFENSAS (pegar en StarterPlayer > StarterPlayerScripts)
-- La cara visible de serverscript_defensas.lua: dentro de partida
-- muestra el botón CONSTRUIR y un panel con las 3 defensas y su
-- coste en tablas (y la trampa, 1 diamante). Al tocar una, el
-- servidor la levanta delante
-- del jugador. GUI propia; NO toca partida ni su interfaz.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local RE = RS:WaitForChild("DefensasEvent", 60)
local RE_UI = RS:WaitForChild("AvadaBosqueUI", 60)
if not RE then
	return
end

local FUENTE = Enum.Font.Kalam
local COSTES = {
	Muro = { tablas = 4, diamantes = 0 },
	Trampa = { tablas = 2, diamantes = 1 },
	Farol = { tablas = 3, diamantes = 0 },
}

-- saldo de la moneda (lo difunde el núcleo por AvadaDiamantesUI)
local moneda = 0
local RE_MONEDA = RS:WaitForChild("AvadaDiamantesUI", 60)
if RE_MONEDA then
	RE_MONEDA.OnClientEvent:Connect(function(n)
		if type(n) == "number" then
			moneda = n
		end
	end)
	pcall(function()
		RE_MONEDA:FireServer()
	end)
end

local function textoCoste(tipo)
	local c = COSTES[tipo]
	local s = "🪵 " .. c.tablas .. " tablas"
	if c.diamantes > 0 then
		s = s .. " + 💎 " .. c.diamantes
	end
	return s
end

--// ============ ¿ESTOY EN PARTIDA? (relé de AvadaBosqueUI) ============
local enPartida = false
if RE_UI then
	RE_UI.OnClientEvent:Connect(function(st)
		if type(st) == "table" then
			enPartida = st.enPartida == true
		end
	end)
end

--// ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "DefensasHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 84
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local boton = Instance.new("TextButton")
boton.AnchorPoint = Vector2.new(1, 0.5)
boton.Position = UDim2.new(1, -14, 0.5, 40)
boton.Size = UDim2.new(0, 118, 0, 46)
boton.BackgroundColor3 = Color3.fromRGB(24, 20, 34)
boton.BackgroundTransparency = 0.15
boton.BorderSizePixel = 0
boton.Font = FUENTE
boton.Text = "🛡 Construir"
boton.TextSize = 19
boton.TextColor3 = Color3.new(1, 1, 1)
boton.Visible = false
boton.Parent = gui
Instance.new("UICorner", boton).CornerRadius = UDim.new(0, 12)
local bordeB = Instance.new("UIStroke")
bordeB.Color = Color3.fromRGB(125, 211, 252)
bordeB.Transparency = 0.4
bordeB.Thickness = 1.4
bordeB.Parent = boton

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -86)
panel.Size = UDim2.new(0, 500, 0, 158)
panel.BackgroundColor3 = Color3.fromRGB(16, 13, 26)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local bordeP = Instance.new("UIStroke")
bordeP.Color = Color3.fromRGB(125, 211, 252)
bordeP.Transparency = 0.45
bordeP.Thickness = 1.2
bordeP.Parent = panel

local titulo = Instance.new("TextLabel")
titulo.BackgroundTransparency = 1
titulo.Position = UDim2.new(0, 16, 0, 8)
titulo.Size = UDim2.new(1, -32, 0, 24)
titulo.Font = FUENTE
titulo.Text = "DEFENSAS — se levantan delante de ti"
titulo.TextSize = 18
titulo.TextColor3 = Color3.fromRGB(190, 235, 255)
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Parent = panel

local saldoLbl = Instance.new("TextLabel")
saldoLbl.BackgroundTransparency = 1
saldoLbl.Position = UDim2.new(0, 16, 0, 32)
saldoLbl.Size = UDim2.new(1, -32, 0, 18)
saldoLbl.Font = FUENTE
saldoLbl.Text = "🪵 0 tablas · 💎 0"
saldoLbl.TextSize = 15
saldoLbl.TextColor3 = Color3.fromRGB(165, 225, 255)
saldoLbl.TextXAlignment = Enum.TextXAlignment.Left
saldoLbl.Parent = panel

--// ============ TARJETAS ============
local tarjetas = {}
local function tarjeta(x, tipo, nombre, desc)
	local b = Instance.new("TextButton")
	b.Position = UDim2.new(0, x, 0, 56)
	b.Size = UDim2.new(0, 152, 0, 90)
	b.BackgroundColor3 = Color3.fromRGB(34, 29, 50)
	b.BorderSizePixel = 0
	b.Font = FUENTE
	b.Text = ""
	b.Parent = panel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local n = Instance.new("TextLabel")
	n.BackgroundTransparency = 1
	n.Position = UDim2.new(0, 8, 0, 6)
	n.Size = UDim2.new(1, -16, 0, 22)
	n.Font = FUENTE
	n.Text = nombre
	n.TextSize = 17
	n.TextColor3 = Color3.new(1, 1, 1)
	n.TextXAlignment = Enum.TextXAlignment.Left
	n.Parent = b
	local d = Instance.new("TextLabel")
	d.BackgroundTransparency = 1
	d.Position = UDim2.new(0, 8, 0, 28)
	d.Size = UDim2.new(1, -16, 0, 36)
	d.Font = FUENTE
	d.Text = desc
	d.TextSize = 12.5
	d.TextColor3 = Color3.fromRGB(200, 200, 215)
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.TextWrapped = true
	d.Parent = b
	local c = Instance.new("TextLabel")
	c.BackgroundTransparency = 1
	c.Position = UDim2.new(0, 8, 0, 64)
	c.Size = UDim2.new(1, -16, 0, 20)
	c.Font = FUENTE
	c.Text = textoCoste(tipo)
	c.TextSize = 15
	c.TextColor3 = Color3.fromRGB(165, 225, 255)
	c.TextXAlignment = Enum.TextXAlignment.Left
	c.Parent = b
	b.MouseButton1Click:Connect(function()
		pcall(function()
			RE:FireServer("Construir", tipo)
		end)
	end)
	tarjetas[tipo] = { boton = b, costeLbl = c }
	return b
end

tarjeta(12, "Muro", "Muro de zarzas", "Frena a los lobos; las espinas los hieren")
tarjeta(174, "Trampa", "Trampa rúnica", "Estalla al pisarla: daño y lobos clavados")
tarjeta(336, "Farol", "Farolillo", "Su luz quema a los lobos que se acerquen")

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
	if accion == "Aviso" then
		avisar(tostring(dato))
	elseif accion == "Construido" then
		panel.Visible = false
		avisar("¡Defensa construida!")
	end
end)

boton.MouseButton1Click:Connect(function()
	panel.Visible = not panel.Visible
end)

--// ============ SALDO Y VISIBILIDAD ============
task.spawn(function()
	while true do
		task.wait(0.4)
		boton.Visible = enPartida
		if not enPartida and panel.Visible then
			panel.Visible = false
		end
		if panel.Visible then
			local tablas = player:GetAttribute("Tablas") or 0
			local madera = player:GetAttribute("Madera") or 0
			saldoLbl.Text = "🪵 " .. madera .. " madera · " .. tablas .. " tablas · 💎 " .. moneda
			for tipo, t in pairs(tarjetas) do
				local c = COSTES[tipo]
				if tablas >= c.tablas and moneda >= c.diamantes then
					t.costeLbl.TextColor3 = Color3.fromRGB(165, 225, 255)
					t.boton.BackgroundColor3 = Color3.fromRGB(34, 29, 50)
				else
					t.costeLbl.TextColor3 = Color3.fromRGB(255, 130, 130)
					t.boton.BackgroundColor3 = Color3.fromRGB(26, 22, 38)
				end
			end
		end
	end
end)

print("[Defensas] Cliente listo")
-- FIN LOCAL DEFENSAS
