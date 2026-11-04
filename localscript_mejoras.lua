-- LocalScript MEJORAS (pegar en StarterPlayer > StarterPlayerScripts)
-- Añade la sección MEJORAS al panel de la maga (la pantalla de
-- poderes): mejorar el HACHA (más daño por golpe) y el SACO (más
-- capacidad), pagando con los diamantes que lleves encima.
-- Como pociones con el caldero: inyecta su sección en el panel ajeno
-- sin tocar el script de poderes.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local RE = RS:WaitForChild("MejorasEvent", 60)
if not RE then
	return
end

local FUENTE = Enum.Font.Kalam
local AMARILLO = Color3.fromRGB(255, 214, 0)
local VERDE = Color3.fromRGB(40, 160, 70)
local GRIS = Color3.fromRGB(95, 95, 100)

local estado = nil
local lblHacha, lblSaco, btnHacha, btnSaco

local function etiqueta(texto, size, pos, tam, color, padre)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FUENTE
	l.Text = texto
	l.TextSize = size
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Position = pos
	l.Size = tam
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = padre
	local st = Instance.new("UIStroke")
	st.Color = Color3.new(0, 0, 0)
	st.Thickness = 1.2
	st.Parent = l
	return l
end

-- aviso flotante propio (arriba, como el de pociones)
local guiAviso = Instance.new("ScreenGui")
guiAviso.Name = "MejorasAviso"
guiAviso.ResetOnSpawn = false
guiAviso.DisplayOrder = 90
guiAviso.IgnoreGuiInset = true
guiAviso.Parent = player:WaitForChild("PlayerGui")

local function avisar(texto)
	local f = Instance.new("TextLabel")
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.new(0.5, 0, 0, 90)
	f.Size = UDim2.new(0, 440, 0, 44)
	f.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	f.BackgroundTransparency = 0.15
	f.Font = FUENTE
	f.TextSize = 19
	f.TextColor3 = Color3.new(1, 1, 1)
	f.Text = texto
	f.TextWrapped = true
	f.Parent = guiAviso
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
	task.delay(2.6, function()
		pcall(function()
			f:Destroy()
		end)
	end)
end

local function refrescar()
	if not estado or not lblHacha then
		return
	end
	local nombresHacha = { "de Aprendiz", "Rúnica", "del Archimago" }
	lblHacha.Text = "🪓 Hacha " .. (nombresHacha[estado.hacha] or "") .. " · Nv " .. estado.hacha
		.. " · " .. estado.hacha .. " de daño (" .. estado.diamantes .. " 💎 encima)"
	lblSaco.Text = "🎒 Saco · Nv " .. estado.saco .. " · guarda " .. estado.cap .. " cosas"
	if estado.costeHacha then
		btnHacha.Text = "Mejorar · " .. estado.costeHacha .. " 💎"
		btnHacha.BackgroundColor3 = estado.diamantes >= estado.costeHacha and VERDE or GRIS
	else
		btnHacha.Text = "NIVEL MÁXIMO"
		btnHacha.BackgroundColor3 = GRIS
	end
	if estado.costeSaco then
		btnSaco.Text = "Mejorar · " .. estado.costeSaco .. " 💎"
		btnSaco.BackgroundColor3 = estado.diamantes >= estado.costeSaco and VERDE or GRIS
	else
		btnSaco.Text = "NIVEL MÁXIMO"
		btnSaco.BackgroundColor3 = GRIS
	end
end

local function botonMejora(padre, x, que)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.Position = UDim2.new(1, -8, 0.5, 0)
	b.Size = UDim2.new(0, 128, 0, 36)
	b.Font = FUENTE
	b.TextSize = 15
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = "Mejorar"
	b.BackgroundColor3 = GRIS
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	b.Parent = padre
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(function()
		RE:FireServer("Comprar", que)
	end)
	return b
end

local function construir()
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:WaitForChild("PoderesGui", 30)
	if not gui then
		return false
	end
	-- el panel es el padre del título "PODERES DE LA MAGA"
	local panel = nil
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("TextLabel") and d.Text == "PODERES DE LA MAGA" then
			panel = d.Parent
			break
		end
	end
	if not panel or panel:FindFirstChild("MejorasSec") then
		return panel ~= nil
	end

	local sec = Instance.new("Frame")
	sec.Name = "MejorasSec"
	sec.BackgroundTransparency = 1
	sec.Position = UDim2.new(0, 28, 0, 428)
	sec.Size = UDim2.new(1, -56, 0, 84)
	sec.ZIndex = 32
	sec.Parent = panel

	local tit = etiqueta("MEJORAS (se paga con diamantes)", 19, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 24), AMARILLO, sec)

	local function caja(y)
		local c = Instance.new("Frame")
		c.Position = UDim2.new(0, 0, 0, y)
		c.Size = UDim2.new(0.49, 0, 0, 40)
		c.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
		c.BorderSizePixel = 0
		c.ZIndex = 32
		c.Parent = sec
		Instance.new("UICorner", c).CornerRadius = UDim.new(0, 10)
		return c
	end
	local cH = caja(28)
	cH.Position = UDim2.new(0, 0, 0, 28)
	local cS = caja(28)
	cS.Position = UDim2.new(0.51, 0, 0, 28)

	lblHacha = etiqueta("🪓 Hacha · Nv 1", 15, UDim2.new(0, 10, 0, 0), UDim2.new(1, -140, 1, 0), Color3.new(1, 1, 1), cH)
	lblHacha.ZIndex = 33
	lblSaco = etiqueta("🎒 Saco · 5 cosas", 15, UDim2.new(0, 10, 0, 0), UDim2.new(1, -140, 1, 0), Color3.new(1, 1, 1), cS)
	lblSaco.ZIndex = 33
	btnHacha = botonMejora(cH, 0, "Hacha")
	btnHacha.ZIndex = 33
	btnSaco = botonMejora(cS, 0, "Saco")
	btnSaco.ZIndex = 33
	refrescar()
	return true
end

RE.OnClientEvent:Connect(function(accion, dato)
	if accion == "Estado" and type(dato) == "table" then
		estado = dato
		refrescar()
	elseif accion == "Aviso" then
		avisar(tostring(dato))
	end
end)

-- construir la sección y mantener el estado fresco con el panel abierto
task.spawn(function()
	local hecho = false
	for _ = 1, 20 do
		if construir() then
			hecho = true
			break
		end
		task.wait(3)
	end
	if not hecho then
		return
	end
	RE:FireServer("Estado")
	while true do
		task.wait(2)
		local pg = player.PlayerGui
		local gui = pg and pg:FindFirstChild("PoderesGui")
		if gui then
			-- solo pide estado si algún ancestro del panel está visible
			local visible = false
			for _, d in ipairs(gui:GetDescendants()) do
				if d:IsA("TextLabel") and d.Text == "PODERES DE LA MAGA" then
					local p = d.Parent
					visible = p and p.Visible and gui.Enabled
					break
				end
			end
			if visible then
				RE:FireServer("Estado")
			end
		end
	end
end)

print("[Mejoras] Cliente listo (sección en el panel de la maga)")
-- FIN LOCAL MEJORAS
