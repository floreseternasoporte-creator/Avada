-- LocalScript CALDERO ANIM (pegar en StarterPlayer > StarterPlayerScripts)
-- La animacion del caldero del dueno: el liquido cambia de color, los
-- objetos flotan y las burbujas suben, todo en el cliente. Va en su
-- propio script para que el panel del caldero quede corto.

-- Animacion del caldero (la del dueno): liquido que cambia de color,
-- objetos flotando y burbujas que suben, todo en el cliente.
local ColeccionCal = game:GetService("CollectionService")
local RunCal = game:GetService("RunService")
local calItems = {}
local function registraCaldero(p)
  if not p:IsA("BasePart") then
    return
  end
  local base = p.CFrame -- la base es donde esta la pieza (vale tambien en mundos clonados)
  if not base then
    return
  end
  calItems[p] = {
    kind = p:GetAttribute("Kind"),
    base = base,
    size = p.Size,
    escala = p:GetAttribute("Scale") or 1,
    fase = p:GetAttribute("Phase") or 0,
    velocidad = p:GetAttribute("Speed") or 1,
    amplitud = p:GetAttribute("Amp") or 0.3,
    giro = p:GetAttribute("Spin") or 0,
    altura = p:GetAttribute("Height") or 10,
    colA = p:GetAttribute("ColorA"),
    colB = p:GetAttribute("ColorB"),
  }
end
for _, p in ipairs(ColeccionCal:GetTagged("CauldronAnim")) do
  registraCaldero(p)
end
ColeccionCal:GetInstanceAddedSignal("CauldronAnim"):Connect(function(p)
  task.defer(registraCaldero, p)
end)
ColeccionCal:GetInstanceRemovedSignal("CauldronAnim"):Connect(function(p)
  calItems[p] = nil
end)
RunCal.RenderStepped:Connect(function()
  local t = os.clock()
  for p, dd in pairs(calItems) do
    if not p.Parent then
      calItems[p] = nil
    else
      local kind = dd.kind
      if kind == "Liquid" then
        local a = (math.sin(t * 0.5) + 1) / 2
        if dd.colA and dd.colB then
          p.Color = dd.colA:Lerp(dd.colB, a)
        end
      elseif kind == "Overlay" then
        p.CFrame = dd.base + Vector3.new(math.cos(t * 0.35) * 3.2 * dd.escala, math.sin(t * 1.3) * 0.04 * dd.escala, math.sin(t * 0.5) * 3.2 * dd.escala)
        p.Transparency = 0.5 + math.sin(t * 0.8) * 0.12
      elseif kind == "Float" then
        local w = t * dd.velocidad + dd.fase
        local pos = dd.base.Position + Vector3.new(0, math.sin(w) * dd.amplitud, 0)
        p.CFrame = CFrame.new(pos) * CFrame.Angles(math.sin(w * 0.7) * 0.12, t * dd.giro + dd.fase, math.cos(w * 0.9) * 0.12)
      elseif kind == "Rise" then
        local u = (t * dd.velocidad + dd.fase) % 1
        local pos = dd.base.Position + Vector3.new(math.sin(u * math.pi * 4 + dd.fase * 6) * 0.9 * dd.escala, u * dd.altura, math.cos(u * math.pi * 3 + dd.fase * 6) * 0.9 * dd.escala)
        p.CFrame = CFrame.new(pos) * CFrame.Angles(t * dd.giro * 0.6, t * dd.giro, t * dd.giro * 0.4)
        p.Size = dd.size * (1 - 0.45 * u)
        local fadeIn = (u < 0.08) and (1 - u / 0.08) or 0
        local fadeOut = (u > 0.65) and ((u - 0.65) / 0.35) or 0
        p.Transparency = math.clamp(math.max(fadeIn, fadeOut), 0, 1)
      end
    end
  end
end)

-- FIN LOCAL CALDERO ANIM
