--[[
	🔮 PODERES DE LA MAGA - SERVIDOR
	---------------------------------
	CÓMO USARLO:
	1. Este archivo va como "Script" (NO LocalScript) en ServerScriptService.
	2. El otro archivo (localscript_poderes.lua) va como "LocalScript" en
	   StarterPlayer > StarterPlayerScripts.
	3. Deben estar también los scripts de la tienda y de la vendedora.

	QUÉ HACE:
	- Pone el botón "Hablar" (ProximityPrompt) sobre la vendedora.
	- Al hablar, el cliente muestra el diálogo y la pantalla de poderes.
	- Poderes disponibles ahora: TIERRA (lianas que atrapan) y FUEGO (llama púrpura).
	- Al elegir un poder recibes una herramienta; haz clic o toca para lanzarlo.
	  (Para probar necesitas otro jugador o un NPC con Humanoid cerca.)
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--// ============ CONFIGURACIÓN ============
local CFG = {
	PROMPT_DISTANCE = 14,

	EARTH_COOLDOWN = 8,
	EARTH_RELEASE_DELAY = 0.95, -- segundos hasta que brotan las lianas (sincronizado con la animación)
	EARTH_RANGE = 45,
	EARTH_TRAP_TIME = 6,
	EARTH_DAMAGE_PER_SEC = 3, -- daño por segundo mientras está atrapado (0 = no hace daño)

	FIRE_COOLDOWN = 3,
	FIRE_RELEASE_DELAY = 0.75,
	FIRE_SPEED = 85,
	FIRE_RANGE = 150,
	FIRE_DAMAGE = 30,
	FIRE_RADIUS = 11,
	FIRE_BURN_TIME = 3,
	FIRE_BURN_DPS = 4,

	AGUA_COOLDOWN = 6,
	AGUA_RELEASE_DELAY = 0.8,
	AGUA_SPEED = 55,
	AGUA_RANGE = 70,
	AGUA_DAMAGE = 18,

	VIENTO_COOLDOWN = 10,
	VIENTO_RELEASE_DELAY = 0.9,
	VIENTO_TIME = 5,
	VIENTO_DPS = 3,

	RAYO_COOLDOWN = 12,
	RAYO_RELEASE_DELAY = 1.0,
	RAYO_DAMAGE = 40,
	RAYO_RADIUS = 10,
}

--// ============ BASE ============
local remote = RS:FindFirstChild("PoderesEvent") or Instance.new("RemoteEvent")
remote.Name = "PoderesEvent"
remote.Parent = RS

local fxFolder = workspace:FindFirstChild("PoderesFX") or Instance.new("Folder")
fxFolder.Name = "PoderesFX"
fxFolder.Parent = workspace

local rng = Random.new()
local kp = NumberSequenceKeypoint.new
local ckp = ColorSequenceKeypoint.new

local function excludeList()
	local list = { fxFolder }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	return list
end

local function groundAt(pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excludeList()
	local r = workspace:Raycast(pos + Vector3.new(0, 8, 0), Vector3.new(0, -60, 0), params)
	if r then
		return r.Position
	end
	return Vector3.new(pos.X, pos.Y - 3, pos.Z)
end

local function newPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = fxFolder
	return p
end

local function tw(inst, t, goal, style, dir)
	local tween = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tween:Play()
	return tween
end

-- la pieza se encoge y desaparece pasados 'life' segundos
local function lifetime(part, life)
	task.delay(life, function()
		if part.Parent then
			tw(part, 0.45, { Size = Vector3.new(0.05, 0.05, 0.05), Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
	end)
	Debris:AddItem(part, life + 0.5)
end

local function shakeNear(pos, radius, mag, dur)
	for _, p in ipairs(Players:GetPlayers()) do
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local d = (hrp.Position - pos).Magnitude
			if d < radius then
				remote:FireClient(p, "Shake", mag * (1 - d / radius), dur)
			end
		end
	end
end

--// ============ EFECTOS: TIERRA ============
local GRASS = {
	Color3.fromRGB(64, 168, 56),
	Color3.fromRGB(92, 196, 64),
	Color3.fromRGB(40, 128, 48),
	Color3.fromRGB(120, 210, 80),
}
local VINE_A = Color3.fromRGB(30, 92, 40)
local VINE_B = Color3.fromRGB(54, 140, 56)
local LEAF = Color3.fromRGB(96, 200, 70)
local THORN = Color3.fromRGB(110, 78, 46)
local EARTH_GREEN = Color3.fromRGB(70, 200, 70)
local DIRT = Color3.fromRGB(96, 70, 44)

local function growUp(part, baseCF, finalSize, t)
	part.Transparency = 0
	part.Size = Vector3.new(finalSize.X, 0.05, finalSize.Z)
	part.CFrame = baseCF * CFrame.new(0, 0.025, 0)
	tw(part, t, { Size = finalSize, CFrame = baseCF * CFrame.new(0, finalSize.Y / 2, 0) }, Enum.EasingStyle.Back)
end

-- hierba que brota del suelo
local function sprout(center, radius, count, life, minH, maxH)
	for _ = 1, count do
		local ang = rng:NextNumber(0, math.pi * 2)
		local r = math.sqrt(rng:NextNumber()) * radius
		local g = groundAt(center + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r))
		local h = rng:NextNumber(minH, maxH)
		local base = CFrame.new(g) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, 6.28), rng:NextNumber(-0.25, 0.25))
		local blade = newPart({
			Color = GRASS[rng:NextInteger(1, #GRASS)],
			Size = Vector3.new(0.05, 0.05, 0.05),
			CFrame = base,
			Transparency = 1,
		})
		task.delay(rng:NextNumber(0, 0.35), function()
			if blade.Parent then
				growUp(blade, base, Vector3.new(0.14, h, 0.05), 0.35)
			end
		end)
		lifetime(blade, life)
	end
end

local function groundRing(pos, color, maxSize)
	local ring = newPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.15, 1, 1),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.35,
	})
	tw(ring, 0.55, { Size = Vector3.new(0.15, maxSize, maxSize), Transparency = 1 })
	Debris:AddItem(ring, 0.8)
end

local function dirtBurst(pos, color, count)
	local a = newPart({ Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(pos), Transparency = 1 })
	local att = Instance.new("Attachment")
	att.Parent = a
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ kp(0, 0.55), kp(1, 0.1) })
	e.Lifetime = NumberRange.new(0.5, 1.1)
	e.Speed = NumberRange.new(10, 24)
	e.SpreadAngle = Vector2.new(40, 40)
	e.EmissionDirection = Enum.NormalId.Top
	e.Acceleration = Vector3.new(0, -45, 0)
	e.Rate = 0
	e.Parent = att
	e:Emit(count)
	Debris:AddItem(a, 1.6)
end

-- crece una liana segmento a segmento (hojas y espinas incluidas)
local function growPath(points, thick, life, delay)
	task.spawn(function()
		local n = #points
		for i = 1, n - 1 do
			local a, b = points[i], points[i + 1]
			local len = (b - a).Magnitude
			if len > 0.01 then
				local th = thick * (1 - 0.5 * (i / n))
				local cf = CFrame.lookAt(a, b) * CFrame.new(0, 0, -len / 2) * CFrame.Angles(0, math.pi / 2, 0)
				local seg = newPart({
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(len + th * 0.7, 0.05, 0.05),
					CFrame = cf,
					Color = (i % 2 == 0) and VINE_A or VINE_B,
				})
				tw(seg, 0.22, { Size = Vector3.new(len + th * 0.7, th, th) }, Enum.EasingStyle.Back)
				lifetime(seg, life)

				if i % 3 == 0 then
					local side = cf.RightVector * (rng:NextInteger(0, 1) == 0 and 1 or -1)
					local lp = a + side * (th * 0.9 + 0.4) + Vector3.new(0, th * 0.3, 0)
					local leaf = newPart({
						Size = Vector3.new(0.05, 0.05, 0.05),
						Color = LEAF,
						CFrame = CFrame.lookAt(lp, lp + side + Vector3.new(0, 0.6, 0)),
					})
					tw(leaf, 0.25, { Size = Vector3.new(0.55, 0.05, 0.9) }, Enum.EasingStyle.Back)
					lifetime(leaf, life)
				end
				if i % 4 == 0 then
					local d = cf.UpVector * rng:NextNumber(-1, 1) + cf.RightVector * rng:NextNumber(-1, 1)
					if d.Magnitude < 0.1 then
						d = Vector3.yAxis
					end
					d = d.Unit
					local thorn = newPart({
						Size = Vector3.new(0.05, 0.05, 0.05),
						Color = THORN,
						CFrame = CFrame.lookAt(a, a + d) * CFrame.new(0, 0, -0.3),
					})
					tw(thorn, 0.2, { Size = Vector3.new(0.14, 0.14, 0.6) }, Enum.EasingStyle.Back)
					lifetime(thorn, life)
				end
			end
			task.wait(delay)
		end
	end)
end

local function groundVinePoints(startPos, endPos, steps, sway, phase)
	local pts = {}
	local dir = endPos - startPos
	local flat = Vector3.new(dir.X, 0, dir.Z)
	local side = flat.Magnitude > 0.01 and flat.Unit:Cross(Vector3.yAxis) or Vector3.xAxis
	for i = 0, steps do
		local f = i / steps
		local base = startPos:Lerp(endPos, f)
		local off = side * math.sin(f * math.pi * 3 + phase) * sway * math.sin(f * math.pi)
		local g = groundAt(base + off)
		pts[#pts + 1] = g + Vector3.new(0, 0.35 + math.abs(math.sin(f * 8 + phase)) * 0.25, 0)
	end
	return pts
end

local function spiralPoints(center, radius, height, turns, phase, n)
	local pts = {}
	for i = 0, n do
		local f = i / n
		local ang = phase + f * turns * math.pi * 2
		local r = radius * (1 - 0.7 * f ^ 3)
		pts[#pts + 1] = center + Vector3.new(math.cos(ang) * r, 0.2 + f * height, math.sin(ang) * r)
	end
	return pts
end

--// ============ TIERRA: ATRAPAR ============
local trapToken = setmetatable({}, { __mode = "k" })

local function trap(model, seconds)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		return
	end
	local token = (trapToken[model] or 0) + 1
	trapToken[model] = token
	if not model:GetAttribute("Trapped") then
		model:SetAttribute("Trapped", true)
		model:SetAttribute("_ws", hum.WalkSpeed)
		model:SetAttribute("_jp", hum.JumpPower)
		model:SetAttribute("_jh", hum.JumpHeight)
	end
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.JumpHeight = 0
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.Anchored = true

	task.spawn(function()
		local elapsed = 0
		while elapsed < seconds do
			task.wait(1)
			elapsed = elapsed + 1
			if trapToken[model] ~= token or not model.Parent or hum.Health <= 0 then
				break
			end
			if CFG.EARTH_DAMAGE_PER_SEC > 0 then
				hum:TakeDamage(CFG.EARTH_DAMAGE_PER_SEC)
			end
		end
		if trapToken[model] == token and model.Parent then
			hum.WalkSpeed = model:GetAttribute("_ws") or 16
			hum.JumpPower = model:GetAttribute("_jp") or 50
			hum.JumpHeight = model:GetAttribute("_jh") or 7.2
			hrp.Anchored = false
			model:SetAttribute("Trapped", nil)
		end
	end)
end

local function findTarget(char, origin, dir, range)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, fxFolder }
	local parts = workspace:GetPartBoundsInRadius(origin, range, params)
	local seen, best, bestScore = {}, nil, -math.huge
	for _, part in ipairs(parts) do
		local m = part:FindFirstAncestorOfClass("Model")
		if m and not seen[m] then
			seen[m] = true
			local h = m:FindFirstChildOfClass("Humanoid")
			local r = m:FindFirstChild("HumanoidRootPart")
			if h and r and h.Health > 0 then
				local d = r.Position - origin
				local flat = Vector3.new(d.X, 0, d.Z)
				local dist = flat.Magnitude
				local dot = dist > 0.01 and flat.Unit:Dot(dir) or 1
				local score = -dist + dot * 25 -- prefiere al más cercano y de frente
				if score > bestScore then
					best, bestScore = m, score
				end
			end
		end
	end
	return best
end

local function earth(plr, char, dir)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local origin = hrp.Position
	local feet = groundAt(origin)
	local right = dir:Cross(Vector3.yAxis).Unit
	local handsAt = feet + dir * 3.0
	local life = CFG.EARTH_TRAP_TIME + 0.8

	-- las manos tocan el suelo: grieta verde, tierra y hierba
	groundRing(handsAt, EARTH_GREEN, 10)
	dirtBurst(handsAt, DIRT, 30)
	sprout(handsAt, 3.5, 24, life, 0.8, 2.2)
	shakeNear(handsAt, 60, 0.6, 0.5)

	local target = findTarget(char, origin, dir, CFG.EARTH_RANGE)
	if target then
		local tpos = groundAt(target.HumanoidRootPart.Position)
		local dist = (tpos - handsAt).Magnitude
		local steps = math.clamp(math.ceil(dist / 1.5), 8, 40)
		local delay = 0.016
		for k = -1, 1 do
			local startP = handsAt + right * k * 1.1
			local endP = tpos + right * k * 0.6
			growPath(groundVinePoints(startP, endP, steps, 2.2, k * 1.7), 0.5, life, delay)
		end
		task.delay(steps * delay + 0.15, function()
			local tr = target.Parent and target:FindFirstChild("HumanoidRootPart")
			if not tr then
				return
			end
			local c = groundAt(tr.Position)
			trap(target, CFG.EARTH_TRAP_TIME)
			groundRing(c, EARTH_GREEN, 13)
			dirtBurst(c, DIRT, 40)
			sprout(c, 4.5, 28, life - 0.4, 1, 3)
			for k = 0, 4 do
				growPath(spiralPoints(c, 2.3, 7, 1.5, k * math.pi * 2 / 5, 24), 0.42, life - 0.6, 0.02)
			end
			local victim = Players:GetPlayerFromCharacter(target)
			if victim then
				remote:FireClient(victim, "Shake", 0.7, 0.6)
			end
		end)
	else
		-- sin objetivo: un abanico de lianas hacia adelante
		for k = -2, 2 do
			local d = CFrame.Angles(0, k * 0.22, 0) * dir
			growPath(groundVinePoints(handsAt, handsAt + d * 26, 18, 2.0, k), 0.45, 3.2, 0.018)
		end
	end
end

--// ============ EFECTOS: FUEGO PÚRPURA ============
local function flameEmitters(att, s, rateMul)
	local flame = Instance.new("ParticleEmitter")
	flame.Name = "Flame"
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
	embers.Name = "Embers"
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

	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(70, 28, 120))
	smoke.LightEmission = 0.2
	smoke.Size = NumberSequence.new({ kp(0, 1.6 * s), kp(1, 4.5 * s) })
	smoke.Transparency = NumberSequence.new({ kp(0, 0.65), kp(1, 1) })
	smoke.Lifetime = NumberRange.new(0.8, 1.4)
	smoke.Rate = 22 * rateMul
	smoke.Speed = NumberRange.new(1, 2)
	smoke.SpreadAngle = Vector2.new(180, 180)
	smoke.Rotation = NumberRange.new(0, 360)
	smoke.Acceleration = Vector3.new(0, 2, 0)
	smoke.Parent = att

	return flame, embers, smoke
end

local PURPLE = Color3.fromRGB(170, 64, 255)

local burning = setmetatable({}, { __mode = "k" })
local function burn(model)
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return
	end
	local untilT = os.clock() + CFG.FIRE_BURN_TIME
	if burning[model] then
		burning[model] = untilT -- ya ardiendo: se alarga
		return
	end
	burning[model] = untilT
	local att = Instance.new("Attachment")
	att.Name = "PurpleBurn"
	att.Parent = hrp
	flameEmitters(att, 0.9, 0.5)
	task.spawn(function()
		while burning[model] and os.clock() < burning[model] and hum.Health > 0 and model.Parent do
			task.wait(1)
			hum:TakeDamage(CFG.FIRE_BURN_DPS)
		end
		burning[model] = nil
		if att.Parent then
			att:Destroy()
		end
	end)
end

local function explode(char, pos, dir)
	local anchor = newPart({ Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos), Transparency = 1 })
	local att = Instance.new("Attachment")
	att.Parent = anchor
	local flash = Instance.new("PointLight")
	flash.Color = PURPLE
	flash.Range = 26
	flash.Brightness = 5
	flash.Parent = anchor
	tw(flash, 0.5, { Brightness = 0 })

	local flame, embers, smoke = flameEmitters(att, 2.4, 0)
	embers.Speed = NumberRange.new(20, 45)
	flame.Speed = NumberRange.new(6, 16)
	flame:Emit(50)
	embers:Emit(70)
	smoke:Emit(16)
	Debris:AddItem(anchor, 2.5)

	-- ondas de choque
	local ball = newPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(pos),
		Color = PURPLE,
		Material = Enum.Material.Neon,
		Transparency = 0.3,
	})
	local big = CFG.FIRE_RADIUS * 1.8
	tw(ball, 0.4, { Size = Vector3.new(big, big, big), Transparency = 1 })
	Debris:AddItem(ball, 0.6)
	local ring = newPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 2, 2),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(225, 160, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	})
	tw(ring, 0.5, { Size = Vector3.new(0.2, big * 1.5, big * 1.5), Transparency = 1 })
	Debris:AddItem(ring, 0.7)

	shakeNear(pos, 90, 1.2, 0.55)

	-- daño en área
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, fxFolder }
	local hitModels = {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(pos, CFG.FIRE_RADIUS, params)) do
		local m = part:FindFirstAncestorOfClass("Model")
		if m and not hitModels[m] then
			local h = m:FindFirstChildOfClass("Humanoid")
			local r = m:FindFirstChild("HumanoidRootPart")
			if h and r and h.Health > 0 then
				hitModels[m] = true
				local dist = (r.Position - pos).Magnitude
				local f = math.clamp(1 - (dist / CFG.FIRE_RADIUS) * 0.6, 0.4, 1)
				h:TakeDamage(CFG.FIRE_DAMAGE * f)
				if not r.Anchored then
					local d = r.Position - pos
					d = d.Magnitude > 0.1 and d.Unit or dir
					r:ApplyImpulse((d * 60 + Vector3.new(0, 38, 0)) * r.AssemblyMass)
				end
				burn(m)
			end
		end
	end
end

local function fire(plr, char, dir)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local pos = hrp.Position + Vector3.new(0, 1.2, 0) + dir * 3

	local core = newPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2),
		Color = PURPLE,
		Material = Enum.Material.Neon,
		Transparency = 0.15,
		CFrame = CFrame.new(pos),
	})
	local heart = newPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.1, 1.1, 1.1),
		Color = Color3.fromRGB(245, 225, 255),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(pos),
	})
	local att = Instance.new("Attachment")
	att.Parent = core
	flameEmitters(att, 1, 1)

	local light = Instance.new("PointLight")
	light.Color = PURPLE
	light.Range = 14
	light.Brightness = 1.6
	light.Parent = core

	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.9, 0)
	a1.Position = Vector3.new(0, -0.9, 0)
	a0.Parent, a1.Parent = core, core
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime = 0.4
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(Color3.fromRGB(220, 150, 255), Color3.fromRGB(90, 30, 190))
	trail.Transparency = NumberSequence.new({ kp(0, 0.2), kp(1, 1) })
	trail.WidthScale = NumberSequence.new({ kp(0, 1), kp(1, 0) })
	trail.Parent = core

	-- raycast que ignora piezas invisibles (luces, ayudas...)
	local ignore = { char, fxFolder }
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local function castRay(origin, vec)
		for _ = 1, 5 do
			local r = workspace:Raycast(origin, vec, params)
			if r and r.Instance.Transparency >= 0.95 and r.Instance.Name ~= "HumanoidRootPart" then
				table.insert(ignore, r.Instance)
				params.FilterDescendantsInstances = ignore
			else
				return r
			end
		end
		return nil
	end

	local traveled = 0
	local conn
	local function finish(hitPos)
		if conn then
			conn:Disconnect()
			conn = nil
		end
		-- las partículas se apagan solas, la bola desaparece
		for _, e in ipairs(att:GetChildren()) do
			if e:IsA("ParticleEmitter") then
				e.Rate = 0
			end
		end
		core.Transparency = 1
		heart.Transparency = 1
		light.Enabled = false
		Debris:AddItem(core, 1.5)
		Debris:AddItem(heart, 0.1)
		if hitPos then
			explode(char, hitPos, dir)
		end
	end

	conn = RunService.Heartbeat:Connect(function(dt)
		local stepLen = CFG.FIRE_SPEED * dt
		local r = castRay(pos, dir * (stepLen + 1.2))
		if r then
			finish(r.Position - dir * 0.3)
			return
		end
		pos = pos + dir * stepLen
		traveled = traveled + stepLen
		core.CFrame = CFrame.new(pos)
		heart.CFrame = core.CFrame
		if traveled >= CFG.FIRE_RANGE then
			finish(nil)
		end
	end)
end

--// ============ AGUA: OLA ABISAL ============
local WATER = Color3.fromRGB(60, 140, 255)
local WATER_DARK = Color3.fromRGB(30, 80, 200)

local function agua(plr, char, dir)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local origin = hrp.Position + Vector3.new(0, 1, 0)
	local wave = newPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6, 4, 2.5),
		Color = WATER,
		Material = Enum.Material.Neon,
		Transparency = 0.25,
		CFrame = CFrame.lookAt(origin + dir * 3, origin + dir * 4),
	})
	local att = Instance.new("Attachment")
	att.Parent = wave
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(WATER, WATER_DARK)
	pe.LightEmission = 0.6
	pe.Size = NumberSequence.new({ kp(0, 1.2), kp(1, 0) })
	pe.Lifetime = NumberRange.new(0.4, 0.9)
	pe.Rate = 80
	pe.Speed = NumberRange.new(6, 14)
	pe.SpreadAngle = Vector2.new(60, 60)
	pe.Parent = att
	local light = Instance.new("PointLight")
	light.Color = WATER
	light.Range = 12
	light.Brightness = 1.4
	light.Parent = wave
	shakeNear(origin, 50, 0.7, 0.4)

	local traveled = 0
	local golpeados = {}
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local step = CFG.AGUA_SPEED * dt
		traveled = traveled + step
		wave.CFrame = CFrame.lookAt(wave.Position + dir * step, wave.Position + dir * (step + 1))
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char, fxFolder }
		for _, part in ipairs(workspace:GetPartBoundsInRadius(wave.Position, 5, params)) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m and not golpeados[m] then
				local h = m:FindFirstChildOfClass("Humanoid")
				local r = m:FindFirstChild("HumanoidRootPart")
				if h and r and h.Health > 0 then
					golpeados[m] = true
					h:TakeDamage(CFG.AGUA_DAMAGE)
					if not r.Anchored then
						r:ApplyImpulse((dir * 70 + Vector3.new(0, 30, 0)) * r.AssemblyMass)
					end
					-- empapado: más lento 4 s
					if not m:GetAttribute("Empapado") then
						m:SetAttribute("Empapado", true)
						local ws = h.WalkSpeed
						h.WalkSpeed = ws * 0.5
						task.delay(4, function()
							if m.Parent and h.Parent then
								h.WalkSpeed = m:GetAttribute("Trapped") and 0 or ws
							end
							m:SetAttribute("Empapado", nil)
						end)
					end
				end
			end
		end
		if traveled >= CFG.AGUA_RANGE then
			conn:Disconnect()
			tw(wave, 0.4, { Transparency = 1, Size = Vector3.new(8, 1, 4) })
			Debris:AddItem(wave, 0.5)
		end
	end)
end

--// ============ VIENTO: TORNADO ============
local function viento(plr, char, dir)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local centro = groundAt(hrp.Position + dir * 10)
	local anillos = {}
	for i = 1, 4 do
		local radio = 1.5 + i * 1.2
		local a = newPart({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.5, radio * 2, radio * 2),
			CFrame = CFrame.new(centro + Vector3.new(0, 1 + i * 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Color = Color3.fromRGB(200, 230, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.55,
		})
		table.insert(anillos, { p = a, h = 1 + i * 2, fase = rng:NextNumber(0, 6.28) })
	end
	shakeNear(centro, 60, 0.8, 0.5)
	local t0 = os.clock()
	local ultimoDano = {}
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local t = os.clock() - t0
		if t >= CFG.VIENTO_TIME then
			conn:Disconnect()
			for _, x in ipairs(anillos) do
				tw(x.p, 0.5, { Transparency = 1 })
				Debris:AddItem(x.p, 0.6)
			end
			return
		end
		centro = centro + dir * 8 * dt
		for _, x in ipairs(anillos) do
			x.fase = x.fase + dt * 7
			x.p.CFrame = CFrame.new(centro + Vector3.new(0, x.h, 0))
				* CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(x.fase, 0, 0)
		end
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char, fxFolder }
		for _, part in ipairs(workspace:GetPartBoundsInRadius(centro + Vector3.new(0, 3, 0), 11, params)) do
			local m = part:FindFirstAncestorOfClass("Model")
			if m then
				local h = m:FindFirstChildOfClass("Humanoid")
				local r = m:FindFirstChild("HumanoidRootPart")
				if h and r and h.Health > 0 and not r.Anchored then
					local hacia = (centro + Vector3.new(0, 2, 0)) - r.Position
					if hacia.Magnitude > 0.5 then
						r.AssemblyLinearVelocity = r.AssemblyLinearVelocity:Lerp(hacia.Unit * 16 + Vector3.new(0, 7, 0), 0.12)
					end
					if os.clock() - (ultimoDano[m] or 0) >= 0.5 then
						ultimoDano[m] = os.clock()
						h:TakeDamage(CFG.VIENTO_DPS)
					end
				end
			end
		end
	end)
end

--// ============ RAYO: JUICIO CELESTIAL ============
local function rayo(plr, char, dir)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local punto = groundAt(hrp.Position + dir * 42)
	-- rayo quebrado que baja del cielo
	local desde = punto + Vector3.new(0, 70, 0)
	local prev = desde
	local segs = 7
	for i = 1, segs do
		local f = i / segs
		local pos = desde:Lerp(punto, f)
			+ Vector3.new(rng:NextNumber(-4, 4) * (1 - f), 0, rng:NextNumber(-4, 4) * (1 - f))
		local len = (pos - prev).Magnitude
		if len > 0.01 then
			local b = newPart({
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(len, 0.7, 0.7),
				CFrame = CFrame.lookAt((prev + pos) / 2, pos) * CFrame.Angles(0, math.rad(90), 0),
				Color = Color3.fromRGB(235, 245, 255),
				Material = Enum.Material.Neon,
			})
			tw(b, 0.45, { Transparency = 1 })
			Debris:AddItem(b, 0.6)
		end
		prev = pos
	end
	local anchorR = newPart({ Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(punto), Transparency = 1 })
	local flash = Instance.new("PointLight")
	flash.Color = Color3.fromRGB(220, 235, 255)
	flash.Range = 30
	flash.Brightness = 6
	flash.Parent = anchorR
	tw(flash, 0.5, { Brightness = 0 })
	Debris:AddItem(anchorR, 1)
	-- marca quemada en el suelo
	local marca = newPart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 8, 8),
		CFrame = CFrame.new(punto + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(20, 20, 25),
		Transparency = 0.4,
	})
	tw(marca, 2, { Transparency = 1 })
	Debris:AddItem(marca, 2.2)
	groundRing(punto, Color3.fromRGB(220, 235, 255), 16)
	shakeNear(punto, 80, 1.4, 0.6)

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char, fxFolder }
	for _, part in ipairs(workspace:GetPartBoundsInRadius(punto, CFG.RAYO_RADIUS, params)) do
		local m = part:FindFirstAncestorOfClass("Model")
		if m then
			local h = m:FindFirstChildOfClass("Humanoid")
			if h and h.Health > 0 then
				h:TakeDamage(CFG.RAYO_DAMAGE)
				-- aturdido 1.5 s
				if not m:GetAttribute("Aturdido") and not m:GetAttribute("Trapped") then
					m:SetAttribute("Aturdido", true)
					local ws = h.WalkSpeed
					h.WalkSpeed = 0
					task.delay(1.5, function()
						if m.Parent and h.Parent and not m:GetAttribute("Trapped") then
							h.WalkSpeed = ws
						end
						m:SetAttribute("Aturdido", nil)
					end)
				end
			end
		end
	end
end

--// ============ PODERES, HERRAMIENTAS Y CONTROL ============
local POWERS = {
	Tierra = {
		toolName = "Poder de Tierra",
		tip = "Lianas y hierba brotan del suelo y atrapan a quien esté cerca",
		cd = CFG.EARTH_COOLDOWN,
		delay = CFG.EARTH_RELEASE_DELAY,
		run = earth,
	},
	Fuego = {
		toolName = "Llama Púrpura",
		tip = "Lanza una llama púrpura que explota al impactar",
		cd = CFG.FIRE_COOLDOWN,
		delay = CFG.FIRE_RELEASE_DELAY,
		run = fire,
	},
	Agua = {
		toolName = "Ola Abisal",
		tip = "Lanza una ola que empuja y empapa a tus enemigos",
		cd = CFG.AGUA_COOLDOWN,
		delay = CFG.AGUA_RELEASE_DELAY,
		run = agua,
	},
	Viento = {
		toolName = "Tornado",
		tip = "Invoca un tornado que arrastra y golpea a quien atrape",
		cd = CFG.VIENTO_COOLDOWN,
		delay = CFG.VIENTO_RELEASE_DELAY,
		run = viento,
	},
	Rayo = {
		toolName = "Juicio Celestial",
		tip = "Un rayo cae del cielo donde apuntas y aturde",
		cd = CFG.RAYO_COOLDOWN,
		delay = CFG.RAYO_RELEASE_DELAY,
		run = rayo,
	},
}

local function removePowerTools(plr)
	local function clean(container)
		if container then
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("Power") then
					t:Destroy()
				end
			end
		end
	end
	clean(plr:FindFirstChildOfClass("Backpack"))
	clean(plr.Character)
end

local function givePower(plr, power, equipNow)
	local def = POWERS[power]
	if not def then
		return
	end
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	removePowerTools(plr)
	local tool = Instance.new("Tool")
	tool.Name = def.toolName
	tool.ToolTip = def.tip
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute("Power", power)
	tool.Parent = plr:WaitForChild("Backpack")
	plr:SetAttribute("EquippedPower", power)
	if equipNow then
		hum:EquipTool(tool)
	end
end

local cooldowns = {}

local function isAlive(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart") ~= nil
end

remote.OnServerEvent:Connect(function(plr, action, a, b)
	if action == "Equip" then
		if type(a) == "string" then
			givePower(plr, a, true)
			plr:SetAttribute("PoderOfrecido", true)
		end
	elseif action == "NoPick" then
		-- cerró el diálogo sin elegir: se le vuelve a ofrecer en 45 s
		plr:SetAttribute("PoderOfrecidoCD", os.clock() + 45)
	elseif action == "Cast" then
		local def = type(a) == "string" and POWERS[a]
		if not def or typeof(b) ~= "Vector3" then
			return
		end
		if plr:GetAttribute("EquippedPower") ~= a then
			return
		end
		local char = plr.Character
		if not isAlive(char) or char:GetAttribute("Trapped") then
			return
		end
		cooldowns[plr] = cooldowns[plr] or {}
		if os.clock() < (cooldowns[plr][a] or 0) then
			return
		end
		cooldowns[plr][a] = os.clock() + def.cd

		local hrp = char.HumanoidRootPart
		local dir = b - hrp.Position
		if dir.Magnitude < 0.1 then
			dir = hrp.CFrame.LookVector
		end
		if a == "Tierra" then
			dir = Vector3.new(dir.X, 0, dir.Z)
			if dir.Magnitude < 0.1 then
				dir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
			end
		end
		dir = dir.Unit

		remote:FireAllClients("CastFX", plr, a, dir, def.delay)
		task.delay(def.delay, function()
			if isAlive(plr.Character) and plr.Character == char then
				def.run(plr, char, dir)
			end
		end)
	end
end)

local function setupPlayer(plr)
	plr.CharacterAdded:Connect(function()
		local p = plr:GetAttribute("EquippedPower")
		if p then
			task.wait(0.8)
			givePower(plr, p, false)
		end
	end)
end
Players.PlayerAdded:Connect(setupPlayer)
for _, plr in ipairs(Players:GetPlayers()) do
	setupPlayer(plr)
end
Players.PlayerRemoving:Connect(function(plr)
	cooldowns[plr] = nil
end)

--// ============ BOTÓN "HABLAR" SOBRE LA VENDEDORA ============
task.spawn(function()
	local vend = workspace:WaitForChild("VendedoraMagica", 120)
	local torso = vend and vend:WaitForChild("Torso", 10)
	if not torso then
		warn("MagoPoderes: no encontré a la vendedora (VendedoraMagica). Pon también su script.")
		return
	end
	local old = torso:FindFirstChild("HablarPrompt")
	if old then
		old:Destroy()
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HablarPrompt"
	prompt.ActionText = "Hablar"
	prompt.ObjectText = "Vendedora Mágica"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CFG.PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = torso
	prompt.Triggered:Connect(function(plr)
		remote:FireClient(plr, "Talk")
	end)
end)

--// ============ PODERES DENTRO DE LA PARTIDA ============
-- La vendedora vive en la tienda (lobby). Para que el poder se brinde
-- ADENTRO de la partida (en el bosque, jugando), cuando un jugador entra
-- al bosque y aún no tiene poder, se le abre solo el diálogo de la maga
-- una vez por visita. No toca PARTIDA: solo mira posiciones y atributos.
local CENTRO_BOSQUE = Vector3.new(0, 0, 4200) -- mismo centro que el bosque
local RADIO_PARTIDA = 260

task.spawn(function()
	while true do
		task.wait(3)
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dentro = (hrp.Position - CENTRO_BOSQUE).Magnitude < RADIO_PARTIDA
				if dentro then
					local cd = plr:GetAttribute("PoderOfrecidoCD") or 0
					if not plr:GetAttribute("EquippedPower")
						and not plr:GetAttribute("PoderOfrecido")
						and os.clock() >= cd then
						-- anti-spam de 8 s mientras el diálogo abre; si elige,
						-- "Equip" marca PoderOfrecido; si cierra, "NoPick" da 45 s
						plr:SetAttribute("PoderOfrecidoCD", os.clock() + 8)
						remote:FireClient(plr, "Talk")
					end
				else
					-- salió del bosque (volvió al lobby): se puede ofrecer de nuevo
					if plr:GetAttribute("PoderOfrecido") then
						plr:SetAttribute("PoderOfrecido", nil)
					end
					if plr:GetAttribute("PoderOfrecidoCD") then
						plr:SetAttribute("PoderOfrecidoCD", nil)
					end
				end
			end
		end
	end
end)

print("🔮 Poderes de la maga listos (servidor)")
