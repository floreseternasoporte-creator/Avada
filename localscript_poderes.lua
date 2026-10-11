--[[
	🔮 PODERES DE LA MAGA - CLIENTE
	--------------------------------
	CÓMO USARLO:
	Este archivo va como "LocalScript" (NO Script) en
	StarterPlayer > StarterPlayerScripts.
	El otro archivo (serverscript_poderes.lua) va como Script en ServerScriptService.

	QUÉ HACE:
	- Diálogo con texto que se escribe solo abajo ("Hola, hechicero...").
	- Pantalla de poderes con el estilo de la Reserva del Caldero.
	- Animaciones de lanzar poderes (agacharse y tocar el suelo / estirar la mano).
	  Las animaciones son por código y funcionan con personajes R15.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local remote = RS:WaitForChild("PoderesEvent")
local camera = workspace.CurrentCamera

-- recargas (deben coincidir con las del servidor)
local CD = { Tierra = 8, Fuego = 3, Agua = 6, Viento = 10, Rayo = 12 }
local cdEnd = { Tierra = 0, Fuego = 0, Agua = 0, Viento = 0, Rayo = 0 }
local equippedPower = nil

-- estilo del menú
local YELLOW = Color3.fromRGB(255, 214, 10)
local GOLD_CARD = Color3.fromRGB(176, 142, 10)
local WHITE = Color3.new(1, 1, 1)
local FONT_NAME = Enum.Font.Fondamento
local FONT_HEAD = Enum.Font.FredokaOne

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local gui = make("ScreenGui", {
	Name = "PoderesGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 40,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

--// ============ TEMBLOR DE CÁMARA ============
local shakeMag, shakeDur, shakeEnd = 0, 1, 0
local function shake(mag, dur)
	local now = os.clock()
	local cur = now < shakeEnd and shakeMag * ((shakeEnd - now) / shakeDur) or 0
	if mag > cur then
		shakeMag, shakeDur, shakeEnd = mag, dur, now + dur
	end
end
RunService:BindToRenderStep("PoderesShake", Enum.RenderPriority.Camera.Value + 1, function()
	local now = os.clock()
	if now < shakeEnd then
		local m = shakeMag * ((shakeEnd - now) / shakeDur)
		camera.CFrame = camera.CFrame
			* CFrame.new((math.random() - 0.5) * m, (math.random() - 0.5) * m, 0)
			* CFrame.Angles(0, 0, (math.random() - 0.5) * m * 0.05)
	end
end)

--// ============ AVISO AMARILLO (como "Equipaste la clase...") ============
local toastLabel = make("TextLabel", {
	Name = "Aviso",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.34, 0),
	Size = UDim2.new(0.9, 0, 0, 60),
	BackgroundTransparency = 1,
	Text = "",
	Font = FONT_HEAD,
	TextSize = 36,
	TextColor3 = YELLOW,
	TextStrokeColor3 = Color3.new(0, 0, 0),
	TextStrokeTransparency = 1,
	TextTransparency = 1,
	ZIndex = 60,
}, gui)
local toastId = 0
local function toast(text)
	toastId = toastId + 1
	local id = toastId
	toastLabel.Text = text
	toastLabel.TextTransparency = 0
	toastLabel.TextStrokeTransparency = 0
	task.delay(2.4, function()
		if id == toastId then
			TweenService:Create(toastLabel, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

--// ============ DIÁLOGO DE ABAJO (texto que se escribe) ============
local dlg = make("Frame", {
	Name = "Dialogo",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 160),
	Size = UDim2.new(0.62, 0, 0, 118),
	BackgroundColor3 = Color3.fromRGB(16, 16, 20),
	BackgroundTransparency = 0.1,
	Visible = false,
	ZIndex = 20,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 14) }, dlg)
make("UIStroke", { Color = YELLOW, Thickness = 2, Transparency = 0.15 }, dlg)
make("UISizeConstraint", { MinSize = Vector2.new(320, 100), MaxSize = Vector2.new(900, 140) }, dlg)

local nameTag = make("TextLabel", {
	Position = UDim2.new(0, 18, 0, -16),
	Size = UDim2.new(0, 210, 0, 32),
	BackgroundColor3 = YELLOW,
	Text = "Vendedora Mágica",
	Font = FONT_HEAD,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(40, 24, 0),
	ZIndex = 21,
}, dlg)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, nameTag)

local dlgText = make("TextLabel", {
	Position = UDim2.new(0, 22, 0, 24),
	Size = UDim2.new(1, -44, 1, -36),
	BackgroundTransparency = 1,
	Text = "",
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Font = FONT_NAME,
	TextSize = 26,
	TextColor3 = WHITE,
	MaxVisibleGraphemes = 0,
	ZIndex = 21,
}, dlg)
local arrow = make("TextLabel", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -14, 1, -8),
	Size = UDim2.new(0, 24, 0, 24),
	BackgroundTransparency = 1,
	Text = "▼",
	TextColor3 = YELLOW,
	TextSize = 20,
	Font = FONT_HEAD,
	Visible = false,
	ZIndex = 21,
}, dlg)
local skipBtn = make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 22 }, dlg)

local skipFlag = false
skipBtn.Activated:Connect(function()
	skipFlag = true
end)

task.spawn(function()
	while true do
		task.wait(0.4)
		arrow.TextTransparency = (arrow.TextTransparency == 0) and 0.7 or 0
	end
end)

local function say(text)
	skipFlag = false
	arrow.Visible = false
	dlgText.Text = text
	dlgText.MaxVisibleGraphemes = 0
	local total = utf8.len(text) or #text
	for i = 1, total do
		if skipFlag then
			break
		end
		dlgText.MaxVisibleGraphemes = i
		task.wait(0.03)
	end
	dlgText.MaxVisibleGraphemes = -1
	skipFlag = false
	arrow.Visible = true
end

local function showDialog(show)
	if show then
		dlg.Visible = true
		dlg.Position = UDim2.new(0.5, 0, 1, 160)
		TweenService:Create(dlg, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 1, -26) }):Play()
	else
		TweenService:Create(dlg, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 1, 160) }):Play()
		task.delay(0.32, function()
			dlg.Visible = false
		end)
	end
end

--// ============ PANTALLA DE PODERES (estilo "Reserva del Caldero") ============
local overlay = make("Frame", {
	Name = "PoderesPantalla",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Visible = false,
	Active = true,
	ZIndex = 30,
}, gui)

local panel = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 780, 0, 520),
	BackgroundColor3 = Color3.fromRGB(13, 13, 15),
	BackgroundTransparency = 0.05,
	ZIndex = 31,
}, overlay)
make("UICorner", { CornerRadius = UDim.new(0, 16) }, panel)
make("UIStroke", { Color = Color3.fromRGB(90, 90, 98), Thickness = 2, Transparency = 0.3 }, panel)
local panelScale = make("UIScale", {}, panel)

local function updateScale()
	local vp = camera.ViewportSize
	panelScale.Scale = math.clamp(math.min(vp.X / 840, vp.Y / 560), 0.4, 1.2)
end

-- título dorado como "RESERVA DEL CALDERO"
make("TextLabel", {
	Position = UDim2.new(0, 28, 0, 16),
	Size = UDim2.new(1, -300, 0, 36),
	BackgroundTransparency = 1,
	Text = "PODERES DE LA MAGA",
	Font = FONT_HEAD,
	TextSize = 30,
	TextColor3 = YELLOW,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 32,
}, panel)

-- recargas arriba a la derecha (como los contadores del caldero)
local chipsRow = make("Frame", {
	Position = UDim2.new(1, -346, 0, 16),
	Size = UDim2.new(0, 330, 0, 36),
	BackgroundTransparency = 1,
	ZIndex = 32,
}, panel)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
}, chipsRow)
local function chip(order)
	local pill = make("Frame", {
		Size = UDim2.new(0, 58, 1, 0),
		BackgroundColor3 = Color3.fromRGB(28, 28, 32),
		LayoutOrder = order,
		ZIndex = 33,
	}, chipsRow)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, pill)
	return make("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT_NAME,
		TextSize = 20,
		TextColor3 = WHITE,
		Text = "",
		ZIndex = 34,
	}, pill)
end
local chipEarth, chipFire, chipAgua, chipViento, chipRayo = chip(1), chip(2), chip(3), chip(4), chip(5)
local function refreshChips()
	chipEarth.Text = "🌿 " .. math.max(0, math.ceil(cdEnd.Tierra - os.clock()))
	chipFire.Text = "🔥 " .. math.max(0, math.ceil(cdEnd.Fuego - os.clock()))
	chipAgua.Text = "💧 " .. math.max(0, math.ceil(cdEnd.Agua - os.clock()))
	chipViento.Text = "🌪️ " .. math.max(0, math.ceil(cdEnd.Viento - os.clock()))
	chipRayo.Text = "⚡ " .. math.max(0, math.ceil(cdEnd.Rayo - os.clock()))
end
refreshChips()
task.spawn(function()
	while true do
		task.wait(0.25)
		if overlay.Visible then
			refreshChips()
		end
	end
end)

-- sub-título dorado
make("TextLabel", {
	Position = UDim2.new(0, 28, 0, 62),
	Size = UDim2.new(1, -56, 0, 28),
	BackgroundTransparency = 1,
	Text = "ELIGE TU PODER",
	Font = FONT_HEAD,
	TextSize = 22,
	TextColor3 = YELLOW,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 32,
}, panel)

-- cierre de la pantalla
local panelClosed = Instance.new("BindableEvent")
local panelOpen = false
local function closePanel(reason, power)
	if not panelOpen then
		return
	end
	panelOpen = false
	overlay.Visible = false
	panelClosed:Fire(reason, power)
end

-- X roja redondeada como la del caldero
local closeBtn = make("TextButton", {
	Position = UDim2.new(1, -66, 0, 12),
	Size = UDim2.new(0, 54, 0, 54),
	BackgroundColor3 = Color3.fromRGB(228, 32, 32),
	Text = "X",
	Font = FONT_HEAD,
	TextSize = 40,
	TextColor3 = WHITE,
	AutoButtonColor = true,
	ZIndex = 40,
}, panel)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, closeBtn)
closeBtn.Activated:Connect(function()
	closePanel("close")
end)

-- tarjetas estilo caldero: icono arriba, nombre al medio, costo abajo
-- (los 5 poderes desbloqueados)
local POWER_DEFS = {
	{ power = "Tierra", icon = "🌿", name = "Tierra", cost = "⏱ 8s", desc = "Pon las manos en el suelo y despierta la tierra: lianas y hierba brotan y atrapan a quien esté cerca." },
	{ power = "Fuego", icon = "🔥", name = "Fuego", cost = "⏱ 3s", desc = "Estira la mano y lanza una llama púrpura que explota al impactar y deja a tu enemigo ardiendo." },
	{ power = "Agua", icon = "💧", name = "Agua", cost = "⏱ 6s", desc = "Lanza una ola abisal que empuja a tus enemigos y los deja empapados (más lentos)." },
	{ power = "Viento", icon = "🌪️", name = "Viento", cost = "⏱ 10s", desc = "Invoca un tornado que avanza arrastrando y golpeando a quien atrape." },
	{ power = "Rayo", icon = "⚡", name = "Rayo", cost = "⏱ 12s", desc = "Un rayo cae del cielo donde apuntas: gran daño y deja aturdido." },
}
local powerCards = {}

local function makeCard(i, d)
	local card = make("Frame", {
		Position = UDim2.new(0, 28 + (i - 1) * 146, 0, 100),
		Size = UDim2.new(0, 132, 0, 172),
		BackgroundColor3 = Color3.fromRGB(10, 10, 12),
		BackgroundTransparency = 0.04,
		ZIndex = 32,
	}, panel)
	make("UICorner", { CornerRadius = UDim.new(0, 14) }, card)
	local stroke = make("UIStroke", { Color = Color3.fromRGB(70, 70, 78), Thickness = 2, Transparency = 0.15 }, card)
	local iconL = make("TextLabel", {
		Position = UDim2.new(0, 0, 0, 12),
		Size = UDim2.new(1, 0, 0, 66),
		BackgroundTransparency = 1,
		Text = d.icon,
		TextSize = 56,
		Font = FONT_NAME,
		TextColor3 = WHITE,
		ZIndex = 33,
	}, card)
	local nameL = make("TextLabel", {
		Position = UDim2.new(0, 0, 0, 84),
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = d.name,
		TextSize = 24,
		Font = FONT_NAME,
		TextColor3 = WHITE,
		ZIndex = 33,
	}, card)
	local costL = make("TextLabel", {
		Position = UDim2.new(0, 0, 0, 122),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
		Text = d.locked and "🔒" or d.cost,
		TextSize = 30,
		Font = FONT_NAME,
		TextColor3 = WHITE,
		ZIndex = 33,
	}, card)
	if d.locked then
		local dim = make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			ZIndex = 36,
		}, card)
		make("UICorner", { CornerRadius = UDim.new(0, 14) }, dim)
	end
	local btn = make("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 40,
	}, card)
	return { card = card, stroke = stroke, iconL = iconL, nameL = nameL, costL = costL, btn = btn, def = d }
end

local DARK_TEXT = Color3.fromRGB(48, 30, 4)
local function refreshCards()
	for power, c in pairs(powerCards) do
		local on = (equippedPower == power)
		c.card.BackgroundColor3 = on and GOLD_CARD or Color3.fromRGB(10, 10, 12)
		c.stroke.Color = on and YELLOW or Color3.fromRGB(70, 70, 78)
		local tc = on and DARK_TEXT or WHITE
		c.nameL.TextColor3 = tc
		c.costL.TextColor3 = tc
		c.iconL.TextColor3 = tc
	end
end

local function pickPower(power)
	equippedPower = power
	remote:FireServer("Equip", power)
	refreshCards()
	closePanel("equip", power)
end

make("TextLabel", {
	Position = UDim2.new(0, 28, 0, 292),
	Size = UDim2.new(1, -56, 0, 26),
	BackgroundTransparency = 1,
	Text = "CÓMO SE USA",
	Font = FONT_HEAD,
	TextSize = 20,
	TextColor3 = YELLOW,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 33,
}, panel)

local descLabel = make("TextLabel", {
	Position = UDim2.new(0, 28, 0, 322),
	Size = UDim2.new(1, -56, 0, 60),
	BackgroundTransparency = 1,
	Text = "Elige un poder para equiparlo.",
	Font = FONT_NAME,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(210, 210, 218),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	ZIndex = 33,
}, panel)

make("TextLabel", {
	Position = UDim2.new(0, 28, 0, 400),
	Size = UDim2.new(1, -56, 0, 96),
	BackgroundTransparency = 1,
	Text = "Puedes hablar con la vendedora en la tienda o recibir tu poder al entrar a la partida. Con la herramienta equipada, haz clic o toca hacia donde apuntas para lanzarlo.",
	Font = FONT_NAME,
	TextSize = 19,
	TextColor3 = Color3.fromRGB(170, 170, 178),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	ZIndex = 33,
}, panel)

for i, d in ipairs(POWER_DEFS) do
	local c = makeCard(i, d)
	powerCards[d.power] = c
	if d.locked then
		c.btn.Activated:Connect(function()
			toast("Aún no disponible")
		end)
		c.btn.MouseEnter:Connect(function()
			descLabel.Text = "Este poder se desbloqueará más adelante."
		end)
	else
		c.btn.MouseEnter:Connect(function()
			descLabel.Text = d.desc
			if equippedPower ~= d.power then
				c.stroke.Color = YELLOW
			end
		end)
		c.btn.MouseLeave:Connect(function()
			refreshCards()
		end)
		c.btn.Activated:Connect(function()
			pickPower(d.power)
		end)
	end
end


local function openPanel()
	updateScale()
	refreshChips()
	refreshCards()
	descLabel.Text = "Elige un poder para equiparlo."
	panelOpen = true
	overlay.BackgroundTransparency = 1
	overlay.Visible = true
	panel.Position = UDim2.new(0.5, 0, 0.58, 0)
	TweenService:Create(overlay, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

--// ============ HABLAR CON LA MAGA ============
local busy = false
local function talk()
	if busy then
		return
	end
	busy = true
	PromptService.Enabled = false
	showDialog(true)
	say("Hola, hechicero. Aquí te dejo la lista de los poderes disponibles para ti.")
	task.wait(0.7)
	openPanel()
	local reason, power = panelClosed.Event:Wait()
	if reason == "equip" then
		toast("Equipaste el poder de " .. power)
		say("Buena elección, hechicero. Haz clic o toca para lanzar tu poder.")
		task.wait(2.4)
	else
		remote:FireServer("NoPick")
		say("Vuelve cuando quieras, hechicero.")
		task.wait(1.4)
	end
	showDialog(false)
	busy = false
	PromptService.Enabled = true
end

--// ============ LANZAR PODERES (animación + efectos locales) ============
local Debris = game:GetService("Debris")
local kp = NumberSequenceKeypoint.new
local ckp = ColorSequenceKeypoint.new
local PURPLE = Color3.fromRGB(170, 64, 255)

local localFx = workspace:FindFirstChild("PoderesFXLocal") or make("Folder", { Name = "PoderesFXLocal" }, workspace)
local localCasting = false
local active = {}

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

-- ---------- herramientas ----------
local function hookTool(tool)
	if not tool:IsA("Tool") or not tool:GetAttribute("Power") or tool:GetAttribute("Hooked") then
		return
	end
	tool:SetAttribute("Hooked", true)
	tool.Activated:Connect(function()
		local power = tool:GetAttribute("Power")
		if localCasting then
			return
		end
		if os.clock() < (cdEnd[power] or 0) then
			toast("Recargando...")
			return
		end
		local aim = player:GetMouse().Hit.Position
		cdEnd[power] = os.clock() + (CD[power] or 3)
		remote:FireServer("Cast", power, aim)
	end)
end

local function watchContainer(c)
	c.ChildAdded:Connect(hookTool)
	for _, t in ipairs(c:GetChildren()) do
		hookTool(t)
	end
end

local function onCharacter(char)
	watchContainer(char)
	watchContainer(player:WaitForChild("Backpack"))
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

-- ---------- poses ----------
local function lerpN(a, b, t)
	return a + (b - a) * t
end

local function ease(t)
	return t * t * (3 - 2 * t)
end

local function blend(p0, p1, t)
	local r = {}
	for k, v in pairs(p1) do
		r[k] = lerpN(p0[k] or 0, v, t)
	end
	for k, v in pairs(p0) do
		if r[k] == nil then
			r[k] = lerpN(v, 0, t)
		end
	end
	return r
end

local function sample(keys, t)
	if t <= keys[1][1] then
		return keys[1][2]
	end
	for i = 2, #keys do
		if t <= keys[i][1] then
			local a, b = keys[i - 1], keys[i]
			return blend(a[2], b[2], ease((t - a[1]) / (b[1] - a[1])))
		end
	end
	return keys[#keys][2]
end

-- Convención R15: ángulo X positivo = brazo/pierna hacia ADELANTE.
-- Waist X negativo = inclinarse hacia adelante. Neck X positivo = mirar arriba.
local EARTH_FULL = { hip = 1.25, knee = -2.3, ankle = 1.05, lean = 1.2, rsx = 1.95, lsx = 1.95, rsz = 0.2, lsz = -0.2, re = 0.15, le = 0.15, neckX = 0.9 }
local EARTH_KEYS = {
	{ 0, {} },
	{ 0.45, { hip = 0.6, knee = -1.2, ankle = 0.6, lean = 0.5, rsx = -0.4, lsx = -0.4, neckX = 0.3 } },
	{ 0.85, EARTH_FULL },
	{ 1.7, EARTH_FULL },
	{ 2.3, {} },
}
local FIRE_CHARGE = { hip = 0.5, knee = -0.85, ankle = 0.35, lean = 0.15, twist = -0.55, neckY = 0.55, rsx = -0.9, rsz = 0.2, re = 1.8, lsx = 0.6, le = 0.7 }
local FIRE_THRUST = { hip = 0.65, knee = -1.0, ankle = 0.35, lean = 0.3, twist = 0.4, neckY = -0.4, rsx = 1.5, rsz = 0, re = 0.05, lsx = -0.5, lsz = -0.2, le = 0.3 }
local FIRE_HOLD = { hip = 0.6, knee = -0.9, ankle = 0.3, lean = 0.2, twist = 0.35, neckY = -0.35, rsx = 1.5, rsz = 0, re = 0.05, lsx = -0.4, lsz = -0.2, le = 0.3 }
local FIRE_KEYS = {
	{ 0, {} },
	{ 0.55, FIRE_CHARGE },
	{ 0.75, FIRE_THRUST },
	{ 1.1, FIRE_HOLD },
	{ 1.8, {} },
}
-- Agua: carga con ambas manos al pecho y empuja la ola al frente
local AGUA_CHARGE = { hip = 0.5, knee = -0.8, ankle = 0.35, lean = 0.1, rsx = -0.7, lsx = -0.7, re = 1.6, le = 1.6, neckX = 0.2 }
local AGUA_PUSH = { hip = 0.7, knee = -1.0, ankle = 0.4, lean = 0.45, rsx = 1.6, lsx = 1.6, re = 0.1, le = 0.1, neckX = -0.2 }
local AGUA_KEYS = {
	{ 0, {} },
	{ 0.5, AGUA_CHARGE },
	{ 0.8, AGUA_PUSH },
	{ 1.2, AGUA_PUSH },
	{ 1.8, {} },
}
-- Viento: brazos al cielo invocando y remolino al frente
local VIENTO_UP = { hip = 0.4, knee = -0.7, ankle = 0.3, lean = -0.2, rsx = -2.7, lsx = -2.7, rsz = 0.3, lsz = -0.3, re = 0.2, le = 0.2, neckX = 0.6 }
local VIENTO_SPIN = { hip = 0.5, knee = -0.9, ankle = 0.35, lean = 0.2, twist = 0.5, rsx = 1.2, lsx = 1.2, rsz = 0.5, lsz = -0.5, re = 0.4, le = 0.4 }
local VIENTO_KEYS = {
	{ 0, {} },
	{ 0.6, VIENTO_UP },
	{ 0.9, VIENTO_SPIN },
	{ 1.4, VIENTO_SPIN },
	{ 2.0, {} },
}
-- Rayo: mano al cielo y descarga hacia el objetivo
local RAYO_SKY = { hip = 0.4, knee = -0.7, ankle = 0.3, lean = -0.25, rsx = -2.9, rsz = 0.1, re = 0.1, lsx = 0.4, le = 0.8, neckX = 0.7 }
local RAYO_DOWN = { hip = 0.6, knee = -0.9, ankle = 0.35, lean = 0.35, rsx = 1.5, rsz = 0, re = 0.05, lsx = -0.4, le = 0.4, neckX = -0.3 }
local RAYO_KEYS = {
	{ 0, {} },
	{ 0.55, RAYO_SKY },
	{ 0.85, RAYO_DOWN },
	{ 1.1, RAYO_DOWN },
	{ 1.6, {} },
}

-- estilo de lanzamiento por poder (Tierra va por su propia rama)
local CAST_STYLE = {
	Fuego = { keys = FIRE_KEYS, dur = 1.8, orb = Color3.fromRGB(170, 64, 255), flash = Color3.fromRGB(150, 60, 255), fov = -12 },
	Agua = { keys = AGUA_KEYS, dur = 1.8, orb = Color3.fromRGB(60, 140, 255), flash = Color3.fromRGB(60, 140, 255), fov = -8 },
	Viento = { keys = VIENTO_KEYS, dur = 2.0, orb = Color3.fromRGB(190, 230, 255), flash = Color3.fromRGB(200, 235, 255), fov = -6 },
	Rayo = { keys = RAYO_KEYS, dur = 1.6, orb = Color3.fromRGB(235, 245, 255), flash = Color3.fromRGB(200, 220, 255), fov = -10 },
}

local function getRig(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.RigType ~= Enum.HumanoidRigType.R15 then
		return nil
	end
	local function mot(part, joint)
		local p = char:FindFirstChild(part)
		return p and p:FindFirstChild(joint)
	end
	local m = {
		Root = mot("LowerTorso", "Root"),
		Waist = mot("UpperTorso", "Waist"),
		Neck = mot("Head", "Neck"),
		RS = mot("RightUpperArm", "RightShoulder"),
		LS = mot("LeftUpperArm", "LeftShoulder"),
		RE = mot("RightLowerArm", "RightElbow"),
		LE = mot("LeftLowerArm", "LeftElbow"),
		RH = mot("RightUpperLeg", "RightHip"),
		LH = mot("LeftUpperLeg", "LeftHip"),
		RK = mot("RightLowerLeg", "RightKnee"),
		LK = mot("LeftLowerLeg", "LeftKnee"),
		RA = mot("RightFoot", "RightAnkle"),
		LA = mot("LeftFoot", "LeftAnkle"),
	}
	if not (m.Root and m.Waist and m.RS and m.LS) then
		return nil
	end
	local o = {}
	for k, v in pairs(m) do
		o[k] = v.C0
	end
	local ul, ll = char:FindFirstChild("RightUpperLeg"), char:FindFirstChild("RightLowerLeg")
	return { m = m, o = o, U = ul and ul.Size.Y or 1, L = ll and ll.Size.Y or 1.2 }
end

local function applyPose(rig, p)
	local m, o = rig.m, rig.o
	local function set(n, cf)
		if m[n] then
			m[n].C0 = o[n] * cf
		end
	end
	local hip, knee, ankle = p.hip or 0, p.knee or 0, p.ankle or 0
	-- cuánto baja la cadera para que los pies sigan en el suelo
	local drop = (rig.U + rig.L) - (rig.U * math.cos(hip) + rig.L * math.cos(hip + knee))
	set("Root", CFrame.new(0, -drop, 0))
	set("Waist", CFrame.Angles(-(p.lean or 0), p.twist or 0, 0))
	set("Neck", CFrame.Angles(p.neckX or 0, p.neckY or 0, 0))
	set("RH", CFrame.Angles(hip, 0, 0))
	set("LH", CFrame.Angles(hip, 0, 0))
	set("RK", CFrame.Angles(knee, 0, 0))
	set("LK", CFrame.Angles(knee, 0, 0))
	set("RA", CFrame.Angles(ankle, 0, 0))
	set("LA", CFrame.Angles(ankle, 0, 0))
	set("RS", CFrame.Angles(p.rsx or 0, 0, p.rsz or 0))
	set("LS", CFrame.Angles(p.lsx or 0, 0, p.lsz or 0))
	set("RE", CFrame.Angles(p.re or 0, 0, 0))
	set("LE", CFrame.Angles(p.le or 0, 0, 0))
end

-- ---------- efectos locales ----------
local function groundPoint(pos)
	local list = { localFx }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	local fx = workspace:FindFirstChild("PoderesFX")
	if fx then
		table.insert(list, fx)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = list
	local r = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), params)
	return r and r.Position or Vector3.new(pos.X, pos.Y - 3, pos.Z)
end

local function purpleEmitters(att, s, rateMul)
	local flame = Instance.new("ParticleEmitter")
	flame.Texture = "rbxasset://textures/particles/fire_main.dds"
	flame.Color = ColorSequence.new({
		ckp(0, Color3.fromRGB(240, 205, 255)),
		ckp(0.3, Color3.fromRGB(176, 70, 255)),
		ckp(0.7, Color3.fromRGB(104, 32, 200)),
		ckp(1, Color3.fromRGB(34, 10, 80)),
	})
	flame.LightEmission = 1
	flame.LightInfluence = 0
	flame.Size = NumberSequence.new({ kp(0, 2.4 * s), kp(0.4, 2.0 * s), kp(1, 0) })
	flame.Transparency = NumberSequence.new({ kp(0, 0.15), kp(0.7, 0.5), kp(1, 1) })
	flame.Lifetime = NumberRange.new(0.35, 0.7)
	flame.Rate = 110 * rateMul
	flame.Speed = NumberRange.new(1, 3)
	flame.SpreadAngle = Vector2.new(180, 180)
	flame.Rotation = NumberRange.new(0, 360)
	flame.RotSpeed = NumberRange.new(-150, 150)
	flame.Acceleration = Vector3.new(0, 5, 0)
	flame.Parent = att

	local embers = Instance.new("ParticleEmitter")
	embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	embers.Color = ColorSequence.new(Color3.fromRGB(235, 160, 255), Color3.fromRGB(150, 70, 255))
	embers.LightEmission = 1
	embers.LightInfluence = 0
	embers.Size = NumberSequence.new({ kp(0, 0.45 * s), kp(1, 0) })
	embers.Lifetime = NumberRange.new(0.5, 1.2)
	embers.Rate = 55 * rateMul
	embers.Speed = NumberRange.new(4, 9)
	embers.SpreadAngle = Vector2.new(180, 180)
	embers.Acceleration = Vector3.new(0, -6, 0)
	embers.Parent = att
	return flame, embers
end

local function greenEmitter(att)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(150, 255, 110), Color3.fromRGB(60, 200, 70))
	e.LightEmission = 0.8
	e.Size = NumberSequence.new({ kp(0, 0.5), kp(1, 0) })
	e.Lifetime = NumberRange.new(0.5, 1)
	e.Rate = 45
	e.Speed = NumberRange.new(3, 8)
	e.SpreadAngle = Vector2.new(70, 70)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, 4, 0)
	e.Parent = att
	return e
end

local function makeOrb(hand, grow, color, fiery)
	local orb = make("Part", {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.3, 0.3, 0.3),
		Material = Enum.Material.Neon,
		Color = color,
		Transparency = 0.1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Massless = true,
		CastShadow = false,
	}, nil)
	orb.CFrame = hand.CFrame * CFrame.new(0, -0.55, 0)
	orb.Parent = localFx
	make("WeldConstraint", { Part0 = hand, Part1 = orb }, orb)
	local att = make("Attachment", {}, orb)
	if fiery then
		purpleEmitters(att, 0.6, 0.6)
	else
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(color)
		e.Size = NumberSequence.new({ kp(0, 0.6), kp(1, 0) })
		e.Lifetime = NumberRange.new(0.4, 0.9)
		e.Rate = 60
		e.Speed = NumberRange.new(2, 6)
		e.SpreadAngle = Vector2.new(180, 180)
		e.LightEmission = 0.9
		e.Parent = att
	end
	make("PointLight", { Color = color, Range = 10, Brightness = 1.2, Shadows = false }, orb)
	TweenService:Create(orb, TweenInfo.new(grow, Enum.EasingStyle.Quad), { Size = Vector3.new(2.1, 2.1, 2.1) }):Play()
	return orb
end

local function burstAt(pos)
	local p = make("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(0.5, 0.5, 0.5),
		CFrame = CFrame.new(pos),
	}, localFx)
	local att = make("Attachment", {}, p)
	local f, e = purpleEmitters(att, 1.4, 0)
	f.Speed = NumberRange.new(4, 12)
	e.Speed = NumberRange.new(10, 26)
	f:Emit(25)
	e:Emit(35)
	Debris:AddItem(p, 2)
end

local function screenFlash(color, alpha)
	local f = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = color, BackgroundTransparency = alpha, BorderSizePixel = 0, ZIndex = 5 }, gui)
	TweenService:Create(f, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	Debris:AddItem(f, 0.5)
end

-- destello genérico del color del poder (para Agua/Viento/Rayo)
local function puffAt(pos, color)
	local p = make("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.new(0.5, 0.5, 0.5),
		CFrame = CFrame.new(pos),
	}, localFx)
	local att = make("Attachment", {}, p)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ kp(0, 0.9), kp(1, 0) })
	e.Lifetime = NumberRange.new(0.4, 0.9)
	e.Rate = 0
	e.Speed = NumberRange.new(8, 20)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = 0.8
	e.Parent = att
	e:Emit(30)
	Debris:AddItem(p, 1.5)
end

-- ---------- reproducir el lanzamiento (se ejecuta en TODOS los clientes) ----------
local function playCast(plr, power, dir, delay)
	local char = plr.Character
	if not char or active[char] then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return
	end
	active[char] = true
	local isLocal = (plr == player)
	local isEarth = (power == "Tierra")
	local st = CAST_STYLE[power] or CAST_STYLE.Fuego
	if isLocal then
		localCasting = true
	end

	local rig = getRig(char)
	local flat = Vector3.new(dir.X, 0, dir.Z)
	flat = flat.Magnitude > 0.01 and flat.Unit or hrp.CFrame.LookVector
	local right = flat:Cross(Vector3.yAxis).Unit

	-- el que lanza se queda quieto y mira hacia donde apunta
	local saved
	if isLocal then
		saved = { ws = hum.WalkSpeed, jp = hum.JumpPower, jh = hum.JumpHeight, ar = hum.AutoRotate }
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		hum.JumpHeight = 0
		hum.AutoRotate = false
		hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
	end

	-- IK: las manos llegan exactamente al suelo / al frente (si IKControl no funciona, queda la pose)
	local targets, iks = {}, {}
	local function addIK(handName, upperName)
		local tp = make("Part", {
			Size = Vector3.new(0.4, 0.4, 0.4),
			Transparency = 1,
			Anchored = true,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
		}, localFx)
		table.insert(targets, tp)
		local hand, upper = char:FindFirstChild(handName), char:FindFirstChild(upperName)
		if hand and upper then
			local ok, res = pcall(function()
				local c = Instance.new("IKControl")
				c.Type = Enum.IKControlType.Position
				c.ChainRoot = upper
				c.EndEffector = hand
				c.Target = tp
				c.Weight = 0
				c.SmoothTime = 0.05
				c.Parent = hum
				return c
			end)
			if ok then
				table.insert(iks, res)
				return tp, res
			end
		end
		return tp, nil
	end

	local tpR, ikR, tpL, ikL
	if rig then
		tpR, ikR = addIK("RightHand", "RightUpperArm")
		if isEarth then
			tpL, ikL = addIK("LeftHand", "LeftUpperArm")
			local o = hrp.Position
			tpR.Position = groundPoint(o + flat * 3.0 + right * 0.8) + Vector3.new(0, 0.2, 0)
			tpL.Position = groundPoint(o + flat * 3.0 - right * 0.8) + Vector3.new(0, 0.2, 0)
		end
	end

	local handR = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	local handL = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
	local keys = isEarth and EARTH_KEYS or st.keys
	local duration = isEarth and 2.3 or st.dur
	local baseFov = camera.FieldOfView
	local fxObjects, handEmitters = {}, {}
	local orb, released, handFxOn = nil, false, false
	local t0 = os.clock()
	local conn

	local function cleanup()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		for _, ik in ipairs(iks) do
			ik:Destroy()
		end
		for _, tp in ipairs(targets) do
			tp:Destroy()
		end
		for _, o in ipairs(fxObjects) do
			if o.Parent then
				o:Destroy()
			end
		end
		if rig then
			for k, mot in pairs(rig.m) do
				mot.C0 = rig.o[k]
			end
		end
		if isLocal then
			if not char:GetAttribute("Trapped") then
				hum.WalkSpeed = saved.ws
				hum.JumpPower = saved.jp
				hum.JumpHeight = saved.jh
			end
			hum.AutoRotate = saved.ar
			localCasting = false
			TweenService:Create(camera, TweenInfo.new(0.3), { FieldOfView = baseFov }):Play()
		end
		active[char] = nil
	end

	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > duration or not char.Parent or hum.Health <= 0 then
			cleanup()
			return
		end

		-- pose del cuerpo
		if rig then
			local p = {}
			for k, v in pairs(sample(keys, t)) do
				p[k] = v
			end
			if isEarth and t > 0.85 and t < 1.7 then
				p.lean = (p.lean or 0) + math.sin(t * 45) * 0.03 -- la tierra vibra
			end
			applyPose(rig, p)

			if not isEarth then
				if tpR then
					tpR.Position = hrp.Position + Vector3.new(0, 0.7, 0) + dir * 5.5
				end
				local w = (t < 1.1) and clamp01((t - 0.55) / 0.18) or clamp01((1.6 - t) / 0.5)
				if ikR then
					ikR.Weight = w
				end
			else
				local w = (t < 1.7) and clamp01((t - 0.5) / 0.35) or clamp01((2.15 - t) / 0.45)
				if ikR then
					ikR.Weight = w
				end
				if ikL then
					ikL.Weight = w
				end
			end
		end

		-- efectos y cámara
		if not isEarth then
			if not orb and t >= 0.05 and handR then
				orb = makeOrb(handR, math.max(delay - 0.05, 0.3), st.orb, power == "Fuego")
				table.insert(fxObjects, orb)
			end
			if isLocal and not released then
				camera.FieldOfView = baseFov + st.fov * clamp01(t / 0.55)
			end
			if not released and t >= delay then
				released = true
				if orb then
					orb:Destroy()
				end
				if handR then
					if power == "Fuego" then
						burstAt(handR.Position + flat * 1.5)
					else
						puffAt(handR.Position + flat * 1.5, st.orb)
					end
				end
				if isLocal then
					shake(1.0, 0.35)
					screenFlash(st.flash, 0.72)
					TweenService:Create(camera, TweenInfo.new(0.1), { FieldOfView = baseFov + 14 }):Play()
					task.delay(0.1, function()
						TweenService:Create(camera, TweenInfo.new(0.5), { FieldOfView = baseFov }):Play()
					end)
				end
			end
		else
			if not handFxOn and t >= 0.8 then
				handFxOn = true
				for _, h in ipairs({ handR, handL }) do
					if h then
						local att = make("Attachment", {}, h)
						local light = make("PointLight", { Color = Color3.fromRGB(100, 255, 100), Range = 8, Brightness = 1, Shadows = false }, h)
						table.insert(fxObjects, att)
						table.insert(fxObjects, light)
						table.insert(handEmitters, greenEmitter(att))
					end
				end
			end
			if handFxOn and t > 1.7 then
				for _, e in ipairs(handEmitters) do
					e.Enabled = false
				end
			end
			if isLocal then
				if not released then
					camera.FieldOfView = baseFov + 4 * clamp01(t / 0.8)
				end
				if t > 0.8 and t < 1.7 then
					shake(0.16, 0.15)
				end
				if not released and t >= delay then
					released = true
					shake(0.9, 0.5)
				end
			end
		end
	end)
end

remote.OnClientEvent:Connect(function(action, a, b, c, d)
	if action == "Talk" then
		task.spawn(talk)
	elseif action == "CastFX" then
		if typeof(a) == "Instance" and a:IsA("Player") and typeof(c) == "Vector3" then
			task.spawn(playCast, a, b, c, d or 0.8)
		end
	elseif action == "Shake" then
		shake(a or 0.5, b or 0.4)
	end
end)

print("🔮 Poderes de la maga listos (cliente)")
