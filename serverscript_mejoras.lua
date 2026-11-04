--[[
  ⬆️ MEJORAS DE LA MAGA - SERVIDOR
  Pegar como "Script" en ServerScriptService. NO toca partida (solo
  deja dos atributos en el jugador que los demás sistemas leen):
  - NivelHacha (1-3): lo lee serverscript_hacha.lua (daño 1/2/3 y
    aspecto del filo: Aprendiz -> Rúnica -> del Archimago).
  - SacoMax (5/8/12): lo lee partida vía sacoMaxDe() para la
    capacidad del Saco mágico.

  Se paga con DIAMANTES de verdad: las Tools "Diamante" que el
  jugador lleve en la mano o la mochila (los que caen de los árboles
  de cristal). Comprar consume los diamantes.
  - Hacha: Nv 2 = 3 diamantes, Nv 3 = 6 diamantes.
  - Saco:  8 cosas = 4 diamantes, 12 cosas = 8 diamantes.
  La tienda vive en el panel de la maga (localscript_mejoras.lua
  añade la sección MEJORAS a su pantalla de poderes).
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local RE = RS:FindFirstChild("MejorasEvent")
if not RE then
	RE = Instance.new("RemoteEvent")
	RE.Name = "MejorasEvent"
	RE.Parent = RS
end

local COSTE_HACHA = { [1] = 3, [2] = 6 } -- coste para SUBIR desde ese nivel
local COSTE_SACO = { [1] = 4, [2] = 8 }
local CAP_SACO = { [1] = 5, [2] = 8, [3] = 12 }

local function nivelHacha(player)
	local n = player:GetAttribute("NivelHacha")
	if type(n) ~= "number" or n < 1 or n > 3 then
		return 1
	end
	return math.floor(n)
end

local function nivelSaco(player)
	local n = player:GetAttribute("NivelSaco")
	if type(n) ~= "number" or n < 1 or n > 3 then
		return 1
	end
	return math.floor(n)
end

local function asegurarAtributos(player)
	if player:GetAttribute("NivelHacha") == nil then
		player:SetAttribute("NivelHacha", 1)
	end
	if player:GetAttribute("NivelSaco") == nil then
		player:SetAttribute("NivelSaco", 1)
	end
	if player:GetAttribute("SacoMax") == nil then
		player:SetAttribute("SacoMax", CAP_SACO[nivelSaco(player)])
	end
end

-- diamantes que lleva encima (mano + mochila), como Tools "Diamante"
local function diamantesDe(player)
	local lista = {}
	local function mira(cont)
		if not cont then
			return
		end
		for _, t in ipairs(cont:GetChildren()) do
			if t:IsA("Tool") and t.Name == "Diamante" then
				table.insert(lista, t)
			end
		end
	end
	mira(player.Character)
	mira(player:FindFirstChildOfClass("Backpack"))
	return lista
end

local function estado(player)
	local nh, ns = nivelHacha(player), nivelSaco(player)
	return {
		hacha = nh,
		saco = ns,
		cap = CAP_SACO[ns],
		diamantes = #diamantesDe(player),
		costeHacha = COSTE_HACHA[nh], -- nil si ya es nivel máximo
		costeSaco = COSTE_SACO[ns],
	}
end

local function enviarEstado(player)
	pcall(function()
		RE:FireClient(player, "Estado", estado(player))
	end)
end

local function avisar(player, texto)
	pcall(function()
		RE:FireClient(player, "Aviso", texto)
	end)
end

local function comprar(player, que)
	asegurarAtributos(player)
	local lista = diamantesDe(player)
	if que == "Hacha" then
		local n = nivelHacha(player)
		if n >= 3 then
			avisar(player, "Tu hacha ya es del Archimago (nivel máximo)")
			return
		end
		local coste = COSTE_HACHA[n]
		if #lista < coste then
			avisar(player, "Te faltan diamantes: la mejora cuesta " .. coste .. " y llevas " .. #lista)
			return
		end
		for i = 1, coste do
			lista[i]:Destroy()
		end
		player:SetAttribute("NivelHacha", n + 1)
		avisar(player, "¡Hacha mejorada al nivel " .. (n + 1) .. "! Ahora hace " .. (n + 1) .. " de daño por golpe")
	elseif que == "Saco" then
		local n = nivelSaco(player)
		if n >= 3 then
			avisar(player, "Tu saco ya es el más grande (nivel máximo)")
			return
		end
		local coste = COSTE_SACO[n]
		if #lista < coste then
			avisar(player, "Te faltan diamantes: la mejora cuesta " .. coste .. " y llevas " .. #lista)
			return
		end
		for i = 1, coste do
			lista[i]:Destroy()
		end
		player:SetAttribute("NivelSaco", n + 1)
		player:SetAttribute("SacoMax", CAP_SACO[n + 1])
		avisar(player, "¡Saco mejorado! Ahora guarda hasta " .. CAP_SACO[n + 1] .. " cosas")
	else
		return
	end
	enviarEstado(player)
end

RE.OnServerEvent:Connect(function(player, accion, dato)
	if not player or not player.Parent then
		return
	end
	if accion == "Comprar" then
		comprar(player, dato)
	elseif accion == "Estado" then
		asegurarAtributos(player)
		enviarEstado(player)
	end
end)

for _, p in ipairs(Players:GetPlayers()) do
	asegurarAtributos(p)
end
Players.PlayerAdded:Connect(asegurarAtributos)

print("[Avada] MEJORAS listas: hacha y saco por niveles, con diamantes")
-- FIN SERVER MEJORAS
