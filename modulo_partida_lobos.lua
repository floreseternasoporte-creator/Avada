-- PartidaLobos: ModuleScript en ServerScriptService (lobos sombrios de la partida).
-- Fabrica por sesion: crear(E, SE, ctx, W, M).
local function crear(E, SE, ctx, W, M)
-- LOBOS SOMBRÍOS (los enemigos de la noche: el lobo del dueno del
-- juego, archivo LOBOS; PARTIDA solo lo invoca al caer la noche y
-- vigila las reglas del bosque: el fuego quema y el amanecer borra)
--===========================================================
local function llamarEsencias(player, cantidad)
  local bf = game:GetService("ServerScriptService"):FindFirstChild("AvadaEsencias")
  if bf then
    pcall(function()
      bf:Invoke("sumar", player, cantidad)
    end)
  end
end

local function llamarLobos(accion, a, b)
  local bf = game:GetService("ServerScriptService"):FindFirstChild("AvadaLobos")
  if not bf then
    return nil
  end
  local ok, res = pcall(function()
    return bf:Invoke(accion, a, b)
  end)
  if ok then
    return res
  end
  warn("[Avada] El Script LOBOS respondio con error: " .. tostring(res))
  return nil
end

local function quitarLoboDeLaLista(som)
  for i, s2 in ipairs(SE.sombras) do
    if s2 == som then
      table.remove(SE.sombras, i)
      break
    end
  end
end

local function loboCayo(som)
  quitarLoboDeLaLista(som)
  if som.ultimoGolpe then
    E.bajaKill(som.ultimoGolpe)
  end
  if som.guardian and som.jaula then
    local quedan = false
    for _, s2 in ipairs(SE.sombras) do
      if s2.guardian and s2.jaula == som.jaula then
        quedan = true
        break
      end
    end
    if not quedan then
      local j = W.jaulas[som.jaula]
      if j and not j.libre then
        j.libre = true
        for _, bar in ipairs(j.barrotes) do
          bar.Transparency = 0.75
          bar.CanCollide = false
        end
        if j.label then j.label.Text = "Jaula abierta: toca al aprendiz" end
      end
    end
  end
end

local function crearLoboPartida(pos, tipo, jaulaIdx)
  local opts = nil
  if tipo == "grande" then
    opts = { escala = 1.5, vida = 100000, dano = 26 }
  end
  local modelo = llamarLobos("crear", pos, opts)
  if not modelo then
    SE.lobosFaltan = true
    if not SE.loboAvisoDado then
      SE.loboAvisoDado = true
      warn("[Avada] LOS LOBOS NO SALEN: falta el Script LOBOS completo en ServerScriptService (su ultima linea dice -- FIN LOBOS)")
    end
    return nil
  end
  SE.lobosFaltan = false
  local som = {
    model = modelo,
    root = modelo:FindFirstChild("HumanoidRootPart"),
    hum = modelo:FindFirstChildOfClass("Humanoid"),
    tipo = tipo or "normal",
    guardian = jaulaIdx ~= nil,
    jaula = jaulaIdx,
    ultimoGolpe = nil,
  }
  table.insert(SE.sombras, som)
  if som.hum then
    som.hum.Died:Connect(function()
      loboCayo(som)
    end)
  end
  return som
end

local function danarLobo(som, dmg, de, player)
  if player then
    som.ultimoGolpe = player
  end
  if som.tipo == "grande" and som.root then
    -- EL GRANDE no cae con hechizos: se clava en el sitio un momento
    som.root.Anchored = true
    task.delay(1.2, function()
      if som.root and som.root.Parent then
        som.root.Anchored = false
      end
    end)
  end
  if som.hum then
    pcall(function()
      som.hum:TakeDamage(dmg)
    end)
  end
end

local function destruirLobos(soloNocturnos)
  llamarLobos("sinReaparicion")
  for i = #SE.sombras, 1, -1 do
    local som = SE.sombras[i]
    if (not soloNocturnos) or (not som.guardian and som.tipo ~= "bosque") then
      if som.model then
        som.model:Destroy()
      end
      table.remove(SE.sombras, i)
    end
  end
end

-- Hechizos contra los lobos (sin duelo: golpea al mas cercano)
local function golpeSombra(caster, spellName)
  if not E.jugadorEnPartida(SE, caster) then
    return false
  end
  if not SE.players[caster].vivo then
    return true
  end
  local dmgBase = E.danoHechizo(spellName)
  if not dmgBase then
    return true
  end
  local char = caster.Character
  if not char then
    return true
  end
  local wand = char:FindFirstChild("Varita Magica")
  if wand then
    wand:SetAttribute("CastSpell", spellName)
    wand:SetAttribute("Casting", true)
    task.delay(0.5, function()
      if wand and wand.Parent then
        wand:SetAttribute("Casting", false)
      end
    end)
  end
  local now = os.clock()
  if SE.castCd[caster] and now - SE.castCd[caster] < 0.5 then
    return true
  end
  SE.castCd[caster] = now
  local hrp = char:FindFirstChild("HumanoidRootPart")
  if not hrp then
    return true
  end
  local best, bestD
  for _, som in ipairs(SE.sombras) do
    if som.root and som.root.Parent then
      local d = (som.root.Position - hrp.Position).Magnitude
      if d <= 34 and (not bestD or d < bestD) then
        best, bestD = som, d
      end
    end
  end
  if best then
    local dmg = dmgBase or 40
    if spellName ~= "AvadaKedavra" then
      dmg = math.floor(dmg * 1.4)
    end
    danarLobo(best, dmg, hrp.Position, caster)
  end
  return true
end

--===========================================================
--===========================================================
  return {
    crearLoboPartida = crearLoboPartida,
    destruirLobos = destruirLobos,
    llamarLobos = llamarLobos,
    llamarEsencias = llamarEsencias,
    golpeSombra = golpeSombra,
  }
end
return crear
-- FIN MODULO PARTIDA LOBOS
