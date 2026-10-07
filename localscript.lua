--===========================================================
-- ⚡ HARRY POTTER DUELING GAME - LOCAL SCRIPT v12.0 ⚡
-- Coloca en: StarterPlayerScripts > LocalScript
--===========================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Camera = workspace.CurrentCamera
local Remotes = ReplicatedStorage:WaitForChild("DuelRemotes", 30)
if not Remotes then error("DuelRemotes not found") end
local RE_BattleStart = Remotes:WaitForChild("BattleStart")
local RE_BattleEnd = Remotes:WaitForChild("BattleEnd")
local RE_CastSpell = Remotes:WaitForChild("CastSpell")
local RE_Countdown = Remotes:WaitForChild("Countdown")
local RE_RoundUpdate = Remotes:WaitForChild("RoundUpdate")
local RE_SpellEffect = Remotes:WaitForChild("SpellEffect")
local RE_ClashUpdate = Remotes:WaitForChild("ClashUpdate")
--===========================================================
-- SPELL DEFINITIONS
--===========================================================
local SPELLS = {
{
name = "Expelliarmus",
label = "EXPELLIARMUS",
cmd = "/expelliarmus",
key = "Q", keyCode = Enum.KeyCode.Q,
cd = 3.0,
color = Color3.fromRGB(255, 55, 55),
glow = Color3.fromRGB(255, 80, 80),
bgCol = Color3.fromRGB(40, 5, 5),
desc = "Hechizo Desarmador — Proyectil rojo veloz que desestabiliza al rival",
power = "⭐⭐",
animType = "flick",
},
{
name = "Stupefy",
label = "STUPEFY",
cmd = "/stupefy",
key = "E", keyCode = Enum.KeyCode.E,
cd = 4.0,
color = Color3.fromRGB(255, 75, 20),
glow = Color3.fromRGB(255, 110, 40),
bgCol = Color3.fromRGB(40, 10, 2),
desc = "Hechizo Aturdidor — Bola de energía ardiente que aplasta al oponente",
power = "⭐⭐⭐",
animType = "thrust",
},
{
name = "Reducto",
label = "REDUCTO",
cmd = "/reducto",
key = "R", keyCode = Enum.KeyCode.R,
cd = 7.0,
color = Color3.fromRGB(155, 20, 255),
glow = Color3.fromRGB(185, 45, 255),
bgCol = Color3.fromRGB(18, 3, 38),
desc = "Hechizo Reductor — Explosión violeta que destruye todo a su paso",
power = "⭐⭐⭐⭐",
animType = "sweep",
},
{
name = "Sectumsempra",
label = "SECTUMSEMPRA",
cmd = "/sectumsempra",
key = "F", keyCode = Enum.KeyCode.F,
cd = 9.0,
color = Color3.fromRGB(210, 0, 28),
glow = Color3.fromRGB(235, 15, 45),
bgCol = Color3.fromRGB(30, 0, 5),
desc = "Maldición Oscura — Cuchilla de energía que inflige daño masivo",
power = "⭐⭐⭐⭐",
animType = "slash",
},
{
name = "Crucio",
label = "CRUCIO",
cmd = "/crucio",
key = "G", keyCode = Enum.KeyCode.G,
cd = 12.0,
color = Color3.fromRGB(230, 215, 0),
glow = Color3.fromRGB(255, 245, 20),
bgCol = Color3.fromRGB(35, 33, 0),
desc = "Maldición Imperdonable — Tormento que paraliza de dolor al rival",
power = "⭐⭐⭐",
animType = "twist",
},
{
name = "Incendio",
label = "INCENDIO",
cmd = "/incendio",
key = "H", keyCode = Enum.KeyCode.H,
cd = 8.0,
color = Color3.fromRGB(255, 95, 0),
glow = Color3.fromRGB(255, 140, 30),
bgCol = Color3.fromRGB(40, 13, 0),
desc = "Conjuración de Fuego — Bola de llamas que envuelve al enemigo",
power = "⭐⭐⭐",
animType = "push",
},
{
name = "AvadaKedavra",
label = "AVADA KEDAVRA",
cmd = "/avada",
key = "T", keyCode = Enum.KeyCode.T,
cd = 30.0,
color = Color3.fromRGB(0, 205, 18),
glow = Color3.fromRGB(0, 255, 40),
bgCol = Color3.fromRGB(0, 14, 2),
desc = "Maldición de la Muerte — El hechizo más temible. No falla. Recarga larga.",
power = "☠☠☠☠☠",
animType = "avada",
},
}
local WAND_NAME = "Varita Magica"
local isInDuel = false
local duelSessionActive = false
local spellOnCD = {}
local BOOK_CAST_ENABLED = false
--===========================================================
-- UI HELPERS
--===========================================================
local oldGui = PlayerGui:FindFirstChild("DuelUI")
if oldGui then oldGui:Destroy() end
local sg = Instance.new("ScreenGui")
sg.Name = "DuelUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.Parent = PlayerGui
local function tw(obj, props, t, sty, dir)
    return TweenService:Create(obj, TweenInfo.new(t or 0.3, sty or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end
local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(r or 0.1, 0)
    c.Parent = p
end
local function stroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col
    s.Thickness = th or 2
    s.Parent = p
    return s
end
local function grad(p, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent = p
    return g
end
local function mF(parent, size, pos, bg, alpha, zi)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = bg or Color3.new(0,0,0)
    f.BackgroundTransparency = alpha or 0
    f.BorderSizePixel = 0
    f.ZIndex = zi or 10
    f.Parent = parent
    return f
end
local function mL(parent, text, size, pos, col, font, zi, scaled)
    local l = Instance.new("TextLabel")
    l.Size = size
    l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = col or Color3.new(1,1,1)
    l.Font = font or Enum.Font.GothamBold
    l.TextScaled = (scaled ~= false)
    l.BorderSizePixel = 0
    l.ZIndex = zi or 10
    l.Parent = parent
    return l
end
--===========================================================
-- BLACK SCREEN
--===========================================================
local blackScreen = mF(sg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.new(0,0,0), 1, 80)
local function fadeBlack(target, t)
    local twn = tw(blackScreen, {BackgroundTransparency = target}, t or 0.5, Enum.EasingStyle.Linear)
    twn:Play()
    twn.Completed:Wait()
end
--===========================================================
-- CAMERA SHAKE
--===========================================================
local shakeActive = false
local shakeMag = 0
local shakeDur = 0
local function cameraShake(magnitude, duration)
    shakeMag = magnitude
    shakeDur = duration
    if shakeActive then return end
    shakeActive = true
    task.spawn(function()
        local startT = tick()
        while tick() - startT < shakeDur do
            local t = tick() - startT
            local fade = 1 - (t / shakeDur)
            local m = shakeMag * fade
            local ox = (math.random() * 2 - 1) * m
            local oy = (math.random() * 2 - 1) * m
            Camera.CFrame = Camera.CFrame * CFrame.new(ox, oy, 0)
            task.wait()
        end
        shakeActive = false
    end)
end
--===========================================================
-- SCREEN FLASH
--===========================================================
local function screenFlash(col, alpha, dur, extra)
    local fl = mF(sg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), col, alpha, 78)
    tw(fl, {BackgroundTransparency = 1}, dur):Play()
    task.delay(dur + 0.05, function()
        if fl.Parent then fl:Destroy() end
    end)
    if extra == "vignette" then
        local vi = mF(sg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), col, 1, 77)
        local ig = Instance.new("UIGradient")
        ig.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, col),
        ColorSequenceKeypoint.new(0.4, Color3.new(0,0,0)),
        ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
        }
        ig.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 1),
        }
        ig.Parent = vi
        tw(vi, {BackgroundTransparency = 1}, dur * 1.5):Play()
        task.delay(dur * 1.5 + 0.1, function()
            if vi.Parent then vi:Destroy() end
        end)
    end
end
--===========================================================
-- SPELL FX CLIENT
--===========================================================
local function screenFX(spellName, isVictim)
    if spellName == "AvadaKill_victim" then
        screenFlash(Color3.fromRGB(0,220,40), 0.08, 1.45, "vignette")
        cameraShake(0.85, 1.9)
        task.spawn(function()
            for _ = 1, 7 do
                screenFlash(Color3.fromRGB(20,255,80), 0.2, 0.16)
                task.wait(0.17)
            end
        end)
    elseif spellName == "AvadaKill_cast" then
        screenFlash(Color3.fromRGB(80,255,120), 0.42, 0.75)
        cameraShake(0.26, 0.8)
    elseif spellName == "Expelliarmus_hit" then
        screenFlash(Color3.fromRGB(255,50,50), isVictim and 0.55 or 0.25, isVictim and 0.6 or 0.3)
        if isVictim then cameraShake(0.3, 0.7) end
    elseif spellName == "Stupefy_hit" then
        screenFlash(Color3.fromRGB(255,80,30), isVictim and 0.65 or 0.28, isVictim and 0.65 or 0.3)
        if isVictim then cameraShake(0.35, 0.8) end
    elseif spellName == "Reducto_hit" then
        screenFlash(Color3.fromRGB(160,20,255), isVictim and 0.6 or 0.25, isVictim and 0.7 or 0.3)
        if isVictim then cameraShake(0.4, 0.9) end
    elseif spellName == "Sectumsempra_hit" then
        screenFlash(Color3.fromRGB(220,0,30), isVictim and 0.7 or 0.3, isVictim and 0.75 or 0.3)
        if isVictim then cameraShake(0.45, 1.0) end
    elseif spellName == "Crucio_hit" then
        screenFlash(Color3.fromRGB(230,215,0), isVictim and 0.65 or 0.3, isVictim and 0.9 or 0.3)
        if isVictim then cameraShake(0.25, 2.2) end
    elseif spellName == "Incendio_hit" then
        screenFlash(Color3.fromRGB(255,100,0), isVictim and 0.65 or 0.3, isVictim and 0.8 or 0.3)
        if isVictim then cameraShake(0.3, 0.8) end
    elseif spellName == "ClashStart" then
        screenFlash(Color3.fromRGB(120,255,120), 0.4, 0.5)
        cameraShake(0.2, 4.0)
    elseif spellName == "ClashEnd" then
        screenFlash(Color3.fromRGB(255,255,255), isVictim and 0.5 or 0.65, isVictim and 0.5 or 0.4)
        cameraShake(isVictim and 0.5 or 0.6, isVictim and 0.8 or 1.0)
    end
end
--===========================================================
-- WAND ANIMATION
--===========================================================
local function getMotors(char)
    if not char then return nil, nil end
    local ut = char:FindFirstChild("UpperTorso")
    if ut then
        return ut:FindFirstChild("RightShoulder"), char:FindFirstChild("RightUpperArm") and char.RightUpperArm:FindFirstChild("RightElbow")
    end
    local torso = char:FindFirstChild("Torso")
    if torso then return torso:FindFirstChild("Right Shoulder"), nil end
    return nil, nil
end
local function animateWand(animType)
    local char = LocalPlayer.Character
    if not char then return end
    local shoulder, elbow = getMotors(char)
    if not shoulder then return end
    local keyframes = {}
    if animType == "flick" then
        keyframes = {
        {t = 0.0, sh = CFrame.Angles(math.rad(-55), math.rad(12), math.rad(14))},
        {t = 0.1, sh = CFrame.Angles(math.rad(-10), math.rad(18), math.rad(-5))},
        {t = 0.25, sh = CFrame.Angles(0,0,0)},
        }
    elseif animType == "thrust" then
        keyframes = {
        {t = 0.0, sh = CFrame.Angles(math.rad(-70), 0, math.rad(10))},
        {t = 0.08, sh = CFrame.Angles(math.rad(-80), 0, math.rad(8))},
        {t = 0.18, sh = CFrame.Angles(math.rad(-15), math.rad(5), 0)},
        {t = 0.32, sh = CFrame.Angles(0,0,0)},
        }
    elseif animType == "sweep" then
        keyframes = {
        {t = 0.0, sh = CFrame.Angles(math.rad(-30), math.rad(-25), math.rad(-18))},
        {t = 0.10, sh = CFrame.Angles(math.rad(-60), math.rad(5), math.rad(20))},
        {t = 0.20, sh = CFrame.Angles(math.rad(-65), math.rad(15), math.rad(8))},
        {t = 0.35, sh = CFrame.Angles(0,0,0)},
        }
    elseif animType == "slash" then
        keyframes = {
        {t = 0.0, sh = CFrame.Angles(math.rad(-20), math.rad(-20), math.rad(-25))},
        {t = 0.08, sh = CFrame.Angles(math.rad(-75), math.rad(20), math.rad(20))},
        {t = 0.16, sh = CFrame.Angles(math.rad(-10), math.rad(5), math.rad(-10))},
        {t = 0.30, sh = CFrame.Angles(0,0,0)},
        }
    elseif animType == "twist" then
        keyframes = {
        {t = 0.0, sh = CFrame.Angles(math.rad(-40), math.rad(-8), math.rad(-12))},
        {t = 0.12, sh = CFrame.Angles(math.rad(-50), math.rad(15), math.rad(18))},
        {t = 0.22, sh = CFrame.Angles(math.rad(-30), math.rad(-10), math.rad(8))},
        {t = 0.38, sh = CFrame.Angles(0,0,0)},
        }
    elseif animType == "push" then
        keyframes = {
        {t = 0.0, sh = CFrame.Angles(math.rad(-50), math.rad(10), math.rad(10))},
        {t = 0.12, sh = CFrame.Angles(math.rad(-80), math.rad(18), math.rad(5))},
        {t = 0.25, sh = CFrame.Angles(math.rad(-20), math.rad(5), 0)},
        {t = 0.40, sh = CFrame.Angles(0,0,0)},
        }
    elseif animType == "avada" then
        keyframes = {
        {t = 0.0, sh = CFrame.Angles(math.rad(-20), math.rad(-15), math.rad(-15))},
        {t = 0.08, sh = CFrame.Angles(math.rad(-35), math.rad(-10), math.rad(-8))},
        {t = 0.16, sh = CFrame.Angles(math.rad(-85), math.rad(20), math.rad(18))},
        {t = 0.28, sh = CFrame.Angles(math.rad(-20), math.rad(5), math.rad(-5))},
        {t = 0.44, sh = CFrame.Angles(0,0,0)},
        }
    end
    for _, kf in ipairs(keyframes) do
        task.delay(kf.t, function()
            if shoulder and shoulder.Parent then
                shoulder.Transform = kf.sh
            end
        end)
    end
end
--===========================================================
-- DECLARATIONS
--===========================================================
local bookOpen = false
local spellEntries = {}
local openBook
local closeBook
local toggleBook
local updateSpellCooldown
local castSpell
--===========================================================
-- SPELLBOOK UI
--===========================================================
local bookTriggerWrap = mF(
sg,
UDim2.new(0, 56, 0, 56),
UDim2.new(1, -92, 0.70, 0),
Color3.fromRGB(18, 5, 2),
0,
25
)
bookTriggerWrap.Visible = false
corner(bookTriggerWrap, 0.2)
stroke(bookTriggerWrap, Color3.fromRGB(180, 100, 20), 2.5)
grad(bookTriggerWrap, Color3.fromRGB(40, 12, 5), Color3.fromRGB(15, 4, 2))
local bookTriggerIcon = mL(bookTriggerWrap, "📖", UDim2.new(1,0,0.55,0), UDim2.new(0,0,0,0), Color3.fromRGB(255,200,80), Enum.Font.GothamBold, 26)
local bookTriggerTxt = mL(bookTriggerWrap, "[B]", UDim2.new(1,0,0.38,0), UDim2.new(0,0,0.62,0), Color3.fromRGB(200,160,60), Enum.Font.GothamBold, 26)
local bookOverlay = mF(sg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.new(0,0,0), 0.55, 28)
bookOverlay.Visible = false
bookOverlay.Active = false
local bookFrame = mF(sg, UDim2.new(0,560,0,390), UDim2.new(0.5,-280,0.5,-195), Color3.fromRGB(70,15,8), 0, 30)
bookFrame.Visible = false
corner(bookFrame, 0.04)
stroke(bookFrame, Color3.fromRGB(200,140,40), 3.5)
grad(bookFrame, Color3.fromRGB(80,20,8), Color3.fromRGB(50,10,5), 0)
local topBar = mF(bookFrame, UDim2.new(1,0,0,8), UDim2.new(0,0,0,0), Color3.fromRGB(200,155,40), 0, 31)
local botBar = mF(bookFrame, UDim2.new(1,0,0,8), UDim2.new(0,0,1,-8), Color3.fromRGB(200,155,40), 0, 31)
local spine = mF(bookFrame, UDim2.new(0,16,1,0), UDim2.new(0.5,-8,0,0), Color3.fromRGB(50,12,5), 0, 31)
stroke(spine, Color3.fromRGB(180,120,30), 1.5)
grad(spine, Color3.fromRGB(55,15,8), Color3.fromRGB(30,8,3), 0)
local leftPage = mF(bookFrame, UDim2.new(0.5,-10,1,-16), UDim2.new(0,8,0,8), Color3.fromRGB(242,220,158), 0, 31)
corner(leftPage, 0.02)
grad(leftPage, Color3.fromRGB(248,228,168), Color3.fromRGB(235,212,148), 135)
local leftVig = mF(leftPage, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(180,140,80), 0.75, 32)
corner(leftVig, 0.02)
local lvg = Instance.new("UIGradient")
lvg.Transparency = NumberSequence.new{
NumberSequenceKeypoint.new(0,0),
NumberSequenceKeypoint.new(0.12,0.85),
NumberSequenceKeypoint.new(0.88,0.85),
NumberSequenceKeypoint.new(1,0)
}
lvg.Parent = leftVig
local lTitle = Instance.new("TextLabel")
lTitle.Size = UDim2.new(0.85,0,0.1,0)
lTitle.Position = UDim2.new(0.075,0,0.05,0)
lTitle.BackgroundTransparency = 1
lTitle.Text = "Libro de Hechizos"
lTitle.TextScaled = true
lTitle.Font = Enum.Font.Antique
lTitle.TextColor3 = Color3.fromRGB(55,25,8)
lTitle.TextStrokeColor3 = Color3.fromRGB(120,80,30)
lTitle.TextStrokeTransparency = 0.5
lTitle.ZIndex = 33
lTitle.Parent = leftPage
local ltDiv = mF(leftPage, UDim2.new(0.75,0,0,2), UDim2.new(0.125,0,0.17,0), Color3.fromRGB(130,80,20), 0, 33)
grad(ltDiv, Color3.fromRGB(200,155,40), Color3.fromRGB(180,120,25))
local circleArea = mF(leftPage, UDim2.new(0.7,0,0.44,0), UDim2.new(0.15,0,0.2,0), Color3.new(0,0,0), 1, 32)
local function makeCircle(parent, size, pos, col, zi, thick)
    local c = Instance.new("Frame")
    c.Size = size
    c.Position = pos
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    c.ZIndex = zi or 33
    c.Parent = parent
    stroke(c, col, thick or 1.5)
    Instance.new("UICorner", c).CornerRadius = UDim.new(1,0)
    return c
end
makeCircle(circleArea, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(100,60,15), 34, 1.8)
makeCircle(circleArea, UDim2.new(0.7,0,0.7,0), UDim2.new(0.15,0,0.15,0), Color3.fromRGB(100,60,15), 34, 1.4)
makeCircle(circleArea, UDim2.new(0.38,0,0.38,0), UDim2.new(0.31,0,0.31,0), Color3.fromRGB(100,60,15), 34, 1.2)
local function makeStar(parent, zi)
    local function line(angle)
        local l = mF(parent, UDim2.new(0.48,0,0,1.5), UDim2.new(0.26,0,0.499,0), Color3.fromRGB(90,55,12), 0, zi)
        l.Rotation = angle
        return l
    end
    for i = 0, 4 do
        line(i * 36)
    end
end
makeStar(circleArea, 35)
local runeSymbols = {"᚛","᚜","ᚁ","ᚂ","ᚃ","ᚄ"}
for i, sym in ipairs(runeSymbols) do
    local angle = (i - 1) * (360 / #runeSymbols) * (math.pi / 180)
    local rx = 0.5 + math.cos(angle) * 0.44
    local ry = 0.5 + math.sin(angle) * 0.44
    local rl = Instance.new("TextLabel")
    rl.Size = UDim2.new(0.08,0,0.12,0)
    rl.Position = UDim2.new(rx - 0.04,0,ry - 0.06,0)
    rl.BackgroundTransparency = 1
    rl.Text = sym
    rl.TextScaled = true
    rl.Font = Enum.Font.Antique
    rl.TextColor3 = Color3.fromRGB(80,45,10)
    rl.ZIndex = 35
    rl.Parent = circleArea
end
local lInstr = Instance.new("TextLabel")
lInstr.Size = UDim2.new(0.85,0,0.08,0)
lInstr.Position = UDim2.new(0.075,0,0.68,0)
lInstr.BackgroundTransparency = 1
lInstr.Text = "Toca un hechizo para lanzarlo"
lInstr.TextScaled = true
lInstr.Font = Enum.Font.Antique
lInstr.TextColor3 = Color3.fromRGB(70,35,10)
lInstr.ZIndex = 33
lInstr.Parent = leftPage
local lInstr2 = Instance.new("TextLabel")
lInstr2.Size = UDim2.new(0.85,0,0.06,0)
lInstr2.Position = UDim2.new(0.075,0,0.78,0)
lInstr2.BackgroundTransparency = 1
lInstr2.Text = "o usa las teclas Q E R F G H T"
lInstr2.TextScaled = true
lInstr2.Font = Enum.Font.Antique
lInstr2.TextColor3 = Color3.fromRGB(90,50,15)
lInstr2.ZIndex = 33
lInstr2.Parent = leftPage
local ldDiv2 = mF(leftPage, UDim2.new(0.75,0,0,2), UDim2.new(0.125,0,0.66,0), Color3.fromRGB(130,80,20), 0, 33)
grad(ldDiv2, Color3.fromRGB(200,155,40), Color3.fromRGB(180,120,25))
local ldDiv3 = mF(leftPage, UDim2.new(0.75,0,0,2), UDim2.new(0.125,0,0.86,0), Color3.fromRGB(130,80,20), 0, 33)
grad(ldDiv3, Color3.fromRGB(200,155,40), Color3.fromRGB(180,120,25))
local rightPage = mF(bookFrame, UDim2.new(0.5,-10,1,-16), UDim2.new(0.5,2,0,8), Color3.fromRGB(240,218,152), 0, 31)
corner(rightPage, 0.02)
grad(rightPage, Color3.fromRGB(246,224,162), Color3.fromRGB(233,210,142), 135)
local rightVig = mF(rightPage, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(175,135,75), 0.75, 32)
corner(rightVig, 0.02)
local rvg = Instance.new("UIGradient")
rvg.Transparency = NumberSequence.new{
NumberSequenceKeypoint.new(0,0),
NumberSequenceKeypoint.new(0.1,0.88),
NumberSequenceKeypoint.new(0.9,0.88),
NumberSequenceKeypoint.new(1,0)
}
rvg.Parent = rightVig
local rHeader = Instance.new("TextLabel")
rHeader.Size = UDim2.new(0.85,0,0.07,0)
rHeader.Position = UDim2.new(0.075,0,0.015,0)
rHeader.BackgroundTransparency = 1
rHeader.Text = "Hechizos Disponibles"
rHeader.TextScaled = true
rHeader.Font = Enum.Font.Antique
rHeader.TextColor3 = Color3.fromRGB(55,25,8)
rHeader.TextStrokeColor3 = Color3.fromRGB(120,80,30)
rHeader.TextStrokeTransparency = 0.5
rHeader.ZIndex = 33
rHeader.Parent = rightPage
local rhDiv = mF(rightPage, UDim2.new(0.85,0,0,2), UDim2.new(0.075,0,0.085,0), Color3.fromRGB(130,80,20), 0, 33)
grad(rhDiv, Color3.fromRGB(200,155,40), Color3.fromRGB(180,120,25))
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(0.92,0,0.87,0)
scrollFrame.Position = UDim2.new(0.04,0,0.1,0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(130,80,20)
scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ZIndex = 33
scrollFrame.Parent = rightPage
local spellListLayout = Instance.new("UIListLayout")
spellListLayout.Padding = UDim.new(0,5)
spellListLayout.FillDirection = Enum.FillDirection.Vertical
spellListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
spellListLayout.Parent = scrollFrame
local function updateSpellCooldown(spellName, cd)
    local entry = spellEntries[spellName]
    if not entry then return end
    entry.cdOverlay.Visible = true
    entry.cdBarFill.Size = UDim2.new(1,0,1,0)
    local endT = tick() + cd
    task.spawn(function()
        while spellOnCD[spellName] do
            local remaining = endT - tick()
            local pct = math.clamp(remaining / cd, 0, 1)
            entry.cdOvLabel.Text = string.format("%.1fs", math.max(0, remaining))
            tw(entry.cdBarFill, {Size = UDim2.new(pct,0,1,0)}, 0.12):Play()
            task.wait(0.1)
        end
        entry.cdOverlay.Visible = false
        entry.cdBarFill.Size = UDim2.new(0,0,1,0)
    end)
end
local function closeBook()
    if not bookOpen then return end
    bookOpen = false
    tw(leftPage, {BackgroundTransparency = 1}, 0.12):Play()
    tw(rightPage, {BackgroundTransparency = 1}, 0.12):Play()
    task.wait(0.08)
    tw(bookFrame, {
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(1, -92, 0.70, 0),
    }, 0.24, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
    tw(bookOverlay, {BackgroundTransparency = 1}, 0.24):Play()
    task.wait(0.25)
    bookFrame.Visible = false
    bookOverlay.Visible = false
end
local function openBook()
    if bookOpen then return end
    bookOpen = true
    bookOverlay.Visible = true
    bookOverlay.BackgroundTransparency = 0.55
    bookFrame.Visible = true
    bookFrame.Size = UDim2.new(0, 50, 0, 50)
    bookFrame.Position = UDim2.new(1, -92, 0.70, 0)
    leftPage.Visible = false
    rightPage.Visible = false
    spine.Visible = false
    topBar.Visible = false
    botBar.Visible = false
    tw(bookOverlay, {BackgroundTransparency = 0.3}, 0.12):Play()
    tw(bookFrame, {
    Size = UDim2.new(0,560,0,390),
    Position = UDim2.new(0.5,-280,0.5,-195),
    }, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    task.wait(0.18)
    topBar.Visible = true
    botBar.Visible = true
    spine.Visible = true
    leftPage.Visible = true
    leftPage.BackgroundTransparency = 1
    rightPage.Visible = true
    rightPage.BackgroundTransparency = 1
    tw(leftPage, {BackgroundTransparency = 0}, 0.2):Play()
    task.wait(0.06)
    tw(rightPage, {BackgroundTransparency = 0}, 0.2):Play()
end
local function toggleBook()
    if bookOpen then
        closeBook()
    else
        openBook()
    end
end
local function castSpell(spellName)
    if not isInDuel then return end
    if spellOnCD[spellName] then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local sp
    for _, s in ipairs(SPELLS) do
        if s.name == spellName then
            sp = s
            break
        end
    end
    if not sp then return end
    animateWand(sp.animType)
    spellOnCD[spellName] = true
    RE_CastSpell:FireServer(spellName)
    updateSpellCooldown(spellName, sp.cd)
    task.spawn(function()
        local endT = tick() + sp.cd
        while tick() < endT do
            task.wait(0.1)
        end
        spellOnCD[spellName] = nil
    end)
end
local function makeSpellEntry(sp)
    local entry = Instance.new("TextButton")
    entry.Size = UDim2.new(0.97,0,0,54)
    entry.BackgroundColor3 = sp.bgCol
    entry.BackgroundTransparency = 0.08
    entry.BorderSizePixel = 0
    entry.Text = ""
    entry.AutoButtonColor = false
    entry.ZIndex = 34
    entry.Parent = scrollFrame
    corner(entry, 0.12)
    stroke(entry, Color3.fromRGB(130,80,20), 1.2)
    local accentBar = mF(entry, UDim2.new(0,5,0.72,0), UDim2.new(0,6,0.14,0), sp.color, 0, 35)
    corner(accentBar, 1)
    local accentGlow = mF(entry, UDim2.new(0,18,1,0), UDim2.new(0,0,0,0), sp.color, 0.85, 34)
    local ag = Instance.new("UIGradient")
    ag.Color = ColorSequence.new(sp.color, Color3.new(0,0,0))
    ag.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0,0.3),
    NumberSequenceKeypoint.new(1,1)
    }
    ag.Rotation = 0
    ag.Parent = accentGlow
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.52,0,0.5,0)
    nameLabel.Position = UDim2.new(0.06,0,0.06,0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = sp.label
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Antique
    nameLabel.TextColor3 = sp.glow
    nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 35
    nameLabel.Parent = entry
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.72,0,0.32,0)
    descLabel.Position = UDim2.new(0.06,0,0.56,0)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = sp.desc .. "  |  Comando: " .. string.upper(sp.cmd)
    descLabel.TextScaled = true
    descLabel.Font = Enum.Font.Antique
    descLabel.TextColor3 = Color3.fromRGB(200,175,120)
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.ZIndex = 35
    descLabel.Parent = entry
    local keyBadge = mF(entry, UDim2.new(0,36,0,24), UDim2.new(1,-52,0.5,-12), Color3.fromRGB(20,12,5), 0.1, 35)
    corner(keyBadge, 0.2)
    stroke(keyBadge, Color3.fromRGB(150,100,30), 1.5)
    local keyLabel = mL(keyBadge, "CMD", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(220,185,80), Enum.Font.GothamBold, 36)
    local powerLabel = Instance.new("TextLabel")
    powerLabel.Size = UDim2.new(0.22,0,0.45,0)
    powerLabel.Position = UDim2.new(0.77,0,0.06,0)
    powerLabel.BackgroundTransparency = 1
    powerLabel.Text = sp.power
    powerLabel.TextScaled = true
    powerLabel.Font = Enum.Font.GothamBold
    powerLabel.TextColor3 = Color3.fromRGB(255,215,0)
    powerLabel.ZIndex = 35
    powerLabel.Parent = entry
    local cdOverlay = mF(entry, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(0,0,0), 0.62, 36)
    cdOverlay.Visible = false
    corner(cdOverlay, 0.12)
    local cdOvLabel = mL(cdOverlay, "", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(255,255,255), Enum.Font.GothamBlack, 37)
    cdOvLabel.TextStrokeColor3 = Color3.new(0,0,0)
    cdOvLabel.TextStrokeTransparency = 0
    local cdBarBg = mF(cdOverlay, UDim2.new(1,0,0,4), UDim2.new(0,0,1,-4), Color3.fromRGB(20,20,20), 0, 37)
    local cdBarFill = mF(cdBarBg, UDim2.new(0,0,1,0), UDim2.new(0,0,0,0), sp.color, 0, 38)
    entry.MouseEnter:Connect(function()
        if not spellOnCD[sp.name] then
            tw(entry, {BackgroundTransparency = 0}, 0.12):Play()
            tw(nameLabel, {TextColor3 = Color3.fromRGB(255,255,255)}, 0.12):Play()
        end
    end)
    entry.MouseLeave:Connect(function()
        if not spellOnCD[sp.name] then
            tw(entry, {BackgroundTransparency = 0.08}, 0.12):Play()
            tw(nameLabel, {TextColor3 = sp.glow}, 0.12):Play()
        end
    end)
    if BOOK_CAST_ENABLED then
        entry.Activated:Connect(function()
            task.spawn(function()
                if bookOpen then
                    closeBook()
                    task.wait(0.08)
                end
                castSpell(sp.name)
            end)
        end)
    else
        entry.AutoButtonColor = false
        entry.Active = false
    end
    spellEntries[sp.name] = {
    entry = entry,
    nameLabel = nameLabel,
    descLabel = descLabel,
    cdOverlay = cdOverlay,
    cdOvLabel = cdOvLabel,
    cdBarFill = cdBarFill,
    sp = sp,
    }
end
for _, sp in ipairs(SPELLS) do
    makeSpellEntry(sp)
end
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-38,0,6)
closeBtn.BackgroundColor3 = Color3.fromRGB(100,15,8)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,180,160)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.ZIndex = 36
closeBtn.Parent = bookFrame
corner(closeBtn, 0.2)
stroke(closeBtn, Color3.fromRGB(200,80,50), 1.5)
local bookTriggerBtn = Instance.new("TextButton")
bookTriggerBtn.Size = UDim2.new(1,0,1,0)
bookTriggerBtn.BackgroundTransparency = 1
bookTriggerBtn.Text = ""
bookTriggerBtn.ZIndex = 27
bookTriggerBtn.Parent = bookTriggerWrap
bookTriggerBtn.Activated:Connect(function()
    toggleBook()
end)
closeBtn.Activated:Connect(function()
    closeBook()
end)
--===========================================================
-- KEYBOARD INPUT
--===========================================================
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.B then
        toggleBook()
    end
end)

local COMMAND_TO_SPELL = {}
for _, sp in ipairs(SPELLS) do
    COMMAND_TO_SPELL[string.lower(sp.cmd)] = sp.name
end

LocalPlayer.Chatted:Connect(function(message)
    if not isInDuel then return end
    if typeof(message) ~= "string" then return end
    local cmd = string.lower((message:match("^%s*(.-)%s*$") or ""))
    local spell = COMMAND_TO_SPELL[cmd]
    if spell then
        castSpell(spell)
    end
end)
--===========================================================
-- COUNTDOWN UI
--===========================================================
local cdWrap = mF(sg, UDim2.new(0,190,0,105), UDim2.new(0.5,-95,0.04,0), Color3.fromRGB(4,1,14), 0.18, 22)
cdWrap.Visible = false
corner(cdWrap, 0.16)
stroke(cdWrap, Color3.fromRGB(255,215,0), 2.5)
grad(cdWrap, Color3.fromRGB(8,3,22), Color3.fromRGB(3,1,12))
local cdTitle = mL(cdWrap, "⚔ DUELO ⚔", UDim2.new(1,0,0.38,0), UDim2.new(0,0,0,0), Color3.fromRGB(255,215,0), Enum.Font.GothamBlack, 23)
cdTitle.TextStrokeColor3 = Color3.fromRGB(0,0,0)
cdTitle.TextStrokeTransparency = 0.2
local cdNum = mL(cdWrap, "5", UDim2.new(1,0,0.58,0), UDim2.new(0,0,0.4,0), Color3.fromRGB(255,255,255), Enum.Font.GothamBlack, 23)
local function showCountdown(n)
    cdWrap.Visible = true
    cdNum.Text = tostring(n)
    cdNum.TextColor3 = (n <= 2) and Color3.fromRGB(255,80,80) or Color3.fromRGB(255,255,255)
    cdNum.TextTransparency = 0.8
    cdWrap.Size = UDim2.new(0,160,0,88)
    local t1 = tw(cdNum, {TextTransparency = 0}, 0.18, Enum.EasingStyle.Back)
    t1:Play()
    tw(cdWrap, {Size = UDim2.new(0,190,0,105)}, 0.18, Enum.EasingStyle.Back):Play()
    if n == 1 then
        task.delay(1.1, function()
            cdNum.Text = "¡DUEL!"
            cdNum.TextColor3 = Color3.fromRGB(255,60,60)
            screenFlash(Color3.fromRGB(255,100,0), 0.4, 0.5)
            task.wait(0.9)
            tw(cdWrap, {BackgroundTransparency = 1}, 0.35):Play()
            tw(cdTitle, {TextTransparency = 1}, 0.35):Play()
            tw(cdNum, {TextTransparency = 1}, 0.35):Play()
            task.wait(0.38)
            cdWrap.Visible = false
            cdWrap.BackgroundTransparency = 0.18
            cdTitle.TextTransparency = 0
            cdNum.TextTransparency = 0
            cdNum.TextColor3 = Color3.fromRGB(255,255,255)
        end)
    end
end
--===========================================================
-- HUD
--===========================================================
local hudWrap = mF(sg, UDim2.new(0,520,0,96), UDim2.new(0.5,-260,0,6), Color3.fromRGB(3,1,12), 0.15, 18)
hudWrap.Visible = false
corner(hudWrap, 0.14)
stroke(hudWrap, Color3.fromRGB(255,215,0), 1.5)
grad(hudWrap, Color3.fromRGB(10,5,30), Color3.fromRGB(3,1,12))
local oppLabel = mL(hudWrap, "VS ????", UDim2.new(1,0,0,22), UDim2.new(0,0,0,4), Color3.fromRGB(255,215,0), Enum.Font.GothamBold, 19)
oppLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
oppLabel.TextStrokeTransparency = 0.3
mF(hudWrap, UDim2.new(0.85,0,0,1), UDim2.new(0.075,0,0,28), Color3.fromRGB(255,215,0), 0.6, 19)
local hudBottom = mF(hudWrap, UDim2.new(1,0,0,62), UDim2.new(0,0,0,32), Color3.new(0,0,0), 1, 19)
local timerBox = mF(hudBottom, UDim2.new(0,80,0,44), UDim2.new(1,-88,0.5,-22), Color3.fromRGB(8,4,25), 0.25, 20)
corner(timerBox, 0.2)
stroke(timerBox, Color3.fromRGB(160,120,255), 1.5)
local timerLabel = mL(timerBox, "1:00", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(255,255,255), Enum.Font.GothamBlack, 21)
local roundRow = mF(hudBottom, UDim2.new(0,230,0,44), UDim2.new(0.5,-115,0.5,-22), Color3.new(0,0,0), 1, 20)
local rLayout = Instance.new("UIListLayout")
rLayout.FillDirection = Enum.FillDirection.Horizontal
rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rLayout.Padding = UDim.new(0,8)
rLayout.Parent = roundRow
local roundDots = {}
for i = 1, 3 do
    local cap = mF(roundRow, UDim2.new(0,64,0,38), UDim2.new(0,0,0,0), Color3.fromRGB(35,35,45), 0, 20)
    corner(cap, 0.35)
    stroke(cap, Color3.fromRGB(80,80,100), 1.5)
    local rl = mL(cap, "R"..i, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(150,150,170), Enum.Font.GothamBlack, 21)
    roundDots[i] = {frame = cap, label = rl, str = cap:FindFirstChildOfClass("UIStroke")}
end
local function updateHUD(round, timeLeft, myWins, oppWins)
    local m = math.floor(timeLeft / 60)
    local s = math.max(0, math.floor(timeLeft % 60))
    timerLabel.Text = string.format("%d:%02d", m, s)
    timerLabel.TextColor3 = timeLeft <= 10 and Color3.fromRGB(255,50,50) or timeLeft <= 20 and Color3.fromRGB(255,160,40) or Color3.fromRGB(255,255,255)
    for i = 1, 3 do
        local d = roundDots[i]
        if i == round then
            d.frame.BackgroundColor3 = Color3.fromRGB(255,215,0)
            d.label.TextColor3 = Color3.new(0,0,0)
            if d.str then d.str.Color = Color3.fromRGB(255,215,0) end
        elseif i < round then
            local won = (i <= myWins)
            d.frame.BackgroundColor3 = won and Color3.fromRGB(0,180,50) or Color3.fromRGB(180,30,30)
            d.label.TextColor3 = Color3.new(1,1,1)
            if d.str then d.str.Color = won and Color3.fromRGB(0,255,70) or Color3.fromRGB(255,60,60) end
        else
            d.frame.BackgroundColor3 = Color3.fromRGB(35,35,45)
            d.label.TextColor3 = Color3.fromRGB(150,150,170)
            if d.str then d.str.Color = Color3.fromRGB(80,80,100) end
        end
    end
end
--===========================================================
-- HP BAR
--===========================================================
local hpWrap = mF(sg, UDim2.new(0,320,0,58), UDim2.new(0.02,0,1,-70), Color3.fromRGB(4,1,14), 0.25, 18)
hpWrap.Visible = false
corner(hpWrap, 0.18)
stroke(hpWrap, Color3.fromRGB(200,10,10), 2)
grad(hpWrap, Color3.fromRGB(12,3,3), Color3.fromRGB(4,1,8))
local hpTextLabel = mL(hpWrap, "HP 100 / 100", UDim2.new(1,-14,0,22), UDim2.new(0,7,0,5), Color3.fromRGB(255,255,255), Enum.Font.GothamBold, 19)
local hpBg = mF(hpWrap, UDim2.new(1,-14,0,12), UDim2.new(0,7,0,30), Color3.fromRGB(40,4,4), 0, 19)
corner(hpBg, 1)
local hpBar = mF(hpBg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(50,220,55), 0, 20)
corner(hpBar, 1)
local hpShine = mF(hpBar, UDim2.new(1,0,0.5,0), UDim2.new(0,0,0,0), Color3.fromRGB(255,255,255), 0.6, 21)
corner(hpShine, 1)
--===========================================================
-- ANNOUNCEMENT SCREEN
--===========================================================
local annBg = mF(sg, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.new(0,0,0), 0, 58)
annBg.Visible = false
local annContainer = mF(annBg, UDim2.new(0.65,0,0.6,0), UDim2.new(0.175,0,0.2,0), Color3.new(0,0,0), 1, 59)
local ann1 = mL(annContainer, "LA BATALLA", UDim2.new(1,0,0.34,0), UDim2.new(0,0,0,0), Color3.fromRGB(255,215,0), Enum.Font.GothamBlack, 60)
ann1.TextStrokeColor3 = Color3.new(0,0,0)
ann1.TextStrokeTransparency = 0
ann1.TextTransparency = 1
local ann2 = mL(annContainer, "COMIENZA AHORA", UDim2.new(1,0,0.22,0), UDim2.new(0,0,0.35,0), Color3.fromRGB(200,200,255), Enum.Font.GothamBold, 60)
ann2.TextStrokeColor3 = Color3.new(0,0,0)
ann2.TextStrokeTransparency = 0
ann2.TextTransparency = 1
local annDivider = mF(annContainer, UDim2.new(0.7,0,0,2), UDim2.new(0.15,0,0.6,0), Color3.fromRGB(255,215,0), 0.3, 60)
annDivider.Visible = false
local annVS = mL(annContainer, "", UDim2.new(1,0,0.28,0), UDim2.new(0,0,0.65,0), Color3.fromRGB(180,180,220), Enum.Font.GothamBold, 60)
annVS.TextStrokeColor3 = Color3.new(0,0,0)
annVS.TextStrokeTransparency = 0
annVS.TextTransparency = 1
local function playAnnouncement(opponentName)
    closeBook()
    fadeBlack(0, 0.5)
    annBg.Visible = true
    annBg.BackgroundTransparency = 0
    ann1.TextTransparency = 1
    ann2.TextTransparency = 1
    annVS.TextTransparency = 1
    annDivider.Visible = false
    task.wait(0.15)
    screenFlash(Color3.fromRGB(255,215,0), 0.3, 0.4)
    local t1 = tw(ann1, {TextTransparency = 0}, 0.5, Enum.EasingStyle.Back)
    t1:Play()
    t1.Completed:Wait()
    task.wait(0.06)
    local t2 = tw(ann2, {TextTransparency = 0}, 0.45, Enum.EasingStyle.Back)
    t2:Play()
    t2.Completed:Wait()
    annDivider.Visible = true
    annVS.Text = LocalPlayer.Name .. " ⚔ ".. opponentName
    oppLabel.Text = "⚔ " .. opponentName
    local t3 = tw(annVS, {TextTransparency = 0}, 0.4)
    t3:Play()
    t3.Completed:Wait()
    task.wait(2.0)
    tw(ann1, {TextTransparency = 1}, 0.28):Play()
    tw(ann2, {TextTransparency = 1}, 0.28):Play()
    tw(annVS, {TextTransparency = 1}, 0.28):Play()
    task.wait(0.2)
    local hide = tw(annBg, {BackgroundTransparency = 1}, 0.4, Enum.EasingStyle.Linear)
    hide:Play()
    hide.Completed:Wait()
    annBg.Visible = false
    fadeBlack(1, 0.5)
    isInDuel = true
    hudWrap.Visible = true
    hpWrap.Visible = true
    bookTriggerWrap.Visible = true
    spellOnCD = {}
    task.defer(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local wand = Backpack:FindFirstChild(WAND_NAME) or (char and char:FindFirstChild(WAND_NAME))
        if hum and wand and wand.Parent == Backpack then
            hum:EquipTool(wand)
        end
    end)
end
--===========================================================
-- RESULT SCREEN
--===========================================================
local resWrap = mF(sg, UDim2.new(0,420,0,190), UDim2.new(0.5,-210,0.3,0), Color3.new(0,0,0), 0.2, 92)
resWrap.Visible = false
corner(resWrap, 0.12)
stroke(resWrap, Color3.fromRGB(255,215,0), 2.5)
grad(resWrap, Color3.fromRGB(10,8,25), Color3.fromRGB(3,2,10))
local resTxt = mL(resWrap, "VICTORIA", UDim2.new(1,0,0.55,0), UDim2.new(0,0,0.1,0), Color3.fromRGB(255,215,0), Enum.Font.GothamBlack, 93)
resTxt.TextStrokeColor3 = Color3.new(0,0,0)
resTxt.TextStrokeTransparency = 0
resTxt.TextTransparency = 1
local resSub = mL(resWrap, "", UDim2.new(1,0,0.28,0), UDim2.new(0,0,0.72,0), Color3.fromRGB(200,200,200), Enum.Font.GothamBold, 93)
resSub.TextTransparency = 1
--===========================================================
-- REMOTES
--===========================================================
RE_BattleStart.OnClientEvent:Connect(function(opponentName)
    duelSessionActive = true
    task.spawn(playAnnouncement, opponentName)
end)
RE_BattleEnd.OnClientEvent:Connect(function(winnerName, isWinner)
    duelSessionActive = false
    isInDuel = false
    spellOnCD = {}
    hudWrap.Visible = false
    hpWrap.Visible = false
    bookTriggerWrap.Visible = false
    cdWrap.Visible = false
    resWrap.Visible = false
    annBg.Visible = false
    blackScreen.BackgroundTransparency = 1
    closeBook()
    local isTie = (winnerName == "EMPATE")
    local sub = ""
    if isTie then
        resTxt.Text = "EMPATE ⚖"
        resTxt.TextColor3 = Color3.fromRGB(200,200,80)
        sub = ""
        resWrap:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(200,200,80)
    elseif isWinner then
        resTxt.Text = "⚡ VICTORIA ⚡"
        resTxt.TextColor3 = Color3.fromRGB(255,215,0)
        sub = "¡Has ganado el duelo!"
        resWrap:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(255,215,0)
        screenFlash(Color3.fromRGB(255,215,0), 0.35, 1.0)
        cameraShake(0.2, 0.8)
    else
        resTxt.Text = "☠ DERROTA ☠"
        resTxt.TextColor3 = Color3.fromRGB(220,55,55)
        sub = "Ganó " .. winnerName
        resWrap:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(180,30,30)
        screenFlash(Color3.fromRGB(100,0,0), 0.4, 0.8)
    end
    resSub.Text = sub or ""
    resWrap.Visible = true
    resWrap.BackgroundTransparency = 1
    resTxt.TextTransparency = 1
    resSub.TextTransparency = 1
    tw(resWrap, {BackgroundTransparency = 0.2}, 0.5, Enum.EasingStyle.Back):Play()
    task.wait(0.3)
    tw(resTxt, {TextTransparency = 0}, 0.45):Play()
    tw(resSub, {TextTransparency = 0}, 0.45):Play()
    task.wait(4)
    tw(resWrap, {BackgroundTransparency = 1}, 0.45):Play()
    tw(resTxt, {TextTransparency = 1}, 0.45):Play()
    tw(resSub, {TextTransparency = 1}, 0.45):Play()
    task.wait(0.5)
    resWrap.Visible = false
end)
RE_Countdown.OnClientEvent:Connect(function(n)
    showCountdown(n)
end)
RE_RoundUpdate.OnClientEvent:Connect(function(round, timeLeft, myWins, oppWins)
    updateHUD(round, timeLeft, myWins, oppWins)
end)
RE_SpellEffect.OnClientEvent:Connect(function(spellName, isVictim)
    screenFX(spellName, isVictim)
end)
RE_ClashUpdate.OnClientEvent:Connect(function(progress, youreWinning)
    local intensity = 0.05 + progress * (youreWinning and 0.05 or 0.18)
    cameraShake(intensity, 0.12)
end)
--===========================================================
-- HP BAR UPDATE
--===========================================================
RunService.Heartbeat:Connect(function()
    if not isInDuel then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
    TweenService:Create(hpBar, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Size = UDim2.new(pct,0,1,0)}):Play()
    hpTextLabel.Text = "HP "..math.ceil(hum.Health).." / "..math.ceil(hum.MaxHealth)
    hpBar.BackgroundColor3 = pct > 0.55 and Color3.fromRGB(40,220,55) or pct > 0.28 and Color3.fromRGB(255,165,0) or Color3.fromRGB(230,30,30)
end)
Backpack.ChildAdded:Connect(function(c)
    if c.Name == WAND_NAME and isInDuel then
        task.wait(0.12)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and c.Parent == Backpack then
            hum:EquipTool(c)
        end
    end
end)
LocalPlayer.CharacterAdded:Connect(function()
    if duelSessionActive then
        isInDuel = true
        hudWrap.Visible = true
        hpWrap.Visible = true
        bookTriggerWrap.Visible = true
        cdWrap.Visible = true
        resWrap.Visible = false
        annBg.Visible = false
        blackScreen.BackgroundTransparency = 1
        closeBook()
        task.wait(0.35)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local wand = Backpack:FindFirstChild(WAND_NAME) or (char and char:FindFirstChild(WAND_NAME))
        if hum and wand and wand.Parent == Backpack then
            hum:EquipTool(wand)
        end
        return
    end
    
    isInDuel = false
    spellOnCD = {}
    hudWrap.Visible = false
    hpWrap.Visible = false
    bookTriggerWrap.Visible = false
    cdWrap.Visible = false
    resWrap.Visible = false
    annBg.Visible = false
    blackScreen.BackgroundTransparency = 1
    closeBook()
    task.wait(0.25)
end)
print("⚡ [DuelGame v12.0] LocalScript loaded — Spellbook fixed, casting fixed, UI resized ⚡")
