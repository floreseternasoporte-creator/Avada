--[[
  🪵 MOLINO DE LA FOGATA - SERVIDOR (pedido del dueño, 2026-11-03)
  Pegar como "Script" en ServerScriptService. NO toca partida.

  Junto a cada fogata hay un MOLINO con su rueda girando. Sirve para
  MOLER la madera que sueltan los árboles al caer (atributo "Madera"
  del jugador, lo suma el hacha al recoger los trozos) y convertirla
  en TABLAS (atributo "Tablas"), el material con el que se construyen
  las DEFENSAS (serverscript_defensas.lua).

  Como partida clona bosque/fogata/caldero por sesión y NO clona un
  cuarto modelo, el molino se construye SOLO: un guardián vigila los
  modelos BosqueProhibido (molde y clones) y levanta un molino junto
  a su centro si aún no tiene uno. Al destruirse el clon al final de
  la partida, el molino se va con él. También pone el botón de uso
  (ProximityPrompt) y hace girar la rueda.

  Panel propio (localscript_molino.lua) vía el remoto MolinoEvent:
  el jugador lo abre con el prompt y muele x1, x5 o todo.
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RE = RS:FindFirstChild("MolinoEvent")
if not RE then
	RE = Instance.new("RemoteEvent")
	RE.Name = "MolinoEvent"
	RE.Parent = RS
end

local DESPLAZAMIENTO = Vector3.new(19, 0, 13) -- desde el centro del bosque

--// ============ CONSTRUIR EL MOLINO ============
local PIEDRA = Color3.fromRGB(96, 94, 104)
local PIEDRA_OSCURA = Color3.fromRGB(66, 64, 74)
local MADERA = Color3.fromRGB(110, 76, 44)
local MADERA_OSCURA = Color3.fromRGB(74, 50, 28)
local TEJA = Color3.fromRGB(140, 62, 48)

local function parte(padre, nombre, size, cf, color, material, collide)
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
	p.Parent = padre
	return p
end

local function construirMolino(bosque)
	local piv = bosque:GetPivot().Position
	local pos = Vector3.new(piv.X + DESPLAZAMIENTO.X, 0, piv.Z + DESPLAZAMIENTO.Z)
	-- apoyarlo en el suelo real
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { bosque }
	local r = Workspace:Raycast(pos + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), params)
	local sueloY = r and r.Position.Y or piv.Y
	local base = Vector3.new(pos.X, sueloY, pos.Z)
	-- mirando al centro del bosque (a la fogata)
	local cf = CFrame.new(base, Vector3.new(piv.X, sueloY, piv.Z))

	local m = Instance.new("Model")
	m.Name = "Molino"
	-- base de piedra (lleva el prompt de uso)
	local baseP = parte(m, "BaseMolino", Vector3.new(9, 1.2, 8), cf * CFrame.new(0, 0.6, 0), PIEDRA_OSCURA, Enum.Material.Slate, true)
	parte(m, "Pared", Vector3.new(7.5, 5.5, 0.7), cf * CFrame.new(0, 3.9, -3.2), PIEDRA, Enum.Material.Slate, true)
	parte(m, "LadoI", Vector3.new(0.7, 5.5, 6.4), cf * CFrame.new(-3.6, 3.9, 0), PIEDRA, Enum.Material.Slate, true)
	parte(m, "LadoD", Vector3.new(0.7, 5.5, 6.4), cf * CFrame.new(3.6, 3.9, 0), PIEDRA, Enum.Material.Slate, true)
	parte(m, "VigaI", Vector3.new(0.6, 6.2, 0.6), cf * CFrame.new(-3.2, 4.2, 3.2), MADERA_OSCURA, Enum.Material.Wood, true)
	parte(m, "VigaD", Vector3.new(0.6, 6.2, 0.6), cf * CFrame.new(3.2, 4.2, 3.2), MADERA_OSCURA, Enum.Material.Wood, true)
	-- tejado a dos aguas (dos losas inclinadas)
	parte(m, "TejaI", Vector3.new(5.4, 0.35, 8.6), cf * CFrame.new(-2.1, 7.6, 0) * CFrame.Angles(0, 0, math.rad(38)), TEJA, Enum.Material.Slate, true)
	parte(m, "TejaD", Vector3.new(5.4, 0.35, 8.6), cf * CFrame.new(2.1, 7.6, 0) * CFrame.Angles(0, 0, math.rad(-38)), TEJA, Enum.Material.Slate, true)
	-- la rueda: eje + aro + radios soldados (gira con el eje)
	local ruedaCF = cf * CFrame.new(0, 4.1, 4.1)
	local eje = parte(m, "EjeRueda", Vector3.new(0.7, 1.4, 0.7), ruedaCF * CFrame.Angles(math.rad(90), 0, 0), MADERA_OSCURA, Enum.Material.Wood, false, Enum.PartType.Cylinder)
	local function piezaRueda(nombre, size, off, rot, color)
		local p = Instance.new("Part")
		p.Name = nombre
		p.Size = size
		p.CFrame = ruedaCF * (off or CFrame.new()) * (rot or CFrame.new())
		p.Color = color or MADERA
		p.Material = Enum.Material.Wood
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		if nombre == "Aro" then
			p.Shape = Enum.PartType.Cylinder
		end
		p.Parent = m
		local w = Instance.new("WeldConstraint")
		w.Part0 = eje
		w.Part1 = p
		w.Parent = p
		return p
	end
	piezaRueda("Aro", Vector3.new(6.4, 0.55, 6.4), nil, CFrame.Angles(math.rad(90), 0, 0))
	piezaRueda("Radio1", Vector3.new(0.7, 5.9, 0.4), nil, nil)
	piezaRueda("Radio2", Vector3.new(5.9, 0.7, 0.4), nil, nil)
	piezaRueda("Buje", Vector3.new(1.1, 1.1, 1.1), nil, nil, MADERA_OSCURA)
	-- sacos de madera junto a la puerta (decoración)
	parte(m, "Saco1", Vector3.new(1.6, 1.3, 1.6), cf * CFrame.new(-2.8, 1.8, 3.4), Color3.fromRGB(150, 116, 74), Enum.Material.Wood, false, Enum.PartType.Ball)
	parte(m, "Saco2", Vector3.new(1.3, 1.1, 1.3), cf * CFrame.new(-1.4, 1.7, 3.8), Color3.fromRGB(132, 100, 62), Enum.Material.Wood, false, Enum.PartType.Ball)
	m.PrimaryPart = baseP
	m.Parent = bosque
	return m, baseP
end

local function ponerPrompt(molino, baseP)
	local p = Instance.new("ProximityPrompt")
	p.Name = "UsarMolino"
	p.ActionText = "Usar el molino"
	p.ObjectText = "Molino de la fogata"
	p.MaxActivationDistance = 12
	p.HoldDuration = 0.3
	p.RequiresLineOfSight = false
	p.Parent = baseP
	p.Triggered:Connect(function(player)
		pcall(function()
			RE:FireClient(player, "Abrir")
		end)
		enviarEstado(player)
	end)
	return p
end

function enviarEstado(player)
	pcall(function()
		RE:FireClient(player, "Estado", {
			madera = player:GetAttribute("Madera") or 0,
			tablas = player:GetAttribute("Tablas") or 0,
		})
	end)
end

-- guardián: cada bosque (molde o clon) tiene su molino con su prompt,
-- y de paso la rueda gira
local molinos = {} -- modelo -> eje
task.spawn(function()
	while true do
		task.wait(1.5)
		for _, b in ipairs(Workspace:GetChildren()) do
			if b:IsA("Model") and b.Name == "BosqueProhibido" then
				local mol = b:FindFirstChild("Molino")
				if not mol then
					local ok, nuevo, baseP = pcall(construirMolino, b)
					if ok and nuevo then
						mol = nuevo
						ponerPrompt(mol, baseP)
						molinos[mol] = mol:FindFirstChild("EjeRueda")
						print("[Molino] construido junto a una fogata")
					end
				else
					local baseP = mol:FindFirstChild("BaseMolino")
					if baseP and not baseP:FindFirstChild("UsarMolino") then
						ponerPrompt(mol, baseP)
					end
					if not molinos[mol] then
						molinos[mol] = mol:FindFirstChild("EjeRueda")
					end
				end
			end
		end
		for mol in pairs(molinos) do
			if not mol.Parent then
				molinos[mol] = nil
			end
		end
	end
end)

-- la rueda gira (suave, con el tiempo real entre latidos)
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
	for _, eje in pairs(molinos) do
		if eje and eje.Parent then
			eje.CFrame = eje.CFrame * CFrame.Angles(0, dt * 1.1, 0)
		end
	end
end)

--// ============ MOLER ============
local function moler(player, cantidad)
	local madera = player:GetAttribute("Madera") or 0
	if madera <= 0 then
		pcall(function()
			RE:FireClient(player, "Aviso", "No tienes madera: cae de los árboles al cortarlos")
		end)
		return
	end
	local n = cantidad == -1 and madera or math.min(cantidad or 1, madera)
	player:SetAttribute("Madera", madera - n)
	player:SetAttribute("Tablas", (player:GetAttribute("Tablas") or 0) + n)
	pcall(function()
		RE:FireClient(player, "Aviso", "¡" .. n .. " tabla(s) molidas! 🪵→🪚")
	end)
	enviarEstado(player)
end

RE.OnServerEvent:Connect(function(player, accion, dato)
	if accion == "Moler" and type(dato) == "number" then
		moler(player, dato)
	elseif accion == "Estado" then
		enviarEstado(player)
	end
end)

local function asegurar(player)
	if player:GetAttribute("Madera") == nil then
		player:SetAttribute("Madera", 0)
	end
	if player:GetAttribute("Tablas") == nil then
		player:SetAttribute("Tablas", 0)
	end
end
for _, p in ipairs(Players:GetPlayers()) do
	asegurar(p)
end
Players.PlayerAdded:Connect(asegurar)

print("[Avada] MOLINO listo: muele la madera de los árboles y haz tablas")
-- FIN SERVER MOLINO
