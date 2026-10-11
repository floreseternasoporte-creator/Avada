--[[
  🧪 POCIONES DEL CALDERO - SERVIDOR
  Pegar como "Script" en ServerScriptService.
  NO toca serverscript_partida.lua.

  El caldero es la estación de creación del juego. Este sistema:
  - Lee la reserva del equipo (hongos de partida + moras/diamantes propios).
  - Fabrica 3 pociones con validación en el servidor.
  - Las pociones se beben con el botón Comer (vía localscript_pociones.lua).
  - Si la mano y el saco están llenos al fabricar, NO consume ingredientes.

  NOTA HONESTA: el hambre (d.hambre) y la llama (SE.llama) viven dentro de
  partida y la regla dura prohíbe tocarlo. Por eso:
  - Vida: +60 de vida (directo, exacto).
  - Vigor: +80 de VIDA como "vigor" (el +80 de hambre exacto vive en partida).
  - Llama: erupción visual en la fogata + aura de fuego + 25 de vida
    (el +25 funcional a la llama vive en partida).
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local RE = RS:FindFirstChild("PocionesEvent")
if not RE then
  RE = Instance.new("RemoteEvent")
  RE.Name = "PocionesEvent"
  RE.Parent = RS
end

--// RESERVA DEL EQUIPO -------------------------------------------------------
-- Los hongos los guarda partida (SE.calderoHongos). Aquí llevo el libro mayor:
-- disponibles = reportados - gastados. Se auto-corrige si partida reinicia.
local RES = { Mora = 0, Diamante = 0 }
local hongosGastados = 0
local hongosReportados = 0

local function hongosDisp()
  return math.max(0, hongosReportados - hongosGastados)
end

--// RECETAS ------------------------------------------------------------------
local RECETAS = {
  Vida  = { hongo = 2, mora = 1, diamante = 0, titulo = "Poción de Vida",
            desc = "Cura 60 de vida", color = Color3.fromRGB(255, 90, 90) },
  Vigor = { hongo = 1, mora = 2, diamante = 0, titulo = "Poción de Vigor",
            desc = "+80 de vida (vigor)", color = Color3.fromRGB(90, 180, 255) },
  Llama = { hongo = 0, mora = 2, diamante = 1, titulo = "Poción de Llama",
            desc = "Erupción en la fogata", color = Color3.fromRGB(255, 160, 60) },
}

--// Saco virtual de pociones (cuando la mano está ocupada) --------------------
local sacoPoc = {}
local SACO_POC_MAX = 5

--// Posiciones ----------------------------------------------------------------
local function posCaldero()
  local cal = Workspace:FindFirstChild("Cauldron")
  if cal then
    local ancla = cal:FindFirstChild("CalderoAncla")
    if ancla and ancla:IsA("BasePart") then
      return ancla.Position
    end
    local ok, piv = pcall(function() return cal:GetPivot() end)
    if ok then
      return piv.Position
    end
  end
  return Vector3.new(-15.7, 2, 4207)
end

local function posFogata()
  for _, d in ipairs(Workspace:GetDescendants()) do
    if d:GetAttribute("Rol") == "FireAnchor" then
      return d.Position - Vector3.new(0, 11, 0)
    end
  end
  return Vector3.new(0, 2, 4200)
end

local function cercaCaldero(jugador)
  local ch = jugador.Character
  local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
  if not hrp then
    return false
  end
  return (hrp.Position - posCaldero()).Magnitude <= 18
end

--// Estado --------------------------------------------------------------------
local function estadoReserva()
  return { hongo = hongosDisp(), mora = RES.Mora, diamante = RES.Diamante }
end

local function puedeFabricar(id)
  local r = RECETAS[id]
  if not r then
    return false
  end
  return hongosDisp() >= r.hongo and RES.Mora >= r.mora and RES.Diamante >= r.diamante
end

local function difundir()
  local est = estadoReserva()
  for _, pl in ipairs(Players:GetPlayers()) do
    pcall(function()
      RE:FireClient(pl, "Reserva", est)
    end)
  end
end

local function avisar(jugador, texto)
  pcall(function()
    RE:FireClient(jugador, "Aviso", texto)
  end)
end

local function syncSaco(jugador)
  pcall(function()
    RE:FireClient(jugador, "SacoPoc", sacoPoc[jugador] or {})
  end)
end

--// Herramientas ----------------------------------------------------------------
local function buscarHerramienta(jugador, nombres)
  local set = {}
  for _, n in ipairs(nombres) do
    set[n:lower()] = true
  end
  local function esLa(t)
    return t:IsA("Tool") and set[t.Name:lower()] ~= nil
  end
  local bp = jugador:FindFirstChildOfClass("Backpack")
  if bp then
    for _, t in ipairs(bp:GetChildren()) do
      if esLa(t) then
        return t
      end
    end
  end
  local ch = jugador.Character
  if ch then
    for _, t in ipairs(ch:GetChildren()) do
      if esLa(t) then
        return t
      end
    end
  end
  return nil
end

local function pocionEquipada(jugador)
  local ch = jugador.Character
  if not ch then
    return nil
  end
  local t = ch:FindFirstChildOfClass("Tool")
  if t and t:GetAttribute("Pocion") then
    return t
  end
  return nil
end

local function manoOcupada(jugador)
  local ch = jugador.Character
  return ch and ch:FindFirstChildOfClass("Tool") ~= nil
end

local function crearPocion(id)
  local r = RECETAS[id]
  local tool = Instance.new("Tool")
  tool.Name = "Pocion" .. id
  tool:SetAttribute("Pocion", id)
  tool.ToolTip = r.titulo .. ": " .. r.desc .. " (se toma con Comer)"
  tool.CanBeDropped = false
  tool.RequiresHandle = true
  local h = Instance.new("Part")
  h.Name = "Handle"
  h.Size = Vector3.new(0.7, 1.1, 0.7)
  h.Color = r.color
  h.Material = Enum.Material.Neon
  h.CanCollide = false
  h.CanQuery = false
  h.Parent = tool
  local tapa = Instance.new("Part")
  tapa.Name = "Tapa"
  tapa.Size = Vector3.new(0.4, 0.3, 0.4)
  tapa.Color = Color3.fromRGB(70, 45, 25)
  tapa.Material = Enum.Material.Wood
  tapa.CanCollide = false
  tapa.CanQuery = false
  tapa.CFrame = h.CFrame * CFrame.new(0, 0.7, 0)
  tapa.Parent = tool
  local w = Instance.new("WeldConstraint")
  w.Part0 = h
  w.Part1 = tapa
  w.Parent = tapa
  local luz = Instance.new("PointLight")
  luz.Color = r.color
  luz.Range = 6
  luz.Brightness = 1
  luz.Shadows = false
  luz.Parent = h
  return tool
end

--// Erupción de la Llama (visual; lo funcional vive en partida) -----------------
local function erupcionLlama()
  local pos = posFogata()
  local ancla = Instance.new("Part")
  ancla.Name = "ErupcionPocion"
  ancla.Anchored = true
  ancla.CanCollide = false
  ancla.CanQuery = false
  ancla.CanTouch = false
  ancla.Transparency = 1
  ancla.Size = Vector3.new(1, 1, 1)
  ancla.CFrame = CFrame.new(pos)
  ancla.Parent = Workspace
  local att = Instance.new("Attachment")
  att.Parent = ancla
  local fuego = Instance.new("ParticleEmitter")
  fuego.Texture = "rbxasset://textures/particles/fire_main.dds"
  fuego.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 210, 130)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 20)),
  })
  fuego.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 3),
    NumberSequenceKeypoint.new(1, 0),
  })
  fuego.Lifetime = NumberRange.new(1, 2)
  fuego.Rate = 60
  fuego.Speed = NumberRange.new(10, 20)
  fuego.SpreadAngle = Vector2.new(30, 30)
  fuego.LightEmission = 1
  fuego.Parent = att
  local luz = Instance.new("PointLight")
  luz.Color = Color3.fromRGB(255, 150, 60)
  luz.Range = 30
  luz.Brightness = 3
  luz.Shadows = false
  luz.Parent = ancla
  Debris:AddItem(ancla, 45)
end

--// Efectos al beber --------------------------------------------------------------
local function efectoPocion(jugador, id)
  local ch = jugador.Character
  local hum = ch and ch:FindFirstChildOfClass("Humanoid")
  if not hum or hum.Health <= 0 then
    return false
  end
  if id == "Vida" then
    hum.Health = math.min(hum.MaxHealth, hum.Health + 60)
  elseif id == "Vigor" then
    -- El +80 de hambre vive en partida (regla dura: no tocarlo).
    -- Se entrega como +80 de vida (vigor).
    hum.Health = math.min(hum.MaxHealth, hum.Health + 80)
  elseif id == "Llama" then
    -- El +25 funcional a la llama vive en partida (regla dura: no tocarlo).
    -- Se entrega como erupción visual + aura + calor.
    erupcionLlama()
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if hrp then
      local f = Instance.new("Fire")
      f.Size = 4
      f.Heat = 6
      f.Color = Color3.fromRGB(255, 150, 60)
      f.SecondaryColor = Color3.fromRGB(255, 80, 20)
      f.Parent = hrp
      Debris:AddItem(f, 60)
    end
    hum.Health = math.min(hum.MaxHealth, hum.Health + 25)
  end
  return true
end

--// Acciones del cliente -------------------------------------------------------------
RE.OnServerEvent:Connect(function(jugador, accion, a)
  if not jugador or not jugador.Parent then
    return
  end

  if accion == "Hongos" then
    -- El cliente me pasa el calderoHongos que le manda partida.
    local n = tonumber(a) or 0
    if n < hongosGastados then
      hongosGastados = n -- partida reinició: me auto-corrigo
    end
    hongosReportados = n

  elseif accion == "DepositarTodo" then
    -- Echa TODAS las moras y diamantes de la mano/mochila (para el botón Soltar).
    if not cercaCaldero(jugador) then
      return
    end
    local nM, nD = 0, 0
    local function vaciar(nombres)
      local n = 0
      while true do
        local t = buscarHerramienta(jugador, nombres)
        if not t then break end
        t:Destroy()
        n += 1
      end
      return n
    end
    nM = vaciar({ "Mora" })
    nD = vaciar({ "Diamante", "Diamantes", "Diamond", "Diamonds", "Gema" })
    if nM > 0 then RES.Mora += nM end
    if nD > 0 then RES.Diamante += nD end
    if nM + nD > 0 then
      difundir()
      avisar(jugador, string.format("Guardado: %d mora(s), %d diamante(s)", nM, nD))
    end

  elseif accion == "Depositar" then
    -- Echa moras o diamantes de la mano/mochila a la reserva (junto al caldero).
    if not cercaCaldero(jugador) then
      avisar(jugador, "Acércate al caldero")
      return
    end
    local que = a == "Diamante" and "Diamante" or "Mora"
    local nombres = que == "Mora"
      and { "Mora" }
      or { "Diamante", "Diamantes", "Diamond", "Diamonds", "Gema" }
    local t = buscarHerramienta(jugador, nombres)
    if not t then
      avisar(jugador, "No llevas " .. (que == "Mora" and "moras" or "diamantes") .. " en la mano")
      return
    end
    t:Destroy()
    if que == "Mora" then
      RES.Mora += 1
    else
      RES.Diamante += 1
    end
    difundir()
    avisar(jugador, (que == "Mora" and "Mora" or "Diamante") .. " guardada en la reserva")

  elseif accion == "Fabricar" then
    local id = a
    local r = RECETAS[id]
    if not r then
      return
    end
    if not cercaCaldero(jugador) then
      avisar(jugador, "Acércate al caldero para fabricar")
      return
    end
    if not puedeFabricar(id) then
      avisar(jugador, "Te faltan ingredientes")
      difundir()
      return
    end
    -- ¿Cabe la poción? Si la mano y el saco están llenos, NO se consume nada.
    local ch = jugador.Character
    local ocupada = manoOcupada(jugador)
    local saco = sacoPoc[jugador]
    if ocupada and saco and #saco >= SACO_POC_MAX then
      avisar(jugador, "Mano y saco llenos: no se gastó nada")
      return
    end
    if not ocupada then
      local bp = jugador:FindFirstChildOfClass("Backpack")
      if not bp then
        avisar(jugador, "Espera un momento e inténtalo de nuevo")
        return
      end
    end
    -- Consumir (validado en el servidor)
    hongosGastados += r.hongo
    RES.Mora -= r.mora
    RES.Diamante -= r.diamante
    -- Entregar
    if not ocupada then
      local hum = ch and ch:FindFirstChildOfClass("Humanoid")
      local bp = jugador:FindFirstChildOfClass("Backpack")
      local tool = crearPocion(id)
      tool.Parent = bp
      if hum then
        pcall(function()
          hum:EquipTool(tool)
        end)
      end
      avisar(jugador, r.titulo .. " fabricada (en tu mano)")
    else
      if not saco then
        saco = {}
        sacoPoc[jugador] = saco
      end
      table.insert(saco, id)
      syncSaco(jugador)
      avisar(jugador, r.titulo .. " fabricada (en tu saco)")
    end
    difundir()

  elseif accion == "Beber" then
    -- Busca poción: equipada > saco virtual > mochila.
    local id = nil
    local t = pocionEquipada(jugador)
    if t then
      id = t:GetAttribute("Pocion")
      t:Destroy()
    else
      local saco = sacoPoc[jugador]
      if saco and #saco > 0 then
        id = table.remove(saco, 1)
        syncSaco(jugador)
      else
        local bp = jugador:FindFirstChildOfClass("Backpack")
        if bp then
          for _, tt in ipairs(bp:GetChildren()) do
            if tt:IsA("Tool") and tt:GetAttribute("Pocion") then
              id = tt:GetAttribute("Pocion")
              tt:Destroy()
              break
            end
          end
        end
      end
    end
    if id and RECETAS[id] and efectoPocion(jugador, id) then
      avisar(jugador, RECETAS[id].titulo .. " tomada: " .. RECETAS[id].desc)
    end
  end
end)

Players.PlayerRemoving:Connect(function(pl)
  sacoPoc[pl] = nil
end)

-- Reserva inicial para los que ya están
task.delay(3, difundir)

print("[Avada] Pociones del caldero listas")
-- FIN POCIONES
