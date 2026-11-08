if _G._genToken then pcall(function() _G._genToken.unload() end) end
_G.GenLib = nil
do

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local _G_ = _G
local GEN = (_G_._genGEN or 0) + 1
_G_._genGEN = GEN
local old = _G_._genTokenf
if old then
    if old.unload then pcall(function() old.unload() end) end
end

local running = true

-- Neverlose-style flat dark palette
local C_ACC  = Color3.fromRGB(255, 255, 255)
local C_TACC = Color3.fromRGB(22, 36, 54)
local C_WBG  = Color3.fromRGB(11, 11, 14)
local C_SOUT_DARK = Color3.fromRGB(38, 38, 44)
local C_SOUT = C_SOUT_DARK
local C_CNT_DARK  = Color3.fromRGB(16, 16, 20)
local C_CNT  = C_CNT_DARK
_G._allSectors = {}
_G.__uiScroll = nil
_G.__uiScrollBar = nil
_G.__uiScrollDrag = nil
_G._bgIsLight = false
_G._bgIsRed = false
_G._bgIsBlack = true
_G._bgIsPink = false
_G._sectClr = C_SOUT_DARK
_G._bdrClr = Color3.fromRGB(38, 38, 44)
_G._tabBgA = Color3.fromRGB(16, 16, 20)
_G._tabBgH = Color3.fromRGB(30, 30, 36)
local C_CTRL = Color3.fromRGB(26, 26, 32)
local C_GRY  = Color3.fromRGB(138, 138, 147)
local C_GRY2 = Color3.fromRGB(201, 201, 209)
local C_WHT  = Color3.fromRGB(232, 232, 238)
local C_SL1  = Color3.fromRGB(255, 255, 255)
local C_UL   = Color3.fromRGB(70, 170, 240)

local function colLerp(a, b, k)
    return Color3.new(a.R + (b.R - a.R) * k, a.G + (b.G - a.G) * k, a.B + (b.B - a.B) * k)
end

local accentReg = {}

local PRESETS = {
    { "White", Color3.fromRGB(255, 255, 255) },
    { "Red", Color3.fromRGB(255, 60, 60) },
    { "Black", Color3.fromRGB(10, 10, 10) },
    { "Pink", Color3.fromRGB(255, 150, 200) },
}
local AP_PRESETS = {
    { "White", Color3.fromRGB(255, 255, 255) },
    { "Red", Color3.fromRGB(255, 60, 60) },
    { "Black", Color3.fromRGB(10, 10, 10) },
    { "Pink", Color3.fromRGB(255, 150, 200) },
    { "Orange", Color3.fromRGB(255, 165, 0) },
    { "Yellow", Color3.fromRGB(255, 255, 0) },
    { "Lime", Color3.fromRGB(50, 255, 50) },
    { "Cyan", Color3.fromRGB(0, 255, 255) },
    { "Light Blue", Color3.fromRGB(80, 160, 255) },
    { "Blue", Color3.fromRGB(0, 120, 255) },
    { "Purple", Color3.fromRGB(150, 80, 255) },
    { "Magenta", Color3.fromRGB(255, 0, 255) },
    { "Gold", Color3.fromRGB(255, 215, 0) },
    { "Teal", Color3.fromRGB(0, 200, 180) },
    { "Green", Color3.fromRGB(0, 200, 80) },
}

PRESETS = AP_PRESETS

local allD = {}
local baseTs = {}
local function D(type, props)
    local d = Drawing.new(type)
    d.Visible = false
    if props then for k, v in pairs(props) do d[k] = v end end
    allD[#allD + 1] = d
    baseTs[#allD] = (props and props.Transparency) or 1
    return d
end
local function T(size, col)
    return D("Text", { Size = size, Font = 11, Color = col, ZIndex = 9, Visible = false, Outline = true })
end

local function fakeOutline(z, thickness)
    local parts = {
        D("Square", { Filled = true, ZIndex = z }),
        D("Square", { Filled = true, ZIndex = z }),
        D("Square", { Filled = true, ZIndex = z }),
        D("Square", { Filled = true, ZIndex = z }),
    }
    local t = thickness or 1
    local px, py, pw, ph = 0, 0, 0, 0
    local function upd()
        parts[1].Position = Vector2.new(px, py)
        parts[1].Size = Vector2.new(pw, t)
        parts[2].Position = Vector2.new(px, py + ph - t)
        parts[2].Size = Vector2.new(pw, t)
        parts[3].Position = Vector2.new(px, py)
        parts[3].Size = Vector2.new(t, ph)
        parts[4].Position = Vector2.new(px + pw - t, py)
        parts[4].Size = Vector2.new(t, ph)
    end
    return setmetatable({}, {
        __newindex = function(self, k, v)
            if k == "Position" then px, py = v.X, v.Y
            elseif k == "Size" then pw, ph = v.X, v.Y
            elseif k == "Visible" then for _, p in ipairs(parts) do p.Visible = v end
            elseif k == "Color" then for _, p in ipairs(parts) do p.Color = v end
            elseif k == "Thickness" then t = v
            else rawset(self, k, v) end
            if k == "Position" or k == "Size" or k == "Thickness" then upd() end
        end,
        __index = function(self, k)
            if k == "_parts" then return parts end
            if k == "_rect" then return { px, py, pw, ph } end
            return nil
        end,
    })
end

local function polyLines(radius, segs)
    local out = {}
    for i = 1, segs do
        local a1 = (i - 1) / segs * math.pi * 2
        local a2 = i / segs * math.pi * 2
        out[#out + 1] = {
            fx = math.cos(a1) * radius, fy = math.sin(a1) * radius,
            tx = math.cos(a2) * radius, ty = math.sin(a2) * radius,
        }
    end
    return out
end

local nameToVK = {}
do
    for i = 65, 90 do nameToVK[string.char(i)] = i end
    for i = 0, 9 do nameToVK[tostring(i)] = 48 + i end
    for i = 1, 12 do nameToVK["F" .. i] = 111 + i end
    local sp = {
        Escape = 27, Backspace = 8, Tab = 9, Enter = 13, Space = 32,
        Left = 37, Up = 38, Right = 39, Down = 40,
        Shift = 16, LeftShift = 16, RightShift = 16,
        Control = 17, LeftControl = 17, RightControl = 17,
        Alt = 18, LeftAlt = 18, RightAlt = 18,
        Backquote = 192, Minus = 189, Equals = 187,
        LeftBracket = 219, RightBracket = 221, Backslash = 220,
        Semicolon = 186, Quote = 222, Comma = 188, Period = 190, Slash = 191,
        CapsLock = 20, Home = 36, End = 35, PageUp = 33, PageDown = 34,
        Insert = 45, Delete = 46,
    }
    for n, vk in pairs(sp) do nameToVK[n] = vk end
end
local vkToName = {}
do
    for n, vk in pairs(nameToVK) do
        if not vkToName[vk] or #vkToName[vk] > #n then vkToName[vk] = n end
    end
end
local function keyName(v) return vkToName[v] or tostring(v) end
local commonVKs = {}
do
    local seen = {}
    for _, vk in pairs(nameToVK) do
        if not seen[vk] then seen[vk] = true; commonVKs[#commonVKs + 1] = vk end
    end
    table.sort(commonVKs)
end
local function vkChar(vk)
    if vk >= 65 and vk <= 90 then return string.char(vk) end
    local map = {
        [48] = "0", [49] = "1", [50] = "2", [51] = "3", [52] = "4", [53] = "5",
        [54] = "6", [55] = "7", [56] = "8", [57] = "9",
        [189] = "-", [187] = "=", [219] = "[", [221] = "]", [220] = "\\",
        [186] = ";", [222] = "'", [188] = ",", [190] = ".", [191] = "/", [192] = "`",
        [32] = " ",
    }
    return map[vk]
end

local uiPos = Vector2.new(400, 120)
local menuOpen = true
local minimized = false
local minRect, xRect
local uiSettle = 0
local _lmx, _lmy, _pm1, _pm2 = nil, nil, nil, nil
local _lOpen = true
local activeTab = 1
local tabHandles = {}
local values = {}
local openPopup = nil
local focusTextBox = nil
local bindingKB = nil
local kbHeld = {}
local winDrag = false
local dragOffX, dragOffY = 0, 0
local hovEl, hovKB, hovSwatch = nil, nil, nil
local hovTab, hovSec = nil, nil
local hovSector = nil
local hovRow = nil
local gShow = true

local function inRect(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local WIN_W, WIN_H = 620, 440
_G.__hdrBg = D("Square", { Filled = true, Color = Color3.fromRGB(22, 22, 26), Size = Vector2.new(WIN_W, 44), ZIndex = 3, Rounding = 0, Visible = false })
_G.__hdrBd = D("Square", { Filled = true, Color = Color3.fromRGB(38, 38, 44), Size = Vector2.new(WIN_W, 1), ZIndex = 4, Visible = false })
_G.__hdrMark = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(3, 16), ZIndex = 6, Visible = false })
accentReg[#accentReg + 1] = _G.__hdrMark
_G.__sideSep = D("Square", { Filled = true, Color = Color3.fromRGB(38, 38, 44), Size = Vector2.new(1, 1), ZIndex = 4, Visible = false })
local winBg = D("Square", { Filled = true, Color = Color3.fromRGB(11, 11, 14), Size = Vector2.new(WIN_W, WIN_H), ZIndex = 2, Rounding = 2, Visible = false })
_G.swapBgForAccent = function(c)
    local col = c or Color3.fromRGB(255, 255, 255)
    _G._uiAccent = col
    _G._bgIsLight = false
    _G._bgIsRed = false
    _G._bgIsBlack = true
    _G._bgIsPink = false
    _G._sectClr = Color3.fromRGB(38, 38, 44)
    _G._bdrClr = Color3.fromRGB(38, 38, 44)
    _G._tabBgA = Color3.fromRGB(16, 16, 20)
    _G._tabBgH = Color3.fromRGB(30, 30, 36)
    if contentBg then pcall(function() contentBg.Color = Color3.fromRGB(16, 16, 20); contentBg.Transparency = 0 end) end
    for _, sect in ipairs(_G._allSectors or {}) do
        if sect.outer then pcall(function() sect.outer.Color = Color3.fromRGB(38, 38, 44); sect.outer.Transparency = 0.0; sect.outer.Rounding = 2 end) end
        if sect.cont then pcall(function() sect.cont.Color = Color3.fromRGB(16, 16, 20); sect.cont.Transparency = 0.0; sect.cont.Rounding = 2 end) end
        if sect.border then pcall(function() sect.border.Color = _G._bdrClr end) end
    end
    if contentBd then pcall(function() contentBd.Color = Color3.fromRGB(38, 38, 44) end) end
    if railBd then pcall(function() railBd.Color = Color3.fromRGB(38, 38, 44) end) end
end
local uiAlpha = 1
local menuFade = 0
local winBd = fakeOutline(4, 1)
winBd.Color = Color3.fromRGB(38, 38, 44)
local titleSepSegs = {}
do
    titleSepSegs[1] = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(1, 3), ZIndex = 6, Transparency = 0.45 })
    accentReg[#accentReg + 1] = titleSepSegs[1]
    titleSepSegs[1].Visible = false
end
_G.contentBg = D("Square", { Filled = true, Color = Color3.fromRGB(16, 16, 20), Transparency = 0.0, ZIndex = 3, Rounding = 2 })
local titleGlow = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(120, 2), ZIndex = 7 })
local titleGlowCore = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(120, 1), ZIndex = 7 })
_G.contentBd = fakeOutline(4, 1)
contentBd.Color = Color3.fromRGB(38, 38, 44)
local titleTxt = T(16, C_WHT)
titleTxt.Outline = true
local minBtn = T(18, C_GRY)
minBtn.Text = "-"
local xBtn = T(14, C_GRY)
xBtn.Text = "X"
_G.railBd = fakeOutline(4, 1)
railBd.Color = Color3.fromRGB(38, 38, 44)

local avRing = D("Circle", { Filled = true, Radius = 27, Color = C_CNT, ZIndex = 4, Visible = false })
local avImg = D("Image", { Size = Vector2.new(40, 40), ZIndex = 5, Visible = false })
local avName = T(14, C_WHT)
avName.Outline = true
avName.Visible = false
_G._avRealName = nil

-- Orbiting border comet: a pink ball that circles the window edge with a fading trail.
do
    local bb = { trail = {} }
    bb.ball = D("Circle", { Filled = true, Radius = 4, Color = C_UL, Transparency = 0, ZIndex = 3, Visible = false })
    bb.glow = D("Circle", { Filled = true, Radius = 10, Color = C_ACC, Transparency = 0.8, ZIndex = 2, Visible = false })
    for i = 1, 16 do
        bb.trail[i] = D("Circle", { Filled = true, Radius = 2.6, Color = C_ACC, Transparency = 0.4, ZIndex = 2, Visible = false })
    end
    _G.__bb = bb
    _G.__bbPhase = 0
    _G.__bbLast = nil
    _G.__bbMode = nil
    _G.__bbBallHist = nil
    _G.__bbBallPos = nil
end
_G.__bbPos = function(d, x, y, w, h)
    local P = 2 * (w + h)
    d = d % P
    if d < w then return x + d, y end
    d = d - w
    if d < h then return x + w, y + d end
    d = d - h
    if d < w then return x + w - d, y + h end
    return x, y + h - (d - w)
end
_G.__bbNearestPhase = function(px, py, x, y, w, h)
    if not px or not py then return 0 end
    local bestD, bestT = math.huge, 0
    local cx = math.clamp(px, x, x + w)
    local d2 = (cx - px) * (cx - px) + (y - py) * (y - py)
    if d2 < bestD then bestD, bestT = d2, cx - x end
    local cy = math.clamp(py, y, y + h)
    d2 = (x + w - px) * (x + w - px) + (cy - py) * (cy - py)
    if d2 < bestD then bestD, bestT = d2, w + (cy - y) end
    cx = math.clamp(px, x, x + w)
    d2 = (cx - px) * (cx - px) + (y + h - py) * (y + h - py)
    if d2 < bestD then bestD, bestT = d2, w + h + (w - (cx - x)) end
    cy = math.clamp(py, y, y + h)
    d2 = (x - px) * (x - px) + (cy - py) * (cy - py)
    if d2 < bestD then bestD, bestT = d2, 2 * w + h + (h - (cy - y)) end
    local P = 2 * (w + h)
    return bestT % P
end
_G.__bbUpdate = function(x, y, w, h, fade, mX, mY)
    local bb = _G.__bb
    if not bb then return end
    local a = math.clamp(fade or 0, 0, 1)
    if a <= 0.01 then
        bb.ball.Visible = false
        bb.glow.Visible = false
        for i = 1, #bb.trail do bb.trail[i].Visible = false end
        _G.__bbLast = nil
        return
    end
    bb.ball.Color = C_UL
    bb.glow.Color = C_ACC
    local now = tick()
    local last = _G.__bbLast
    local dt = last and math.min(now - last, 0.1) or 0.016
    _G.__bbLast = now

    local onUi = mX and mY and mX >= x - 4 and mX <= x + w + 4 and mY >= y - 4 and mY <= y + h + 4

    if onUi then
        if _G.__bbMode ~= "follow" then
            _G.__bbMode = "follow"
            _G.__bbBallHist = {}
            if _G.__bbLastOrbit then
                _G.__bbBallPos = { x = _G.__bbLastOrbit.x, y = _G.__bbLastOrbit.y }
            else
                _G.__bbBallPos = nil
            end
        end
        local lp2 = _G.__bbBallPos
        local cx, cy
        if lp2 then
            local lerp = math.min(1, dt * 6)
            cx = lp2.x + (mX - lp2.x) * lerp
            cy = lp2.y + (mY - lp2.y) * lerp
        else
            cx, cy = mX, mY
        end
        _G.__bbBallPos = { x = cx, y = cy }
        local h = _G.__bbBallHist
        table.insert(h, 1, { x = cx, y = cy })
        if #h > 18 then table.remove(h, #h) end
        _G.__bbBallHist = h
        local pulse = 0.5 + 0.5 * math.sin(now * 2.6)
        for i = 1, #bb.trail do
            local t = bb.trail[i]
            local p2 = h[i + 1]
            if p2 then
                t.Color = C_ACC
                t.Position = Vector2.new(p2.x, p2.y)
                t.Radius = math.max(1, 1.5 - i * 0.06)
                t.Transparency = 1 - (1 - (0.22 + i * 0.047)) * a
                t.Visible = true
            else
                t.Visible = false
            end
        end
        bb.ball.Position = Vector2.new(cx, cy)
        bb.ball.Radius = 2.5 + 0.4 * pulse
        bb.ball.ZIndex = 6
        bb.glow.ZIndex = 5
        bb.ball.Transparency = 1 - a
        bb.ball.Visible = true
        bb.glow.Position = Vector2.new(cx, cy)
        bb.glow.Radius = 5.5 + 1.5 * pulse
        bb.glow.Transparency = 1 - (1 - (0.78 + 0.1 * pulse)) * a
        bb.glow.Visible = true
    else
        if _G.__bbMode ~= "orbit" then
            _G.__bbMode = "orbit"
            _G.__bbBallHist = nil
            if _G.__bbBallPos then
                _G.__bbPhase = _G.__bbNearestPhase(_G.__bbBallPos.x, _G.__bbBallPos.y, x, y, w, h)
            end
            _G.__bbBallPos = nil
            bb.ball.ZIndex = 6
            bb.glow.ZIndex = 5
        end
        local P = 2 * (w + h)
        _G.__bbPhase = (_G.__bbPhase + dt * 95) % P
        local d0 = _G.__bbPhase
        local pulse = 0.5 + 0.5 * math.sin(now * 2.6)
        for i = 1, #bb.trail do
            local t = bb.trail[i]
            local tx, ty = _G.__bbPos(d0 - i * 5.5, x, y, w, h)
            t.Color = C_ACC
            t.Position = Vector2.new(tx, ty)
            t.Radius = math.max(1, 1.5 - i * 0.06)
            t.Transparency = 1 - (1 - (0.22 + i * 0.047)) * a
            t.Visible = true
        end
        local bx, by = _G.__bbPos(d0, x, y, w, h)
        bb.ball.Position = Vector2.new(bx, by)
        bb.ball.Radius = 2.5 + 0.4 * pulse
        bb.ball.Transparency = 1 - a
        bb.ball.Visible = true
        bb.glow.Position = Vector2.new(bx, by)
        bb.glow.Radius = 5.5 + 1.5 * pulse
        bb.glow.Transparency = 1 - (1 - (0.78 + 0.1 * pulse)) * a
        bb.glow.Visible = true
        _G.__bbLastOrbit = { x = bx, y = by }
    end
end

_G.applyAvName = function()
    avName.Text = ""
    avRing.Visible = false
    avImg.Visible = false
    avName.Visible = false
end
task.spawn(function()
    local plrs = game:GetService("Players")
    local hs = game:GetService("HttpService")
    local lp = plrs.LocalPlayer
    if lp then _G._avRealName = lp.Name; _G.applyAvName() end
    for _ = 1, 10 do
        if lp then break end
        task.wait(0.5)
        lp = plrs.LocalPlayer
        if lp then _G._avRealName = lp.Name; _G.applyAvName() end
    end
    if not lp then return end
    local okj, body = pcall(httpget, "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. tostring(lp.UserId) .. "&size=150x150&format=Png&isCircular=false")
    if not okj or not body then return end
    local okd, dec = pcall(function() return hs:JSONDecode(body) end)
    if not okd or type(dec) ~= "table" or type(dec.data) ~= "table" or not dec.data[1] or not dec.data[1].imageUrl then return end
    local okb, bytes = pcall(httpget, dec.data[1].imageUrl)
    if not okb or not bytes then return end
    avImg.Data = bytes
end)

local TAB_PNG = {
    sword = "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",
    eye = "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",
    gear = "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",
}

local iconInfo = {}
local function makeIcon(kind)
    local g = {}
    local img
    if TAB_PNG[kind] then
        local ok, dec = pcall(base64decode, TAB_PNG[kind])
        if ok and dec then
            img = D("Image", { Size = Vector2.new(42, 42), ZIndex = 9, Visible = false })
            pcall(function() img.Data = dec end)
        end
    end
    local g = {}
    local function add(d, info)
        g[#g + 1] = d
        iconInfo[d] = info or {}
    end
    if kind == "crosshair" then
        for _, seg in ipairs(polyLines(9, 16)) do
            add(D("Line", { Thickness = 1.5 }), seg)
        end
        add(D("Circle", { Filled = true, Radius = 1.5 }))
        for _, a in ipairs({ 0, 90, 180, 270 }) do
            local r = math.rad(a)
            add(D("Line", { Thickness = 1.5 }), {
                fx = math.cos(r) * 13, fy = math.sin(r) * 13,
                tx = math.cos(r) * 16, ty = math.sin(r) * 16,
            })
        end
    elseif kind == "target" then
        for _, seg in ipairs(polyLines(11, 20)) do
            add(D("Line", { Thickness = 1.5 }), seg)
        end
        add(D("Circle", { Filled = true, Radius = 3 }))
    elseif kind == "person" then
        for _, seg in ipairs(polyLines(4, 14)) do
            add(D("Line", { Thickness = 1.5 }), seg)
        end
        add(D("Line", { Thickness = 1.5 }), { fx = -6, fy = 4, tx = 6, ty = 4 })
        add(D("Line", { Thickness = 1.5 }), { fx = -6, fy = 4, tx = -6, ty = 9 })
        add(D("Line", { Thickness = 1.5 }), { fx = 6, fy = 4, tx = 6, ty = 9 })
        add(D("Line", { Thickness = 1.5 }), { fx = -6, fy = 9, tx = 6, ty = 9 })
    elseif kind == "sliders" then
        for i = 0, 2 do
            local y = -6 + i * 6
            add(D("Line", { Thickness = 1.5 }), { fx = -10, fy = y, tx = 10, ty = y })
            add(D("Square", { Filled = true, Size = Vector2.new(4, 4) }), { kx = 6, ky = y - 2 })
        end
    elseif kind == "sword" then
        add(D("Line", { Thickness = 2 }), { fx = -7, fy = 7, tx = 8, ty = -8 })
        add(D("Line", { Thickness = 2 }), { fx = -7.5, fy = 0.5, tx = -0.5, ty = 7.5 })
        add(D("Circle", { Filled = true, Radius = 1.8 }), { kx = -9, ky = 9 })
    elseif kind == "eye" then
        local n = 10
        for i = 1, n do
            local t1 = (i - 1) / n
            local t2 = i / n
            local x1 = -12 + 24 * t1
            local x2 = -12 + 24 * t2
            add(D("Line", { Thickness = 2 }), {
                fx = x1, fy = -6 * math.sin(math.pi * t1),
                tx = x2, ty = -6 * math.sin(math.pi * t2),
            })
            add(D("Line", { Thickness = 2 }), {
                fx = x1, fy = 6 * math.sin(math.pi * t1),
                tx = x2, ty = 6 * math.sin(math.pi * t2),
            })
        end
        add(D("Circle", { Filled = true, Radius = 2.5 }))
    elseif kind == "gear" then
        for _, seg in ipairs(polyLines(7, 16)) do
            add(D("Line", { Thickness = 2 }), seg)
        end
        for i = 0, 7 do
            local r = math.rad(i * 45)
            add(D("Line", { Thickness = 2 }), {
                fx = math.cos(r) * 7, fy = math.sin(r) * 7,
                tx = math.cos(r) * 11, ty = math.sin(r) * 11,
            })
        end
        add(D("Circle", { Radius = 2.5 }))
    end
    for _, d in ipairs(g) do
        d.Color = C_GRY
        d.ZIndex = 4
    end
    return g, img
end

local popShadow = D("Square", { Filled = true, Color = Color3.new(0, 0, 0), Transparency = 0.55, ZIndex = 9, Rounding = 2 })
local popBg = D("Square", { Filled = true, Color = Color3.fromRGB(18, 18, 22), ZIndex = 10, Rounding = 2 })
local popBd = fakeOutline(10, 1)
popBd.Color = Color3.fromRGB(38, 38, 44)
local popRows = {}
for i = 1, 20 do
    popRows[i] = {
        bg = D("Square", { Filled = true, Color = Color3.fromRGB(26, 26, 32), ZIndex = 10, Rounding = 0 }),
        dec = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(1, 20), ZIndex = 11 }),
        sw = D("Square", { Filled = true, Size = Vector2.new(16, 14), ZIndex = 11 }),
        tx = T(13, C_GRY),
    }
    popRows[i].tx.ZIndex = 12
    accentReg[#accentReg + 1] = popRows[i].dec
end

local function renderPopup()
    local p = openPopup
    if not p then
        popShadow.Visible = false
        popBg.Visible = false
        popBd.Visible = false
for i = 1, 20 do
            popRows[i].bg.Visible = false
            popRows[i].dec.Visible = false
            popRows[i].sw.Visible = false
            popRows[i].tx.Visible = false
        end
        return
    end
    if not gShow then
        popShadow.Visible = false
        popBg.Visible = false
        popBd.Visible = false
for i = 1, 20 do
            popRows[i].bg.Visible = false
            popRows[i].dec.Visible = false
            popRows[i].sw.Visible = false
            popRows[i].tx.Visible = false
        end
        return
    end
    local h = p.h
    local pw = p.w or 228
    popShadow.Visible = true
    popShadow.Position = Vector2.new(p.x + 3, p.y + 3)
    popShadow.Size = Vector2.new(pw, h)
    popBg.Visible = true
    popBg.Position = Vector2.new(p.x, p.y)
    popBg.Size = Vector2.new(pw, h)
    popBd.Visible = true
    popBd.Position = Vector2.new(p.x, p.y)
    popBd.Size = Vector2.new(pw, h)
for i = 1, 20 do
        local r = popRows[i]
        local py = p.y + (i - 1) * 18
        if i > #p.rows then
            r.bg.Visible = false; r.dec.Visible = false; r.sw.Visible = false; r.tx.Visible = false
        else
            r.bg.Visible = true
            r.bg.Position = Vector2.new(p.x, py)
            r.bg.Size = Vector2.new(pw, 18)
            r.tx.Visible = true
            r.tx.Position = Vector2.new(p.x + 8, py + 3)
            local row = p.rows[i]
            local hov = hovRow == i
            r.tx.Text = row.txt or ""
            r.dec.Position = Vector2.new(p.x, py)
            r.dec.Size = Vector2.new(2, 18)
            if p.kind == "color" then
                r.sw.Visible = true
                r.sw.Position = Vector2.new(p.x + 8, py + 3)
                r.sw.Color = row.color
                r.tx.Position = Vector2.new(p.x + 30, py + 3)
                r.tx.Color = (hov or row.sel) and C_WHT or C_GRY
                r.dec.Visible = row.sel
            else
                r.sw.Visible = false
                r.tx.Color = (hov or row.sel) and C_WHT or C_GRY
                r.dec.Visible = row.sel
            end
        end
    end
end

local function openDrop(el)
    if openPopup then if openPopup.owner then openPopup.owner.open = false end end
    openPopup = { kind = el.kind, x = el.popX, y = el.popY, h = el.popH, w = el.popW or 228, owner = el, rows = {} }
    for i, o in ipairs(el.opts) do
        local sel
        if el.kind == "Dropdown" then sel = o == el.value.Dropdown
        else sel = table.find(el.value.Combo, o) ~= nil end
        openPopup.rows[i] = { txt = o, sel = sel }
    end
    el.open = true
end

local function makeElement(type, text, data, cb, sector, tabNum, secName)
    local el = {
        text = text, cb = cb, kind = type, opts = data.options or {}, hov = false,
        min = data.default and data.default.min or 0,
        max = data.default and data.default.max or 100,
        open = false, x = 0, y = 0, w = 211, h = 18, rect = { x = 0, y = 0, w = 211, h = 18 },
        show = false,
    }
    local flag = text
    local value = values[tabNum][secName][sector.name][flag] or {}

    local function commit()
        values[tabNum][secName][sector.name][flag] = el.value
    end

    el.get_value = function() return el.value end
    el.set_value = function(self, v, noCb)
        el.value = v or el.value
        commit()
        if not noCb and el.cb then pcall(el.cb, el.value) end
    end

    if type == "Toggle" then
        el.h = 16
        el.value = { Toggle = value.Toggle ~= nil and value.Toggle or (data.default and data.default.Toggle or false) }
        el.def = { Toggle = el.value.Toggle }
        el.animT = el.value.Toggle and 1 or 0
        el.track = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(26, 13), ZIndex = 6, Rounding = 6 })
        el.knob = D("Circle", { Filled = true, Radius = 4, Color = C_GRY, ZIndex = 7 })
        el.dot = D("Circle", { Filled = true, Radius = 2.5, Color = C_GRY, ZIndex = 7 })
        el.lab = T(13, C_GRY)
        el.parts = { el.track, el.knob, el.lab }
        el.draw = function()
            local tgt = el.value.Toggle and 1 or 0
            local d = tgt - el.animT
            if math.abs(d) < 0.02 then el.animT = tgt else el.animT = el.animT + d * 0.28 end
            local t = el.animT
            el.track.Position = Vector2.new(el.x + el.w - 35, el.y + 2)
            el.track.Color = colLerp(Color3.fromRGB(38, 40, 48), C_SL1, t)
            el.knob.Position = Vector2.new(el.x + el.w - 29 + t * 14, el.y + 8.5)
            local knbC = _G._bgIsLight and Color3.new(0, 0, 0) or C_WHT
            el.knob.Color = colLerp(C_GRY, knbC, t)
            el.dot.Position = Vector2.new(el.x + el.w - 44, el.y + 8.5)
            el.dot.Color = colLerp(C_GRY, C_ACC, t)
            el.lab.Position = Vector2.new(el.x + 9, el.y + 2)
            if el._labLt ~= el.text then el.lab.Text = el.text; el._labLt = el.text end
            el.lab.Color = C_WHT
            for _, p in ipairs(el.parts) do p.Visible = el.show end
            if el.kb then el.kb:draw() end
            if el.cl then el.cl:draw() end
        end
        el.click = function()
            uiSettle = 25
            el.value.Toggle = not el.value.Toggle
            commit()
            if el.cb then pcall(el.cb, el.value) end
        end
        el.kb = nil
        el.add_keybind = function()
            if el.kb then return el.kb end
            el.kb = {
                bg = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(36, 16), ZIndex = 7, Rounding = 8 }),
                txt = T(12, C_GRY),
                value = { Key = nil, Type = "Always", Active = true },
                cb = nil,
                toggleElement = true,
                rect = { x = 0, y = 0, w = 60, h = 18 },
                draw = function()
                    local k = el.kb.value.Key
                    local kt = k and keyName(k):upper() or "NONE"
                    if el._kbLt ~= kt then el.kb.txt.Text = kt; el._kbLt = kt end
                    local hov = hovKB == el.kb
                    local cw = math.max(36, math.min(el.kb.txt.TextBounds.X + 14, 84))
                    el.kb.bg.Size = Vector2.new(cw, 16)
                    el.kb.bg.Position = Vector2.new(el.x + el.w - 46 - cw, el.y + 3)
                    el.kb.bg.Color = hov and colLerp(C_CTRL, Color3.fromRGB(40, 42, 50), 0.9) or C_CTRL
                    el.kb.txt.Center = true
                    el.kb.txt.Position = Vector2.new(el.x + el.w - 46 - cw * 0.5, el.y + 11 + (16 - el.kb.txt.TextBounds.Y) * 0.5)
                    el.kb.txt.Color = hov and C_WHT or C_GRY
                    el.kb.txt.Visible = el.show
                    el.kb.bg.Visible = el.show
                    el.kb.rect.x = el.x + el.w - 46 - cw
                    el.kb.rect.y = el.y + 2
                    el.kb.rect.w = cw
                end,
            }
            values[tabNum][secName][sector.name]["$" .. flag] = el.kb.value
            return el.kb
        end
        el.cl = nil
        el.add_color = function(default)
            if el.cl then return el.cl end
            el.cl = {
                swatch = D("Square", { Filled = true, Color = C_WHT, Size = Vector2.new(35, 11), ZIndex = 7 }),
                value = { Color = (default and default.Color) or Color3.fromRGB(255, 255, 255), Transparency = 0 },
                defC = (default and default.Color) or Color3.fromRGB(255, 255, 255),
                rect = { x = 0, y = 0, w = 35, h = 11 },
                draw = function()
                    el.cl.swatch.Position = Vector2.new(el.x + el.w - 45, el.y + 4)
                    el.cl.swatch.Color = el.cl.value.Color
                    el.cl.swatch.Visible = el.show
                    el.cl.rect.x = el.x + el.w - 45
                    el.cl.rect.y = el.y + 4
                end,
            }
            values[tabNum][secName][sector.name]["$" .. flag] = el.cl.value
            return el.cl
        end
        commit()

    elseif type == "Dropdown" or type == "Combo" then
        el.h = 40
        if type == "Dropdown" then
            el.value = { Dropdown = value.Dropdown or (data.default and data.default.Dropdown) or el.opts[1] }
        else
            el.value = { Combo = value.Combo or (data.default and data.default.Combo) or {} }
        end
        el.def = { Dropdown = el.value.Dropdown, Combo = el.value.Combo }
        el.lab = T(13, C_GRY)
        el.btnBg = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(228, 20), ZIndex = 6, Rounding = 8 })
        el.btnTxt = T(13, C_GRY)
        el.arrow = D("Triangle", { Filled = true, Color = C_GRY })
        el.parts = { el.lab, el.btnBg, el.btnTxt, el.arrow }
        el.display = function()
            if type == "Dropdown" then return el.value.Dropdown end
            local sel = {}
            for _, o in ipairs(el.opts) do if table.find(el.value.Combo, o) then sel[#sel + 1] = o end end
            if #sel == 0 then return "..."
            elseif #sel == 1 then return sel[1]
            else
                local s = sel[1]
                for i = 2, math.min(3, #sel) do s = s .. ",  " .. sel[i] end
                if #sel > 3 then s = s .. ",  ..." end
                return s
            end
        end
        el.draw = function()
            local active = el.open or el.hov
            local iw = el.w - 18
            el.lab.Position = Vector2.new(el.x + 9, el.y + 5)
            if el._labLt ~= el.text then el.lab.Text = el.text; el._labLt = el.text end
            el.lab.Color = C_WHT
            el.btnBg.Position = Vector2.new(el.x + 9, el.y + 20)
            el.btnBg.Size = Vector2.new(iw, 20)
            el.btnTxt.Position = Vector2.new(el.x + 15, el.y + 25)
            local dt = el.display()
            if el._btnLt ~= dt then el.btnTxt.Text = dt; el._btnLt = dt end
            el.btnTxt.Color = active and C_WHT or C_GRY
            el.arrow.PointA = Vector2.new(el.x + 9 + iw - 9, el.y + 28)
            el.arrow.PointB = Vector2.new(el.x + 9 + iw - 1, el.y + 28)
            el.arrow.PointC = Vector2.new(el.x + 9 + iw - 5, el.y + 32)
            el.arrow.Color = active and C_WHT or C_GRY
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        local nOpts = #el.opts
        el.popH = math.min(nOpts, 20) * 18
        el.popX, el.popY = 0, 0
        el.openPopup = function()
            el.popX = el.x + 9
            el.popY = el.y + 41
            el.popW = el.w - 18
            openDrop(el)
        end
        el.select = function(self, idx)
            local o = el.opts[idx]
            if not o then return end
            if type == "Dropdown" then
                el.value.Dropdown = o
            else
                local found = table.find(el.value.Combo, o)
                if found then table.remove(el.value.Combo, found)
                else table.insert(el.value.Combo, o) end
            end
            commit()
            if el.cb then pcall(el.cb, el.value) end
        end
        commit()

    elseif type == "Slider" then
        el.h = 32
        el.value = { Slider = value.Slider or (data.default and data.default.default) or 0 }
        el.def = { Slider = el.value.Slider }
        el.lab = T(13, C_GRY)
        el.valTxt = T(13, C_GRY)
        el.track = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(228, 10), ZIndex = 6, Rounding = 5 })
        el.fill = D("Square", { Filled = true, Color = C_SL1, ZIndex = 7 })
        accentReg[#accentReg + 1] = el.fill
        el.handle = D("Circle", { Filled = true, Radius = 5, Color = C_WHT, ZIndex = 8 })
        el.parts = { el.lab, el.valTxt, el.track, el.fill, el.handle }
        el.dragging = false
        el.draw = function()
            local iw = el.w - 18
            el.lab.Position = Vector2.new(el.x + 9, el.y + 4)
            if el._labLt ~= el.text then el.lab.Text = el.text; el._labLt = el.text end
            el.lab.Color = C_WHT
            local sv = el.disp and el.disp(el.value.Slider) or tostring(el.value.Slider)
            if el._valLt ~= sv then el.valTxt.Text = sv; el._valLt = sv end
            el.valTxt.Position = Vector2.new(el.x + 9 + iw - el.valTxt.TextBounds.X, el.y + 4)
            el.valTxt.Color = (el.hov or el.dragging) and C_WHT or C_GRY
            el.track.Position = Vector2.new(el.x + 9, el.y + 20)
            el.track.Size = Vector2.new(iw, 10)
            local frac = (el.value.Slider - el.min) / (el.max - el.min)
            local fw = math.max(1, math.floor(iw * frac))
            el.fill.Position = Vector2.new(el.x + 9, el.y + 20)
            el.fill.Size = Vector2.new(fw, 10)
            el.handle.Position = Vector2.new(el.x + 9 + fw, el.y + 25)
            if _G._bgIsBlack then
                el.fill.Color = C_ACC
                el.handle.Color = C_UL
            else
                local hc = _G._bgIsLight and Color3.new(0, 0, 0) or C_WHT
                el.handle.Color = (el.hov or el.dragging) and hc or colLerp(hc, C_ACC, 0.55)
            end
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        el.drag = function(self, mx)
            local frac = math.max(0, math.min(1, (mx - (el.x + 9)) / (el.w - 18)))
            local v = math.floor(el.min + (el.max - el.min) * frac)
            if v ~= el.value.Slider then
                el.value.Slider = v
                commit()
                if el.cb then pcall(el.cb, el.value) end
            end
        end
        commit()

    elseif type == "Button" then
        el.h = 26
        el.value = {}
        el.bg = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(188, 18), ZIndex = 6, Rounding = 8 })
        el.tx = T(13, C_GRY)
        el.parts = { el.bg, el.tx }
        el.draw = function()
            el.bg.Position = Vector2.new(el.x + 9, el.y + 5)
            el.bg.Size = Vector2.new(el.w - 18, 18)
            if el._txLt ~= el.text then el.tx.Text = el.text; el._txLt = el.text end
            el.tx.Position = Vector2.new(el.x + el.w / 2 - el.tx.TextBounds.X / 2, el.y + 9)
            local bgTgt = el.hov and Color3.fromRGB(40, 42, 50) or C_CTRL
            el._bgC = colLerp(el._bgC or bgTgt, bgTgt, 0.25)
            el.bg.Color = el._bgC
            local txTgt = el.hov and C_WHT or C_GRY
            el._txC = colLerp(el._txC or txTgt, txTgt, 0.25)
            el.tx.Color = el._txC
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        el.click = function()
            if el.cb then pcall(el.cb) end
        end

    elseif type == "Label" then
        el.h = 16
        el.value = {}
        el.lab = T(13, C_GRY)
        el.parts = { el.lab }
        el.draw = function()
            el.lab.Position = Vector2.new(el.x + 9, el.y + 4)
            if el._labLt ~= el.text then el.lab.Text = el.text; el._labLt = el.text end
            el.lab.Color = C_WHT
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        el.click = function() end

    elseif type == "TextBox" then
        el.h = 26
        el.value = { Text = (value.Text ~= nil and value.Text) or (data.default and data.default.Text) or "" }
        el.def = { Text = el.value.Text }
        el.bg = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(188, 18), ZIndex = 6, Rounding = 8 })
        el.tx = T(13, C_GRY)
        el.parts = { el.bg, el.tx }
        el.draw = function()
            el.bg.Position = Vector2.new(el.x + 9, el.y + 5)
            el.bg.Size = Vector2.new(el.w - 18, 18)
            el.tx.Position = Vector2.new(el.x + 15, el.y + 9)
            if el.value.Text == "" and focusTextBox ~= el then
                el.tx.Text = el.text .. "..."
            else
                el.tx.Text = el.value.Text
            end
            el.tx.Color = (el.hov or focusTextBox == el) and C_WHT or C_GRY
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        el.click = function()
            focusTextBox = el
        end

    elseif type == "Scroll" then
        local ss = math.max(1, data.scrollsize or 5)
        el.h = ss * 18 + 8
        el.value = { Scroll = value.Scroll or el.opts[1] }
        el.sel = el.value.Scroll
        el.scroll = 0
        el.rows = {}
        for i = 1, 12 do
            el.rows[i] = {
                bg = D("Square", { Filled = true, Color = C_CTRL, ZIndex = 6, Rounding = 8 }),
                dec = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(1, 20), ZIndex = 7 }),
                tx = T(13, C_GRY),
            }
            accentReg[#accentReg + 1] = el.rows[i].dec
        end
        el.draw = function()
            for i = 1, 12 do
                local r = el.rows[i]
                local idx = el.scroll + i
                local showRow = el.show and idx <= #el.opts
                r.bg.Visible = showRow
                r.tx.Visible = showRow
                r.dec.Visible = showRow and el.opts[idx] == el.sel
                if showRow then
                    local iw = el.w - 18
                    r.bg.Position = Vector2.new(el.x + 9, el.y + 5 + (i - 1) * 18)
                    r.bg.Size = Vector2.new(iw, 18)
                    r.tx.Text = el.opts[idx]
                    r.tx.Position = Vector2.new(el.x + 16, el.y + 9 + (i - 1) * 18)
                    local isSel = el.opts[idx] == el.sel
                    r.tx.Color = isSel and C_WHT or (hovEl == el and hovRow == idx and C_GRY2 or C_GRY)
                    r.dec.Position = Vector2.new(el.x + 9, el.y + 5 + (i - 1) * 18)
                end
            end
        end
        el.select = function(self, idx)
            local o = el.opts[idx]
            if not o then return end
            el.sel = o
            el.value.Scroll = o
            commit()
            if el.cb then pcall(el.cb, el.value) end
        end
        el.add_value = function(self, v)
            for _, o in ipairs(el.opts) do if o == v then return end end
            el.opts[#el.opts + 1] = v
        end
        commit()
    end

    return el
end

local library = {}

local function ensureDir(d)
    pcall(function() makefolder(d) end)
end
local function listCfg(d)
    local out = {}
    local ok, files = pcall(listfiles, d)
    if ok and files then
        for _, f in ipairs(files) do
            local n = f:gsub("^.+[\\/]", ""):gsub("%.txt$", "")
            if n ~= "" then out[#out + 1] = n end
        end
    end
    return out
end

local CFG_DIR = "nemv2"

local function deepcopy(o)
    if type(o) ~= "table" then return o end
    local c = {}
    for k, v in pairs(o) do c[k] = deepcopy(v) end
    return c
end

function library:set_accent(col)
    C_ACC = col
    C_TACC = Color3.new(0.086 + col.R * 0.06, 0.086 + col.G * 0.08, 0.10 + col.B * 0.10)
    C_SL1 = col
    C_UL = Color3.new(math.min(1, col.R + (1 - col.R) * 0.28), math.min(1, col.G + (1 - col.G) * 0.28), math.min(1, col.B + (1 - col.B) * 0.28))
    _G._uiAccent = col
    for _, d in ipairs(accentReg) do d.Color = col end
end

function library:save_cfg(name)
    ensureDir(CFG_DIR)
    local flat = {}
    for t, tabV in pairs(values) do
        for s, secV in pairs(tabV) do
            for k, sec in pairs(secV) do
                for flag, v in pairs(sec) do
                    local vc = deepcopy(v)
                    if type(vc) == "table" and vc.Color then
                        vc.Color = { R = vc.Color.R, G = vc.Color.G, B = vc.Color.B }
                    end
                    flat[(tostring(t) .. "|" .. tostring(s) .. "|" .. tostring(k) .. "|" .. tostring(flag))] = vc
                end
            end
        end
    end
    pcall(function() writefile(CFG_DIR .. "\\" .. name .. ".txt", HttpService:JSONEncode(flat)) end)
end

function library:load_cfg(name)
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_DIR .. "\\" .. name .. ".txt")) end)
    if not ok then return end
    for key, v in pairs(data) do
        local t, s, k, flag = key:match("^(.-)|(.-)|(.-)|(.*)$")
        if t and values[t] and values[t][s] and values[t][s][k] and values[t][s][k][flag] ~= nil then
            if type(v) == "table" and v.Color then
                v.Color = Color3.new(v.Color.R or 1, v.Color.G or 1, v.Color.B or 1)
            end
            values[t][s][k][flag] = v
        end
    end
end

function library:set_alpha(a)
    uiAlpha = math.clamp(a, 0, 1)
    for i = 1, #allD do
        local bt = baseTs[i]
        if type(bt) ~= "number" then bt = 0 end
        local mf = menuFade
        if mf < 1 and allD[i].ClassName == "Text" then mf = mf ^ 0.55 end
        pcall(function() allD[i].Transparency = bt * uiAlpha * mf end)
    end
end
local function applyMenuFade()
    for i = 1, #allD do
        local bt = baseTs[i]
        if type(bt) ~= "number" then bt = 0 end
        local mf = menuFade
        if mf < 1 and allD[i].ClassName == "Text" then mf = mf ^ 0.55 end
        pcall(function() allD[i].Transparency = bt * uiAlpha * mf end)
    end
end
_G.applyMenuFade = applyMenuFade

function library:fire_all()
    for _, tb in ipairs(tabHandles) do
        for _, sec in ipairs(tb.sections) do
            for _, sector in ipairs(sec.sectors) do
                for _, el in ipairs(sector.elements) do
                    if el.cb and el.value and el.def then pcall(el.cb, el.value) end
                end
            end
        end
    end
end

function library:set_all_toggles(state)
    for _, tb in ipairs(tabHandles) do
        for _, sec in ipairs(tb.sections) do
            for _, sector in ipairs(sec.sectors) do
                for _, el in ipairs(sector.elements) do
                    if el.def and el.def.Toggle ~= nil and el.value.Toggle ~= state then
                        el.value.Toggle = state
                        pcall(el.cb, el.value)
                    end
                end
            end
        end
    end
end

function library:reset_ui()
    for _, tb in ipairs(tabHandles) do
        for _, sec in ipairs(tb.sections) do
            for _, sector in ipairs(sec.sectors) do
                for _, el in ipairs(sector.elements) do
                    if el.def then
                        if el.def.Toggle ~= nil then el.value.Toggle = el.def.Toggle end
                        if el.def.Slider ~= nil then el.value.Slider = el.def.Slider end
                        if el.def.Dropdown ~= nil then el.value.Dropdown = el.def.Dropdown end
                        if el.def.Combo ~= nil then
                            local c = {}
                            for _, o in ipairs(el.def.Combo) do c[#c + 1] = o end
                            el.value.Combo = c
                        end
                        if el.def.Text ~= nil then el.value.Text = el.def.Text end
                        if el.cb then pcall(el.cb, el.value) end
                    end
                    if el.cl and el.cl.defC then
                        el.cl.value.Color = el.cl.defC
                        if el.cl.cb then pcall(el.cl.cb, el.cl.value) end
                    end
                end
            end
        end
    end
end

function library.new(title, cfgDir)
    if cfgDir then CFG_DIR = cfgDir:gsub("[\\/]+$", "") end
    local cam = pcall(function() return workspace.CurrentCamera end)
    local vs = pcall(function() return workspace.CurrentCamera.ViewportSize end)
    local cx = type(vs) == "table" and vs.X or 1600
    local cy = type(vs) == "table" and vs.Y or 900
    uiPos = Vector2.new(math.floor(cx / 2 - WIN_W / 2), math.max(0, math.floor(cy / 2 - WIN_H / 2)))

    local menu = {}
    menu.values = values
    menu.open = menuOpen

    menu.save_cfg = function(n) library:save_cfg(n) end
    menu.load_cfg = function(n) library:load_cfg(n) end

    function menu.new_tab(icon, label)
        local gi, im = makeIcon(icon)
    local tab = { sections = {}, activeSection = 1, tabNum = #tabHandles + 1, icon = gi, img = im }
            tab.btnBg = D("Square", { Filled = true, Color = C_WBG, ZIndex = 5 })
            tab.lbl = T(11, C_GRY)
            tab.lbl.Text = label or ""
        values[tab.tabNum] = {}
        tabHandles[#tabHandles + 1] = tab

        function tab.new_section(name)
            local sec = { name = name, hov = false }
            sec.txt = T(15, C_GRY)
            sec.txt.Outline = true
            sec.ind = D("Triangle", { Filled = true, Color = C_ACC, ZIndex = 7 })
            accentReg[#accentReg + 1] = sec.ind
            sec.pill = D("Square", { Filled = true, Color = Color3.fromRGB(29, 30, 36), Size = Vector2.new(1, 1), ZIndex = 4, Visible = false })
            sec.accBar = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(3, 14), ZIndex = 5, Visible = false })
            accentReg[#accentReg + 1] = sec.accBar
            sec._indA = 0
            sec.ulSegs = {}
            local K = 14
            for k = 1, K do
                local f = math.abs(k - (K + 1) * 0.5) / ((K + 1) * 0.5)
                local v = 0.95 - (0.95 - 0.06) * f
                sec.ulSegs[k] = D("Square", { Filled = true, Color = C_UL, Size = Vector2.new(1, 1), ZIndex = 6, Transparency = v })
                accentReg[#accentReg + 1] = sec.ulSegs[k]
            end
            sec.sectors = {}
            values[tab.tabNum][name] = {}

            tab.sections[#tab.sections + 1] = sec

            function sec.new_sector(sname, side, desc)
                local sector = {
                    name = sname,
                    side = side or "Left",
                    elements = {},
                    height = 27,
                    _fullHeight = 27,
                    _collapsed = false,
                }
                sec.sectors[#sec.sectors + 1] = sector
                _G._allSectors[#_G._allSectors + 1] = sector
                sector.outer = D("Square", { Filled = true, Color = C_SOUT, ZIndex = 4, Rounding = 2 })
                sector.cont = D("Square", { Filled = true, Color = C_CNT, ZIndex = 5, Rounding = 2 })
                sector.border = fakeOutline(4, 1)
                sector.border.Color = Color3.fromRGB(38, 38, 44)
                sector.bar = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(2, 10), ZIndex = 6 })
                sector._colBtn = T(13, C_GRY)
                sector._colBtn.ZIndex = 10
                accentReg[#accentReg + 1] = sector.bar
                sector.title = T(13, Color3.fromRGB(150, 150, 160))
                sector.title.Text = string.upper(sname)
                sector.title.Outline = true
                values[tab.tabNum][name][sname] = {}

                function sector.element(type, text, data, cb)
                    local el = makeElement(type, text, data or {}, cb or function() end, sector, tab.tabNum, name)
                    sector.height = sector.height + el.h
                    sector._fullHeight = (sector._fullHeight or 20) + el.h
                    sector.elements[#sector.elements + 1] = el
                    return el
                end

                return sector
            end

            return sec
        end

        return tab
    end

    return menu
end

local RAIL_X, RAIL_Y = 12, 50
local TB_W, TB_H = 102, 56
local SIDE_X, SIDE_Y, SIDE_W, SIDE_H = 12, 116, 132, 30
local COL_X, COL_Y, COL_W = 156, 116, 450
local COL_GAP, COL_LEFT_W = 8, 211
local SEC_H = 30

_G.__hideEl = function(el)
    el.show = false
    for _, p in ipairs(el.parts or {}) do p.Visible = false end
    if el.kb then el.kb.txt.Visible = false; el.kb.bg.Visible = false end
    if el.cl then el.cl.swatch.Visible = false end
    if el.rows then
        for _, r in ipairs(el.rows) do r.bg.Visible = false; r.tx.Visible = false; r.dec.Visible = false end
    end
end
_G.__kdown = function(vk)
    local v = false
    pcall(function() v = iskeypressed(vk) end)
    return v
end

local _titleLt
local function layout()
    local x0, y0 = uiPos.X, uiPos.Y

    winBg.Position = uiPos
    winBg.Size = Vector2.new(WIN_W, minimized and 44 or WIN_H)
    winBd.Position = uiPos
    winBd.Size = Vector2.new(WIN_W, minimized and 44 or WIN_H)
    _G.__hdrBg.Position = uiPos
    _G.__hdrBg.Size = Vector2.new(WIN_W, 44)
    _G.__hdrBd.Position = Vector2.new(x0, y0 + 43)
    _G.__hdrBd.Size = Vector2.new(WIN_W, 1)
    _G.__sideSep.Position = Vector2.new(x0 + SIDE_X + SIDE_W + 5, y0 + SIDE_Y - 4)
    _G.__sideSep.Size = Vector2.new(1, WIN_H - SIDE_Y - 2)
    minRect = { x = x0 + WIN_W - 50, y = y0 + 5, w = 22, h = 22 }
    xRect = { x = x0 + WIN_W - 26, y = y0 + 5, w = 24, h = 22 }
    local mmx, mmy = _lmx or -1, _lmy or -1
    minBtn.Visible = true
    minBtn.Position = Vector2.new(x0 + WIN_W - 42, y0 + 7)
    minBtn.Color = inRect(mmx, mmy, minRect.x, minRect.y, minRect.w, minRect.h) and C_WHT or C_GRY
    xBtn.Visible = true
    xBtn.Position = Vector2.new(x0 + WIN_W - 21, y0 + 9)
    xBtn.Color = inRect(mmx, mmy, xRect.x, xRect.y, xRect.w, xRect.h) and C_WHT or C_GRY
    railBd.Position = Vector2.new(uiPos.X + RAIL_X - 4, uiPos.Y + RAIL_Y - 4)
    railBd.Size = Vector2.new(#tabHandles * (TB_W + 6) + 2, TB_H + 8)
    do
        for k, seg in ipairs(titleSepSegs) do
            seg.Position = Vector2.new(x0, y0 + 43)
            seg.Size = Vector2.new(WIN_W, 1)
            seg.Color = Color3.fromRGB(38, 38, 44)
            seg.Transparency = (k == 1) and 0 or 1
        end
    end
    _G.__hdrMark.Position = Vector2.new(x0 + 10, y0 + 14)
    _G.__hdrMark.Size = Vector2.new(3, 16)
    titleTxt.Position = Vector2.new(x0 + 20, y0 + 12)
    titleTxt.Text = "gennegen"; _titleLt = "gennegen"
    titleGlow.Position = Vector2.new(x0 + 20, y0 + 33)
    titleGlow.Size = Vector2.new(56, 2)
    titleGlow.Color = C_ACC
    titleGlow.Transparency = 0.55
    titleGlowCore.Position = Vector2.new(x0 + 20, y0 + 33)
    titleGlowCore.Size = Vector2.new(54, 1)
    titleGlowCore.Color = C_ACC
    do
        local ax = x0 + WIN_W - 206
        local ay = y0 + 8
        avRing.Radius = 13
        avRing.Position = Vector2.new(ax + 13, ay + 13)
        avImg.Position = Vector2.new(ax, ay)
        avImg.Size = Vector2.new(28, 28)
        avName.Position = Vector2.new(ax + 34, ay + 9)
    end

    for i, tb in ipairs(tabHandles) do
        local bx = x0 + RAIL_X + (i - 1) * (TB_W + 6)
        local by = y0 + RAIL_Y
        tb.rect = { x = bx, y = by, w = TB_W, h = TB_H }
        local pt = (hovTab == tb) and 1 or 0
        local pd = pt - (tb._pop or 0)
        if math.abs(pd) < 0.02 then tb._pop = pt else tb._pop = (tb._pop or 0) + pd * 0.25 end
        local p = tb._pop
        local grow = 1 + 0.03 * p
        local bw, bh = TB_W * grow, TB_H * grow
        tb.btnBg.Position = Vector2.new(bx - (bw - TB_W) * 0.5, by - (bh - TB_H) * 0.5)
        tb.btnBg.Size = Vector2.new(bw, bh)
        tb.btnBg.ZIndex = (hovTab == tb) and 6 or 5
        local active = i == activeTab
        local bgTgt
        if active then
            bgTgt = C_TACC
        elseif _G._bgIsLight or _G._bgIsRed or _G._bgIsBlack or _G._bgIsPink then
            bgTgt = hovTab == tb and (_G._tabBgH or C_CNT) or (_G._tabBgA or C_WBG)
        else
            bgTgt = hovTab == tb and C_CNT or C_WBG
        end
        tb._bgC = colLerp(tb._bgC or bgTgt, bgTgt, 0.22)
        tb.btnBg.Color = tb._bgC
        local wantRound = (_G._bgIsLight or _G._bgIsRed or _G._bgIsBlack or _G._bgIsPink) and 3 or 0
        tb.btnBg.Rounding = wantRound
        local icTgt = active and C_WHT or (hovTab == tb and C_GRY2 or C_GRY)
        tb._icC = colLerp(tb._icC or icTgt, icTgt, 0.22)
        local s = 0.55 + 0.14 * p
        local cx, cy = bx + TB_W / 2, by + (TB_H / 2) - 8
        local im = tb.img
        local imgOn = im and im.IsLoaded
        for _, g in ipairs(tb.icon) do
            g.Visible = not imgOn
        end
        if im then
            if imgOn then
                im.ZIndex = (hovTab == tb) and 10 or 9
                im.Position = Vector2.new(cx - 31.5 * s, cy - 31.5 * s)
                im.Size = Vector2.new(63 * s, 63 * s)
            end
            im.Visible = imgOn
        end
    for _, g in ipairs(tb.icon) do
        local info = iconInfo[g]
        g.Color = tb._icC
        g.ZIndex = (hovTab == tb) and 10 or 9
        if info and info.fx then
            g.From = Vector2.new(cx + info.fx * s, cy + info.fy * s)
            g.To = Vector2.new(cx + info.tx * s, cy + info.ty * s)
        elseif info and info.kx then
            g.Position = Vector2.new(cx + info.kx * s, cy + info.ky * s)
        else
            g.Position = Vector2.new(cx, cy)
        end
    end
        local lab = tb.lbl
        if lab then
            lab.Position = Vector2.new(cx - lab.TextBounds.X / 2, by + 42)
            local lc = active and C_WHT or (hovTab == tb and C_GRY2 or C_GRY)
            tb._lblC = colLerp(tb._lblC or lc, lc, 0.22)
            lab.Color = tb._lblC
            lab.ZIndex = (hovTab == tb) and 10 or 9
            lab.Visible = true
        end
    end

    local tab = tabHandles[activeTab]
    if not tab then return end
    local sX0 = x0 + COL_X
    local sY0 = y0 + COL_Y
    for i, sec in ipairs(tab.sections) do
        local hx = x0 + SIDE_X
        local hy = y0 + SIDE_Y + (i - 1) * SIDE_H
        sec.rect = { x = hx, y = hy, w = SIDE_W, h = SEC_H }
        sec.txt.Text = sec.name
        sec.txt.Position = Vector2.new(hx + 18, hy + 8)
        local active = i == tab.activeSection
        local hovd = (hovSec == sec) and not active
        sec.txt.Color = active and C_WHT or (hovd and C_GRY2 or C_GRY)
        sec.pill.Visible = active or hovd
        if active or hovd then
            sec.pill.Position = Vector2.new(hx + 4, hy + 2)
            sec.pill.Size = Vector2.new(SIDE_W - 8, SEC_H - 4)
            sec.pill.Color = active and Color3.fromRGB(29, 30, 36) or Color3.fromRGB(20, 20, 25)
        end
        sec.accBar.Visible = active
        if active then
            sec.accBar.Position = Vector2.new(hx + 3, hy + 9)
            sec.accBar.Size = Vector2.new(2, 12)
        end
        if sec.ind then sec.ind.Visible = false end
        for _, seg in ipairs(sec.ulSegs) do seg.Visible = false end
    end

    local cy0 = y0 + COL_Y
    local colL = { x = x0 + COL_X + 6, y = cy0 + 16 }
    local colR = { x = x0 + COL_X + 6 + COL_LEFT_W + COL_GAP, y = cy0 + 16 }
    local activeSec = tab.sections[tab.activeSection]
    if not activeSec then return end

    local cTop = cy0
    local cBot = y0 + WIN_H - 4
    local viewH = cBot - cTop

    local curL, curR, maxBottom = 0, 0, 0
    for _, sec in ipairs(activeSec.sectors) do
        local isR = sec.side == "Right"
        local top = isR and curR or curL
        sec._top = top
        local inc = top + (sec._collapsed and 27 or (sec._fullHeight or sec.height)) + 12
        if isR then curR = inc else curL = inc end
        if inc > maxBottom then maxBottom = inc end
    end

    local contentH = (colL.y - cTop) + math.max(maxBottom - 12, 0)
    local maxScroll = math.max(0, contentH - viewH)
    local sc = math.clamp(activeSec.scrollY or 0, 0, maxScroll)
    activeSec.scrollY = sc

    for _, sec in ipairs(activeSec.sectors) do
        local isR = sec.side == "Right"
        local col = isR and colR or colL
        local top = sec._top or 0
        local sy = col.y + top - sc
        local secBot = sy + (sec._collapsed and 27 or (sec._fullHeight or sec.height))
        local vis = secBot > cTop and sy < cBot
        local vy0 = math.max(sy, cTop)
        local vy1 = math.min(secBot, cBot)
        local pt = (hovSector == sec) and 1 or 0
        local pd = pt - (sec._pop or 0)
        if math.abs(pd) < 0.02 then sec._pop = pt else sec._pop = (sec._pop or 0) + pd * 0.25 end
        local po = sec._pop * 4
        sec.outer.Color = colLerp(Color3.fromRGB(38, 38, 44), Color3.fromRGB(58, 60, 68), sec._pop)
        sec.cont.Color = colLerp(Color3.fromRGB(16, 16, 20), Color3.fromRGB(22, 22, 27), sec._pop)
        sec.border.Color = colLerp(Color3.fromRGB(38, 38, 44), Color3.fromRGB(58, 60, 68), sec._pop)
        sec.outer.Visible = vis
        sec.cont.Visible = vis
        sec.border.Visible = vis
        if vis then
            sec.outer.Position = Vector2.new(col.x + po, vy0)
            sec.outer.Size = Vector2.new(COL_LEFT_W, vy1 - vy0)
            sec.cont.Position = Vector2.new(col.x + 1 + po, vy0 + 1)
            sec.cont.Size = Vector2.new(COL_LEFT_W - 2, math.max(1, vy1 - vy0 - 2))
            sec.border.Position = Vector2.new(col.x + po, vy0)
            sec.border.Size = Vector2.new(COL_LEFT_W, vy1 - vy0)
        end
        sec.title.Color = Color3.fromRGB(150, 150, 160)
        sec.title.Position = Vector2.new(col.x + po + 14, sy + 5)

        if sec._colBtn then sec._colBtn.Text = sec._collapsed and "+" or "-"; sec._colBtn.Position = Vector2.new(col.x + po + COL_LEFT_W - 14, sy + 6); sec._colRect = { x = col.x + po + COL_LEFT_W - 16, y = sy + 5, w = 14, h = 14 } end
        local tvis = vis and (sy + 5) >= cTop
        sec.title.Visible = tvis
        sec.bar.Visible = tvis
        if tvis then
            sec.bar.Position = Vector2.new(col.x + po + 7, sy + 7)
            sec.bar.Size = Vector2.new(2, 12)
        end

        local ey = sy + 20
        if sec._collapsed then
            for _, el in ipairs(sec.elements) do
                el.rect = nil
                el.show = false
                _G.__hideEl(el)
            end
        else
        for _, el in ipairs(sec.elements) do
            local elBot = ey + el.h
            local full = ey >= cTop and elBot <= cBot
            el.x = col.x + po
            el.y = ey
            el.w = COL_LEFT_W
            if full then
                el.rect = { x = col.x + po, y = ey, w = COL_LEFT_W, h = el.h }
                el.show = true
                el:draw()
                if el.kb then el.kb.rect.x = col.x + po + COL_LEFT_W - 46 - el.kb.rect.w end
            else
                el.rect = nil
                _G.__hideEl(el)
            end
            ey = elBot
        end
        end
        if vis then
            sec.bounds = { x = col.x, y = vy0, w = COL_LEFT_W, h = vy1 - vy0 }
        else
            sec.bounds = nil
        end
    end

    local bdX = sX0 - 1
    local bdW = COL_W + 2
    local bdY = sY0 - 1
    local bdH = math.max(1, (y0 + WIN_H - 4) - bdY)
    contentBg.Position = Vector2.new(bdX, bdY)
    contentBg.Size = Vector2.new(bdW, bdH)
    contentBd.Position = Vector2.new(bdX, bdY)
    contentBd.Size = Vector2.new(bdW, bdH)

    local sbT = _G.__uiScroll
    if not sbT then
        sbT = {
            track = D("Square", { Filled = true, ZIndex = 8, Rounding = 6, Transparency = 0.2 }),
            thumb = D("Square", { Filled = true, ZIndex = 8, Rounding = 6, Transparency = 0 }),
        }
        _G.__uiScroll = sbT
    end
    if maxScroll > 0.5 and not minimized then
        local sbx = sX0 + COL_W - 6
        local trackY = cTop + 2
        local trackH = math.max(1, viewH - 4)
        local thumbH = math.max(22, trackH * viewH / math.max(contentH, 1))
        if thumbH > trackH then thumbH = trackH end
        local thumbY = trackY + (trackH - thumbH) * (sc / maxScroll)
        local light = _G._bgIsLight
        local trackCol = light and Color3.fromRGB(118, 120, 134)
            or (_G._bgIsBlack and Color3.fromRGB(44, 44, 52)
            or (_G._bgIsPink and Color3.fromRGB(150, 60, 96)
            or (_G._bgIsRed and Color3.fromRGB(96, 28, 36) or Color3.fromRGB(64, 68, 88))))
        local thumbCol
        if light then thumbCol = Color3.fromRGB(62, 66, 92)
        else thumbCol = _G._uiAccent or C_ACC end
        if _G.__uiScrollDrag and not light then thumbCol = Color3.new(1, 1, 1) end
        sbT.track.Visible = true
        sbT.track.Position = Vector2.new(sbx, trackY)
        sbT.track.Size = Vector2.new(6, trackH)
        sbT.track.Color = trackCol
        sbT.thumb.Visible = true
        sbT.thumb.Position = Vector2.new(sbx, thumbY)
        sbT.thumb.Size = Vector2.new(6, thumbH)
        sbT.thumb.Color = thumbCol
        _G.__uiScrollBar = {
            sec = activeSec, x = sbx, trackY = trackY, trackH = trackH,
            thumbY = thumbY, thumbH = thumbH, viewH = viewH, max = maxScroll,
        }
    else
        sbT.track.Visible = false
        sbT.thumb.Visible = false
        _G.__uiScrollBar = nil
    end
end

local m1Prev = false
local function handleClick(mx, my)
    if minRect and inRect(mx, my, minRect.x, minRect.y, minRect.w, minRect.h) then
        minimized = not minimized
        openPopup = nil
        uiSettle = 25
        return
    end
    if xRect and inRect(mx, my, xRect.x, xRect.y, xRect.w, xRect.h) then
        minimized = false
        menuOpen = false
        uiSettle = 25
        return
    end
    if minimized then
        if inRect(mx, my, uiPos.X, uiPos.Y, WIN_W, 44) then
            winDrag = true
            dragOffX = mx - uiPos.X
            dragOffY = my - uiPos.Y
        end
        return
    end
    if openPopup then
        if inRect(mx, my, openPopup.x, openPopup.y, openPopup.w or 228, openPopup.h) then
            local idx = math.floor((my - openPopup.y) / 18) + 1
            if idx >= 1 and idx <= #openPopup.rows then
                local p = openPopup
                if p.owner and (p.owner.kind == "Dropdown" or p.owner.kind == "Combo") then
                    p.owner:select(idx)
                elseif p.kind == "color" and p.owner then
                    p.owner.value.Color = p.rows[idx].color
                    if p.owner.cb then pcall(p.owner.cb, p.owner.value) end
                elseif p.kind == "keybind" and p.owner then
                    p.owner.value.Type = p.rows[idx].txt
                    p.owner.value.Active = true
                    if p.owner.cb then pcall(p.owner.cb, p.owner.value) end
                end
            end
            openPopup = nil
            return true
        else
            if openPopup.owner then openPopup.owner.open = false end
            openPopup = nil
        end
    end

    for i, tb in ipairs(tabHandles) do
        if tb.rect and inRect(mx, my, tb.rect.x, tb.rect.y, tb.rect.w, tb.rect.h) then
            activeTab = i
            openPopup = nil
            return true
        end
    end

    local tab = tabHandles[activeTab]
    if tab then
        for i, sec in ipairs(tab.sections) do
            if sec.rect and inRect(mx, my, sec.rect.x, sec.rect.y, sec.rect.w, sec.rect.h) then
                tab.activeSection = i
                openPopup = nil
                return true
            end
        end
    end

    if tab then
                local activeSec = tab.sections[tab.activeSection]
                if activeSec then
                    for _, sec in ipairs(activeSec.sectors) do
                    end
                    for _, sec in ipairs(activeSec.sectors) do
                        local cr = sec._colRect
                        if cr and inRect(mx, my, cr.x, cr.y, cr.w, cr.h) then
                            sec._collapsed = not sec._collapsed
                            uiSettle = 25
                            openPopup = nil
                            return true
                        end
                    end
                    for _, sec in ipairs(activeSec.sectors) do
                        for _, el in ipairs(sec.elements) do
                    local r = el.rect
                    if r and inRect(mx, my, r.x, r.y, r.w, r.h) then
                        if el.kind == "Toggle" then
                            if el.kb and inRect(mx, my, el.kb.rect.x, el.kb.rect.y, el.kb.rect.w, el.kb.rect.h) then
                                bindingKB = el.kb
                                return true
                            end
                            if el.cl and inRect(mx, my, el.cl.rect.x, el.cl.rect.y, el.cl.rect.w, el.cl.rect.h) then
                                local list = el.cl.isAccent and PRESETS or AP_PRESETS
                                openPopup = { kind = "color", owner = el.cl, x = r.x + r.w - 120, y = r.y, w = 120, h = #list * 18, rows = {} }
                                local cur = el.cl.value.Color
                                for i, pr in ipairs(list) do
                                    local m = math.abs(cur.R - pr[2].R) < 0.01 and math.abs(cur.G - pr[2].G) < 0.01 and math.abs(cur.B - pr[2].B) < 0.01
                                    openPopup.rows[i] = { txt = pr[1], color = pr[2], sel = m }
                                end
                                return true
                            end
                            el:click()
                            return true
                        elseif el.kind == "Dropdown" or el.kind == "Combo" then
                            el.openPopup()
                            return true
                        elseif el.kind == "Slider" then
                            el.dragging = true
                            el:drag(mx)
                            return true
                        elseif el.kind == "Button" then
                            el:click()
                            return true
                        elseif el.kind == "TextBox" then
                            focusTextBox = el
                            return true
                        elseif el.kind == "Scroll" then
                            local boxX = r.x + 9
                            local boxY = r.y + 5
                            if inRect(mx, my, boxX, boxY, r.w - 18, 54) then
                                local idx = el.scroll + math.floor((my - boxY) / 18) + 1
                                el:select(idx)
                            end
                            return true
                        end
                    end
                end
            end
        end
    end

    if inRect(mx, my, uiPos.X, uiPos.Y, WIN_W, minimized and 44 or WIN_H) then
        winDrag = true
        dragOffX = mx - uiPos.X
        dragOffY = my - uiPos.Y
        return true
    end
    return false
end

local m2Prev = false
local function handleRightClick(mx, my)
    if openPopup then
        openPopup = nil
        return true
    end
    local tab = tabHandles[activeTab]
    if not tab then return false end
    local activeSec = tab.sections[tab.activeSection]
    if not activeSec then return false end
    for _, sec in ipairs(activeSec.sectors) do
        for _, el in ipairs(sec.elements) do
            if el.kind == "Toggle" and el.rect and el.kb and el.kb.rect and inRect(mx, my, el.kb.rect.x, el.kb.rect.y, el.kb.rect.w, el.kb.rect.h) then
                openPopup = { kind = "keybind", owner = el.kb, x = math.min(el.kb.rect.x, uiPos.X + WIN_W - 124), y = el.kb.rect.y, w = 120, h = 54, rows = {} }
                local types = { "Always", "Hold", "Toggle" }
                for i, t in ipairs(types) do
                    openPopup.rows[i] = { txt = t, sel = el.kb.value.Type == t }
                end
                return true
            end
        end
    end
    return false
end

local conn
conn = RunService.RenderStepped:Connect(function()
    if not running or GEN ~= _G_._genGEN then
        conn:Disconnect()
        return
    end

    local m = nil
    if lp then pcall(function() m = lp:GetMouse() end) end

    local mx, my = 0, 0
    if m then mx, my = m.X, m.Y end
    if _G.__fallUpdate then _G.__fallUpdate(uiPos.X, uiPos.Y, WIN_W, minimized and 44 or WIN_H, 1) end

    local _splashAgain = (_G.__splashActive == true) or (_G.__splashWaiting == true) or (_G.__splashEnd ~= nil and tick() < _G.__splashEnd + 0.6)
    if menuFade <= 0.01 then
        for _, tb in ipairs(tabHandles or {}) do
            for _, sec in ipairs(tb.sections or {}) do
                for _, sector in ipairs(sec.sectors or {}) do
                    if sector._colBtn then sector._colBtn.Visible = false end
                    if sector._infoBtn then sector._infoBtn.Visible = false end
                end
            end
        end
    end
    local fadeTgt = (menuOpen and _G._genLoaded and not _splashAgain) and 1 or 0
    -- if _G.__splashUpdate then _G.__splashUpdate(uiPos.X, uiPos.Y, WIN_W, minimized and 44 or WIN_H) end
    if _splashAgain then menuFade = 0 end
    if menuFade ~= fadeTgt then
        menuFade = menuFade + math.clamp(fadeTgt - menuFade, -0.12, 0.12)
        if math.abs(menuFade - fadeTgt) < 0.005 then menuFade = fadeTgt end
        applyMenuFade()
        uiSettle = 3
    end

    _G.__bbUpdate(uiPos.X, uiPos.Y, WIN_W, minimized and 44 or WIN_H, menuFade, mx, my)
    _G.__animUpdate(uiPos.X, uiPos.Y, WIN_W, minimized and 44 or WIN_H, menuFade)

    _G.__fallUpdate(uiPos.X, uiPos.Y, WIN_W, minimized and 44 or WIN_H, menuFade)

    if (menuOpen and _G._genLoaded and not _splashAgain) or menuFade > 0.001 then
        gShow = true
        local m1 = ismouse1pressed()
        local m2 = ismouse2pressed()
        local moved = (mx ~= _lmx or my ~= _lmy)
        _lmx, _lmy = mx, my
        local pressedEdge = (m1 ~= _pm1) or (m2 ~= _pm2)
        _pm1, _pm2 = m1, m2
        if menuOpen ~= _lOpen then uiSettle = 25; _lOpen = menuOpen end
        if uiSettle > 0 then uiSettle = uiSettle - 1 end
        if moved then uiSettle = 6 end
        if pressedEdge or winDrag or openPopup then uiSettle = 25 end
        if uiSettle <= 0 and not moved and not winDrag then
            return
        end

        if menuOpen then
        hovEl, hovKB, hovSwatch, hovTab, hovSec, hovRow, hovSector = nil, nil, nil, nil, nil, nil, nil
        if openPopup and inRect(mx, my, openPopup.x, openPopup.y, openPopup.w or 228, openPopup.h) then
            hovRow = math.floor((my - openPopup.y) / 18) + 1
        else
            for _, tb in ipairs(tabHandles) do
                if tb.rect and inRect(mx, my, tb.rect.x, tb.rect.y, tb.rect.w, tb.rect.h) then hovTab = tb end
            end
            local tab = tabHandles[activeTab]
            if tab then
                for _, sec in ipairs(tab.sections) do
                    if sec.rect and inRect(mx, my, sec.rect.x, sec.rect.y, sec.rect.w, sec.rect.h) and sec.txt.Visible then hovSec = sec end
                end
                local activeSec = tab.sections[tab.activeSection]
                if activeSec then
                    for _, sec in ipairs(activeSec.sectors) do
                        if sec.bounds and inRect(mx, my, sec.bounds.x, sec.bounds.y, sec.bounds.w, sec.bounds.h) then
                            hovSector = sec
                        end
                        for _, el in ipairs(sec.elements) do
                            if el.rect and inRect(mx, my, el.rect.x, el.rect.y, el.rect.w, el.rect.h) then
                                hovEl = el
                                if el.kb and inRect(mx, my, el.kb.rect.x, el.kb.rect.y, el.kb.rect.w, el.kb.rect.h) then
                                    hovKB = el.kb
                                end
                                if el.cl and inRect(mx, my, el.cl.rect.x, el.cl.rect.y, el.cl.rect.w, el.cl.rect.h) then
                                    hovSwatch = el.cl
                                end
                                if el.kind == "Scroll" then
                                    hovRow = el.scroll + math.floor((my - (el.rect.y + 5)) / 18) + 1
                                end
                            end
                        end
                    end
                end
            end
        end

        if m1 and not m1Prev then
            local sb = _G.__uiScrollBar
            if sb and sb.max > 0 and mx >= sb.x - 4 and mx <= sb.x + 8
                and my >= sb.trackY and my <= sb.trackY + sb.trackH then
                local off = my - sb.thumbY
                if off < 0 or off > sb.thumbH then off = sb.thumbH * 0.5 end
                _G.__uiScrollDrag = { off = off }
                openPopup = nil
                uiSettle = 30
            else
                handleClick(mx, my)
            end
        end
        if m2 and not m2Prev then
            handleRightClick(mx, my)
        end
        m1Prev, m2Prev = m1, m2

        local sdrag = _G.__uiScrollDrag
        if sdrag then
            if m1 then
                local sb = _G.__uiScrollBar
                if sb and sb.max > 0 then
                    local span = sb.trackH - sb.thumbH
                    local frac = span > 0 and math.clamp((my - sdrag.off - sb.trackY) / span, 0, 1) or 0
                    sb.sec.scrollY = frac * sb.max
                    uiSettle = 20
                end
            else
                _G.__uiScrollDrag = nil
            end
        end

        if m1 then
            for _, tb in ipairs(tabHandles) do
                if tb.tabNum == activeTab then
                    local activeSec = tb.sections[tb.activeSection]
                    if activeSec then
                        for _, sec in ipairs(activeSec.sectors) do
                            for _, el in ipairs(sec.elements) do
                                if el.dragging and el.kind == "Slider" then el:drag(mx) end
                            end
                        end
                    end
                end
            end
        else
            for _, tb in ipairs(tabHandles) do
                if tb.tabNum == activeTab then
                    local activeSec = tb.sections[tb.activeSection]
                    if activeSec then
                        for _, sec in ipairs(activeSec.sectors) do
                            for _, el in ipairs(sec.elements) do
                                if el.dragging then el.dragging = false end
                            end
                        end
                    end
                end
            end
        end

        if winDrag then
            uiPos = Vector2.new(mx - dragOffX, math.max(0, my - dragOffY))
        end
        if not m1 then winDrag = false end
        end
        winBg.Visible = true
        winBd.Visible = true
        _G.__hdrBg.Visible = true
        _G.__hdrBd.Visible = true
        _G.__hdrMark.Visible = true
        _G.__sideSep.Visible = true
        for _, seg in ipairs(titleSepSegs) do seg.Visible = true end
        titleGlow.Visible = true
        titleGlowCore.Visible = true
        contentBg.Visible = true
        contentBd.Visible = true
        titleTxt.Visible = true
        railBd.Visible = true
        avRing.Visible = false
        avImg.Visible = false
        avName.Visible = false
        for _, tb in ipairs(tabHandles) do
            tb.btnBg.Visible = true
            for _, g in ipairs(tb.icon) do g.Visible = true end
            tb.lbl.Visible = true
            local isActiveTab = tb.tabNum == activeTab
            local activeSec = isActiveTab and tb.sections[tb.activeSection]
            for _, sec in ipairs(tb.sections) do
                sec.txt.Visible = isActiveTab
                    local showSec = isActiveTab
                    sec.txt.Visible = showSec
                if sec.ind and not (isActiveTab and sec == activeSec) then sec.ind.Visible = false end
                local ulVis = isActiveTab and sec == activeSec
                sec.pill.Visible = ulVis and showSec
                sec.accBar.Visible = ulVis and showSec
                for _, seg in ipairs(sec.ulSegs) do seg.Visible = ulVis and showSec end
                 
                for _, sector in ipairs(sec.sectors) do
                    local svis = isActiveTab and sec == activeSec and not (_G.__splashActive == true or _G.__splashWaiting == true or (_G.__splashEnd ~= nil and tick() < _G.__splashEnd + 0.6))
                    sector.outer.Visible = svis
                    sector.cont.Visible = svis
                    sector.border.Visible = svis
                    sector.bar.Visible = svis
                    sector.title.Visible = svis

                    if sector._colBtn then sector._colBtn.Visible = svis end
                    for _, el in ipairs(sector.elements) do
                        if not svis and el.show ~= false then
                            el.show = false
                            for _, p in ipairs(el.parts or {}) do p.Visible = false end
                            if el.kb then el.kb.txt.Visible = false; el.kb.bg.Visible = false end
                            if el.cl then el.cl.swatch.Visible = false end
                            if el.rows then
                                for _, r in ipairs(el.rows) do r.bg.Visible = false; r.tx.Visible = false; r.dec.Visible = false end
                            end
                        else
                            el.show = svis
                        end
                    end
                end
            end
        end

        layout()

        if minimized then
            _G.__uiScrollBar = nil
            _G.__uiScrollDrag = nil
            if _G.__uiScroll then _G.__uiScroll.track.Visible = false; _G.__uiScroll.thumb.Visible = false end
            contentBg.Visible = false
            contentBd.Visible = false
            railBd.Visible = false
            avRing.Visible = false
            avImg.Visible = false
            avName.Visible = false
            titleGlow.Visible = true
            titleGlowCore.Visible = true
            for _, tb in ipairs(tabHandles) do
                tb.btnBg.Visible = false
                for _, g in ipairs(tb.icon) do g.Visible = false end
                tb.lbl.Visible = false
                if tb.img then tb.img.Visible = false end
                for _, sec in ipairs(tb.sections) do
                    sec.txt.Visible = false
                    if sec.ind then sec.ind.Visible = false end
                    sec.pill.Visible = false
                    sec.accBar.Visible = false
                    for _, seg2 in ipairs(sec.ulSegs) do seg2.Visible = false end
                    for _, sector in ipairs(sec.sectors) do
                        sector.outer.Visible = false
                        sector.cont.Visible = false
                        sector.border.Visible = false
                        sector.bar.Visible = false
                        sector.title.Visible = false
                        if sector._colBtn then sector._colBtn.Visible = false end

                        for _, el in ipairs(sector.elements) do
                            if el.show ~= false then
                                el.show = false
                                for _, pp in ipairs(el.parts or {}) do pp.Visible = false end
                                if el.kb then el.kb.txt.Visible = false; el.kb.bg.Visible = false end
                                if el.cl then el.cl.swatch.Visible = false end
                                if el.rows then
                                    for _, r in ipairs(el.rows) do r.bg.Visible = false; r.tx.Visible = false; r.dec.Visible = false end
                                end
                            end
                        end
                    end
                end
            end
        end

        renderPopup()
    else
        _pm1, _pm2 = nil, nil
        _G.__uiScrollBar = nil
        _G.__uiScrollDrag = nil
        if _G.__uiScroll then _G.__uiScroll.track.Visible = false; _G.__uiScroll.thumb.Visible = false end
        if gShow then
            gShow = false
            winBg.Visible = false
            winBd.Visible = false
            _G.__hdrBg.Visible = false
            _G.__hdrBd.Visible = false
            _G.__hdrMark.Visible = false
            _G.__sideSep.Visible = false
            for _, seg in ipairs(titleSepSegs) do seg.Visible = false end
            titleGlow.Visible = false
            titleGlowCore.Visible = false
            contentBg.Visible = false
            contentBd.Visible = false
            titleTxt.Visible = false
            minBtn.Visible = false
            xBtn.Visible = false
            railBd.Visible = false
            avRing.Visible = false
            avImg.Visible = false
            avName.Visible = false
        for _, tb in ipairs(tabHandles) do
            tb.btnBg.Visible = false
            for _, g in ipairs(tb.icon) do g.Visible = false end
            tb.lbl.Visible = false
            if tb.img then tb.img.Visible = false end
            for _, sec in ipairs(tb.sections) do
                sec.txt.Visible = false
                if sec.ind then sec.ind.Visible = false end
                sec.pill.Visible = false
                sec.accBar.Visible = false
                for _, seg in ipairs(sec.ulSegs) do seg.Visible = false end
                for _, sector in ipairs(sec.sectors) do
                    sector.outer.Visible = false
                    sector.cont.Visible = false
                    sector.border.Visible = false
                    sector.bar.Visible = false
                    sector.title.Visible = false
                    for _, el in ipairs(sector.elements) do
                        el.show = false
                        el:draw()
                    end
                end
            end
        end
        renderPopup()
        end
    end
end)

local keyPrev = {}
local insertVK = nameToVK["Insert"]
local insertPrev = false

task.spawn(function()
    while running and GEN == _G_._genGEN do
        pcall(function()
        local ins = false
        local uiVK = _G._genUIKey or insertVK
        pcall(function() ins = iskeypressed(uiVK) end)
        if ins and not insertPrev then
            menuOpen = not menuOpen
        end
        insertPrev = ins

        if bindingKB then
            for _, vk in ipairs(commonVKs) do
                local down = false
                pcall(function() down = iskeypressed(vk) end)
                if down and not keyPrev[vk] then
                    if vk == nameToVK["Escape"] then
                        bindingKB.value.Key = nil
                    else
                        bindingKB.value.Key = vk
                    end
                    bindingKB.value.Active = true
                    if bindingKB.cb then pcall(bindingKB.cb, bindingKB.value) end
                        bindingKB = nil
                    break
                end
                keyPrev[vk] = down
            end
        elseif focusTextBox then
            for _, vk in ipairs(commonVKs) do
                local down = false
                pcall(function() down = iskeypressed(vk) end)
                if down and not keyPrev[vk] then
                    if vk == nameToVK["Enter"] or vk == nameToVK["Escape"] then
                        focusTextBox = nil
                    elseif vk == nameToVK["Backspace"] then
                        local txt = focusTextBox.value.Text or ""
                        focusTextBox.value.Text = txt:sub(1, #txt - 1)
                    else
                        local ch = vkChar(vk)
                        if ch and #(focusTextBox.value.Text or "") < 60 then
                            focusTextBox.value.Text = (focusTextBox.value.Text or "") .. ch
                        end
                    end
                    if focusTextBox and focusTextBox.cb then pcall(focusTextBox.cb, focusTextBox.value) end
                    break
                end
                keyPrev[vk] = down
            end
        else
            if menuOpen and not minimized then
                local sb = _G.__uiScrollBar
                if sb and sb.max > 0 then
                    local d = 0
                    if _G.__kdown(nameToVK["PageDown"]) then d = 36
                    elseif _G.__kdown(nameToVK["PageUp"]) then d = -36
                    elseif _G.__kdown(nameToVK["Down"]) then d = 18
                    elseif _G.__kdown(nameToVK["Up"]) then d = -18
                    elseif _G.__kdown(nameToVK["Home"]) then d = -1e9
                    elseif _G.__kdown(nameToVK["End"]) then d = 1e9
                    end
                    if d ~= 0 then
                        local now = tick()
                        if now - (_G.__uiScrollKeyT or 0) > 0.12 then
                            _G.__uiScrollKeyT = now
                            sb.sec.scrollY = math.clamp((sb.sec.scrollY or 0) + d, 0, sb.max)
                            uiSettle = 20
                        end
                    end
                end
            end
            for _, tb in ipairs(tabHandles) do
                for _, sec in ipairs(tb.sections) do
                    for _, sector in ipairs(sec.sectors) do
                        for _, el in ipairs(sector.elements) do
                            if el.kb and el.kb.value.Key then
                                local k = el.kb.value.Key
                                local down = false
                                pcall(function() down = iskeypressed(k) end)
                                local v = el.kb.value
                                local was = kbHeld[el.kb]
                                if v.Type == "Always" then
                                    v.Active = true
                                elseif v.Type == "Hold" then
                                    v.Active = down
                                    if down and not was then
                                        if el.kb.cb then pcall(el.kb.cb, v) end
                                        if el.kb.toggleElement and el.click then el:click() end
                                    end
                                elseif v.Type == "Toggle" then
                                    if down and not was then
                                        v.Active = not v.Active
                                        if el.kb.cb then pcall(el.kb.cb, v) end
                                        if el.kb.toggleElement and el.click then el:click() end
                                    end
                                end
                                kbHeld[el.kb] = down
                            end
                        end
                    end
                end
            end
        end
        end)
        task.wait(0.03)
    end
end)

task.spawn(function()
    while running and GEN == _G_._genGEN do
        pcall(function()
        local files = listCfg(CFG_DIR)
        for _, tb in ipairs(tabHandles) do
            for _, sec in ipairs(tb.sections) do
                for _, sector in ipairs(sec.sectors) do
                    for _, el in ipairs(sector.elements) do
                        if el.kind == "Scroll" then
                            for _, f in ipairs(files) do el:add_value(f) end
                        end
                    end
                end
            end
        end
        end)
        task.wait(1)
    end
end)

-- Extra UI motion helpers (safe, behind-boxes friendly)
_G.__tabUlX = _G.__tabUlX or nil
do
    if not _G.__tabUnderline then
        _G.__tabUnderline = D("Square", { Filled = true, Color = C_ACC, Transparency = 0.1, Size = Vector2.new(TB_W - 14, 2), ZIndex = 6, Visible = false })
    end
end
_G.__animUpdate = function(x0, y0, w, h, fade)
    local a = math.clamp(fade or 0, 0, 1)
    if a <= 0.01 then
        if _G.__tabUnderline then _G.__tabUnderline.Visible = false end
        if avRing then avRing.Transparency = 1 end
        _G.__animLast = nil
        return
    end
    local now = tick()
    local last = _G.__animLast
    local dt = last and math.min(now - last, 0.1) or 0.016
    _G.__animLast = now

    local u = _G.__tabUnderline
    local tb = tabHandles and activeTab and tabHandles[activeTab]
    if u and tb and tb.rect then
        local ulW = TB_W - 10
        local tgt = tb.rect.x + (TB_W - ulW) / 2
        _G.__tabUlX = _G.__tabUlX or tgt
        _G.__tabUlX = _G.__tabUlX + (tgt - _G.__tabUlX) * math.min(1, dt * 10)
        u.Position = Vector2.new(_G.__tabUlX, tb.rect.y + tb.rect.h + 3)
        u.Size = Vector2.new(TB_W - 10, 2)
        u.Color = C_ACC
        u.Transparency = 1 - (1 - 0.25) * a
        u.Visible = true
    elseif u then u.Visible = false end

    if avRing then
        avRing.Radius = 13
    end
end
-- Ambient and edge waves removed by user request
_G.__particles = nil
_G.__edgeWaves = nil
_G.__animExtra = function(x0, y0, w, h, fade) return end
-- Ambient falling particles (30) top-to-bottom drift
_G.__fallStart = tick()
do
    local ps = {}
    for i = 1, 60 do
        ps[i] = {
            d = D("Square", { Filled = true, Color = C_ACC, Transparency = 0.6, Size = Vector2.new(1.8, 1.8), ZIndex = 3, Visible = false }),
            rx = math.random() * 1000,
            ry = math.random() * 1000,
            vx = (math.random() - 0.5) * 0.6,
            vy = 20 + math.random() * 40,
            scale = 0.3 + math.random() * 2.2,
            phase = math.random() * math.pi * 2,
        }
    end
    _G.__fallParticles = ps
end
_G.__fallUpdate = function(x0, y0, w, h, fade)
    local a = math.clamp(fade or 0, 0, 1)
    if a <= 0.01 then
        for _, p in ipairs(_G.__fallParticles or {}) do if p.d then p.d.Visible = false end end
        _G.__fallLast = nil
        return
    end
    local now = tick()
    local last = _G.__fallLast
    local dt = last and math.min(now - last, 0.1) or 0.016
    _G.__fallLast = now
    for _, p in ipairs(_G.__fallParticles or {}) do
        p.vy = math.min(p.vy + dt * 8, 70)
        p.rx = p.rx + p.vx * dt
        p.ry = p.ry + p.vy * dt
        if p.rx < 0 then p.rx = w end
        if p.rx > w then p.rx = 0 end
        if p.ry > h then
            p.ry = 0 + math.random() * 20
            p.vy = 20 + math.random() * 40
            p.rx = math.random() * w
        end
        p.d.Color = colLerp(C_ACC, C_UL, 0.5 + 0.5 * math.sin(now * 0.4 + p.phase))
        p.d.Position = Vector2.new(x0 + p.rx, y0 + p.ry)
        p.d.Size = Vector2.new(p.scale * 2.0, p.scale * 2.0)
        p.d.Transparency = 1 - (0.5 * a)
        p.d.Visible = true
    end
end

_G_._genToken = {
    unload = function()
        running = false
        if conn then pcall(function() conn:Disconnect() end) end
        for _, d in ipairs(allD) do pcall(function() d:Remove() end) end
        _G_._genToken = nil
    end,
}

_G.GenDbg = {
    state = function()
        local out = {}
        out.activeTab = activeTab
        out.uiPos = { uiPos.X, uiPos.Y }
        out.drawings = #allD
        out.winBorder = (winBd._parts and winBd._parts[1].Visible) or false
        out.contentBd = (contentBd._parts and contentBd._parts[1].Visible) or false
        out.contentRect = contentBd._rect and { contentBd._rect[1], contentBd._rect[2], contentBd._rect[3], contentBd._rect[4] } or {}
        out.tabs = {}
        for i, tb in ipairs(tabHandles) do
            out.tabs[i] = { activeSection = tb.activeSection, sections = #tb.sections }
        end
        local tb = tabHandles[activeTab]
        if tb then
            local sec = tb.sections[tb.activeSection]
            out.activeSectionName = sec and sec.name
            if sec then
                out.sectors = {}
                for _, s in ipairs(sec.sectors) do
                    local bvis = false
                    local bpos = { 0, 0 }
                    if s.border and s.border._parts then
                        bvis = s.border._parts[1].Visible
                        local r = s.border._rect
                        bpos = { r[1], r[2] }
                    end
                    out.sectors[#out.sectors + 1] = {
                        name = s.name, h = s.height, side = s.side,
                        outerVis = s.outer.Visible,
                        outerPos = { s.outer.Position.X, s.outer.Position.Y },
                        outerSize = { s.outer.Size.X, s.outer.Size.Y },
                        titleVis = s.title.Visible,
                        borderVis = bvis,
                        borderPos = bpos,
                    }
                end
            end
        end
        return out
    end,
    simDrag = function(x, y)
        local tab = tabHandles[activeTab]
        if not tab then return "no tab" end
        local activeSec = tab.sections[tab.activeSection]
        if not activeSec then return "no section" end
        for _, sec in ipairs(activeSec.sectors) do
            for _, el in ipairs(sec.elements) do
                if el.kind == "Slider" and el.rect and inRect(x, y, el.rect.x, el.rect.y, el.rect.w, el.rect.h) then
                    el.dragging = true
                    local okd, errd = pcall(function() el:drag(x) end)
                    if not okd then
                        return "drag ERROR: " .. tostring(errd)
                            .. " | x=" .. tostring(x) .. "(" .. typeof(x) .. ")"
                            .. " | el.x=" .. tostring(el.x) .. "(" .. typeof(el.x) .. ")"
                            .. " | el.min=" .. tostring(el.min) .. " | el.max=" .. tostring(el.max)
                    end
                    return "hit " .. el.text .. " -> " .. tostring(el.value.Slider)
                end
            end
        end
        return "no slider at " .. tostring(x) .. "," .. tostring(y)
    end,
    sliderValues = function()
        local out = {}
        local tab = tabHandles[activeTab]
        if not tab then return out end
        local activeSec = tab.sections[tab.activeSection]
        if not activeSec then return out end
        for _, sec in ipairs(activeSec.sectors) do
            for _, el in ipairs(sec.elements) do
                if el.kind == "Slider" then
                    out[#out + 1] = { name = el.text, val = el.value.Slider, x = math.floor(el.x), y = math.floor(el.y), rect = { el.rect.x, el.rect.y, el.rect.w, el.rect.h } }
                end
            end
        end
        return out
    end,
    setTab = function(i)
        if tabHandles[i] then activeTab = i end
    end,
    openDD = function(label)
        local tab = tabHandles[activeTab]
        if not tab then return "no tab" end
        local activeSec = tab.sections[tab.activeSection]
        if not activeSec then return "no sec" end
        for _, sec in ipairs(activeSec.sectors) do
            for _, el in ipairs(sec.elements) do
                if (el.kind == "Dropdown" or el.kind == "Combo") and (label == nil or el.text == label) then
                    el.openPopup()
                    return "opened"
                end
            end
        end
        return "no dropdown"
    end,
    setOpen = function(b)
        menuOpen = b and true or false
        return menuOpen
    end,
    visSample = function()
        local out = { menuOpen = menuOpen }
        local tb = tabHandles[activeTab]
        if not tb then return out end
        local sec = tb.sections[tb.activeSection]
        if not sec then return out end
        for _, s in ipairs(sec.sectors) do
            for _, el in ipairs(s.elements) do
                out[#out + 1] = {
                    text = el.text, show = tostring(el.show),
                    labVis = el.lab and el.lab.Visible,
                    boxVis = el.box and el.box.Visible,
                    kbVis = el.kb and el.kb.txt.Visible,
                }
                if #out >= 6 then return out end
            end
        end
        return out
    end,
    popState = function()
        local out = {}
        if not openPopup then return { open = false } end
        out.open = true
        for i = 1, #openPopup.rows do
            local pr = popRows[i]
            out[#out + 1] = { txt = tostring(pr.tx.Text), vis = tostring(pr.tx.Visible), z = tostring(pr.tx.ZIndex) }
        end
        return out
    end,
    findEl = function(label)
        local res = {}
        for _, tb in ipairs(tabHandles) do
            for _, sec in ipairs(tb.sections) do
                for _, sector in ipairs(sec.sectors) do
                    for _, el in ipairs(sector.elements) do
                        if el.text == label or (el.kind == "Dropdown" and el.value and el.value.Dropdown) then
                            if el.kind == "Dropdown" then
                                res[#res + 1] = {
                                    text = el.text, kind = el.kind,
                                    val = tostring(el.value and el.value.Dropdown),
                                    x = el.x, y = el.y, show = tostring(el.show),
                                    btnTxt = tostring(el.btnTxt and el.btnTxt.Text),
                                    btnVis = tostring(el.btnTxt and el.btnTxt.Visible),
                                    btnPos = el.btnTxt and (el.btnTxt.Position.X .. "," .. el.btnTxt.Position.Y) or "none",
                                }
                            end
                        end
                    end
                end
            end
        end
        return res
    end,
}

_G.GenLib = library

end

do
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local hs = game:GetService("HttpService")
local lp = Players.LocalPlayer
local remyCodes = { 70 }
local remyHasMouse = false
local remyLabel = "F"
local abilityCodes = { 81 }
local abilityReadyAt = 0
local CFG_FILE = "remybb-circle-config.json"
local TAU = math.pi * 2
local DN = 18

local realKeypress = _G.__apRealKeypress or keypress
local realKeyrelease = _G.__apRealKeyrelease or keyrelease
_G.__apRealKeypress = realKeypress
_G.__apRealKeyrelease = realKeyrelease
pcall(function() _G.keypress = function() end end)
pcall(function() _G.keyrelease = function() end end)

_G.__apGen = (_G.__apGen or 0) + 1
local bob = _G.__apGen

_G.__apTapState = _G.__apTapState or {}
local remy = _G.__apTapState
remy.recentlyTapped = remy.recentlyTapped or {}
remy.tapping = remy.tapping or false
remy.lastTap = remy.lastTap or 0

_G.__apUserF = _G.__apUserF or 0

_G.autoParry = _G.autoParry or {}
local lala = _G.autoParry
lala.v2 = true
lala.leadTime = 0.22
lala.pingComp = true
lala.pingTiers = { 30, 50, 70, 120, 170 }
lala.pingLead = { 0.34, 0.38, 0.44, 0.52, 0.58, 0.64 }
lala.pingMax = 0.5
lala.customLeadMode = false
lala.customLeadValue = 0.10
lala.minDist = 16
lala.maxDist = 400
lala.panicBase = 28
lala.panicSpeedMul = 0.08
lala.cooldown = 0.05
lala.userSuppress = 0
lala.maxSpeed = 2000
lala.fastBallThreshold = 120
lala.closeRangeDist = 14
lala.facingMin = -0.35
lala.customFacingMinMode = false
lala.customFacingMinValue = -0.35
lala.showVis = false
    lala.spin = false
    lala.spinSpeed = 45
lala.clash = false
lala.keyP = lala.keyP or 80
lala.keyX = lala.keyX or 88
lala.keyL = lala.keyL or 76
lala.keyB = lala.keyB or 66
lala.keyR = lala.keyR or 82
lala.keyN = lala.keyN or 78
lala.keyT = lala.keyT or 84
lala.keySmart = lala.keySmart or 77
lala.keyPanic = lala.keyPanic or 75
lala.accuracy = 100
lala.randomize = false
lala.randMin = 20
lala.randMax = 100
lala.bvExtras = false
lala.keybindsHud = false
lala.viewMode = "Circle"
lala.viewEnabled = true
lala.infinityAvoid = true
lala.curveOnHit = false
lala.curveDir = "Left"
lala.keyY = lala.keyY or 89
lala.curvePreTurn = true
lala.curveFast = false
if type(lala.curveRandomSet) ~= "table" then lala.curveRandomSet = { "Left", "Right", "Up", "Back", "Back Up", "Back Down", "Back Left", "Back Right", "Left Up", "Left Down", "Right Up", "Right Down" } end
lala.curveRandom = false
lala.curveNoRepeat = false
lala.curveStrength = 100
local __curveRandDirs = { "Left", "Right", "Up", "Back", "Back Up", "Back Down", "Back Left", "Back Right", "Left Up", "Left Down", "Right Up", "Right Down" }
for _, __d in ipairs(__curveRandDirs) do lala["curveRand_" .. __d:gsub(" ", "")] = lala["curveRand_" .. __d:gsub(" ", "")] ~= false end
lala.accSpeedBoostOn = false
lala.singularityV1AutoTrigger = true
lala.dualityAutoTrigger = true
lala.infAutoTrigger = true
lala.infAutoTriggerDist = 30
-- Track Singularity v1 / Infinity use via the AbilityActive attribute (10 Hz).
-- Each player's equipped ability is cached for 1s, and AbilityActive is only read for
-- players who actually have one of the enabled abilities equipped.
task.spawn(function()
    local prev = {}
    local abiCache = {}
    local abiAt = {}
    local Players = game:GetService("Players")
    while bob == _G.__apGen do
        local wantSing = lala.singularityV1AutoTrigger == true
        local wantInf = lala.infAutoTrigger == true
        if wantSing or wantInf then
            pcall(function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    local now = tick()
                    local key = tostring(plr.UserId)
                    local ch = plr.Character
                    local abi = abiCache[key]
                    if ch and (not abi or now - (abiAt[key] or 0) > 1.0) then
                        abi = plr:GetAttribute("CurrentlyEquippedAbility")
                        abiCache[key] = abi
                        abiAt[key] = now
                    end
                    local relevant = ch and abi and
                        ((wantSing and abi == "Singularity") or (wantInf and abi == "Infinity"))
                    if relevant then
                        local act = ch:GetAttribute("AbilityActive")
                        if act == true and prev[key] ~= true then
                            if abi == "Singularity" then
                                local up = plr:FindFirstChild("Upgrades")
                                local iv = up and up:FindFirstChild("Singularity")
                                local lvl = (iv and iv.Value or 0)
                                if lvl <= 1 then
                                    _G.__singAutoTarget = _G.__singAutoTarget or {}
                                    _G.__singAutoTarget[key] = now
                                end
                            elseif abi == "Infinity" then
                                _G.__infAutoTarget = _G.__infAutoTarget or {}
                                _G.__infAutoTarget[key] = now
                            end
                        end
                        prev[key] = act
                    else
                        prev[key] = nil
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)
lala.abilityParry = true
lala.smartParry = false
lala.panicParry = true
lala.triggerbot = false
lala.triggerOnce = false
lala.apColor = { r = 0, g = 255, b = 120 }
lala.apThick = 2
lala.apTrans = 5
lala.pdColor = { r = 255, g = 0, b = 0 }
lala.pdThick = 3
lala.pdTrans = 15

local function buildSaveData()
    return {
        keyP = lala.keyP or 0, keyX = lala.keyX or 0, keyL = lala.keyL or 0, keyB = lala.keyB or 0, keyR = lala.keyR or 0, keyN = lala.keyN or 0,
        v2 = lala.v2, showVis = lala.showVis, viewMode = lala.viewMode, spin = lala.spin, spinSpeed = lala.spinSpeed, clash = lala.clash,
        triggerbot = lala.triggerbot,
        triggerOnce = lala.triggerOnce,
        remyCodes = remyCodes, remyHasMouse = remyHasMouse, remyLabel = remyLabel,
        abilityParry = lala.abilityParry,
        smartParry = lala.smartParry,
        panicParry = lala.panicParry,
        customLeadMode = lala.customLeadMode,
        customLeadValue = lala.customLeadValue,
        customFacingMinMode = lala.customFacingMinMode,
        customFacingMinValue = lala.customFacingMinValue,
        curveOnHit = lala.curveOnHit,
        curveDir = lala.curveDir,
        curvePreTurn = lala.curvePreTurn,
        curveRandom = lala.curveRandom,
        curveRandomSet = lala.curveRandomSet,
        curveFast = lala.curveFast,
        curveNoRepeat = lala.curveNoRepeat,
        curveStrength = lala.curveStrength,
        accuracy = lala.accuracy,
        randomize = lala.randomize,
        minDist = lala.minDist, maxDist = lala.maxDist, closeRangeDist = lala.closeRangeDist,
        panicBase = lala.panicBase, panicSpeedMul = lala.panicSpeedMul,
            randMin = lala.randMin, randMax = lala.randMax,
        infinityAvoid = lala.infinityAvoid,
        singularityDetect = lala.singularityDetect,
        keyT = lala.keyT or 0,
        keySmart = lala.keySmart or 0,
keyY = lala.keyY or 0,
        keyPanic = lala.keyPanic or 0,
        apColor = lala.apColor, apThick = lala.apThick, apTrans = lala.apTrans,
        pdColor = lala.pdColor, pdThick = lala.pdThick, pdTrans = lala.pdTrans,
    }
end

local function saveConfig()
    pcall(function()
        writefile(CFG_FILE, hs:JSONEncode(buildSaveData()))
    end)
end

local function applyConfig(data)
    if type(data) ~= "table" then return end
        if data.keyP ~= nil then lala.keyP = data.keyP == 0 and nil or data.keyP end
        if data.keyX ~= nil then lala.keyX = data.keyX == 0 and nil or data.keyX end
        if data.keyL ~= nil then lala.keyL = data.keyL == 0 and nil or data.keyL end
        if data.keyB ~= nil then lala.keyB = data.keyB == 0 and nil or data.keyB end
        if data.keyR ~= nil then lala.keyR = data.keyR == 0 and nil or data.keyR end
        if type(data.accuracy) == "number" then lala.accuracy = math.clamp(data.accuracy, 1, 100) end
        if type(data.randomize) == "boolean" then lala.randomize = data.randomize end
if type(data.accSpeedBoostOn) == "boolean" then lala.accSpeedBoostOn = data.accSpeedBoostOn end
        if type(data.minDist) == "number" then lala.minDist = math.clamp(data.minDist, 1, 100) end
        if type(data.maxDist) == "number" then lala.maxDist = math.clamp(data.maxDist, 50, 2000) end
        if type(data.panicBase) == "number" then lala.panicBase = math.clamp(data.panicBase, 5, 100) end
        if type(data.panicSpeedMul) == "number" then lala.panicSpeedMul = math.clamp(data.panicSpeedMul, 0.001, 0.2) end
        if type(data.randMin) == "number" then lala.randMin = math.clamp(data.randMin, 1, 99) end
        if type(data.randMax) == "number" then lala.randMax = math.clamp(data.randMax, 2, 100) end
        if type(data.bvExtras) == "boolean" then lala.bvExtras = data.bvExtras end
        if type(data.infinityAvoid) == "boolean" then lala.infinityAvoid = data.infinityAvoid end
        if type(data.singularityDetect) == "boolean" then lala.singularityDetect = data.singularityDetect end
        if type(data.v2) == "boolean" then lala.v2 = data.v2 end
        if type(data.showVis) == "boolean" then lala.showVis = data.showVis end
        if type(data.keybindsHud) == "boolean" then lala.keybindsHud = data.keybindsHud end
        if type(data.viewMode) == "string" then lala.viewMode = data.viewMode end
        if type(data.spin) == "boolean" then lala.spin = data.spin end
        if type(data.spinSpeed) == "number" then lala.spinSpeed = math.clamp(data.spinSpeed, 5, 360) end
        if type(data.clash) == "boolean" then lala.clash = data.clash end
        if type(data.apColor) == "table" then
            lala.apColor.r = tonumber(data.apColor.r) or 0
            lala.apColor.g = tonumber(data.apColor.g) or 255
            lala.apColor.b = tonumber(data.apColor.b) or 120
        end
        if type(data.apThick) == "number" then lala.apThick = math.clamp(data.apThick, 1, 8) end
        if type(data.apTrans) == "number" then lala.apTrans = math.clamp(data.apTrans, 0, 100) end
        if type(data.pdColor) == "table" then
            lala.pdColor.r = tonumber(data.pdColor.r) or 255
            lala.pdColor.g = tonumber(data.pdColor.g) or 0
            lala.pdColor.b = tonumber(data.pdColor.b) or 0
        end
        if type(data.pdThick) == "number" then lala.pdThick = math.clamp(data.pdThick, 1, 8) end
        if type(data.pdTrans) == "number" then lala.pdTrans = math.clamp(data.pdTrans, 0, 100) end
        if type(data.remyHasMouse) == "boolean" then remyHasMouse = data.remyHasMouse end
        if type(data.remyCodes) == "table" then
            local good = true
            for _, c in ipairs(data.remyCodes) do if type(c) ~= "number" then good = false break end end
            if good then remyCodes = data.remyCodes end
        elseif remyHasMouse then
            remyCodes = {}
        end
        if type(data.remyLabel) == "string" then remyLabel = data.remyLabel end
        if type(data.abilityParry) == "boolean" then lala.abilityParry = data.abilityParry end
        if type(data.smartParry) == "boolean" then lala.smartParry = data.smartParry end
        if type(data.panicParry) == "boolean" then lala.panicParry = data.panicParry end
        if type(data.customLeadMode) == "boolean" then lala.customLeadMode = data.customLeadMode end
        if type(data.customLeadValue) == "number" then lala.customLeadValue = data.customLeadValue end
        if data.keyN ~= nil then lala.keyN = data.keyN == 0 and nil or data.keyN end
        if type(data.customFacingMinMode) == "boolean" then lala.customFacingMinMode = data.customFacingMinMode end
                if type(data.curveOnHit) == "boolean" then lala.curveOnHit = data.curveOnHit end
        if type(data.curveDir) == "string" then lala.curveDir = data.curveDir end
if type(data.curvePreTurn) == "boolean" then lala.curvePreTurn = data.curvePreTurn end
if type(data.curveFast) == "boolean" then lala.curveFast = data.curveFast end
if type(data.curveRandom) == "boolean" then lala.curveRandom = data.curveRandom end
if type(data.curveNoRepeat) == "boolean" then lala.curveNoRepeat = data.curveNoRepeat end
if type(data.curveStrength) == "number" then lala.curveStrength = math.clamp(data.curveStrength, 25, 200) end
if type(data.curveAngle) == "number" then lala.curveStrength = math.clamp(data.curveAngle / 90 * 100, 25, 200) end
        if type(data.curvePreTurn) == "boolean" then lala.curvePreTurn = data.curvePreTurn end
        if type(data.triggerbot) == "boolean" then lala.triggerbot = data.triggerbot end
        if type(data.triggerOnce) == "boolean" then lala.triggerOnce = data.triggerOnce end
        if data.keyT ~= nil then lala.keyT = data.keyT == 0 and nil or data.keyT end
        if data.keySmart ~= nil then lala.keySmart = data.keySmart == 0 and nil or data.keySmart end
if data.keyY ~= nil then lala.keyY = data.keyY == 0 and nil or data.keyY end
        if data.keyPanic ~= nil then lala.keyPanic = data.keyPanic == 0 and nil or data.keyPanic end
end

local function loadConfig()
    pcall(function()
        if not isfile(CFG_FILE) then return end
        local okd, dd = pcall(hs.JSONDecode, hs, readfile(CFG_FILE))
        if okd and type(dd) == "table" then applyConfig(dd) end
    end)
end
do
    local snap = {}
    for k, v in pairs(lala) do
        local tv = type(v)
        if tv == "number" or tv == "string" or tv == "boolean" then
            snap[k] = v
        elseif tv == "table" then
            local c = {}
            for k2, v2 in pairs(v) do
                if type(v2) == "number" or type(v2) == "string" or type(v2) == "boolean" then c[k2] = v2 end
            end
            snap[k] = c
        end
    end
    _G.remybbDefaults = snap
end
loadConfig()
-- Circle-only build: ignore any saved extra visuals.
lala.bvExtras = false
lala.showVis = false
lala.viewMode = "Circle"
lala.viewEnabled = true
_G.remybbSaveConfig = saveConfig
_G.remybbProfiles = {
    slots = { "1", "2", "3", "4", "5" },
    fileOf = function(slot) return "remybb_circle_profile_" .. tostring(slot) .. ".json" end,
    save = function(slot)
        local ok = false
        pcall(function()
            writefile(_G.remybbProfiles.fileOf(slot), hs:JSONEncode(buildSaveData()))
            ok = true
        end)
        return ok
    end,
    load = function(slot)
        local applied = false
        pcall(function()
            local f = _G.remybbProfiles.fileOf(slot)
            if isfile(f) then
                local okd, dd = pcall(hs.JSONDecode, hs, readfile(f))
                if okd and type(dd) == "table" then
                    applyConfig(dd)
                    applied = true
                end
            end
        end)
        return applied
    end,
}

local TOGGLE_NAMES = { "P", "X", "B", "T", "L", "R", "N", "Smart", "Panic" }
local function keyHeld(k)
    if not k then return false end
    if iskeypressed(k) then return true end
    if k >= 65 and k <= 90 and iskeypressed(k + 32) then return true end
    return false
end
local BANNED_KEYS = { 87, 65, 83, 68, 304 }
local function isBannedKey(code)
    for _, b in ipairs(BANNED_KEYS) do
        if b == code then return true end
    end
    return false
end
local function isParryKey(code)
    for _, c in ipairs(remyCodes) do
        if c == code then return true end
    end
    return false
end
local function freeToggleKey(excludeIdx)
    for c = 65, 90 do
        if not isParryKey(c) and not isBannedKey(c) then
            local used = false
            for i, nm in ipairs(TOGGLE_NAMES) do
                if i ~= excludeIdx and lala["key" .. nm] == c then used = true break end
            end
            if not used then return c end
        end
    end
    return nil
end

local function readText(obj)
    if not obj then return "" end
    local ok, v = pcall(function() return obj.Text end)
    if ok and type(v) == "string" then return v end
    return ""
end

local function refreshParryBindings()
    local codes = {}
    local hasMouse = false
    local acodes = {}
    pcall(function()
        local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        local st = pg and pg:FindFirstChild("Settings")
        local f1 = st and st:FindFirstChild("Frame")
        local f2 = f1 and f1:FindFirstChild("Frame")
        local function parseFrame(kb, out, withMouse)
            if not kb then return end
            for _, b in ipairs(kb:GetChildren()) do
                if b.ClassName == "ImageButton" and string.sub(b.Name, 1, 7) == "Keybind" then
                    local txt = string.upper(readText(b:FindFirstChild("TextBox")))
                    if txt:match("FAILED TO FETCH") or txt == "" then
                    elseif txt == "MOUSE 1" then
                        if withMouse then hasMouse = true end
                    else
                        local ch = txt:match("^%s*([A-Z0-9])")
                        if ch then
                            local code = string.byte(ch)
                            local dup = false
                            for _, c in ipairs(out) do if c == code then dup = true break end end
                            if not dup then out[#out + 1] = code end
                        end
                    end
                end
            end
        end
        parseFrame(f2 and f2:FindFirstChild("Keybinds/Block"), codes, true)
        parseFrame(f2 and f2:FindFirstChild("Keybinds/Ability"), acodes, false)
    end)
    if #acodes > 0 then abilityCodes = acodes end
    if #codes > 0 or hasMouse then
        remyCodes = codes
        remyHasMouse = hasMouse
    end
    if #remyCodes == 0 and not remyHasMouse then remyCodes = { 70 } end
    local lbl = {}
    for _, c in ipairs(remyCodes) do lbl[#lbl + 1] = string.char(c) end
    if remyHasMouse then lbl[#lbl + 1] = "M1" end
    remyLabel = table.concat(lbl, "/")
    if _G.__apParryLabel ~= remyLabel then
        _G.__apParryLabel = remyLabel
        saveConfig()
    end
    for i, nm in ipairs(TOGGLE_NAMES) do
        local tk = lala["key" .. nm]
        if isParryKey(tk) or isBannedKey(tk) then
            local free = freeToggleKey(i)
            if free then
                lala["key" .. nm] = free
                saveConfig()
            end
        end
    end
end

local function parryHeld()
    for _, c in ipairs(remyCodes) do
        if iskeypressed(c) then return true end
        if c >= 65 and c <= 90 and iskeypressed(c + 32) then return true end
    end
    return false
end

local AP_ABILITIES = { ["Raging Deflection"] = true, ["Rapture"] = true, ["Calming Deflection"] = true }
local function getEquippedAbility()
    local n = lp:GetAttribute("CurrentlyEquippedAbility")
    if type(n) ~= "string" then return nil end
    return n
end
local function getAbilityLevel(name)
    local up = lp:FindFirstChild("Upgrades")
    local iv = up and up:FindFirstChild(name)
    if iv then return iv.Value or 0 end
    return 0
end
local function getAbilityCooldown(name)
    if name == "Raging Deflection" then
        local lvl = getAbilityLevel(name)
        if lvl >= 2 then return 22 end
        if lvl == 1 then return 27 end
        return 32
    end
    if name == "Rapture" then return 32 end
    if name == "Calming Deflection" then return 25 end
    return 0
end
local function abilityReady()
    if not lala.abilityParry then return false end
    if #abilityCodes == 0 then return false end
    local n = getEquippedAbility()
    if not n or not AP_ABILITIES[n] then return false end
    return tick() >= abilityReadyAt
end

local function pressParry()
    if _G.__apADLock and tick() < _G.__apADLock then return nil end
    if abilityReady() then
        local n = getEquippedAbility()
        abilityReadyAt = tick() + getAbilityCooldown(n)
        local c = abilityCodes[1]
        pcall(realKeypress, c)
        return function() pcall(realKeyrelease, c) end
    end
    for _, c in ipairs(remyCodes) do
        pcall(realKeypress, c)
        return function() pcall(realKeyrelease, c) end
    end
    if remyHasMouse then
        mouse1press()
        return function() mouse1release() end
    end
    pcall(realKeypress, 70)
    return function() pcall(realKeyrelease, 70) end
end

local nextParryRoll = nil
local function rollNextParry()
    if not lala.randomize then nextParryRoll = nil return lala.accuracy end
    local lo = math.min(tonumber(lala.randMin) or 20, tonumber(lala.randMax) or 100)
    local hi = math.max(lo + 1, tonumber(lala.randMax) or 100)
    local rolled = lo + math.random() * (hi - lo)
    nextParryRoll = rolled
    return rolled
end
local function currentParryAcc()
    if not lala.randomize then return math.clamp(lala.accuracy or 100, 1, 100) end
    if nextParryRoll == nil then rollNextParry() end
    local rolled = nextParryRoll or 100
    if (lala.accSpeedBoostOn and ((tonumber(_G.__apState and _G.__apState.speed) or 0) > math.max(0, tonumber(lala.accSpeedThresh) or 70))) then
        rolled = math.clamp(rolled + rolled * (tonumber(lala.accSpeedBoost) or 25) / 100, 1, 100)
    end
    return rolled
end
_G.finishParry = function()
    local rel = pressParry()
    if rel then pcall(rel) end
end

local function doHumanParry()
    nextParryRoll = nil
    local userRmb = ismouse2pressed() == true

    if not (lala.curveOnHit) then
        _G.finishParry()
        return
    end

    task.spawn(function()
        local okRun, runErr = pcall(function()
            local cam = workspace.CurrentCamera
            if not cam then
            local r = pressParry()
            if r then pcall(r) end
            return
        end

        local baseMode = lala.curveDir or "Left"
        local valid = {
            Left=true, Right=true, Up=true, Back=true,
            ["Back Up"]=true, ["Back Down"]=true, ["Back Left"]=true, ["Back Right"]=true,
            ["Left Up"]=true, ["Left Down"]=true, ["Right Up"]=true, ["Right Down"]=true
        }
        if not valid[baseMode] then baseMode = "Left" end

        local allDirOpts = { "Left", "Right", "Up", "Back", "Back Up", "Back Down", "Back Left", "Back Right", "Left Up", "Left Down", "Right Up", "Right Down" }
        local set = lala.curveRandomSet
        if type(set) ~= "table" then set = allDirOpts end
        local pool = {}
        if lala.curveRandom then
            for _, d in ipairs(allDirOpts) do
                if table.find(set, d) then table.insert(pool, d) end
            end
            if #pool == 0 then pool = allDirOpts end
        else
            pool = { "Left", "Right", "Up", "Back" }
        end

        local dirMode = baseMode
        if lala.curveRandom then
            local pick = pool
            if lala.curveNoRepeat and #pool > 1 then
                local filter = {}
                for _, d in ipairs(pool) do
                    if d ~= _G.__curveLastDir then filter[#filter + 1] = d end
                end
                if #filter > 0 then pick = filter end
            end
            dirMode = pick[math.random(1, #pick)]
        end
        _G.__curveLastDir = dirMode

        local function yawOf(cf)
            local lv = cf.LookVector
            return math.atan2(lv.X, -lv.Z)
        end
        local function pitchOf(cf)
            return math.asin(math.clamp(cf.LookVector.Y, -1, 1))
        end
        local function wrap(a)
            while a > math.pi do a = a - 2 * math.pi end
            while a < -math.pi do a = a + 2 * math.pi end
            return a
        end
        local function clampPitch(p)
            if p > (math.pi / 2 - 0.05) then return (math.pi / 2 - 0.05) end
            if p < (-math.pi / 2 + 0.05) then return (-math.pi / 2 + 0.05) end
            return p
        end

        local deltaSpec = {
            ["Left"] = { -90, 0 },
            ["Right"] = { 90, 0 },
            ["Up"] = { 0, 90 },
            ["Down"] = { 0, -90 },
            ["Back"] = { 180, 0 },
            ["Back Up"] = { 180, 90 },
            ["Back Down"] = { 180, -90 },
            ["Back Left"] = { -135, 0 },
            ["Back Right"] = { 135, 0 },
            ["Left Up"] = { -90, 90 },
            ["Left Down"] = { -90, -90 },
            ["Right Up"] = { 90, 90 },
            ["Right Down"] = { 90, -90 }
        }
        local spec = deltaSpec[dirMode] or deltaSpec.Left
        local curveStrength = math.clamp(tonumber(lala.curveStrength) or 100, 25, 200)
        local angleScale = curveStrength / 100
        local yawDelta = math.rad(math.clamp(spec[1] * angleScale, -180, 180))
        local pitchDelta = math.rad(math.clamp(spec[2] * angleScale, -180, 180))

        local fast = lala.curveFast == true
        local lpCur = game:GetService("Players").LocalPlayer
        local mObj = lpCur:GetMouse()
        local cx, cy = mObj.X, mObj.Y

        if not userRmb then pcall(mouse2press) end
        task.wait(fast and 0.001 or 0.008)

        -- calibrate both axes (once per session, then reuse)
        local sensYaw, sensPitch = _G.__curveSensY, _G.__curveSensP
        if not sensYaw or math.abs(sensYaw) < 1e-5 then
            local a0 = yawOf(cam.CFrame)
            mousemoverel(20, 0)
            task.wait(fast and 0.001 or 0.02)
            sensYaw = wrap(yawOf(cam.CFrame) - a0) / 20
            if math.abs(sensYaw) < 1e-5 then sensYaw = 0.0035 end
            _G.__curveSensY = sensYaw
        end
        if not sensPitch or math.abs(sensPitch) < 1e-5 then
            local p0 = pitchOf(cam.CFrame)
            mousemoverel(0, 20)
            task.wait(fast and 0.001 or 0.02)
            sensPitch = (pitchOf(cam.CFrame) - p0) / 20
            if math.abs(sensPitch) < 1e-5 then sensPitch = 0.0035 end
            _G.__curveSensP = sensPitch
        end

        -- one atomic turn: whole delta in a single input, no convergence loop
        local startYaw = yawOf(cam.CFrame)
        local startPitch = pitchOf(cam.CFrame)
        local turnYaw = wrap(startYaw + yawDelta)
        local turnPitch = clampPitch(startPitch + pitchDelta)
        local px = math.clamp(wrap(turnYaw - yawOf(cam.CFrame)) / sensYaw, -6000, 6000)
        local py = math.clamp((turnPitch - pitchOf(cam.CFrame)) / sensPitch, -6000, 6000)
        mousemoverel(px, py)
        task.wait(fast and 0.001 or 0.008)

        -- parry from the turned view
        _G.finishParry()

        -- restore view + cursor to exact position
        task.wait(fast and 0.005 or 0.03)
        mousemoverel(-px, -py)
        task.wait(0.01)
        local eY = wrap(startYaw - yawOf(cam.CFrame))
        if math.abs(eY) > math.rad(1.5) then
            mousemoverel(math.clamp(eY / sensYaw, -6000, 6000), 0)
            task.wait(0.006)
        end
        if not userRmb then pcall(mouse2release) end
        task.wait(0.01)
        pcall(mousemoveabs, cx, cy)
    end)
  if not okRun then _G.__curveErr = tostring(runErr) end
  if not userRmb then pcall(mouse2release) end
end)
end

do
    local fired = false
    task.spawn(function()
        while bob == _G.__apGen do
            if lala.triggerbot then
                pcall(function()
                    local balls = workspace:FindFirstChild("Balls")
                    if not balls then fired = false return end
                    local ch2 = lp.Character
                    if ch2 and ch2:FindFirstChild("SingularityCape") then fired = false return end
                    local myInf = false
                    pcall(function()
                        for _, b in ipairs(balls:GetChildren()) do
                            if (b:FindFirstChild("InfinityFX") or b:FindFirstChild("TrueInfinityFX")) and remy.recentlyTapped[b.Address or b.Name] and tick() - remy.recentlyTapped[b.Address or b.Name] < 2 then
                                myInf = true
                                break
                            end
                        end
                    end)
                    if myInf then fired = false return end
                    local me = lp.Name
                    local targeting = false
                    for _, b in ipairs(balls:GetChildren()) do
                        local tgt = b:GetAttribute("target")
                        if tgt and tostring(tgt) == me then
                            targeting = true
                            break
                        end
                    end
                    if targeting and not fired then
                        fired = true
                        doHumanParry()
                        if lala.triggerOnce then
                            lala.triggerbot = false
                            saveConfig()
                        end
                    elseif not targeting then
                        fired = false
                    end
                end)
            else
                fired = false
            end
            task.wait()
        end
    end)
end

refreshParryBindings()
task.spawn(function()
    task.wait(0.5)
    while bob == _G.__apGen do
        refreshParryBindings()
        task.wait(3)
    end
end)

local pingSec = 0.03
local pingEma = 0
local function pingSample()
    local ok, p = pcall(GetPingValue)
    if ok and type(p) == "number" and p > 0 then
        local s = math.min(p / 1000, lala.pingMax)
        if pingEma <= 0 then pingEma = s else pingEma = pingEma * 0.85 + s * 0.15 end
        pingSec = pingEma
    end
end
local function leadForPing(pingMs)
    local tiers = lala.pingTiers
    local leads = lala.pingLead
    for i = 1, #tiers do
        if pingMs <= tiers[i] then return leads[i] end
    end
    return leads[#leads]
end
local function getEffectiveLeadTime()
    if lala.customLeadMode then
        return lala.customLeadValue
    end
    return lala.pingComp and leadForPing(pingSec * 1000) or lala.leadTime
end
local function getEffectiveFacingMin()
    if lala.customFacingMinMode then
        return lala.customFacingMinValue
    end
    return lala.facingMin
end
pingSample()
task.spawn(function()
    while bob == _G.__apGen do
        pingSample()
        task.wait(0.5)
    end
end)

task.spawn(function()
    _G.__curvePreState = _G.__curvePreState or { armed = false, ball = nil, parried = false, held = false, mode = nil }
    local st = _G.__curvePreState
    local lp = game:GetService("Players").LocalPlayer
    local cam = workspace.CurrentCamera
    while bob == _G.__apGen do
        if _G.__curvePreTurnOn == true and lala.curveOnHit and lala.curvePreTurn then
            local ls = _G.__apLastTap
            local tb = ls and ls.tapBest
            if type(ls) == "table" and ls.__apLastTap ~= nil then tb = ls.tapBest end
            local targeting = (type(tb) == "table") and tb.addr and tb.dist and (tb.dist <= 22) and (tb.dist > 8)
            if st.armed then
                local disarm = (not targeting) or (type(tb) == "table" and tb.addr ~= st.ball) or (tb.dist and tb.dist > 24) or st.parried == true
                if disarm then
                    -- restore
                    if cam and st.sensYaw and st.startYaw then end
                    local function yawOf(cf) local lv = cf.LookVector return math.atan2(lv.X, -lv.Z) end
                    if st.sensYaw then
                        for _ = 1, 5 do
                            local eY = st.startYaw - yawOf(cam.CFrame)
                            if math.abs(eY) < math.rad(2) then break end
                            mousemoverel(math.clamp(eY / st.sensYaw, -6000, 6000), 0)
                            task.wait(0.006)
                        end
                    end
                    if st.held then pcall(mouse2release); st.held = false end
                    st.armed = false
                    st.ball = nil
                    st.parried = false
                    st.turnStarted = false
                end
            elseif targeting then
                st.armed = true
                st.ball = tb.addr
                st.parried = false
                st.mode = lala.curveDir or "Left"
                pcall(mouse2press)
                st.held = true
                task.wait(0.01)
                local cf = cam.CFrame
                -- simple immediate turn then parry
                mousemoverel(lala.curveDir == "Right" and 1266 or -1266, 0)
                task.wait(0.02)

                -- parry right now
                st.parried = true
                local r = pressParry()
                if r then pcall(r) end

            end
        else
            if st.armed then
                if st.held then pcall(mouse2release); st.held = false end
                st.armed = false
                st.ball = nil
                st.parried = false
            end
        end
        task.wait(0.02)
    end
    pcall(mouse2release)
end)


local ymer = { leadDist = 21, ballPos = nil, centerPos = nil, flash = 0 }
_G.__apState = ymer
local genPrev = {}
local genSeen = {}
local genRet = {}
local genLock = {}
local spdSm = {}
local clashSawMine = false
local clashLastMine = 0
local clashNoBallT = tick()
local clashPartner = nil
local genPrune = 0
local genHp = 0
local meId = tostring(lp and lp.UserId or 0)
local genWatch = {}
local recentlyPanic = {}
local ballParriedOnce = {}
local ballSpawnedAt = {}
local NEW_BALL_GRACE = 0.5
local lastSingularityRelease = 0
local singularityTracking = {}
local visSm = {}
local aeroStates = {}
local InfinityDetection = {
    Enabled = true,
    Active = false
}
do
local function IsInstance(Object)
    return Object ~= nil and type(Object) == "userdata"
end
function InfinityDetection:IsActive()
    local Runtime = workspace:FindFirstChild("Runtime")
    if IsInstance(Runtime) then
        if Runtime:FindFirstChild("InfinityFX") or Runtime:FindFirstChild("TrueInfinityFX") then
            return true
        end
    end
    local Balls = workspace:FindFirstChild("Balls")
    if IsInstance(Balls) then
        for _, Ball in ipairs(Balls:GetChildren()) do
            if IsInstance(Ball) and (Ball.ClassName == "Part" or Ball.ClassName == "MeshPart") then
                local Body = Ball:FindFirstChild("Body")
                if IsInstance(Body) and Body:FindFirstChild("WEMAZOOKIEGO") then
                    return true
                end
            end
        end
    end
    local Character = lp and lp.Character
    if IsInstance(Character) and Character:FindFirstChild("Parry") then
        return true
    end
    return false
end
function InfinityDetection:Update()
    if not self.Enabled or not lala.infinityAvoid then
        self.Active = false
        return false
    end
    self.Active = self:IsActive()
    return self.Active
end
end
local PANIC_GRACE = 0.5
_G.__apStats = _G.__apStats or { taps = 0, parries = 0, misses = 0, hits = 0 }
local stats = _G.__apStats
stats.hits = stats.hits or 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function getBallMotion(b, now, dt, pos)
    local a = b.Address or b.Name
    local e = genPrev[a]
    local accel = 0
    local curve = 0
    local dpos, dT
    if e then
        local ref = e.p2 and { p = e.p2, t = e.t2 } or { p = e.p1, t = e.t1 }
        dpos = pos - ref.p
        dT = now - ref.t
        e.p2, e.t2, e.p1, e.t1 = e.p1, e.t1, pos, now
    else
        genPrev[a] = { p1 = pos, t1 = now }
    end
    local bestV, bestSpeed = nil, 0
    if dpos and dT and dT > 0.0001 then
        local v = dpos / dT
        local s = v.Magnitude
        if s > bestSpeed then bestV, bestSpeed = v, s end
        if e.p1 then
            local dT1 = now - e.t1
            if dT1 > 0.0001 then
                local v1 = (pos - e.p1) / dT1
                local s1 = v1.Magnitude
                if s1 > bestSpeed then bestV, bestSpeed = v1, s1 end
            end
        end
        if e.sv then
            accel = math.min((v - e.sv).Magnitude / dT, 1500)
            local dUnit = v.Unit
            local pUnit = e.sv.Unit
            local dot = math.clamp(dUnit:Dot(pUnit), -1, 1)
            local angle = math.acos(dot)
            local rawCurve = angle / math.pi
            e.curve = (e.curve or 0) * 0.4 + rawCurve * 0.6
            curve = e.curve
        end
        if e.p1 and e.sv then
            local dtPred = now - e.t1
            local predicted = e.p1 + e.sv * dtPred
            local deviation = (pos - predicted).Magnitude
            local devCurve = math.clamp(deviation / 3, 0, 1)
            curve = math.max(curve, devCurve)
        end
        e.sv = v
    end
    if bestSpeed <= 8 then
        local rep = b.AssemblyLinearVelocity
        if rep then
            local rs = rep.Magnitude
            if rs > 5 and rs > bestSpeed then bestV, bestSpeed = rep, rs end
        end
        if bestSpeed <= 8 then
            local rep2 = b.Velocity
            if rep2 then
                local rs2 = rep2.Magnitude
                if rs2 > 5 and rs2 > bestSpeed then bestV, bestSpeed = rep2, rs2 end
            end
        end
    end
    if bestV and bestSpeed > 8 then
        local turn = nil
        if e and e.p1 and e.sv then
            local dtPred = now - e.t1
            if dtPred > 0.0001 then
                local dev = pos - (e.p1 + e.sv * dtPred)
                local par = dev:Dot(bestV.Unit)
                local lat = dev - bestV.Unit * par
                if lat.Magnitude > 0.1 then turn = lat.Unit end
            end
        end
        return bestV.Unit, math.min(bestSpeed, lala.maxSpeed), a, accel, curve, turn
    end
    return nil, 0, a, 0, curve, nil
end

if _G.__apConn then pcall(_G.__apConn.Disconnect, _G.__apConn) end
_G.__apConn = nil
if _G.__apHB then pcall(_G.__apHB.Disconnect, _G.__apHB) end
_G.__apHB = nil
if _G.__apRS then pcall(_G.__apRS.Disconnect, _G.__apRS) end
_G.__apRS = nil
if _G.__apCleanup then pcall(_G.__apCleanup) end
_G.__apCleanup = nil
if _G.__apPool then
    local old = _G.__apPool
    for i = 1, #old do
        local e = old[i]
        if e and e.seg then
            for s = 1, #e.seg do
                local l = e.seg[s]
                if l and l.Remove then pcall(l.Remove, l) end
            end
        end
    end
    _G.__apPool = nil
end

local clashGate = { ok = false, clos = 0, tgt = "", me = "" }
local lastScanState = {}

local scan
scan = function(dt)
    if bob ~= _G.__apGen then return end
    local v2on = lala.v2 and true or false
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local me = char and char.Name or ""
    local balls = workspace:FindFirstChild("Balls")
    local ballKids = balls and balls:GetChildren() or {}
    local now = tick()
    local leadTime = getEffectiveLeadTime()
    ymer.lead = leadTime
    local fDown = parryHeld()
    if fDown and not remy.tapping and now - remy.lastTap > 0.1 then
        _G.__apUserF = now
    end
    local uf = _G.__apUserF
    local abilityActive = false
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local isIdle = not hum or hum.Health <= 0 or #ballKids == 0
    if (not hum or hum.Health <= 0) and not ymer.idle then
        abilityReadyAt = 0
    end
    ymer.idle = isIdle
    if isIdle then
        ymer.leadDist = 0
        ymer.ballPos = nil
        ymer.impDist = nil
        ymer.bAddr = nil
        return
    end
    if root then
        local p = root.Position
        abilityActive = lala.singularityDetect ~= false and root:FindFirstChild("SingularityCape") ~= nil
        ymer.abilityActive = abilityActive
        rayParams.FilterDescendantsInstances = { char }
        local hit = workspace:Raycast(p + Vector3.new(0, 2, 0), Vector3.new(0, -200, 0), rayParams)
        local floorY = hit and hit.Position.Y or (p.Y - 3)
        ymer.centerPos = Vector3.new(p.X, floorY + 0.1, p.Z)
        local hum = char:FindFirstChildOfClass("Humanoid")
        genHp = hum and hum.Health or genHp
    else
        ymer.centerPos = nil
    end
    if now - genPrune > 1 then
        genPrune = now
        for k in pairs(remy.recentlyTapped) do
            if now - remy.recentlyTapped[k] > 2 then remy.recentlyTapped[k] = nil end
        end
        for k, w in pairs(genWatch) do
            if now - w.t > 4 then genWatch[k] = nil end
        end
        for k, v in pairs(recentlyPanic) do
            if now - v > PANIC_GRACE + 0.5 then recentlyPanic[k] = nil end
        end
    end
    local vis = {}
    local best, genScore, bestVi = nil, 0, nil
    local rBest, genTime, rBestVi = nil, math.huge, nil
    local nBest, nBestDist = nil, math.huge
    local nearestMine, nearestMineDist = nil, math.huge
    local dualBest, dualBestDist = nil, math.huge
    local maxTrack = 0
    local seen = {}
    local realClos = nil
    local realTgt = ""
    if lala.singularityDetect == false then
        lastSingularityRelease = -1e18
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp then
                local ch = plr.Character
                local hadCape = singularityTracking[plr.UserId]
                local hasCape = ch and ch:FindFirstChild("SingularityCape") ~= nil
                if hadCape and not hasCape then
                    lastSingularityRelease = now
                    if lala.singularityV1AutoTrigger then
                        local up = plr:FindFirstChild("Upgrades")
                        local iv = up and up:FindFirstChild("Singularity")
                        local lvl = iv and iv.Value or 0
                        if lvl <= 1 then
                            _G.__singAutoTarget = _G.__singAutoTarget or {}
                            _G.__singAutoTarget[tostring(plr.UserId)] = now
                        end
                    end
                end
                singularityTracking[plr.UserId] = hasCape
            end
        end
    end
    if root and balls then
        local rootPos = root.Position
        local infActive = false
        pcall(function() infActive = InfinityDetection:Update() end)
        local infBallDist = nil
        local aeroAny = false
        local needVis = lala.bvExtras ~= false or lala.showVis or lala.clash
        if lala.dualityAutoTrigger == false and lala.dualityTrigger == false then
            _G.__apDualityOn = false
        elseif now - (_G.__apDualCheck or 0) > 0.15 then
            _G.__apDualCheck = now
            local dualFound = false
            if char then
                for _, cc in ipairs(char:GetChildren()) do
                    if string.find(cc.Name, "DUALITY_SELECTION", 1, true) then dualFound = true break end
                end
                if not dualFound then
                    local hd = char:FindFirstChild("Head")
                    if hd then
                        for _, cc in ipairs(hd:GetChildren()) do
                            if string.find(cc.Name, "DualityBillboard", 1, true) then dualFound = true break end
                        end
                    end
                end
            end
            if dualFound then _G.__apDualUntil = now + 1.2 end
            _G.__apDualityOn = dualFound or ((_G.__apDualUntil or 0) > now)
            -- Duality auto triggerbot: turn it on while Slashes of Duality is selected.
            if _G.__apDualityOn and lala.dualityAutoTrigger ~= false and not lala.triggerbot then
                lala.triggerbot = true
                _G.__dualAutoEnabled = true
                _G.__dualAutoLastSeen = now
                pcall(saveConfig)
            end
        end
        for _, b in ipairs(ballKids) do
            local a = b.Address or b.Name
            seen[a] = true
            local pos = b.Position
            if pos then
                local dir, speed, a2, accel, curve, turn = getBallMotion(b, now, dt, pos)
                local dposRoot = rootPos - pos
                local dist = dposRoot.Magnitude
                local closing = 0
                if dir and dist > 0.5 then
                    closing = dir:Dot(dposRoot / dist)
                    if speed > 1 then
                        if not genSeen[a2] then ballSpawnedAt[a2] = now end
                        genSeen[a2] = (genSeen[a2] or 0) + 1
                    end
                end
                local tgt = b:GetAttribute("target")
                local realBall = b:GetAttribute("realBall")
                if b:FindFirstChild("AeroDynamicSlashVFX") then
                    local st = aeroStates[a2]
                    if not st then
                        st = { t = now }
                        aeroStates[a2] = st
                        if tgt == me or tgt == meId then
                            _G.__apADLock = now + 0.35
                            genLock[a2] = nil
                            ballParriedOnce[a2] = nil
                        end
                    end
                    local vs = dir and dir.Y or 0
                    if (now - st.t) < 0.2 or vs > 10 then
                        aeroAny = true
                    end
                else
                    aeroStates[a2] = nil
                end
                local tgtPos = nil
                if needVis and tgt then
                    local tp = Players:FindFirstChild(tostring(tgt))
                    if not tp then
                        for _, pl in ipairs(Players:GetPlayers()) do
                            if tostring(pl.UserId) == tostring(tgt) then tp = pl break end
                        end
                    end
                    local ch = tp and tp.Character
                    local rp = ch and ch:FindFirstChild("HumanoidRootPart")
                    if rp then tgtPos = rp.Position end
                end
                local vi = needVis and 0 or nil
                if needVis and realBall ~= false then
                    local sm = visSm[a2]
                    local sk = 0.3
                    if sm then
                if dir then
                            sm.dir = sm.dir and sm.dir:Lerp(dir, sk) or dir
                        end
                        if turn then
                            sm.turn = sm.turn and sm.turn:Lerp(turn, sk) or turn
                        end
                        sm.curve = sm.curve + ((curve or 0) - sm.curve) * sk
                        sm.speed = sm.speed + ((speed or 0) - sm.speed) * sk
                    else
                        sm = { dir = dir, turn = turn, curve = curve or 0, speed = speed or 0 }
                        visSm[a2] = sm
                    end
                    if tgtPos then
                        sm.tgtPos = sm.tgtPos and sm.tgtPos:Lerp(tgtPos, sk) or tgtPos
                    end
                    vis[#vis + 1] = { pos = pos, dist = dist, speed = sm.speed or speed, addr = a2, closing = closing, best = false, dir = sm.dir or dir, curve = sm.curve or 0, turn = sm.turn, tgtPos = sm.tgtPos }
                    vi = #vis
                end
                clashNoBallT = now
                local isMine = (tgt == me or tgt == meId)
                -- Martyrdom/re-target: let retained balls be parried again.
                if ballParriedOnce[a2] and now - ballParriedOnce[a2] > 0.95 then
                    ballParriedOnce[a2] = nil
                end
                if isMine and dist < dualBestDist then
                    dualBestDist = dist
                    dualBest = { dist = dist, pos = pos, addr = a2 }
                end
                local infNeeded = (lala.v2 == true) or (lala.infAutoTrigger == true)
                if infNeeded then
                    local isInfBall = isMine and (
                        b:FindFirstChild("WEMAZOOKIEGO") ~= nil
                        or b:FindFirstChild("InfinityFX") ~= nil
                        or (b:FindFirstChild("Body") and b.Body:FindFirstChild("WEMAZOOKIEGO") ~= nil)
                    )
                    if isInfBall and (infBallDist == nil or dist < infBallDist) then
                        infBallDist = dist
                    end
                    -- Infinity auto triggerbot: arm when the ability was recently used and
                    -- my Infinity ball is inside the configured trigger distance.
                    if lala.infAutoTrigger == true and isInfBall and infBallDist and infBallDist <= (tonumber(lala.infAutoTriggerDist) or 30) then
                        local recentInf = false
                        for _, ts in pairs((_G.__infAutoTarget or {})) do
                            if now - ts <= 4.0 then recentInf = true break end
                        end
                        if _G.__infAutoLastSeen == nil or recentInf or (now - (_G.__infAutoLastSeen or now)) <= 2.0 then
                            _G.__infAutoLastSeen = now
                        end
                    end
                    if lala.infAutoTrigger == true and isInfBall and not lala.triggerbot and infBallDist and infBallDist <= (tonumber(lala.infAutoTriggerDist) or 30) then
                        lala.triggerbot = true
                        _G.__infAutoEnabled = true
                        pcall(saveConfig)
                    end
                end
                if not isMine then
                    ballParriedOnce[a2] = nil
                end
                if not isMine and abilityActive then
                    local equipped = lp:GetAttribute("CurrentlyEquippedAbility") or ""
                    if equipped == "Slashes of Fury" then
                        abilityActive = false
                        ymer.abilityActive = false
                    end
                end
                if realBall then
                    local tgtStr = tostring(tgt or "")
                    realClos = closing
                    realTgt = tgtStr
                    -- Auto-enable triggerbot when a Singularity v1 user launches the ball at someone.
                    if lala.singularityV1AutoTrigger and not lala.triggerbot then
                        local marks = _G.__singAutoTarget or {}
                        local recent = marks[tgtStr]
                        if recent and (now - recent) <= 2.5 then
                            lala.triggerbot = true
                            _G.__singV1AutoEnabled = true
                            pcall(saveConfig)
                        end
                    end
                    if isMine then
                        clashSawMine = true
                        clashLastMine = now
                    elseif lala.clash then
                        if clashSawMine and now - clashLastMine > 1.2 then
                            lala.clash = false
                            clashSawMine = false
                            clashPartner = nil
                        elseif tgtStr ~= "" then
                            if clashPartner == nil then
                                clashPartner = tgtStr
                            elseif tgtStr ~= clashPartner then
                                lala.clash = false
                                clashSawMine = false
                                clashPartner = nil
                            end
                        end
                    end
                end
                if closing < -0.3 then
                    genRet[a2] = (genRet[a2] or 0) + 1
                else
                    genRet[a2] = 0
                end
                local eng = genLock[a2]
                if eng then
                    local lockTime = 0.6
                    local dynamicPanicLock = lala.panicBase + speed * lala.panicSpeedMul
                    local wasRecentPanicLock = recentlyPanic[a2] and (now - recentlyPanic[a2] < PANIC_GRACE)
                    if dist <= lala.closeRangeDist or (dist < dynamicPanicLock and speed > 30) or wasRecentPanicLock then
                        lockTime = 0.08
                    end
                    if now - eng > lockTime then
                        genLock[a2] = nil
                    end
                end
                local w = genWatch[a2]
                if w then
                    if genHp < (w.hp or 0) - 1 then
                        stats.hits = stats.hits + 1
                        genWatch[a2] = nil
                    elseif closing < -0.3 then
                        w.re = (w.re or 0) + 1
                        if w.re >= 2 then
                            stats.parries = stats.parries + 1
                            genWatch[a2] = nil
                        end
                    elseif now - w.t > 2.5 then
                        stats.misses = stats.misses + 1
                        genWatch[a2] = nil
                    end
                end
                local sm = speed
                if speed > 1 then
                    local o = spdSm[a2]
                    if o then
                        local blend = speed > o and 0.4 or 0.05
                        sm = o + (speed - o) * blend
                    end
                    spdSm[a2] = sm
                end
                local isDeco = realBall == false
                local mine = (not isDeco and isMine) and not infActive and not aeroAny
                if mine and dist > 0.5 and dist < nearestMineDist then
                    nearestMineDist = dist
                    nearestMine = { dist = dist, speed = sm, pos = pos, addr = a2, closing = closing, accel = accel, curve = curve }
                end
                if not isDeco and dist > 0.5 then
                    if dist < nBestDist then
                        nBestDist = dist
                        nBest = { dist = dist, speed = sm, pos = pos, addr = a2, closing = closing, accel = accel, curve = curve }
                    end
                end
                local hasMotion = dir and speed > 1
                local dynamicPanic = lala.panicBase + sm * lala.panicSpeedMul
                local isPanicClose = mine and dist < dynamicPanic and not isDeco
                if isPanicClose or (mine and dist > 0.5) then
                    local useSpeed = hasMotion and sm or 50
                    if useSpeed > maxTrack then maxTrack = useSpeed end
                    local score = hasMotion and (closing * sm / dist) or (100 / dist)
                    if score > genScore then
                        genScore = score
                        best = { dist = dist, speed = useSpeed, pos = pos, addr = a2, closing = closing or 1, accel = accel, curve = curve }
                        bestVi = vi
                    end
                    local isFast = useSpeed >= lala.fastBallThreshold
                    local isClose = dist <= lala.closeRangeDist
                    local isAccel = accel > 200
                    local adjustedLead = leadTime
                    if isFast then adjustedLead = adjustedLead * 1.05 end
                    if isClose then adjustedLead = adjustedLead * 1.1 end
                    if isAccel then adjustedLead = adjustedLead * 1.15 end
                    local curveFactor = 1 - (curve or 0) * 0.75
                    adjustedLead = adjustedLead * math.clamp(curveFactor, 0.25, 1)
                    local leadNow = math.clamp(useSpeed * adjustedLead, lala.minDist, lala.maxDist)
                    if isClose then leadNow = math.max(leadNow, lala.closeRangeDist) end
                    if isFast and isClose then leadNow = math.max(leadNow, 30) end
                    if isPanicClose then leadNow = math.max(leadNow, 35) end
                    local dynamicPanic2 = lala.panicBase + useSpeed * lala.panicSpeedMul
                    if dist <= leadNow or dist < dynamicPanic2 then
                        local impact = isPanicClose and 0 or (dist / math.max(closing * sm, 1))
                        if impact < genTime then
                            genTime = impact
                            rBest = { dist = dist, speed = useSpeed, pos = pos, addr = a2, closing = closing or 1, accel = accel, fast = isFast, close = isClose, highAccel = isAccel, curve = curve }
                            rBestVi = vi
                        end
                    end
                end
            end
        end
        for k in pairs(genPrev) do
            if not seen[k] then
                genPrev[k] = nil
                genSeen[k] = nil
                genRet[k] = nil
                genLock[k] = nil
                spdSm[k] = nil
                visSm[k] = nil
                ballParriedOnce[k] = nil
                ballSpawnedAt[k] = nil
                aeroStates[k] = nil
            end
        end
        if lala.clash and now - clashNoBallT > 5 then
            lala.clash = false
            clashSawMine = false
            clashPartner = nil
        end
    elseif lala.clash and now - clashNoBallT > 5 then
        lala.clash = false
        clashSawMine = false
        clashPartner = nil
    end
    if rBest and rBestVi and vis[rBestVi] then vis[rBestVi].best = true elseif best and bestVi and vis[bestVi] then vis[bestVi].best = true end
    local tapBest = rBest or best
    if nearestMine and (not tapBest or nearestMine.dist < tapBest.dist) and nearestMine.dist <= lala.maxDist then
        tapBest = nearestMine
    end
    local lead = math.clamp(
        tapBest and tapBest.speed * leadTime
            or nBest and nBest.speed * leadTime
            or maxTrack * leadTime,
        lala.minDist, lala.maxDist)
    if tapBest and tapBest.curve and tapBest.curve > 0.05 then
        local cf = 1 - tapBest.curve * 0.75
        lead = lead * math.clamp(cf, 0.25, 1)
    end
    lead = math.clamp(lead, lala.minDist, lala.maxDist)
    ymer.leadDist = lead
    local t2 = tick()
    if _G.__apDualityOn and lala.dualityTrigger ~= false and dualBest and v2on and not abilityActive then
        local dualRange = math.max(lead * 2, 55)
        if dualBest.dist <= dualRange and not ballParriedOnce[dualBest.addr] and not remy.tapping and t2 - remy.lastTap > 0.05 then
            remy.lastTap = t2
            ymer.flash = t2
            genLock[dualBest.addr] = t2
            ballParriedOnce[dualBest.addr] = t2
            stats.taps = stats.taps + 1
            local rel = pressParry()
            if rel then pcall(rel) end
        end
    end
    if v2on and (realTgt == me or realTgt == meId) and (t2 - lastSingularityRelease) < 1.5 and not remy.tapping and t2 - remy.lastTap > 0.001 then
        remy.lastTap = t2
        ymer.flash = t2
        if tapBest then
            genLock[tapBest.addr] = t2
            ballParriedOnce[tapBest.addr] = t2
        end
        stats.taps = stats.taps + 1
        local rel = pressParry()
        if rel then pcall(rel) end
    end
    if v2on and tapBest and infBallDist and infBallDist <= 36 and (realTgt == me or realTgt == meId) and not ballParriedOnce[tapBest.addr] and (now - (ballSpawnedAt[tapBest.addr] or 0)) >= NEW_BALL_GRACE and not remy.tapping and t2 - remy.lastTap > 0.001 then
        remy.lastTap = t2
        ymer.flash = t2
        genLock[tapBest.addr] = t2
        ballParriedOnce[tapBest.addr] = t2
        stats.taps = stats.taps + 1
        local rel = pressParry()
        if rel then pcall(rel) end
    end
    if lala.clash then
        local cBest = nil
        for _, v in ipairs(vis) do
            if not cBest or v.dist < cBest.dist then cBest = v end
        end
        if cBest then
            ymer.ballPos = cBest.pos
            ymer.impDist = cBest.dist
            ymer.bAddr = cBest.addr
        end
        clashGate.clos = realClos or 0
        clashGate.tgt = realTgt
        clashGate.me = me
        if clashGate.lastTgt ~= realTgt then
            clashGate.lastTgt = realTgt
            clashGate.tgtSince = tick()
        end
        clashGate.ok = (realClos ~= nil and realClos > 0.05)
            and (realTgt == me or realTgt == meId or realTgt == clashPartner)
    else
        clashGate.ok = false
    end
    if tapBest then
        ymer.ballPos = tapBest.pos
        ymer.impDist = tapBest.dist
        ymer.bAddr = tapBest.addr
        local readyLead = lead
        local parryAcc = currentParryAcc()
        local curving = (tapBest.closing or 0) <= getEffectiveFacingMin()
        if parryAcc >= 90 then
            if not curving then
                if parryAcc >= 100 then
                    readyLead = lead * 1.08 + 1
                elseif parryAcc >= 95 then
                    readyLead = lead * (0.58 + (parryAcc / 100) * 0.5)
                else
                    readyLead = lead * (0.55 + (parryAcc / 100) * 0.5)
                end
            end
        elseif parryAcc >= 50 and parryAcc < 80 then
            readyLead = lead * (0.5 + (parryAcc / 100) * 0.57)
        elseif parryAcc >= 80 and parryAcc < 90 then
            readyLead = lead * (0.55 + (parryAcc / 100) * 0.48)
        else
            readyLead = lead * (0.45 + (parryAcc / 100) * 0.55)
        end
        local minLead = math.max(lala.closeRangeDist, lala.panicBase + tapBest.speed * lala.panicSpeedMul * 0.5) * 0.85
        if readyLead < minLead then readyLead = minLead end
        if lala.smartParry then
            if lala.randomize then lala.randomize = false end
            local smartAcc = math.clamp(20 + tapBest.speed * 0.04, 20, 35)
            ymer.smartAcc = smartAcc
            ymer.parryDist = nil
            local smartLead = lead * (0.45 + (smartAcc / 100) * 0.65)
            if tapBest.dist > smartLead then
                -- outside smart window
            else
                local curvingSmart = (tapBest.closing or 0) <= getEffectiveFacingMin()
                local isMyAbility = abilityActive
                local isMyInfinity = false
                pcall(function()
                    if tapBest.addr and remy.recentlyTapped[tapBest.addr] and tick() - remy.recentlyTapped[tapBest.addr] < 2 then
                        local b = workspace:FindFirstChild("Balls") and workspace.Balls:FindFirstChild(tapBest.addr)
                        if b and (b:FindFirstChild("InfinityFX") or b:FindFirstChild("TrueInfinityFX")) then
                            isMyInfinity = true
                        end
                    end
                end)
                if isMyAbility or isMyInfinity then
                elseif not curvingSmart and not genLock[tapBest.addr] and not ballParriedOnce[tapBest.addr] and (now - (ballSpawnedAt[tapBest.addr] or 0)) >= NEW_BALL_GRACE then
                    if t2 - remy.lastTap > lala.cooldown then
                        remy.lastTap = t2
                        ymer.flash = t2
                        genLock[tapBest.addr] = t2
                        ballParriedOnce[tapBest.addr] = t2
                        stats.taps = stats.taps + 1
                        doHumanParry()
                    end
                end
            end
            -- when smart parry on it skips normal/panic/visuals entirely PLEASeworkd dfcwsaglfjvkmawgn
        else
            ymer.smartAcc = nil
            ymer.parryDist = readyLead
            local ready = (tapBest.dist <= readyLead)
        local dynamicPanic3 = lala.panicBase + tapBest.speed * lala.panicSpeedMul
        local isPanic = tapBest.dist < dynamicPanic3 and tapBest.dist <= lead
        local threshold = 0
        local readyToParry = v2on and ready and ((genSeen[tapBest.addr] or 0) >= threshold
            and not genLock[tapBest.addr] and not abilityActive
            and not ballParriedOnce[tapBest.addr]
            and (tapBest.closing or 0) > getEffectiveFacingMin()
            and (now - (ballSpawnedAt[tapBest.addr] or 0)) >= NEW_BALL_GRACE)
        if readyToParry then
            local w0 = genWatch[tapBest.addr]
            local speedCooldown = lala.cooldown
            local isCloseTrigger = tapBest.dist <= lala.closeRangeDist
            local dynamicPanic4 = lala.panicBase + tapBest.speed * lala.panicSpeedMul
            local isPanicTrigger = lala.panicParry ~= false and tapBest.dist < dynamicPanic4 and tapBest.speed > 60
            if isPanicTrigger then recentlyPanic[tapBest.addr] = t2 end
            local wasRecentPanic = recentlyPanic[tapBest.addr] and (t2 - recentlyPanic[tapBest.addr] < PANIC_GRACE)
            local curvingPanic = (tapBest.closing or 0) <= getEffectiveFacingMin()
            if lala.panicParry ~= false and not curvingPanic and (isCloseTrigger or isPanicTrigger or wasRecentPanic) then
                speedCooldown = 0.001
            end
            if t2 - remy.lastTap > speedCooldown then
                remy.lastTap = t2
                ymer.flash = t2
                remy.recentlyTapped[tapBest.addr] = t2
                genLock[tapBest.addr] = t2
                ballParriedOnce[tapBest.addr] = t2
                if w0 then
                    w0.t = t2
                    w0.ntap = (w0.ntap or 0) + 1
                    w0.spd = tapBest.speed
                    w0.dist = tapBest.dist
                else
                    genWatch[tapBest.addr] = { t = t2, hp = genHp, spd = tapBest.speed, dist = tapBest.dist, ntap = 1 }
                end
                stats.taps = stats.taps + 1
                doHumanParry()
            end
        end
        end
    else
        if nBest then
            ymer.ballPos = nBest.pos
            ymer.impDist = nBest.dist
            ymer.bAddr = nBest.addr
        else
            ymer.ballPos = nil
            ymer.impDist = nil
            ymer.bAddr = nil
        end
    end
    -- turn the auto-on Sing v1 triggerbot back off when the ball slows down intensely
    if _G.__singV1AutoEnabled and lala.triggerbot and lala.singularityV1AutoTrigger then
        local tgtSpeed = tapBest and tapBest.speed or 0
        if tgtSpeed >= 65 and tgtSpeed < (_G.__singV1LastSpeed or tgtSpeed) * 0.4 then
            lala.triggerbot = false
            _G.__singV1AutoEnabled = false
            saveConfig()
        end
        _G.__singV1LastSpeed = tgtSpeed
    end
    -- turn the auto-on Duality triggerbot back off once Duality has been gone a while
    if _G.__dualAutoEnabled and lala.triggerbot and lala.dualityAutoTrigger then
        local alive = _G.__apDualityOn or false
        local lastD = _G.__dualAutoLastSeen or now
        if not alive and (not tapBest or now - lastD > 2.0) then
            lala.triggerbot = false
            _G.__dualAutoEnabled = false
            saveConfig()
        end
        if alive then _G.__dualAutoLastSeen = now end
    end
    if _G.__apDualityOn then _G.__dualAutoLastSeen = now end
    lastScanState.tapBest = tapBest
    lastScanState.abilityActive = abilityActive
    lastScanState.lead = lead
    lastScanState.parryDist = ymer.parryDist or lead
    lastScanState.now = t2
end
_G.__apHB = RunService.Heartbeat:Connect(function(dt)
    local okS, errS = pcall(scan, dt)
    if not okS then _G.__scanErr = tostring(errS) end
end)
local clashRunning = true
local clashLoop
clashLoop = task.spawn(function()
    while clashRunning do
        if bob == _G.__apGen and lala.v2 and not ymer.idle and lala.clash and clashGate.ok then
            local c = tick()
            local tgtStable = clashGate.tgtSince and (c - clashGate.tgtSince > 0.05)
            if tgtStable and c - remy.lastTap > 0.001 and not remy.tapping then
                local uf = _G.__apUserF
                if uf == 0 or c - uf > lala.userSuppress then
                    remy.lastTap = c
                    ymer.flash = c
                    stats.taps = stats.taps + 1
                    remy.tapping = true
                    local rel = pressParry()
                    task.spawn(function()
                        task.wait(0.00001)
                        if rel then pcall(rel) end
                        remy.tapping = false
                    end)
                end
            end
        end
        task.wait(lala.clash and 0.00001 or 0.05)
    end
end)
_G.__apClashLoop = clashLoop

local panicRunning = true
local panicLoop
panicLoop = task.spawn(function()
    while panicRunning do
        if bob == _G.__apGen and lala.v2 and not ymer.idle and not lala.clash then
            local st = lastScanState
            local tb = st.tapBest
            if tb and tb.addr and not st.abilityActive then
                local c = tick()
                local dynamicPanic = lala.panicBase + tb.speed * lala.panicSpeedMul
                local isPanic = lala.panicParry ~= false and tb.dist < dynamicPanic and tb.speed > 60
                local isClose = tb.dist <= lala.closeRangeDist
                local inLead = tb.dist <= (st.parryDist or st.lead or 0)
                local facingOk = (tb.closing or 0) > getEffectiveFacingMin()
                if (isPanic or isClose or (inLead and facingOk)) and c - remy.lastTap > 0.00003 then
                    if not genLock[tb.addr] and not ballParriedOnce[tb.addr]
                        and (c - (ballSpawnedAt[tb.addr] or 0)) >= NEW_BALL_GRACE then
                        local w0 = genWatch[tb.addr]
                        remy.lastTap = c
                        ymer.flash = c
                        remy.recentlyTapped[tb.addr] = c
                        genLock[tb.addr] = c
                        ballParriedOnce[tb.addr] = c
                        if w0 then
                            w0.t = c
                            w0.ntap = (w0.ntap or 0) + 1
                            w0.spd = tb.speed
                            w0.dist = tb.dist
                        else
                            genWatch[tb.addr] = { t = c, hp = genHp, spd = tb.speed, dist = tb.dist, ntap = 1 }
                        end
                        stats.taps = stats.taps + 1
                        local rel = pressParry()
                        if rel then pcall(rel) end
                    end
                end
            end
        end
        task.wait(0.00003)
    end
end)
_G.__apPanicLoop = panicLoop

_G.__vm = function()
    if lala.viewEnabled == false then return "Off" end
    return "Circle"
end
_G.__spinA = 0
_G.__spinT = 0
_G.__spinOn = function()
    return lala.spin == true and _G.__vm() == "Circle"
end
_G.__spinStep = function()
    local now = tick()
    local dt = now - (_G.__spinT or now)
    if dt <= 0 or dt > 0.25 then dt = 0.016 end
    _G.__spinT = now
    local spd = tonumber(lala.spinSpeed) or 45
    _G.__spinA = ((_G.__spinA or 0) + math.rad(spd) * dt) % TAU
    return _G.__spinA
end
_G.__ringBuild = function(c, R, dn, ptsOut, vflOut)
    local sphase = _G.__spinOn() and _G.__spinStep() or 0
    for j = 0, dn do
        local az = (j / dn) * TAU + sphase
        local wp = c + Vector3.new(math.cos(az) * R, 0, math.sin(az) * R)
        local sp, v = WorldToScreen(wp)
        ptsOut[j] = sp
        vflOut[j] = v
    end
end

local hitDot = Drawing.new("Line")
hitDot.Thickness = 3
hitDot.Color = Color3.fromRGB(255, 0, 0)
hitDot.Transparency = 0.15
hitDot.Visible = false
local rimLines = {}
for i = 1, DN do
    local l = Drawing.new("Line")
    l.Thickness = 2
    l.Color = Color3.fromRGB(0, 255, 120)
    l.Visible = false
    rimLines[i] = l
end

local function keyLabel(k)
    if not k then return "NONE" end
    if k >= 65 and k <= 90 then return string.char(k) end
    if k >= 48 and k <= 57 then return string.char(k) end
    return "K" .. tostring(k)
end

local KB_ROWS = {
    { name = "Auto Parry", key = "keyP", get = function() return lala.v2 end },
    { name = "Clash", key = "keyX", get = function() return lala.clash end },
    { name = "Ability Parry", key = "keyB", get = function() return lala.abilityParry end },
    { name = "Smart Parry", key = "keySmart", get = function() return lala.smartParry end },
    { name = "Triggerbot", key = "keyT", get = function() return lala.triggerbot end },
    { name = "Auto Curve", key = "keyY", get = function() return lala.curveOnHit end },
    { name = "Randomize", key = "keyR", get = function() return lala.randomize end },
    { name = "Custom Lead", key = "keyL", get = function() return lala.customLeadMode end },
    { name = "Anti-Curve", key = "keyN", get = function() return lala.customFacingMinMode end },
    { name = "Panic Parry", key = "keyPanic", get = function() return lala.panicParry end },
}

local kbx, kby = 20, 220
local kbPW, kbPH = 110, 20
local kbSig = nil
local kbDrawn = false
local kbBg = Drawing.new("Square")
kbBg.Filled = true
kbBg.Size = Vector2.new(110, 20)
kbBg.Color = Color3.fromRGB(15, 16, 22)
kbBg.Transparency = 0.72
kbBg.Visible = false
local kbBorder = Drawing.new("Square")
kbBorder.Filled = false
kbBorder.Thickness = 1
kbBorder.Size = kbBg.Size
kbBorder.Color = Color3.fromRGB(60, 62, 80)
kbBorder.Transparency = 1
kbBorder.Visible = false
local kbBar = Drawing.new("Square")
kbBar.Filled = true
kbBar.Color = Color3.fromRGB(255, 255, 255)
kbBar.Transparency = 1
kbBar.Visible = false
local kbTitle = Drawing.new("Text")
kbTitle.Size = 13
kbTitle.Font = 8
kbTitle.Outline = true
kbTitle.Color = Color3.fromRGB(255, 255, 255)
kbTitle.Transparency = 1
kbTitle.Text = "Keybinds"
kbTitle.Visible = false
local kbRow = {}
for ri = 1, #KB_ROWS do
    local t = Drawing.new("Text")
    t.Size = 12
    t.Font = 8
    t.Outline = true
    t.Transparency = 1
    t.Visible = false
    kbRow[ri] = t
end

_G.__apCleanup = function()
    clashRunning = false
    panicRunning = false
    _G.__apClashLoop = nil
    _G.__apPanicLoop = nil
    for i = 1, DN do pcall(rimLines[i].Remove, rimLines[i]) end
    pcall(hitDot.Remove, hitDot)
    for _, o in ipairs({ kbBg, kbBorder, kbBar, kbTitle }) do pcall(o.Remove, o) end
    for i = 1, #kbRow do pcall(kbRow[i].Remove, kbRow[i]) end
end

local lastToggleKey, lastToggleT = nil, 0
local function doToggle(key)
    local t = tick()
    if key == lastToggleKey and t - lastToggleT < 0.25 then return end
    lastToggleKey, lastToggleT = key, t
    if key == "P" then
        lala.v2 = not lala.v2
    elseif key == "X" then
        lala.clash = not lala.clash
        if lala.clash then
            clashSawMine = false
            clashLastMine = 0
            clashNoBallT = tick()
            clashPartner = nil
        end
    elseif key == "B" then
        lala.abilityParry = not lala.abilityParry
    elseif key == "T" then
        lala.triggerbot = not lala.triggerbot
    elseif key == "Smart" then
        lala.smartParry = not lala.smartParry
    elseif key == "Panic" then
        lala.panicParry = not lala.panicParry
    elseif key == "R" then
        if lala.smartParry then return end
        lala.randomize = not lala.randomize
    elseif key == "ACCPLUS" then
        lala.accuracy = math.clamp(lala.accuracy + 5, 1, 100)
    elseif key == "ACCMINUS" then
        lala.accuracy = math.clamp(lala.accuracy - 5, 1, 100)
    elseif key == "L" then
        lala.customLeadMode = not lala.customLeadMode
    elseif key == "LBRACKET" then
        lala.customLeadValue = math.clamp(lala.customLeadValue + 0.01, 0.05, 1.0)
        lala.customLeadMode = true
    elseif key == "RBRACKET" then
        lala.customLeadValue = math.clamp(lala.customLeadValue - 0.01, 0.05, 1.0)
        lala.customLeadMode = true
    elseif key == "N" then
        lala.customFacingMinMode = not lala.customFacingMinMode
    elseif key == "FPLUS" then
        lala.customFacingMinValue = math.clamp(lala.customFacingMinValue + 0.01, -1, 1)
        lala.customFacingMinMode = true
    elseif key == "FMINUS" then
        lala.customFacingMinValue = math.clamp(lala.customFacingMinValue - 0.01, -1, 1)
        lala.customFacingMinMode = true
    end
    saveConfig()
end

local cam = workspace.CurrentCamera or game:GetService("Camera")
local ringR = 21
local pts = {}
local vfl = {}
local lastRingCam = nil
local lastRingCenter = Vector3.zero
local lastRingLead = 0
local lastRingT = 0
local conn
local C_CACHE = { f = nil, t = nil, th = nil, r = nil, g = nil, b = nil }
local hdC = { r = nil, g = nil, b = nil }
local hdTh, hdTr = nil, nil
local wasP, wasX, wasB, wasT, wasL, wasR, wasN = false, false, false, false, false, false, false
local wasLB, wasRB, wasSmart, wasPanic = false, false, false, false
local wasFP, wasFM, wasAccM, wasAccP = false, false, false, false

conn = RunService.RenderStepped:Connect(function()
    if bob ~= _G.__apGen then return end
    local np = keyHeld(lala.keyP)
    local nx = keyHeld(lala.keyX)
    local nb = keyHeld(lala.keyB)
    local nt = keyHeld(lala.keyT)
    local nl = keyHeld(lala.keyL)
    local nr = keyHeld(lala.keyR)
    local nn = keyHeld(lala.keyN)
    local nSmart = keyHeld(lala.keySmart)
    local nPanic = keyHeld(lala.keyPanic)
    local nlb = (219 ~= (_G._genUIKey or 45)) and keyHeld(219) or false
    local nrb = (221 ~= (_G._genUIKey or 45)) and keyHeld(221) or false
    local naccp = (187 ~= (_G._genUIKey or 45)) and keyHeld(187) or false
    local naccm = (189 ~= (_G._genUIKey or 45)) and keyHeld(189) or false
    local nfp = (190 ~= (_G._genUIKey or 45)) and keyHeld(190) or false
    local nfm = (188 ~= (_G._genUIKey or 45)) and keyHeld(188) or false
    if np and not wasP then doToggle("P") end
    if nx and not wasX then doToggle("X") end
    if nb and not wasB then doToggle("B") end
    if nt and not wasT then doToggle("T") end
    if nl and not wasL then doToggle("L") end
    if nr and not wasR then doToggle("R") end
    if nn and not wasN then doToggle("N") end
    if nSmart and not wasSmart then doToggle("Smart") end
    if nPanic and not wasPanic then doToggle("Panic") end
    if nlb and not wasLB then doToggle("LBRACKET") end
    if nrb and not wasRB then doToggle("RBRACKET") end
    if naccp and not wasAccP then doToggle("ACCPLUS") end
    if naccm and not wasAccM then doToggle("ACCMINUS") end
    if nfp and not wasFP then doToggle("FPLUS") end
    if nfm and not wasFM then doToggle("FMINUS") end
    wasP, wasX, wasB, wasT, wasL, wasR, wasN = np, nx, nb, nt, nl, nr, nn
    wasSmart, wasPanic = nSmart, nPanic
    wasLB, wasRB = nlb, nrb
    wasAccP, wasAccM = naccp, naccm
    wasFP, wasFM = nfp, nfm

    -- Keybinds List overlay
    if lala.keybindsHud then
        local sig = nil
        for i = 1, #KB_ROWS do
            if KB_ROWS[i].get() then
                sig = (sig or "") .. i .. ":" .. tostring(lala[KB_ROWS[i].key]) .. ";"
            end
        end
        if sig then
            local rebuild = (sig ~= kbSig)
            if rebuild then
                kbSig = sig
                local maxW = kbTitle.TextBounds.X
                local ri = 0
                for i = 1, #KB_ROWS do
                    if KB_ROWS[i].get() then
                        ri = ri + 1
                        local r = kbRow[ri]
                        r.Text = KB_ROWS[i].name .. " [" .. keyLabel(lala[KB_ROWS[i].key]) .. "]"
                        r.Color = Color3.fromRGB(201, 201, 209)
                        r.Outline = true
                        r.Visible = true
                        local w = r.TextBounds.X
                        if w > maxW then maxW = w end
                    end
                end
                for i = ri + 1, #kbRow do kbRow[i].Visible = false end
                local maxW2 = maxW + 16
                local ph = 32 + ri * 17 + 8
kbBg.Position = Vector2.new(kbx, kby)
                kbBg.Size = Vector2.new(maxW2, ph)
                kbBorder.Position = Vector2.new(kbx, kby)
                kbBorder.Size = Vector2.new(maxW2, ph)
                kbBar.Position = Vector2.new(kbx + 8, kby + 24)
                kbBar.Size = Vector2.new(maxW2 - 16, 2)
                kbTitle.Position = Vector2.new(kbx + 8, kby + 6)
                for i = 1, ri do
                    kbRow[i].Position = Vector2.new(kbx + 8, kby + 34 + (i - 1) * 17)
                end
                kbPW = maxW2
                kbPH = ph
            end
            kbBg.Visible = true
            kbBorder.Visible = true
            kbBar.Visible = true
            kbTitle.Visible = true
            kbDrawn = true
        else
            kbSig = nil
            kbDrawn = false
            kbBg.Visible = false
            kbBorder.Visible = false
            kbBar.Visible = false
            kbTitle.Visible = false
            for i = 1, #kbRow do kbRow[i].Visible = false end
        end
    else
        kbSig = nil
        kbDrawn = false
        kbBg.Visible = false
        kbBorder.Visible = false
        kbBar.Visible = false
        kbTitle.Visible = false
        for i = 1, #kbRow do kbRow[i].Visible = false end
    end

    local tc = tick()
    if _G.__vm() == "Off" or not (lala.v2 and ymer.centerPos) or ymer.abilityActive or ymer.idle then
        for i = 1, DN do
            if rimLines[i].Visible then rimLines[i].Visible = false end
        end
        hitDot.Visible = false
        return
    end
    ringR = ringR + (ymer.leadDist - ringR) * 0.08
    local R = ringR
    local c = ymer.centerPos
    local flashAge = tc - ymer.flash

    local dc = tick()
    local cp = cam.CFrame
    local camMoved = not lastRingCam
        or (cp.Position - lastRingCam.Position).Magnitude > 0.1
        or (cp.LookVector - lastRingCam.LookVector).Magnitude > 0.02
    local ringStale = (c - lastRingCenter).Magnitude > 0.15
        or math.abs(R - lastRingLead) > 1
        or dc - lastRingT > 0.5
        or _G.__spinOn()
    if camMoved or ringStale then
        lastRingT = dc
        lastRingCam = cp
        lastRingCenter = c
        lastRingLead = R
        _G.__ringBuild(c, R, DN, pts, vfl)
    end
    local flashing = flashAge < 0.4
    local acr, acg, acb = lala.apColor.r or 0, lala.apColor.g or 255, lala.apColor.b or 120
    local atrans = lala.apTrans or 5
    local athick = lala.apThick or 2
    if flashing ~= C_CACHE.f or atrans ~= C_CACHE.t or athick ~= C_CACHE.th or acr ~= C_CACHE.r or acg ~= C_CACHE.g or acb ~= C_CACHE.b then
        C_CACHE.f, C_CACHE.t, C_CACHE.th, C_CACHE.r, C_CACHE.g, C_CACHE.b = flashing, atrans, athick, acr, acg, acb
        local bcol
        local bfill = atrans / 100
        if flashing then bcol = Color3.fromRGB(255, 40, 40); bfill = 0.05 else bcol = Color3.fromRGB(acr, acg, acb) end
        for i = 1, DN do
            rimLines[i].Color = bcol
            rimLines[i].Transparency = bfill + 0.3
            rimLines[i].Thickness = athick
        end
    end

    for i = 1, DN do
        local rl = rimLines[i]
        if vfl[i - 1] and vfl[i] then
            rl.From = pts[i - 1]
            rl.To = pts[i]
            rl.Visible = true
        elseif rl.Visible then
            rl.Visible = false
        end
    end

    if not lala.smartParry and lala.parryDistInd ~= false and lala.v2 and ymer.ballPos and c then
        local pDist = ymer.parryDist or R
        local bp = ymer.ballPos
        local dx = bp.X - c.X
        local dz = bp.Z - c.Z
        local dLen = math.sqrt(dx * dx + dz * dz)
        if dLen > 0.5 then
            local ux = dx / dLen
            local uz = dz / dLen
            local floorY = c.Y
            local hitPos = Vector3.new(c.X + ux * pDist, floorY, c.Z + uz * pDist)
            local fromP, fromV = WorldToScreen(Vector3.new(c.X, floorY, c.Z))
            local toP, toV = WorldToScreen(hitPos)
            if fromV and toV then
                hitDot.From = fromP
                hitDot.To = toP
                local hdr, hdg, hdb = lala.pdColor.r or 255, lala.pdColor.g or 0, lala.pdColor.b or 0
                if hdr ~= hdC.r or hdg ~= hdC.g or hdb ~= hdC.b then
                    hdC.r, hdC.g, hdC.b = hdr, hdg, hdb
                    hitDot.Color = Color3.fromRGB(hdr, hdg, hdb)
                end
                local hth = lala.pdThick or 3
                if hth ~= hdTh then hdTh = hth; hitDot.Thickness = hth end
                local htr = (lala.pdTrans or 15) / 100
                if htr ~= hdTr then hdTr = htr; hitDot.Transparency = htr end
                hitDot.Visible = true
            else
                hitDot.Visible = false
            end
        else
            hitDot.Visible = false
        end
    else
        hitDot.Visible = false
    end
end)
_G.__apConn = conn

pcall(function()
    uis.InputBegan:Connect(function(inp)
        if inp and inp.KeyCode and (tostring(inp.KeyCode) == "Slash" or tostring(inp.KeyCode) == "47") then _G.__typingChat = true end
        if inp and tostring(inp.UserInputType):find("MouseButton1",1,true) then _G.__typingChat = false end
        if inp and inp.KeyCode and (tostring(inp.KeyCode) == "Return" or tostring(inp.KeyCode) == "Enter" or tostring(inp.KeyCode) == "13") then _G.__typingChat = false end
        if bob ~= _G.__apGen then return end
        local kc = inp and inp.KeyCode
        local uiVK = _G._genUIKey or 45
        local function match(k)
            if k == uiVK then return false end
            if kc == k then return true end
            if k >= 65 and k <= 90 and kc == k + 32 then return true end
            return false
        end
        if match(lala.keyP) then
            doToggle("P")
        elseif match(lala.keyX) then
            doToggle("X")
        elseif match(lala.keyY) then
            lala.curveOnHit = not (lala.curveOnHit == true)
            local el = ELS and ELS.curveOnHit and ELS.curveOnHit.el
            if el and el.value then el.value.Toggle = lala.curveOnHit end
            pcall(saveConfig)
        end
    end)
end)
end

do
local library = _G.GenLib
local lala = _G.autoParry or {}

local hs = game:GetService("HttpService")
local UI_CFG = "remybbui-circle.json"

local function num(v, d) return type(v) == "number" and v or d end
local function boo(v, d) return type(v) == "boolean" and v or d end

local function cfgData()
    local L = _G.autoParry
    if not L then return nil end
    return {
        _version = 2,
        keyP = L.keyP, keyX = L.keyX,
        keyL = L.keyL, keyB = L.keyB, keyR = L.keyR, keyN = L.keyN,
        v2 = L.v2, abilityParry = L.abilityParry,
        accuracy = L.accuracy, randomize = L.randomize,
        pingComp = L.pingComp, leadTime = L.leadTime, pingMax = L.pingMax,
        customLeadMode = L.customLeadMode, customLeadValue = L.customLeadValue,
        minDist = L.minDist, maxDist = L.maxDist, panicBase = L.panicBase,
        panicSpeedMul = L.panicSpeedMul, cooldown = L.cooldown,
        maxSpeed = L.maxSpeed, fastBallThreshold = L.fastBallThreshold, closeRangeDist = L.closeRangeDist,
        facingMin = L.facingMin, customFacingMinMode = L.customFacingMinMode, customFacingMinValue = L.customFacingMinValue,
        showVis = L.showVis, keybindsHud = L.keybindsHud, clash = L.clash,
        viewEnabled = L.viewEnabled, viewMode = L.viewMode, spin = L.spin, spinSpeed = L.spinSpeed, parryDistInd = L.parryDistInd, curveOnHit = L.curveOnHit, curveDir = L.curveDir, curveRandomSet = L.curveRandomSet, curveFast = L.curveFast,
        uiKey = _G._genUIKey,
        uiAccent = _G._genUIAccent,
        uiTrans = _G._genUITrans,
        hideCard = _G._genHideCard,
        blurName = _G._genBlurName,
    }
end

local lastSnap = hs:JSONEncode(cfgData() or {})

local pendingSave = false
local lastSaveT = 0

local function flushSave()
    if not pendingSave then return end
    if tick() - lastSaveT < 0.5 then return end
    pendingSave = false
    lastSaveT = tick()
    local data = cfgData()
    if not data then return end
    pcall(function() writefile(UI_CFG, hs:JSONEncode(data)) end)
    lastSnap = hs:JSONEncode(data)
end

local function saveUI()
    pendingSave = true
end

local function loadUI()
    pcall(function()
        if not isfile(UI_CFG) then return end
        local data = hs:JSONDecode(readfile(UI_CFG))
        if type(data) ~= "table" then return end
        local ver = tonumber(data._version) or 1
        for k, v in pairs(data) do
            if k ~= "_version" then lala[k] = v end
        end
        if type(data.uiKey) == "number" then _G._genUIKey = data.uiKey end
        if type(data.uiAccent) == "string" and ver >= 2 then _G._genUIAccent = data.uiAccent end
        if type(data.uiTrans) == "number" then _G._genUITrans = math.clamp(data.uiTrans, 35, 100) end
        if type(data.hideCard) == "boolean" then _G._genHideCard = data.hideCard end
        if type(data.blurName) == "boolean" then _G._genBlurName = data.blurName end
        if _G.applyAvName then _G.applyAvName() end
    end)
end
loadUI()
-- Keep the circle view on and all extra visuals off after loading UI state.
lala.bvExtras = false
lala.showVis = false
if lala.viewMode ~= "Circle" then lala.viewMode = "Circle" end
if lala.viewEnabled == nil then lala.viewEnabled = true end

local menu = library.new("gennegen", "nemv2")

local ELS = {}

local MENU_GEN = (_G.__remyMenuGen or 0) + 1
_G.__remyMenuGen = MENU_GEN

local function T(sector, label, field, keyField)
    local el = sector.element("Toggle", label, {
        default = { Toggle = boo(lala[field], false) },
    }, function(v)
        lala[field] = v.Toggle
        saveUI()
    end)
    if keyField then
        local kb = el:add_keybind()
        kb.toggleElement = false
        kb.value.Key = lala[keyField] or nil
        kb.cb = function(v)
            lala[keyField] = v.Key
            saveUI()
        end
    end
    ELS[field] = { el = el, keyField = keyField }
    return el
end

local function S(sector, label, field, min, max, scale, fallback)
    local src = (_G.remybbDefaults and _G.remybbDefaults[field] ~= nil) and _G.remybbDefaults or lala
    local def = math.floor(num(src[field], fallback or 0) * scale + 0.5)
    def = math.max(min, math.min(max, def))
    local el = sector.element("Slider", label, {
        default = { min = min, max = max, default = def },
    }, function(v)
        lala[field] = v.Slider / scale
        saveUI()
    end)
    if scale ~= 1 then
        el.disp = function(v) return string.format("%.2f", v / scale) end
    end
    ELS[field] = { el = el, scale = scale }
    return el
end

do
    local main = menu.new_tab("sword", "COMBAT")

    local autoParry = main.new_section("Main")

    local parry = autoParry.new_sector("Parry")
    parry._desc = "Core parry toggles, clash, ability and panic"
    T(parry, "Autoparry", "v2", "keyP")
    T(parry, "Smart Parry", "smartParry", "keySmart")
    T(parry, "Clash", "clash", "keyX")
    T(parry, "Ability Parry", "abilityParry", "keyB")
    T(parry, "Panic Parry", "panicParry", "keyPanic")

    local trigSec = autoParry.new_sector("Triggerbot")
    trigSec._desc = "Auto-trigger timing"
    T(trigSec, "Triggerbot", "triggerbot", "keyT")
    T(trigSec, "Once", "triggerOnce")
    T(trigSec, "Sing V1 Auto Triggerbot", "singularityV1AutoTrigger")
    T(trigSec, "Duality Auto Triggerbot", "dualityAutoTrigger")
    T(trigSec, "Infinity Auto Triggerbot", "infAutoTrigger")
    S(trigSec, "Infinity Trigger Dist", "infAutoTriggerDist", 1, 60, 1, 30)

    local curveSec = autoParry.new_sector("Auto Curve", "Right")
    curveSec._desc = "Curve direction and power"
    T(curveSec, "Auto Curve On Hit", "curveOnHit", "keyY")
    T(curveSec, "Pre-Turn (fast parry)", "curvePreTurn")
    local simpleCurveOpts = { "Left", "Right", "Up", "Back" }
    local advCurveOpts = { "Back Up", "Back Down", "Back Left", "Back Right", "Left Up", "Left Down", "Right Up", "Right Down" }
    -- if the saved direction is advanced, the standard dropdown cannot display
    -- it, so it should never "overwrite" the active advanced selection

    local curveMainEl = curveSec.element("Dropdown", "Standard Direction", {
        options = simpleCurveOpts,
        default = { Dropdown = (function()
            for _, o in ipairs(simpleCurveOpts) do
                if lala.curveDir == o then return lala.curveDir end
            end
            return simpleCurveOpts[1]
        end)() },
    }, function(v)
        -- only update if the chosen value actually belongs to this list;
        -- advanced directions are ignored here so they cannot be clobbered
        local basic = false
        for _, o in ipairs(simpleCurveOpts) do if v.Dropdown == o then basic = true end end
        if not basic then return end
        lala.curveDir = v.Dropdown
        if curveAdvDirEl and curveAdvDirEl.value then
            for _, o in ipairs(advCurveOpts) do if v.Dropdown == o then curveAdvDirEl.value.Dropdown = v.Dropdown end end
        end
        saveUI()
    end)
    local curveAdvDirEl = curveSec.element("Dropdown", "Advanced Angles", {
        options = advCurveOpts,
        default = { Dropdown = (function()
            for _, o in ipairs(advCurveOpts) do
                if lala.curveDir == o then return lala.curveDir end
            end
            return advCurveOpts[1]
        end)() },
    }, function(v)
        -- advanced only changes the active direction if it is a real advanced
        -- value, so the standard entry is never silently overwritten
        local adv = false
        for _, o in ipairs(advCurveOpts) do if v.Dropdown == o then adv = true end end
        if not adv then return end
        lala.curveDir = v.Dropdown
        if curveMainEl and curveMainEl.value then
            for _, o in ipairs(simpleCurveOpts) do if v.Dropdown == o then curveMainEl.value.Dropdown = v.Dropdown end end
        end
        saveUI()
    end)
    if curveAdvDirEl and curveAdvDirEl.popH then
        curveAdvDirEl.popH = 8 * 18
    end
    T(curveSec, "Random", "curveRandom")
    T(curveSec, "No Repeat", "curveNoRepeat")
    local __curveRandDirs2 = { "Left", "Right", "Up", "Back", "Back Up", "Back Down", "Back Left", "Back Right", "Left Up", "Left Down", "Right Up", "Right Down" }
    local randComboEl = curveSec.element("Combo", "Directions", {
        options = __curveRandDirs2,
        default = { Combo = (type(lala.curveRandomSet) == "table" and lala.curveRandomSet) or __curveRandDirs2 },
    }, function(v)
        lala.curveRandomSet = v.Combo
        saveUI()
    end)
    if randComboEl and randComboEl.popH then
        randComboEl.popH = 12 * 18
    end
    S(curveSec, "Curve Strength", "curveStrength", 25, 200, 1, 100).disp = function(v) return string.format("%d%%", math.floor(v + 0.5)) end

    local selfSec = autoParry.new_sector("Self Abilities")
    selfSec._desc = "Infinity/Singularity avoidance"
    T(selfSec, "Infinity Avoid", "infinityAvoid")
    T(selfSec, "Singularity Avoid", "singularityDetect")

    local secondary = main.new_section("Secondary")
    local lead = secondary.new_sector("Lead")
    lead._desc = "Lead and ping compensation"
    local autoEl = lead.element("Toggle", "Auto-lead", {
        default = { Toggle = (not boo(lala.customLeadMode, false)) and boo(lala.pingComp, false) },
    }, function(v)
        if v.Toggle then
            lala.pingComp = true
            lala.customLeadMode = false
        else
            lala.pingComp = false
        end
        saveUI()
    end)
    ELS.autolead = { el = autoEl }

    local custEl = lead.element("Toggle", "Custom-lead", {
        default = { Toggle = boo(lala.customLeadMode, false) },
    }, function(v)
        if v.Toggle then
            lala.customLeadMode = true
            lala.pingComp = false
        else
            lala.customLeadMode = false
        end
        saveUI()
    end)
    ELS.customlead = { el = custEl }
    do
        local kb = custEl:add_keybind()
        kb.toggleElement = false
        kb.value.Key = lala.keyL or nil
        kb.cb = function(v)
            lala.keyL = v.Key
            saveUI()
        end
    end

    S(lead, "Custom Lead Value", "customLeadValue", 5, 100, 100, 0.10)

    local curve = secondary.new_sector("Anti-Curve")
    curve._desc = "Anti-curve tunables"

    local autoC = curve.element("Toggle", "Auto Anti-Curve", {
        default = { Toggle = not boo(lala.customFacingMinMode, false) },
    }, function(v)
        lala.customFacingMinMode = not v.Toggle
        saveUI()
    end)
    ELS.autocurve = { el = autoC }

    local custC = curve.element("Toggle", "Custom Anti-Curve", {
        default = { Toggle = boo(lala.customFacingMinMode, false) },
    }, function(v)
        lala.customFacingMinMode = v.Toggle
        saveUI()
    end)
    ELS.customcurve = { el = custC }
    do
        local kb = custC:add_keybind()
        kb.toggleElement = false
        kb.value.Key = lala.keyN or nil
        kb.cb = function(v)
            lala.keyN = v.Key
            saveUI()
        end
    end

    S(curve, "Custom Anti-Curve Value", "customFacingMinValue", -100, 0, 100, -0.35)

    local acc = secondary.new_sector("Accuracy", "Right")
    acc._desc = "Accuracy and randomization"
    S(acc, "Parry Accuracy", "accuracy", 1, 100, 1, 100)
    T(acc, "Randomize", "randomize", "keyR")
    S(acc, "Randomize Min", "randMin", 1, 99, 1, 20)
    S(acc, "Randomize Max", "randMax", 2, 100, 1, 100)
    T(acc, "Speed Boost (fast)", "accSpeedBoostOn")
    S(acc, "Boost at Speed", "accSpeedThresh", 20, 150, 1, 70)
    S(acc, "Speed Boost %", "accSpeedBoost", 0, 100, 1, 25)

    local pset = main.new_section("Parry Settings")
    local psec = pset.new_sector("Distances")
    psec._desc = "Distance thresholds"
    S(psec, "Minimum Distance", "minDist", 1, 100, 1, 16)
    S(psec, "Maximum Distance", "maxDist", 50, 2000, 1, 400)
    S(psec, "Panic Range", "panicBase", 5, 100, 1, 28)
    S(psec, "Panic Speed", "panicSpeedMul", 1, 200, 1000, 0.08)
end

do
    local vis = menu.new_tab("eye", "VISUALS").new_section("Visuals")

    local apv = vis.new_sector("Circle")
    apv._desc = "Autoparry circle"
    if lala.parryDistInd == nil then lala.parryDistInd = true end
    if lala.viewMode ~= "Circle" then lala.viewMode = "Circle" end
    if lala.viewEnabled == nil then lala.viewEnabled = true end
    local viewDD
    viewDD = apv.element("Dropdown", "View", {
        options = { "Off", "Circle" },
        default = { Dropdown = (lala.viewEnabled ~= false) and "Circle" or "Off" },
    }, function(v)
        local sel = v.Dropdown
        lala.viewMode = "Circle"
        lala.viewEnabled = (sel ~= "Off")
        saveUI()
    end)
    ELS.viewmode = { el = viewDD }
    T(apv, "Spin", "spin")
    S(apv, "Spin Speed", "spinSpeed", 5, 360, 1, 45)
    do
        local apLookEl = apv.element("Toggle", "AP Color", { default = { Toggle = false } }, function() end)
        do
            local rd = apLookEl.draw
            apLookEl.draw = function()
                rd()
                apLookEl.track.Visible = false
                apLookEl.knob.Visible = false
            end
        end
        local c0 = lala.apColor or { r = 0, g = 255, b = 120 }
        local cl = apLookEl:add_color({ Color = Color3.fromRGB(tonumber(c0.r) or 0, tonumber(c0.g) or 255, tonumber(c0.b) or 120) })
        cl.defC = Color3.fromRGB(0, 255, 120)
        cl.cb = function(v)
            lala.apColor = { r = math.floor(v.Color.R * 255 + 0.5), g = math.floor(v.Color.G * 255 + 0.5), b = math.floor(v.Color.B * 255 + 0.5) }
            saveUI()
        end
    end
    S(apv, "Circle Thickness", "apThick", 1, 8, 1, 2)
    S(apv, "Circle Transparency", "apTrans", 0, 100, 1, 5)
    T(apv, "Parry Distance Indicator", "parryDistInd")
    do
        local pdLookEl = apv.element("Toggle", "Indicator Color", { default = { Toggle = false } }, function() end)
        do
            local rd = pdLookEl.draw
            pdLookEl.draw = function()
                rd()
                pdLookEl.track.Visible = false
                pdLookEl.knob.Visible = false
            end
        end
        local c1 = lala.pdColor or { r = 255, g = 0, b = 0 }
        local cl = pdLookEl:add_color({ Color = Color3.fromRGB(tonumber(c1.r) or 255, tonumber(c1.g) or 0, tonumber(c1.b) or 0) })
        cl.defC = Color3.fromRGB(255, 0, 0)
        cl.cb = function(v)
            lala.pdColor = { r = math.floor(v.Color.R * 255 + 0.5), g = math.floor(v.Color.G * 255 + 0.5), b = math.floor(v.Color.B * 255 + 0.5) }
            saveUI()
        end
    end
    S(apv, "Indicator Thickness", "pdThick", 1, 8, 1, 3)
    S(apv, "Indicator Transparency", "pdTrans", 0, 100, 1, 15)
end

do
    local cfg = menu.new_tab("gear", "CONFIG").new_section("Settings")
    local gen = cfg.new_sector("General")

    local profSlot = "1"
    gen.element("Dropdown", "Config Slot", { options = _G.remybbProfiles and _G.remybbProfiles.slots or { "1" } }, function(v)
        profSlot = v.Dropdown
    end)
    gen.element("Button", "Save To Slot", {}, function()
        if _G.remybbProfiles and _G.remybbProfiles.save(profSlot) then
            pcall(_G.remybbSaveConfig)
            notify("gennegen", "saved to slot " .. profSlot, 2)
        end
    end)
    gen.element("Button", "Load Slot", {}, function()
        if _G.remybbProfiles and _G.remybbProfiles.load(profSlot) then
            task.delay(0.3, function()
                if library.fire_all then library:fire_all() end
                notify("gennegen", "loaded slot " .. profSlot, 2)
            end)
        else
            notify("gennegen", "slot " .. profSlot .. " is empty", 2)
        end
    end)

    local uiKeyEl = gen.element("Toggle", "UI Toggle Key", { default = { Toggle = false } }, function() end)
    do
        local rd = uiKeyEl.draw
        uiKeyEl.draw = function()
            rd()
            uiKeyEl.track.Visible = false
            uiKeyEl.knob.Visible = false
        end
    end
    do
        local kb = uiKeyEl:add_keybind()
        kb.toggleElement = false
        kb.value.Key = _G._genUIKey or 45
        kb.cb = function(v)
            _G._genUIKey = v.Key
            saveUI()
        end
    end

    local uiset = cfg.new_sector("UI Settings", "Right")
    local accEl = uiset.element("Toggle", "Accent Color", { default = { Toggle = false } }, function() end)
    do
        if library.set_alpha then library:set_alpha((tonumber(_G._genUITrans) or 100) / 100) end
        uiset.element("Slider", "UI Transparency", {
            default = { min = 35, max = 100, default = math.max(35, tonumber(_G._genUITrans) or 100) },
        }, function(v)
            _G._genUITrans = v.Slider
            if library.set_alpha then library:set_alpha(v.Slider / 100) end
            saveUI()
        end)
    end
    T(uiset, "Keybinds List", "keybindsHud")

    do
        local rd = accEl.draw
        accEl.draw = function()
            rd()
            accEl.track.Visible = false
            accEl.knob.Visible = false
        end
    end
    do
        local defC = Color3.fromRGB(255, 255, 255)
        if _G._genUIAccent then
            local h = _G._genUIAccent
            defC = Color3.fromRGB(tonumber(h:sub(1, 2), 16) or 255, tonumber(h:sub(3, 4), 16) or 255, tonumber(h:sub(5, 6), 16) or 255)
        end
        local cl = accEl:add_color({ Color = defC })
        cl.isAccent = true
        cl.defC = Color3.fromRGB(255, 255, 255)
        cl.cb = function(v)
            if library.set_accent then library:set_accent(v.Color) end
            _G.swapBgForAccent(v.Color)
            _G._genUIAccent = string.format("%02X%02X%02X", math.floor(v.Color.R * 255 + 0.5), math.floor(v.Color.G * 255 + 0.5), math.floor(v.Color.B * 255 + 0.5))
            saveUI()
        end
        if _G._genUIAccent and library.set_accent then library:set_accent(defC) end
        _G.swapBgForAccent(defC)
    end

    uiset.element("Button", "Reset All Settings", {}, function()
        local d = _G.remybbDefaults
        if d then
            for k, v in pairs(d) do
                if type(v) == "table" then
                    local c = {}
                    for k2, v2 in pairs(v) do c[k2] = v2 end
                    lala[k] = c
                else
                    lala[k] = v
                end
            end
        end
        if library.reset_ui then library:reset_ui() end
        if library.set_all_toggles then library:set_all_toggles(false) end
        lala.customLeadMode = false
        lala.pingComp = true
        lala.customFacingMinMode = false
        lala.viewEnabled = true
        lala.viewMode = "Circle"
        if _G.remybbSaveConfig then pcall(_G.remybbSaveConfig) end
        _G._genUIAccent = nil
        _G._genUIKey = nil
        uiKeyEl.kb.value.Key = 45
        saveUI()
        notify("gennegen", "all settings reset to defaults", 2)
    end)

    uiset.element("Button", "Unload Script", {}, function()
        notify("gennegen", "unloading script", 1)
        task.delay(0.4, function()
            _G.__apGen = (_G.__apGen or 0) + 1
            if _G.__apCleanup then pcall(_G.__apCleanup) end
            pcall(function()
                for _, k in ipairs({ 87, 65, 83, 68, 32 }) do keyrelease(k) end
            end)
            if _G._genToken and _G._genToken.unload then pcall(_G._genToken.unload) end
            _G.GenLib = nil
            _G.remybbMenu = nil
            _G.autoParry = nil
        end)
    end)
end

_G.remybbMenu = menu

local function leadForPing(pingMs)
    local tiers = lala.pingTiers or { 30, 50, 70, 120, 170 }
    local leads = lala.pingLead or { 0.34, 0.38, 0.44, 0.52, 0.58, 0.64 }
    for i = 1, #tiers do
        if pingMs <= tiers[i] then return leads[i] end
    end
    return leads[#leads]
end

task.spawn(function()
    while _G.__remyMenuGen == MENU_GEN and _G._genToken ~= nil do
        pcall(function()
        local snap = hs:JSONEncode(cfgData() or {})
        if snap ~= lastSnap then saveUI() end
        flushSave()
        for field, rec in pairs(ELS) do
            local e = rec.el
            if field == "autolead" then
                local on = (not boo(lala.customLeadMode, false)) and boo(lala.pingComp, false)
                if on ~= e.value.Toggle then e.value.Toggle = on end
                local label = "Auto-lead"
                if on then
                    local ping = 0
                    pcall(function() ping = GetPingValue() or 0 end)
                    label = label .. "  (" .. string.format("%.2f", leadForPing(ping)) .. "s)"
                end
                if e.text ~= label then e.text = label end
            elseif field == "customlead" then
                local on = boo(lala.customLeadMode, false)
                if on ~= e.value.Toggle then e.value.Toggle = on end
            elseif field == "autocurve" then
                local on = not boo(lala.customFacingMinMode, false)
                if on ~= e.value.Toggle then e.value.Toggle = on end
                local label = "Auto Anti-Curve"
                if on then
                    label = label .. "  (" .. string.format("%.2f", num(lala.facingMin, -0.35)) .. ")"
                end
                if e.text ~= label then e.text = label end
            elseif field == "customcurve" then
                local on = boo(lala.customFacingMinMode, false)
                if on ~= e.value.Toggle then e.value.Toggle = on end
            elseif field == "viewmode" then
                local sel = _G.__vm()
                if e.value.Dropdown ~= sel then e.value.Dropdown = sel end
            else
                local lv = lala[field]
                if e.kind == "Toggle" and type(lv) == "boolean" and lv ~= e.value.Toggle then
                    e.value.Toggle = lv
                elseif e.kind == "Slider" and type(lv) == "number" then
                    local scaled = math.floor(lv * (rec.scale or 1) + 0.5)
                    scaled = math.max(e.min, math.min(e.max, scaled))
                    if scaled ~= e.value.Slider then e.value.Slider = scaled end
                end
                if rec.keyField and e.kb and lala[rec.keyField] ~= e.kb.value.Key then
                    e.kb.value.Key = lala[rec.keyField]
                end
            end
        end
        end)
        task.wait(0.1)
    end
end)
end

do
    _G.applyMenuFade()
    local light = _G._bgIsLight
    local red = _G._bgIsRed
    local blk = _G._bgIsBlack
    local pnk = _G._bgIsPink
    local cOuter = light and Color3.fromRGB(185, 185, 190) or (red and Color3.fromRGB(95, 18, 22) or (blk and Color3.fromRGB(28, 28, 32) or (pnk and Color3.fromRGB(130, 45, 82) or Color3.fromRGB(22, 24, 32))))
    local cPanel = light and Color3.fromRGB(248, 248, 250) or (red and Color3.fromRGB(45, 10, 14) or (blk and Color3.fromRGB(12, 12, 15) or (pnk and Color3.fromRGB(100, 30, 60) or Color3.fromRGB(16, 17, 24))))
    local cTitle = light and Color3.fromRGB(28, 28, 34) or C_WHT
    local cStatus = light and Color3.fromRGB(95, 95, 105) or (red and Color3.fromRGB(235, 180, 185) or C_GRY)
    local cTrack = light and Color3.fromRGB(216, 216, 222) or (red and Color3.fromRGB(70, 14, 18) or (blk and Color3.fromRGB(22, 22, 26) or (pnk and Color3.fromRGB(120, 40, 75) or Color3.fromRGB(30, 32, 40))))
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local cx, cy = vp.X * 0.5, vp.Y * 0.5 - 20
    local LW, LH = 300, 104
    local lx, ly = cx - LW / 2, cy - LH / 2
    local function raw(t, props)
        local d = Drawing.new(t)
        if props then for k, v in pairs(props) do d[k] = v end end
        return d
    end
    local shadow = raw("Square", { Filled = true, Color = Color3.new(0, 0, 0), Transparency = 0.55, Position = Vector2.new(lx + 4, ly + 4), Size = Vector2.new(LW, LH), ZIndex = 50, Rounding = 8 })
    local outer = raw("Square", { Filled = true, Color = cOuter, Position = Vector2.new(lx, ly), Size = Vector2.new(LW, LH), ZIndex = 51, Rounding = 8 })
    local panel = raw("Square", { Filled = true, Color = cPanel, Position = Vector2.new(lx + 1, ly + 1), Size = Vector2.new(LW - 2, LH - 2), ZIndex = 52, Rounding = 7 })
    local bordr = raw("Square", { Filled = false, Color = _G._bdrClr or C_ACC, Position = Vector2.new(lx, ly), Size = Vector2.new(LW, LH), ZIndex = 52, Thickness = 1 })
    local ttl = raw("Text", { Text = "gennegen", Size = 18, Font = 2, Color = cTitle, Center = true, Outline = true, Position = Vector2.new(cx, ly + 18), ZIndex = 53 })
    local glowSoft = raw("Square", { Filled = true, Color = C_ACC, Position = Vector2.new(cx - 60, ly + 43), Size = Vector2.new(120, 4), ZIndex = 52, Transparency = 0.15 })
    local glow = raw("Square", { Filled = true, Color = C_ACC, Position = Vector2.new(cx - 60, ly + 44), Size = Vector2.new(120, 2), ZIndex = 53 })
    local st = raw("Text", { Text = "loading modules...", Size = 13, Font = 11, Color = cStatus, Center = true, Outline = not light, Position = Vector2.new(cx, ly + 56), ZIndex = 53 })
    local trk = raw("Square", { Filled = true, Color = cTrack, Position = Vector2.new(cx - 110, ly + 80), Size = Vector2.new(220, 6), ZIndex = 53, Rounding = 3 })
    local fil = raw("Square", { Filled = true, Color = C_ACC, Position = Vector2.new(cx - 110, ly + 80), Size = Vector2.new(1, 6), ZIndex = 54, Rounding = 3 })
    task.spawn(function()
        local t0 = tick()
        local dur = 2.6
        while true do
            local p = math.min(1, (tick() - t0) / dur)
            local e = p < 0.5 and 2 * p * p or 1 - ((-2 * p + 2) ^ 2) / 2
            fil.Size = Vector2.new(math.max(1, math.floor(220 * e)), 6)
            st.Text = p < 0.3 and "loading modules..." or (p < 0.55 and "decoding assets..." or (p < 0.85 and "building interface..." or "done"))
            if p >= 1 then break end
            task.wait()
        end
        st.Text = "done"
        task.wait(0.2)
        shadow:Remove(); outer:Remove(); panel:Remove(); bordr:Remove(); ttl:Remove(); glow:Remove(); glowSoft:Remove(); st:Remove(); trk:Remove(); fil:Remove()
        _G._genLoaded = true
    end)
end