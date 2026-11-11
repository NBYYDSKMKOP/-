local FaceIDLib = {}
FaceIDLib.__index = FaceIDLib
FaceIDLib.Name = "FaceIDLib"
FaceIDLib.Version = "3.1.0"
FaceIDLib.Build = "20261111"
FaceIDLib.Prefix = "[FaceIDLib]"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

local floor = math.floor
local ceil = math.ceil
local abs = math.abs
local sqrt = math.sqrt
local sin = math.sin
local cos = math.cos
local pi = math.pi
local rad = math.rad
local random = math.random
local huge = math.huge
local maxn = math.max
local minn = math.min

local Color3new = Color3.new
local Color3fromRGB = Color3.fromRGB
local Color3fromHSV = Color3.fromHSV
local Color3toHSV = Color3.toHSV
local UDim2new = UDim2.new
local UDim2fromOffset = UDim2.fromOffset
local UDim2fromScale = UDim2.fromScale
local UDimnew = UDim.new
local Vector2new = Vector2.new
local TweenInfoNew = TweenInfo.new

local function isInstance(value)
    return typeof(value) == "Instance"
end

local function isTable(value)
    return type(value) == "table"
end

local function isNumber(value)
    return type(value) == "number"
end

local function isString(value)
    return type(value) == "string"
end

local function isFunction(value)
    return type(value) == "function"
end

local function noop()

end

local function identity(value)
    return value
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function clamp01(value)
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function round(value, precision)
    local mult = 10 ^ (precision or 0)
    return floor(value * mult + 0.5) / mult
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(a, b, t)
    return Color3new(lerp(a.R, b.R, t), lerp(a.G, b.G, t), lerp(a.B, b.B, t))
end

local function inverseLerp(a, b, value)
    if a == b then
        return 0
    end
    return (value - a) / (b - a)
end

local function mapRange(value, inMin, inMax, outMin, outMax)
    return outMin + (outMax - outMin) * clamp01(inverseLerp(inMin, inMax, value))
end

local function approach(current, target, amount)
    if current < target then
        return minn(current + amount, target)
    end
    return maxn(current - amount, target)
end

local function isNaN(value)
    return value ~= value
end

local function deepCopy(source)
    if type(source) ~= "table" then
        return source
    end
    local copy = {}
    for key, value in next, source do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local function deepMerge(target, source)
    if type(source) ~= "table" then
        return target
    end
    for key, value in next, source do
        if type(value) == "table" and type(target[key]) == "table" then
            deepMerge(target[key], value)
        else
            if type(value) == "table" then
                target[key] = deepCopy(value)
            else
                target[key] = value
            end
        end
    end
    return target
end

local function shallowCopy(source)
    local copy = {}
    for key, value in next, source do
        copy[key] = value
    end
    return copy
end

local function countTable(source)
    local total = 0
    for _ in next, source do
        total = total + 1
    end
    return total
end

local function sortedKeys(source)
    local keys = {}
    for key in next, source do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    return keys
end

local function trim(text)
    if type(text) ~= "string" then
        return ""
    end
    return (text:gsub("^%s*(.-)%s*$", "%1"))
end

local function split(text, separator)
    local parts = {}
    if type(text) ~= "string" then
        return parts
    end
    local pattern = "([^" .. separator .. "]+)"
    for piece in text:gmatch(pattern) do
        table.insert(parts, piece)
    end
    return parts
end

local function fillTemplate(template, values)
    if type(template) ~= "string" then
        return ""
    end
    local result = template
    for key, value in next, values do
        result = result:gsub("{" .. tostring(key) .. "}", tostring(value))
    end
    return result
end

local function hexToColor3(hex)
    if typeof(hex) == "Color3" then
        return hex
    end
    if type(hex) ~= "string" then
        return nil
    end
    local text = hex:gsub("#", "")
    if #text == 3 then
        local r = text:sub(1, 1)
        local g = text:sub(2, 2)
        local b = text:sub(3, 3)
        text = r .. r .. g .. g .. b .. b
    end
    if #text ~= 6 and #text ~= 8 then
        return nil
    end
    local r = tonumber(text:sub(1, 2), 16)
    local g = tonumber(text:sub(3, 4), 16)
    local b = tonumber(text:sub(5, 6), 16)
    if not r or not g or not b then
        return nil
    end
    return Color3fromRGB(r, g, b)
end

local function color3ToHex(color)
    if typeof(color) ~= "Color3" then
        return "#000000"
    end
    local r = clamp(floor(color.R * 255 + 0.5), 0, 255)
    local g = clamp(floor(color.G * 255 + 0.5), 0, 255)
    local b = clamp(floor(color.B * 255 + 0.5), 0, 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function parseColor(value, fallback)
    if typeof(value) == "Color3" then
        return value
    end
    if type(value) == "table" then
        local r = value.R or value.r or value[1] or 0
        local g = value.G or value.g or value[2] or 0
        local b = value.B or value.b or value[3] or 0
        if r > 1 or g > 1 or b > 1 then
            return Color3fromRGB(clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255))
        end
        return Color3new(clamp01(r), clamp01(g), clamp01(b))
    end
    if type(value) == "string" then
        local direct = hexToColor3(value)
        if direct then
            return direct
        end
        local r, g, b = value:match("(%d+),%s*(%d+),%s*(%d+)")
        if r and g and b then
            return Color3fromRGB(tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0)
        end
    end
    return fallback or Color3fromRGB(255, 255, 255)
end

local function shadeColor(color, amount)
    if typeof(color) ~= "Color3" then
        color = parseColor(color)
    end
    local h, s, v = Color3toHSV(color)
    if amount >= 0 then
        v = clamp01(v + (1 - v) * amount)
    else
        v = clamp01(v * (1 + amount))
    end
    return Color3fromHSV(h, s, v)
end

local function saturateColor(color, amount)
    if typeof(color) ~= "Color3" then
        color = parseColor(color)
    end
    local h, s, v = Color3toHSV(color)
    return Color3fromHSV(h, clamp01(s + (1 - s) * amount), v)
end

local function rotateHue(color, degrees)
    if typeof(color) ~= "Color3" then
        color = parseColor(color)
    end
    local h, s, v = Color3toHSV(color)
    return Color3fromHSV((h + degrees / 360) % 1, s, v)
end

local function colorDistance(a, b)
    local dr = a.R - b.R
    local dg = a.G - b.G
    local db = a.B - b.B
    return sqrt(dr * dr + dg * dg + db * db)
end

local function mixColors(list, weights)
    local r, g, b = 0, 0, 0
    local total = 0
    for index, color in ipairs(list) do
        local weight = weights and weights[index] or 1
        r = r + color.R * weight
        g = g + color.G * weight
        b = b + color.B * weight
        total = total + weight
    end
    if total <= 0 then
        return Color3new(0, 0, 0)
    end
    return Color3new(r / total, g / total, b / total)
end

local function create(className, properties, children)
    local instance = Instance.new(className)
    if properties then
        for key, value in next, properties do
            if key ~= "Parent" then
                pcall(function()
                    instance[key] = value
                end)
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            if child then
                child.Parent = instance
            end
        end
    end
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function setProps(instance, properties)
    if not instance or not properties then
        return instance
    end
    for key, value in next, properties do
        pcall(function()
            instance[key] = value
        end)
    end
    return instance
end

local function tween(instance, info, properties)
    if not instance then
        return nil
    end
    local created = TweenService:Create(instance, info or TweenInfoNew(0.2), properties)
    created:Play()
    return created
end

local function quickTween(instance, duration, properties, style, direction)
    return tween(instance, TweenInfoNew(
        duration or 0.2,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    ), properties)
end

local function roundCorners(instance, radius)
    local corner = instance:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = create("UICorner", {
            Parent = instance,
        })
    end
    if type(radius) == "number" then
        corner.CornerRadius = UDimnew(0, radius)
    else
        corner.CornerRadius = radius or UDimnew(0, 6)
    end
    return corner
end

local function roundCornersScale(instance, scale)
    local corner = instance:FindFirstChildOfClass("UICorner")
    if not corner then
        corner = create("UICorner", {
            Parent = instance,
        })
    end
    corner.CornerRadius = UDimnew(scale, 0)
    return corner
end

local function addStroke(instance, color, thickness, transparency)
    local stroke = instance:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = create("UIStroke", {
            Parent = instance,
        })
    end
    stroke.Color = parseColor(color)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    return stroke
end

local function addPadding(instance, left, right, top, bottom)
    local padding = instance:FindFirstChildOfClass("UIPadding")
    if not padding then
        padding = create("UIPadding", {
            Parent = instance,
        })
    end
    padding.PaddingLeft = UDimnew(0, left or 0)
    padding.PaddingRight = UDimnew(0, right or 0)
    padding.PaddingTop = UDimnew(0, top or 0)
    padding.PaddingBottom = UDimnew(0, bottom or 0)
    return padding
end

local function addList(instance, direction, padding, align, order)
    local layout = instance:FindFirstChildOfClass("UIListLayout")
    if not layout then
        layout = create("UIListLayout", {
            Parent = instance,
        })
    end
    layout.FillDirection = direction or Enum.FillDirection.Vertical
    layout.Padding = UDimnew(0, padding or 0)
    layout.SortOrder = order or Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
    return layout
end

local function addGrid(instance, cellSize, cellPadding)
    local layout = instance:FindFirstChildOfClass("UIGridLayout")
    if not layout then
        layout = create("UIGridLayout", {
            Parent = instance,
        })
    end
    layout.CellSize = cellSize or UDim2fromOffset(28, 28)
    layout.CellPadding = cellPadding or UDim2fromOffset(6, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    return layout
end

local function guiParent()
    local success, hidden = pcall(function()
        return gethui()
    end)
    if success and isInstance(hidden) then
        return hidden
    end
    local coreSuccess, core = pcall(function()
        return CoreGui
    end)
    if coreSuccess and isInstance(core) then
        return core
    end
    local playerSuccess, playerGui = pcall(function()
        local player = LocalPlayer
        if not player then
            player = Players.LocalPlayer
        end
        if not player then
            player = Players:WaitForChild("LocalPlayer", 10)
        end
        if not player then
            return nil
        end
        return player:WaitForChild("PlayerGui", 5)
    end)
    if playerSuccess and playerGui then
        return playerGui
    end
    return nil
end

local function protectGui(gui)
    if not gui then
        return
    end
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        end
    end)
    pcall(function()
        if protectgui then
            protectgui(gui)
        end
    end)
    pcall(function()
        if (getgenv and getgenv().protectgui) then
            getgenv().protectgui(gui)
        end
    end)
end

local function makeScreenGui(name, displayOrder)
    local parent = guiParent()
    local gui = create("ScreenGui", {
        Name = name or "FaceIDLib",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = displayOrder or 999,
        Parent = parent,
    })
    protectGui(gui)
    return gui
end

local function getLoadstring()
    if type(loadstring) == "function" then
        return loadstring
    end
    if type(load) == "function" then
        return load
    end
    return nil
end

local function httpFetch(url, options)
    local success, body = pcall(function()
        return game:HttpGet(url, true)
    end)
    if success and type(body) == "string" then
        return body
    end
    local requestFn = nil
    if syn and syn.request then
        requestFn = syn.request
    elseif http_request then
        requestFn = http_request
    elseif request then
        requestFn = request
    end
    if requestFn then
        local ok, response = pcall(requestFn, {
            Url = url,
            Method = "GET",
            Headers = (options and options.Headers) or nil,
        })
        if ok and type(response) == "table" and type(response.Body) == "string" then
            return response.Body
        end
    end
    return nil
end

local function safeSpawn(fn)
    local thread = coroutine.create(fn)
    local success, err = coroutine.resume(thread)
    if not success then
        warn(FaceIDLib.Prefix .. " " .. tostring(err))
    end
    return thread
end

local function signalWait()
    return RunService.Heartbeat:Wait()
end

local function clampUDim2(udim2)
    return udim2
end

local function keyCodeFromName(name)
    if type(name) == "EnumItem" then
        return name
    end
    if type(name) == "string" then
        local success, key = pcall(function()
            return Enum.KeyCode[name]
        end)
        if success and key then
            return key
        end
    end
    return Enum.KeyCode.RightShift
end

local function fontFromName(name)
    if type(name) == "EnumItem" then
        return name
    end
    if type(name) == "string" then
        local success, font = pcall(function()
            return Enum.Font[name]
        end)
        if success and font then
            return font
        end
        local map = {
            Regular = Enum.Font.Gotham,
            Medium = Enum.Font.GothamMedium,
            Semibold = Enum.Font.GothamSemibold,
            Bold = Enum.Font.GothamBold,
            Black = Enum.Font.GothamBlack,
            Mono = Enum.Font.Code,
            Code = Enum.Font.Code,
            UI = Enum.Font.SourceSans,
        }
        if map[name] then
            return map[name]
        end
    end
    return Enum.Font.Gotham
end
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({
        _connections = {},
        _destroyed = false,
    }, Signal)
end

function Signal:Connect(callback)
    if type(callback) ~= "function" then
        return {
            Disconnect = noop,
        }
    end
    local connection = {
        Callback = callback,
        Connected = true,
        _owner = self,
    }
    function connection:Disconnect()
        if not self.Connected then
            return
        end
        self.Connected = false
        local list = self._owner._connections
        for index = #list, 1, -1 do
            if list[index] == self then
                table.remove(list, index)
                break
            end
        end
    end
    function connection:Fire(...)
        if self.Connected then
            self.Callback(...)
        end
    end
    table.insert(self._connections, connection)
    return connection
end

function Signal:Once(callback)
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

function Signal:Fire(...)
    if self._destroyed then
        return
    end
    local snapshot = {}
    for index, connection in ipairs(self._connections) do
        snapshot[index] = connection
    end
    for _, connection in ipairs(snapshot) do
        if connection.Connected then
            local success, err = pcall(connection.Callback, ...)
            if not success then
                warn(FaceIDLib.Prefix .. " signal error: " .. tostring(err))
            end
        end
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        if thread then
            coroutine.resume(thread, ...)
        end
    end)
    return coroutine.yield()
end

function Signal:DisconnectAll()
    for index = #self._connections, 1, -1 do
        local connection = self._connections[index]
        connection.Connected = false
        table.remove(self._connections, index)
    end
end

function Signal:Destroy()
    self._destroyed = true
    self:DisconnectAll()
end

local Easing = {}

Easing.Names = {
    "Linear",
    "SineIn",
    "SineOut",
    "SineInOut",
    "QuadIn",
    "QuadOut",
    "QuadInOut",
    "CubicIn",
    "CubicOut",
    "CubicInOut",
    "QuartIn",
    "QuartOut",
    "QuartInOut",
    "QuintIn",
    "QuintOut",
    "QuintInOut",
    "ExpoIn",
    "ExpoOut",
    "ExpoInOut",
    "CircIn",
    "CircOut",
    "CircInOut",
    "BackIn",
    "BackOut",
    "BackInOut",
    "ElasticOut",
    "ElasticIn",
    "BounceOut",
    "BounceIn",
    "SmoothStep",
    "Smoother",
}

local function bounceOut(t)
    if t < 1 / 2.75 then
        return 7.5625 * t * t
    elseif t < 2 / 2.75 then
        t = t - 1.5 / 2.75
        return 7.5625 * t * t + 0.75
    elseif t < 2.5 / 2.75 then
        t = t - 2.25 / 2.75
        return 7.5625 * t * t + 0.9375
    end
    t = t - 2.625 / 2.75
    return 7.5625 * t * t + 0.984375
end

Easing.Functions = {
    Linear = function(t)
        return t
    end,
    SineIn = function(t)
        return 1 - cos(t * pi * 0.5)
    end,
    SineOut = function(t)
        return sin(t * pi * 0.5)
    end,
    SineInOut = function(t)
        return -(cos(pi * t) - 1) * 0.5
    end,
    QuadIn = function(t)
        return t * t
    end,
    QuadOut = function(t)
        return 1 - (1 - t) * (1 - t)
    end,
    QuadInOut = function(t)
        if t < 0.5 then
            return 2 * t * t
        end
        return 1 - ((-2 * t + 2) ^ 2) * 0.5
    end,
    CubicIn = function(t)
        return t * t * t
    end,
    CubicOut = function(t)
        return 1 - ((1 - t) ^ 3)
    end,
    CubicInOut = function(t)
        if t < 0.5 then
            return 4 * t * t * t
        end
        return 1 - ((-2 * t + 2) ^ 3) * 0.5
    end,
    QuartIn = function(t)
        return t * t * t * t
    end,
    QuartOut = function(t)
        return 1 - ((1 - t) ^ 4)
    end,
    QuartInOut = function(t)
        if t < 0.5 then
            return 8 * t * t * t * t
        end
        return 1 - ((-2 * t + 2) ^ 4) * 0.5
    end,
    QuintIn = function(t)
        return t * t * t * t * t
    end,
    QuintOut = function(t)
        return 1 - ((1 - t) ^ 5)
    end,
    QuintInOut = function(t)
        if t < 0.5 then
            return 16 * t * t * t * t * t
        end
        return 1 - ((-2 * t + 2) ^ 5) * 0.5
    end,
    ExpoIn = function(t)
        if t <= 0 then
            return 0
        end
        return 2 ^ (10 * t - 10)
    end,
    ExpoOut = function(t)
        if t >= 1 then
            return 1
        end
        return 1 - 2 ^ (-10 * t)
    end,
    ExpoInOut = function(t)
        if t <= 0 then
            return 0
        end
        if t >= 1 then
            return 1
        end
        if t < 0.5 then
            return (2 ^ (20 * t - 10)) * 0.5
        end
        return (2 - 2 ^ (-20 * t + 10)) * 0.5
    end,
    CircIn = function(t)
        return 1 - sqrt(1 - t * t)
    end,
    CircOut = function(t)
        return sqrt(1 - ((t - 1) ^ 2))
    end,
    CircInOut = function(t)
        if t < 0.5 then
            return (1 - sqrt(1 - (2 * t) ^ 2)) * 0.5
        end
        return (sqrt(1 - (-2 * t + 2) ^ 2) + 1) * 0.5
    end,
    BackIn = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return c3 * t * t * t - c1 * t * t
    end,
    BackOut = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * ((t - 1) ^ 3) + c1 * ((t - 1) ^ 2)
    end,
    BackInOut = function(t)
        local c1 = 1.70158
        local c2 = c1 * 1.525
        if t < 0.5 then
            return ((2 * t) ^ 2 * ((c2 + 1) * 2 * t - c2)) * 0.5
        end
        return (((2 * t - 2) ^ 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) * 0.5
    end,
    ElasticOut = function(t)
        if t <= 0 then
            return 0
        end
        if t >= 1 then
            return 1
        end
        local c4 = (2 * pi) / 3
        return (2 ^ (-10 * t)) * sin((t * 10 - 0.75) * c4) + 1
    end,
    ElasticIn = function(t)
        if t <= 0 then
            return 0
        end
        if t >= 1 then
            return 1
        end
        local c4 = (2 * pi) / 3
        return -(2 ^ (10 * t - 10)) * sin((t * 10 - 10.75) * c4)
    end,
    BounceOut = bounceOut,
    BounceIn = function(t)
        return 1 - bounceOut(1 - t)
    end,
    SmoothStep = function(t)
        return t * t * (3 - 2 * t)
    end,
    Smoother = function(t)
        return t * t * t * (t * (t * 6 - 15) + 10)
    end,
}

function Easing.get(name)
    if type(name) == "function" then
        return name
    end
    local fn = Easing.Functions[name]
    if fn then
        return fn
    end
    return Easing.Functions.QuintOut
end

function Easing.apply(name, alpha)
    alpha = clamp01(alpha)
    return Easing.get(name)(alpha)
end

Easing.Lut = {}
Easing.LutSize = 256

local function buildLuts()
    for name, fn in next, Easing.Functions do
        local lut = {}
        for index = 0, Easing.LutSize do
            lut[index] = fn(index / Easing.LutSize)
        end
        Easing.Lut[name] = lut
    end
end

buildLuts()

function Easing.fast(name, alpha)
    local lut = Easing.Lut[name]
    if not lut then
        return Easing.apply(name, alpha)
    end
    alpha = clamp01(alpha)
    local scaled = alpha * Easing.LutSize
    local lower = floor(scaled)
    local upper = minn(lower + 1, Easing.LutSize)
    local mix = scaled - lower
    return lut[lower] + (lut[upper] - lut[lower]) * mix
end

local Geometry = {}

function Geometry.pointOnQuadratic(p0, p1, p2, t)
    local inverse = 1 - t
    local a = inverse * inverse
    local b = 2 * inverse * t
    local c = t * t
    return Vector2new(
        a * p0.X + b * p1.X + c * p2.X,
        a * p0.Y + b * p1.Y + c * p2.Y
    )
end

function Geometry.tangentOnQuadratic(p0, p1, p2, t)
    local dx = 2 * (1 - t) * (p1.X - p0.X) + 2 * t * (p2.X - p1.X)
    local dy = 2 * (1 - t) * (p1.Y - p0.Y) + 2 * t * (p2.Y - p1.Y)
    return dx, dy
end

function Geometry.angleBetween(a, b)
    local dx = b.X - a.X
    local dy = b.Y - a.Y
    return math.deg(math.atan2(dy, dx))
end

function Geometry.distance(a, b)
    local dx = b.X - a.X
    local dy = b.Y - a.Y
    return sqrt(dx * dx + dy * dy)
end

function Geometry.arcPoints(centerX, centerY, radiusX, radiusY, startAngle, endAngle, segments)
    local points = {}
    segments = segments or 24
    for index = 0, segments do
        local alpha = index / segments
        local angle = rad(lerp(startAngle, endAngle, alpha))
        table.insert(points, Vector2new(
            centerX + cos(angle) * radiusX,
            centerY + sin(angle) * radiusY
        ))
    end
    return points
end

function Geometry.quadraticPath(startX, startY, controlX, controlY, endX, endY, segments)
    local points = {}
    segments = segments or 24
    local p0 = Vector2new(startX, startY)
    local p1 = Vector2new(controlX, controlY)
    local p2 = Vector2new(endX, endY)
    for index = 0, segments do
        table.insert(points, Geometry.pointOnQuadratic(p0, p1, p2, index / segments))
    end
    return points
end

function Geometry.rotatePoint(x, y, originX, originY, degrees)
    local angle = rad(degrees)
    local dx = x - originX
    local dy = y - originY
    return Vector2new(
        originX + dx * cos(angle) - dy * sin(angle),
        originY + dx * sin(angle) + dy * cos(angle)
    )
end

function Geometry.polylineLength(points)
    local total = 0
    for index = 2, #points do
        total = total + Geometry.distance(points[index - 1], points[index])
    end
    return total
end

function Geometry.lerpPoint(a, b, t)
    return Vector2new(lerp(a.X, b.X, t), lerp(a.Y, b.Y, t))
end

local TextMetrics = {}

function TextMetrics.measure(text, font, size, width)
    local success, bounds = pcall(function()
        return TextService:GetTextSize(text or "", size or 14, font or Enum.Font.Gotham, Vector2new(width or 1000, 10000))
    end)
    if success and bounds then
        return bounds
    end
    return Vector2new(#tostring(text or "") * (size or 14) * 0.55, size or 14)
end

function TextMetrics.wrap(text, font, size, width)
    local words = {}
    for word in tostring(text or ""):gmatch("%S+") do
        table.insert(words, word)
    end
    local lines = {}
    local current = ""
    for _, word in ipairs(words) do
        local candidate = current == "" and word or (current .. " " .. word)
        local bounds = TextMetrics.measure(candidate, font, size, width)
        if bounds.X > width and current ~= "" then
            table.insert(lines, current)
            current = word
        else
            current = candidate
        end
    end
    if current ~= "" then
        table.insert(lines, current)
    end
    return lines
end

local State = {
    Idle = "Idle",
    Showing = "Showing",
    Scanning = "Scanning",
    Success = "Success",
    Fail = "Fail",
    Hiding = "Hiding",
    Destroyed = "Destroyed",
}

local clampn = clamp
FaceIDLib.Defaults = {
    Theme = "IOSDark",
    IconStyle = "Classic",
    AutoShow = true,
    AutoHideOnComplete = true,
    Parent = nil,
    DisplayOrder = 999,
    IgnoreGuiInset = true,
    ClearOnDestroy = true,
    Position = {
        AnchorX = 0.5,
        AnchorY = 0.055,
        OffsetX = 0,
        OffsetY = 0,
    },
    Panel = {
        Size = 148,
        CornerRadius = 38,
        Transparency = 0.05,
        StrokeTransparency = 1,
        StrokeThickness = 1,
        Shadow = true,
        ShadowTransparency = 0.55,
        ShadowSize = 26,
        Scale = 1,
    },
    Icon = {
        Scale = 0.66,
        Thickness = 0.054,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        ArcSegments = 7,
        CapRadius = 0.5,
        EyeWidth = 0.078,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.300,
        NoseOffsetY = 0.066,
        NoseHook = 1,
        NoseHookLength = 1.45,
        NoseHookAngle = 36,
        SmileWidth = 0.300,
        SmileDepth = 0.126,
        SmileSegments = 28,
        SmileThickness = 0.044,
        SmileOffsetY = 0.170,
        SmileCurve = 1,
        Glow = 0,
        DrawOnShow = false,
        BracketStyle = "Round",
    },
    Colors = {
        Face = "#34C759",
        FaceDim = "#1F7A3C",
        Panel = "#0B0B0D",
        PanelStroke = "#242427",
        Scan = "#9BFFC0",
        Success = "#32D74B",
        Fail = "#FF453A",
        Glow = "#34C759",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Window = "#0E0E12",
        WindowStroke = "#26262B",
        TitleBar = "#131318",
        Sidebar = "#0B0B0F",
        SidebarStroke = "#1E1E24",
        Element = "#17171D",
        ElementHover = "#1F1F27",
        ElementActive = "#26262F",
        Text = "#F2F2F7",
        SubText = "#8E8E93",
        Accent = "#34C759",
        AccentText = "#04120A",
        Outline = "#2C2C33",
        Shadow = "#000000",
        Highlight = "#FFFFFF",
    },
    Animation = {
        FadeIn = 0.55,
        FadeInScale = 0.86,
        ShowDelay = 0.05,
        ScanDelay = 0.18,
        ScanDuration = 1.05,
        ScanGlow = 0.85,
        ScanHold = 0.25,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        SuccessPulse = 1.35,
        FadeOut = 0.62,
        FadeOutScale = 1.08,
        FailShake = 7,
        FailDuration = 0.9,
        Loop = false,
        Easing = "QuintOut",
        EasingIn = "CubicOut",
        EasingOut = "CubicIn",
    },
    Text = {
        Enabled = false,
        Title = "Face ID",
        Subtitle = "",
        Color = "#FFFFFF",
        SubColor = "#8E8E93",
        Size = 14,
        SubSize = 12,
        Font = "GothamMedium",
        Gap = 10,
    },
    Sound = {
        Enabled = false,
        SuccessId = "",
        FailId = "",
        ScanId = "",
        Volume = 0.4,
    },
    AutoExec = {
        Enabled = false,
        When = "AfterComplete",
        Delay = 0,
        Source = nil,
        Url = nil,
        Function = nil,
        Module = nil,
        Chain = {},
        Retries = 2,
        RetryDelay = 1.5,
        Silent = false,
    },
    Window = {
        Enabled = false,
        Title = "FaceIDLib",
        Subtitle = "Control Panel",
        Size = { X = 580, Y = 400 },
        ToggleKey = "RightShift",
        StartVisible = true,
        Theme = "IOSDark",
        Resizable = false,
        ShowSearch = true,
        ShowThemePicker = true,
        ShowFaceControls = true,
        ShowLoaderPanel = true,
    },
}

function FaceIDLib.getPreset(name)
    if name and FaceIDLib.Presets[name] then
        return FaceIDLib.Presets[name]
    end
    return FaceIDLib.Presets[FaceIDLib.Defaults.Theme]
end

function FaceIDLib.getIconStyle(name)
    if name and FaceIDLib.IconStyles[name] then
        return FaceIDLib.IconStyles[name]
    end
    return FaceIDLib.IconStyles[FaceIDLib.Defaults.IconStyle]
end

function FaceIDLib.themeNames()
    return deepCopy(FaceIDLib.ThemeOrder)
end

function FaceIDLib.styleNames()
    local names = sortedKeys(FaceIDLib.IconStyles)
    return names
end

function FaceIDLib.resolvePalette(config)
    local palette = {}
    for key, value in next, config do
        palette[key] = parseColor(value, Color3fromRGB(255, 255, 255))
    end
    return palette
end

function FaceIDLib.resolveConfig(config)
    local userConfig = deepCopy(config or {})
    local themeName = userConfig.Theme or FaceIDLib.Defaults.Theme
    local preset = FaceIDLib.getPreset(themeName)
    local styleName = userConfig.IconStyle or FaceIDLib.Defaults.IconStyle
    local style = FaceIDLib.getIconStyle(styleName)
    local resolved = deepCopy(FaceIDLib.Defaults)
    if style then
        for key, value in next, style do
            if key ~= "Name" and key ~= "Label" then
                resolved.Icon[key] = value
            end
        end
    end
    if preset then
        deepMerge(resolved.Colors, preset.Colors or {})
        deepMerge(resolved.Icon, preset.Geometry or {})
        deepMerge(resolved.Animation, preset.Animation or {})
        resolved.Theme = preset.Name
    end
    userConfig.Theme = nil
    userConfig.IconStyle = nil
    deepMerge(resolved, userConfig)
    resolved.Theme = themeName
    resolved.IconStyle = styleName
    resolved.RawColors = resolved.Colors
    resolved.Palette = FaceIDLib.resolvePalette(resolved.Colors)
    resolved.Colors = resolved.Palette
    resolved.Panel.Size = clamp(resolved.Panel.Size or 148, 48, 512)
    resolved.Panel.CornerRadius = clamp(resolved.Panel.CornerRadius or 38, 0, 256)
    resolved.Panel.Transparency = clamp01(resolved.Panel.Transparency or 0)
    resolved.Icon.Scale = clamp(resolved.Icon.Scale or 0.62, 0.2, 1)
    resolved.Icon.Thickness = clamp(resolved.Icon.Thickness or 0.052, 0.005, 0.2)
    resolved.Icon.SmileSegments = clamp(floor(resolved.Icon.SmileSegments or 26), 6, 96)
    resolved.Animation.FadeIn = maxn(resolved.Animation.FadeIn or 0.55, 0)
    resolved.Animation.FadeOut = maxn(resolved.Animation.FadeOut or 0.62, 0)
    resolved.Animation.ScanDuration = maxn(resolved.Animation.ScanDuration or 1.05, 0.05)
    return resolved
end

function FaceIDLib.describeTheme(name)
    local preset = FaceIDLib.Presets[name]
    if not preset then
        return nil
    end
    return {
        Name = preset.Name,
        Label = preset.Label,
        Mode = preset.Mode,
        Glow = preset.Glow,
        Accent = preset.Colors.Accent,
        Panel = preset.Colors.Panel,
        Face = preset.Colors.Face,
    }
end

function FaceIDLib.listThemes()
    local list = {}
    for _, name in ipairs(FaceIDLib.ThemeOrder) do
        local info = FaceIDLib.describeTheme(name)
        if info then
            table.insert(list, info)
        end
    end
    return list
end

FaceIDLib.Events = {
    Loaded = "Loaded",
    Shown = "Shown",
    ScanStarted = "ScanStarted",
    ScanFinished = "ScanFinished",
    Success = "Success",
    Fail = "Fail",
    Hidden = "Hidden",
    Completed = "Completed",
    Executed = "Executed",
    ThemeChanged = "ThemeChanged",
    ConfigChanged = "ConfigChanged",
    Destroyed = "Destroyed",
}
FaceIDLib.Presets = {}
FaceIDLib.ThemeOrder = {}

FaceIDLib.Presets["IOSDark"] = {
    Name = "IOSDark",
    Label = "iOS Dark",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070807",
        PanelStroke = "#262A27",
        Face = "#34C759",
        FaceDim = "#185026",
        Scan = "#AAFFC0",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#34C759",
        Window = "#0C0D0C",
        WindowStroke = "#2C302D",
        TitleBar = "#101211",
        Sidebar = "#090A09",
        SidebarStroke = "#262A27",
        Element = "#141615",
        ElementHover = "#1F2220",
        ElementActive = "#282D29",
        Text = "#F5F5F7",
        SubText = "#8B948D",
        Accent = "#34C759",
        AccentText = "#0B0B0D",
        Outline = "#2C302D",
        Shadow = "#000000",
        Highlight = "#F2FFF5",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.054,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.078,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.126,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.55,
        ScanDuration = 1.05,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 7,
    },
}

FaceIDLib.Presets["IOSDarkGlow"] = {
    Name = "IOSDarkGlow",
    Label = "iOS Dark Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040505",
        PanelStroke = "#1F2521",
        Face = "#34C759",
        FaceDim = "#12441E",
        Scan = "#C6FFD5",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#34C759",
        Window = "#090B09",
        WindowStroke = "#222924",
        TitleBar = "#0C0F0D",
        Sidebar = "#060807",
        SidebarStroke = "#1F2521",
        Element = "#101311",
        ElementHover = "#181D19",
        ElementActive = "#1F2621",
        Text = "#F5F5F7",
        SubText = "#8B948D",
        Accent = "#34C759",
        AccentText = "#0B0B0D",
        Outline = "#222924",
        Shadow = "#000000",
        Highlight = "#F2FFF5",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.0594,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.0827,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.1361,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.522,
        ScanDuration = 0.966,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 7,
    },
}

FaceIDLib.Presets["IOSLight"] = {
    Name = "IOSLight",
    Label = "iOS Light",
    Mode = "Light",
    Glow = false,
    Colors = {
        Panel = "#FAFFFB",
        PanelStroke = "#D5E0D8",
        Face = "#34C759",
        FaceDim = "#308F48",
        Scan = "#70BD84",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#34C759",
        Window = "#F1FEF4",
        WindowStroke = "#CDD7CF",
        TitleBar = "#EAF6ED",
        Sidebar = "#E3F1E6",
        SidebarStroke = "#D5E0D8",
        Element = "#E1EDE4",
        ElementHover = "#D4E4D8",
        ElementActive = "#C8DBCD",
        Text = "#181D19",
        SubText = "#7E8580",
        Accent = "#34C759",
        AccentText = "#0B0B0D",
        Outline = "#CDD7CF",
        Shadow = "#7E8C82",
        Highlight = "#FFFFFF",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.058,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.082,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.122,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.6,
        ScanDuration = 1.1,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 8,
    },
}

FaceIDLib.Presets["IOSLightDeep"] = {
    Name = "IOSLightDeep",
    Label = "iOS Light Deep",
    Mode = "Light",
    Glow = true,
    Colors = {
        Panel = "#FAFFFB",
        PanelStroke = "#D5E0D8",
        Face = "#34C759",
        FaceDim = "#308F48",
        Scan = "#70BD84",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#34C759",
        Window = "#E7FEED",
        WindowStroke = "#CDD7CF",
        TitleBar = "#EAF6ED",
        Sidebar = "#E3F1E6",
        SidebarStroke = "#D5E0D8",
        Element = "#E1EDE4",
        ElementHover = "#D4E4D8",
        ElementActive = "#C8DBCD",
        Text = "#181D19",
        SubText = "#7E8580",
        Accent = "#34C759",
        AccentText = "#0B0B0D",
        Outline = "#CDD7CF",
        Shadow = "#7E8C82",
        Highlight = "#FFFFFF",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.0638,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.0869,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.1318,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.57,
        ScanDuration = 1.012,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 8,
    },
}

FaceIDLib.Presets["Midnight"] = {
    Name = "Midnight",
    Label = "Midnight",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070708",
        PanelStroke = "#26282A",
        Face = "#0A84FF",
        FaceDim = "#093766",
        Scan = "#91C8FF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#0A84FF",
        Window = "#0C0D0D",
        WindowStroke = "#2C2E30",
        TitleBar = "#101112",
        Sidebar = "#09090A",
        SidebarStroke = "#26282A",
        Element = "#141516",
        ElementHover = "#1F2122",
        ElementActive = "#282B2D",
        Text = "#F5F5F7",
        SubText = "#8B8F94",
        Accent = "#0A84FF",
        AccentText = "#0B0B0D",
        Outline = "#2C2E30",
        Shadow = "#000000",
        Highlight = "#F2F9FF",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.05,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.075,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.13,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.52,
        ScanDuration = 1,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 9,
    },
}

FaceIDLib.Presets["MidnightGlow"] = {
    Name = "MidnightGlow",
    Label = "Midnight Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040505",
        PanelStroke = "#1F2225",
        Face = "#0A84FF",
        FaceDim = "#032D57",
        Scan = "#B6DAFF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#0A84FF",
        Window = "#090A0B",
        WindowStroke = "#222629",
        TitleBar = "#0C0E0F",
        Sidebar = "#060708",
        SidebarStroke = "#1F2225",
        Element = "#101113",
        ElementHover = "#181A1D",
        ElementActive = "#1F2326",
        Text = "#F5F5F7",
        SubText = "#8B8F94",
        Accent = "#0A84FF",
        AccentText = "#0B0B0D",
        Outline = "#222629",
        Shadow = "#000000",
        Highlight = "#F2F9FF",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.055,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.0795,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.1404,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.494,
        ScanDuration = 0.92,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 9,
    },
}

FaceIDLib.Presets["Ocean"] = {
    Name = "Ocean",
    Label = "Ocean",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070708",
        PanelStroke = "#26292A",
        Face = "#64D2FF",
        FaceDim = "#2B5566",
        Scan = "#B9EBFF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#64D2FF",
        Window = "#0C0D0D",
        WindowStroke = "#2C2F30",
        TitleBar = "#101112",
        Sidebar = "#09090A",
        SidebarStroke = "#26292A",
        Element = "#141616",
        ElementHover = "#1F2122",
        ElementActive = "#282C2D",
        Text = "#F5F5F7",
        SubText = "#8B9194",
        Accent = "#64D2FF",
        AccentText = "#0B0B0D",
        Outline = "#2C2F30",
        Shadow = "#000000",
        Highlight = "#F2FBFF",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.048,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.072,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.134,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.64,
        ScanDuration = 1.15,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 7,
    },
}

FaceIDLib.Presets["OceanGlow"] = {
    Name = "OceanGlow",
    Label = "Ocean Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040505",
        PanelStroke = "#1F2325",
        Face = "#64D2FF",
        FaceDim = "#224757",
        Scan = "#D0F2FF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#64D2FF",
        Window = "#090A0B",
        WindowStroke = "#222729",
        TitleBar = "#0C0E0F",
        Sidebar = "#060708",
        SidebarStroke = "#1F2325",
        Element = "#101213",
        ElementHover = "#181B1D",
        ElementActive = "#1F2426",
        Text = "#F5F5F7",
        SubText = "#8B9194",
        Accent = "#64D2FF",
        AccentText = "#0B0B0D",
        Outline = "#222729",
        Shadow = "#000000",
        Highlight = "#F2FBFF",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.0528,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.0763,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.1447,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.608,
        ScanDuration = 1.058,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 7,
    },
}

FaceIDLib.Presets["Lavender"] = {
    Name = "Lavender",
    Label = "Lavender",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070708",
        PanelStroke = "#29262A",
        Face = "#BF5AF2",
        FaceDim = "#4D2761",
        Scan = "#E7B7FF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#BF5AF2",
        Window = "#0D0C0D",
        WindowStroke = "#2F2C30",
        TitleBar = "#111012",
        Sidebar = "#09090A",
        SidebarStroke = "#29262A",
        Element = "#161416",
        ElementHover = "#211F22",
        ElementActive = "#2C282D",
        Text = "#F5F5F7",
        SubText = "#918B94",
        Accent = "#BF5AF2",
        AccentText = "#0B0B0D",
        Outline = "#2F2C30",
        Shadow = "#000000",
        Highlight = "#FBF2FF",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.054,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.078,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.126,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.55,
        ScanDuration = 1.05,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 8,
    },
}

FaceIDLib.Presets["LavenderGlow"] = {
    Name = "LavenderGlow",
    Label = "Lavender Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050405",
        PanelStroke = "#231F25",
        Face = "#BF5AF2",
        FaceDim = "#411F52",
        Scan = "#EFCFFF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#BF5AF2",
        Window = "#0A090B",
        WindowStroke = "#272229",
        TitleBar = "#0E0C0F",
        Sidebar = "#070608",
        SidebarStroke = "#231F25",
        Element = "#121013",
        ElementHover = "#1B181D",
        ElementActive = "#241F26",
        Text = "#F5F5F7",
        SubText = "#918B94",
        Accent = "#BF5AF2",
        AccentText = "#0B0B0D",
        Outline = "#272229",
        Shadow = "#000000",
        Highlight = "#FBF2FF",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.0594,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.0827,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.1361,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.522,
        ScanDuration = 0.966,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 8,
    },
}

FaceIDLib.Presets["Sunset"] = {
    Name = "Sunset",
    Label = "Sunset",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#080707",
        PanelStroke = "#2A2826",
        Face = "#FF9F0A",
        FaceDim = "#664209",
        Scan = "#FFD491",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF9F0A",
        Window = "#0D0D0C",
        WindowStroke = "#302F2C",
        TitleBar = "#121110",
        Sidebar = "#0A0909",
        SidebarStroke = "#2A2826",
        Element = "#161614",
        ElementHover = "#22211F",
        ElementActive = "#2D2B28",
        Text = "#F5F5F7",
        SubText = "#94908B",
        Accent = "#FF9F0A",
        AccentText = "#0B0B0D",
        Outline = "#302F2C",
        Shadow = "#000000",
        Highlight = "#FFFAF2",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.058,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.082,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.122,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.6,
        ScanDuration = 1.1,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 9,
    },
}

FaceIDLib.Presets["SunsetGlow"] = {
    Name = "SunsetGlow",
    Label = "Sunset Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050504",
        PanelStroke = "#25231F",
        Face = "#FF9F0A",
        FaceDim = "#573603",
        Scan = "#FFE2B6",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF9F0A",
        Window = "#0B0A09",
        WindowStroke = "#292622",
        TitleBar = "#0F0E0C",
        Sidebar = "#080706",
        SidebarStroke = "#25231F",
        Element = "#131210",
        ElementHover = "#1D1B18",
        ElementActive = "#26231F",
        Text = "#F5F5F7",
        SubText = "#94908B",
        Accent = "#FF9F0A",
        AccentText = "#0B0B0D",
        Outline = "#292622",
        Shadow = "#000000",
        Highlight = "#FFFAF2",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.0638,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.0869,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.1318,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.57,
        ScanDuration = 1.012,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 9,
    },
}

FaceIDLib.Presets["Cyber"] = {
    Name = "Cyber",
    Label = "Cyber",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#080707",
        PanelStroke = "#2A2627",
        Face = "#FF2D55",
        FaceDim = "#661625",
        Scan = "#FFA0B3",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF2D55",
        Window = "#0D0C0C",
        WindowStroke = "#302C2D",
        TitleBar = "#121010",
        Sidebar = "#0A0909",
        SidebarStroke = "#2A2627",
        Element = "#161415",
        ElementHover = "#221F1F",
        ElementActive = "#2D2829",
        Text = "#F5F5F7",
        SubText = "#948B8D",
        Accent = "#FF2D55",
        AccentText = "#FFFFFF",
        Outline = "#302C2D",
        Shadow = "#000000",
        Highlight = "#FFF2F5",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.05,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.075,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.13,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.52,
        ScanDuration = 1,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 7,
    },
}

FaceIDLib.Presets["CyberGlow"] = {
    Name = "CyberGlow",
    Label = "Cyber Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050405",
        PanelStroke = "#251F20",
        Face = "#FF2D55",
        FaceDim = "#570F1D",
        Scan = "#FFC0CC",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF2D55",
        Window = "#0B0909",
        WindowStroke = "#292224",
        TitleBar = "#0F0C0D",
        Sidebar = "#080607",
        SidebarStroke = "#251F20",
        Element = "#131010",
        ElementHover = "#1D1819",
        ElementActive = "#261F21",
        Text = "#F5F5F7",
        SubText = "#948B8D",
        Accent = "#FF2D55",
        AccentText = "#FFFFFF",
        Outline = "#292224",
        Shadow = "#000000",
        Highlight = "#FFF2F5",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.055,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.0795,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.1404,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.494,
        ScanDuration = 0.92,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 7,
    },
}

FaceIDLib.Presets["Mono"] = {
    Name = "Mono",
    Label = "Mono",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070708",
        PanelStroke = "#26262A",
        Face = "#C7C7CC",
        FaceDim = "#505052",
        Scan = "#F2F2FF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#C7C7CC",
        Window = "#0C0C0D",
        WindowStroke = "#2C2C30",
        TitleBar = "#101012",
        Sidebar = "#09090A",
        SidebarStroke = "#26262A",
        Element = "#141416",
        ElementHover = "#1F1F22",
        ElementActive = "#28282D",
        Text = "#F5F5F7",
        SubText = "#8B8B94",
        Accent = "#C7C7CC",
        AccentText = "#0B0B0D",
        Outline = "#2C2C30",
        Shadow = "#000000",
        Highlight = "#F2F2FF",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.048,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.072,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.134,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.64,
        ScanDuration = 1.15,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 8,
    },
}

FaceIDLib.Presets["MonoGlow"] = {
    Name = "MonoGlow",
    Label = "Mono Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040405",
        PanelStroke = "#1F1F25",
        Face = "#C7C7CC",
        FaceDim = "#444445",
        Scan = "#FAFAFF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#C7C7CC",
        Window = "#09090B",
        WindowStroke = "#222229",
        TitleBar = "#0C0C0F",
        Sidebar = "#060608",
        SidebarStroke = "#1F1F25",
        Element = "#101013",
        ElementHover = "#18181D",
        ElementActive = "#1F1F26",
        Text = "#F5F5F7",
        SubText = "#8B8B94",
        Accent = "#C7C7CC",
        AccentText = "#0B0B0D",
        Outline = "#222229",
        Shadow = "#000000",
        Highlight = "#F2F2FF",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.0528,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.0763,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.1447,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.608,
        ScanDuration = 1.058,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 8,
    },
}

FaceIDLib.Presets["Blood"] = {
    Name = "Blood",
    Label = "Blood",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#080707",
        PanelStroke = "#2A2626",
        Face = "#FF453A",
        FaceDim = "#661F1B",
        Scan = "#FFABA6",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF453A",
        Window = "#0D0C0C",
        WindowStroke = "#302C2C",
        TitleBar = "#121010",
        Sidebar = "#0A0909",
        SidebarStroke = "#2A2626",
        Element = "#161414",
        ElementHover = "#221F1F",
        ElementActive = "#2D2828",
        Text = "#F5F5F7",
        SubText = "#948C8B",
        Accent = "#FF453A",
        AccentText = "#FFFFFF",
        Outline = "#302C2C",
        Shadow = "#000000",
        Highlight = "#FFF3F2",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.054,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.078,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.126,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.55,
        ScanDuration = 1.05,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 9,
    },
}

FaceIDLib.Presets["BloodGlow"] = {
    Name = "BloodGlow",
    Label = "Blood Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050404",
        PanelStroke = "#251F1F",
        Face = "#FF453A",
        FaceDim = "#571714",
        Scan = "#FFC7C4",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF453A",
        Window = "#0B0909",
        WindowStroke = "#292322",
        TitleBar = "#0F0D0C",
        Sidebar = "#080606",
        SidebarStroke = "#251F1F",
        Element = "#131010",
        ElementHover = "#1D1818",
        ElementActive = "#26201F",
        Text = "#F5F5F7",
        SubText = "#948C8B",
        Accent = "#FF453A",
        AccentText = "#FFFFFF",
        Outline = "#292322",
        Shadow = "#000000",
        Highlight = "#FFF3F2",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.0594,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.0827,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.1361,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.522,
        ScanDuration = 0.966,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 9,
    },
}

FaceIDLib.Presets["Gold"] = {
    Name = "Gold",
    Label = "Gold",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#080807",
        PanelStroke = "#2A2926",
        Face = "#FFD60A",
        FaceDim = "#665609",
        Scan = "#FFED91",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FFD60A",
        Window = "#0D0D0C",
        WindowStroke = "#30302C",
        TitleBar = "#121210",
        Sidebar = "#0A0A09",
        SidebarStroke = "#2A2926",
        Element = "#161614",
        ElementHover = "#22221F",
        ElementActive = "#2D2D28",
        Text = "#F5F5F7",
        SubText = "#94928B",
        Accent = "#FFD60A",
        AccentText = "#0B0B0D",
        Outline = "#30302C",
        Shadow = "#000000",
        Highlight = "#FFFDF2",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.058,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.082,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.122,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.6,
        ScanDuration = 1.1,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 7,
    },
}

FaceIDLib.Presets["GoldGlow"] = {
    Name = "GoldGlow",
    Label = "Gold Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050504",
        PanelStroke = "#25241F",
        Face = "#FFD60A",
        FaceDim = "#574903",
        Scan = "#FFF3B6",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FFD60A",
        Window = "#0B0A09",
        WindowStroke = "#292822",
        TitleBar = "#0F0E0C",
        Sidebar = "#080706",
        SidebarStroke = "#25241F",
        Element = "#131210",
        ElementHover = "#1D1C18",
        ElementActive = "#26251F",
        Text = "#F5F5F7",
        SubText = "#94928B",
        Accent = "#FFD60A",
        AccentText = "#0B0B0D",
        Outline = "#292822",
        Shadow = "#000000",
        Highlight = "#FFFDF2",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.0638,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.0869,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.1318,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.57,
        ScanDuration = 1.012,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 7,
    },
}

FaceIDLib.Presets["Glass"] = {
    Name = "Glass",
    Label = "Glass",
    Mode = "Light",
    Glow = false,
    Colors = {
        Panel = "#FFFAFA",
        PanelStroke = "#E0D5D5",
        Face = "#FFFFFF",
        FaceDim = "#B87777",
        Scan = "#F2E6E6",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FFFFFF",
        Window = "#FEF1F1",
        WindowStroke = "#D7CDCD",
        TitleBar = "#F6EAEA",
        Sidebar = "#F1E3E3",
        SidebarStroke = "#E0D5D5",
        Element = "#EDE1E1",
        ElementHover = "#E4D4D4",
        ElementActive = "#DBC8C8",
        Text = "#1D1818",
        SubText = "#857E7E",
        Accent = "#FFFFFF",
        AccentText = "#0B0B0D",
        Outline = "#D7CDCD",
        Shadow = "#8C7E7E",
        Highlight = "#FFFFFF",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.05,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.075,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.13,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.52,
        ScanDuration = 1,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 8,
    },
}

FaceIDLib.Presets["GlassDeep"] = {
    Name = "GlassDeep",
    Label = "Glass Deep",
    Mode = "Light",
    Glow = true,
    Colors = {
        Panel = "#FFFAFA",
        PanelStroke = "#E0D5D5",
        Face = "#FFFFFF",
        FaceDim = "#B87777",
        Scan = "#F2E6E6",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FFFFFF",
        Window = "#FEE7E7",
        WindowStroke = "#D7CDCD",
        TitleBar = "#F6EAEA",
        Sidebar = "#F1E3E3",
        SidebarStroke = "#E0D5D5",
        Element = "#EDE1E1",
        ElementHover = "#E4D4D4",
        ElementActive = "#DBC8C8",
        Text = "#1D1818",
        SubText = "#857E7E",
        Accent = "#FFFFFF",
        AccentText = "#0B0B0D",
        Outline = "#D7CDCD",
        Shadow = "#8C7E7E",
        Highlight = "#FFFFFF",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.055,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.0795,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.1404,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.494,
        ScanDuration = 0.92,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 8,
    },
}

FaceIDLib.Presets["NeonGreen"] = {
    Name = "NeonGreen",
    Label = "Neon Green",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070807",
        PanelStroke = "#272A26",
        Face = "#39FF14",
        FaceDim = "#1B660D",
        Scan = "#A6FF95",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#39FF14",
        Window = "#0C0D0C",
        WindowStroke = "#2C302C",
        TitleBar = "#101210",
        Sidebar = "#090A09",
        SidebarStroke = "#272A26",
        Element = "#151614",
        ElementHover = "#1F221F",
        ElementActive = "#292D28",
        Text = "#F5F5F7",
        SubText = "#8C948B",
        Accent = "#39FF14",
        AccentText = "#0B0B0D",
        Outline = "#2C302C",
        Shadow = "#000000",
        Highlight = "#F4FFF2",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.048,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.072,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.134,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.64,
        ScanDuration = 1.15,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 9,
    },
}

FaceIDLib.Presets["NeonGreenGlow"] = {
    Name = "NeonGreenGlow",
    Label = "Neon Green Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050504",
        PanelStroke = "#20251F",
        Face = "#39FF14",
        FaceDim = "#135707",
        Scan = "#C4FFB8",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#39FF14",
        Window = "#090B09",
        WindowStroke = "#232922",
        TitleBar = "#0D0F0C",
        Sidebar = "#070806",
        SidebarStroke = "#20251F",
        Element = "#101310",
        ElementHover = "#191D18",
        ElementActive = "#20261F",
        Text = "#F5F5F7",
        SubText = "#8C948B",
        Accent = "#39FF14",
        AccentText = "#0B0B0D",
        Outline = "#232922",
        Shadow = "#000000",
        Highlight = "#F4FFF2",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.0528,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.0763,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.1447,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.608,
        ScanDuration = 1.058,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 9,
    },
}

FaceIDLib.Presets["Forest"] = {
    Name = "Forest",
    Label = "Forest",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070807",
        PanelStroke = "#262A27",
        Face = "#30D158",
        FaceDim = "#165426",
        Scan = "#A7FFBD",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#30D158",
        Window = "#0C0D0C",
        WindowStroke = "#2C302D",
        TitleBar = "#101211",
        Sidebar = "#090A09",
        SidebarStroke = "#262A27",
        Element = "#141615",
        ElementHover = "#1F2220",
        ElementActive = "#282D29",
        Text = "#F5F5F7",
        SubText = "#8B948D",
        Accent = "#30D158",
        AccentText = "#0B0B0D",
        Outline = "#2C302D",
        Shadow = "#000000",
        Highlight = "#F2FFF5",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.054,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.078,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.126,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.55,
        ScanDuration = 1.05,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 7,
    },
}

FaceIDLib.Presets["ForestGlow"] = {
    Name = "ForestGlow",
    Label = "Forest Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040505",
        PanelStroke = "#1F2521",
        Face = "#30D158",
        FaceDim = "#10471E",
        Scan = "#C4FFD3",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#30D158",
        Window = "#090B09",
        WindowStroke = "#222924",
        TitleBar = "#0C0F0D",
        Sidebar = "#060807",
        SidebarStroke = "#1F2521",
        Element = "#101311",
        ElementHover = "#181D19",
        ElementActive = "#1F2621",
        Text = "#F5F5F7",
        SubText = "#8B948D",
        Accent = "#30D158",
        AccentText = "#0B0B0D",
        Outline = "#222924",
        Shadow = "#000000",
        Highlight = "#F2FFF5",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.0594,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.0827,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.1361,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.522,
        ScanDuration = 0.966,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 7,
    },
}

FaceIDLib.Presets["Ice"] = {
    Name = "Ice",
    Label = "Ice",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070708",
        PanelStroke = "#26292A",
        Face = "#5AC8FA",
        FaceDim = "#275164",
        Scan = "#B6E8FF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#5AC8FA",
        Window = "#0C0D0D",
        WindowStroke = "#2C2F30",
        TitleBar = "#101112",
        Sidebar = "#09090A",
        SidebarStroke = "#26292A",
        Element = "#141616",
        ElementHover = "#1F2122",
        ElementActive = "#282C2D",
        Text = "#F5F5F7",
        SubText = "#8B9194",
        Accent = "#5AC8FA",
        AccentText = "#0B0B0D",
        Outline = "#2C2F30",
        Shadow = "#000000",
        Highlight = "#F2FBFF",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.058,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.082,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.122,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.6,
        ScanDuration = 1.1,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 8,
    },
}

FaceIDLib.Presets["IceGlow"] = {
    Name = "IceGlow",
    Label = "Ice Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040505",
        PanelStroke = "#1F2325",
        Face = "#5AC8FA",
        FaceDim = "#1F4455",
        Scan = "#CEF0FF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#5AC8FA",
        Window = "#090A0B",
        WindowStroke = "#222729",
        TitleBar = "#0C0E0F",
        Sidebar = "#060708",
        SidebarStroke = "#1F2325",
        Element = "#101213",
        ElementHover = "#181B1D",
        ElementActive = "#1F2426",
        Text = "#F5F5F7",
        SubText = "#8B9194",
        Accent = "#5AC8FA",
        AccentText = "#0B0B0D",
        Outline = "#222729",
        Shadow = "#000000",
        Highlight = "#F2FBFF",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.0638,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.0869,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.1318,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.57,
        ScanDuration = 1.012,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 8,
    },
}

FaceIDLib.Presets["Grape"] = {
    Name = "Grape",
    Label = "Grape",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070708",
        PanelStroke = "#26262A",
        Face = "#5E5CE6",
        FaceDim = "#28285C",
        Scan = "#BBBAFF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#5E5CE6",
        Window = "#0C0C0D",
        WindowStroke = "#2C2C30",
        TitleBar = "#101012",
        Sidebar = "#09090A",
        SidebarStroke = "#26262A",
        Element = "#141416",
        ElementHover = "#1F1F22",
        ElementActive = "#28282D",
        Text = "#F5F5F7",
        SubText = "#8B8B94",
        Accent = "#5E5CE6",
        AccentText = "#FFFFFF",
        Outline = "#2C2C30",
        Shadow = "#000000",
        Highlight = "#F2F2FF",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.05,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.075,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.13,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.52,
        ScanDuration = 1,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 9,
    },
}

FaceIDLib.Presets["GrapeGlow"] = {
    Name = "GrapeGlow",
    Label = "Grape Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040405",
        PanelStroke = "#1F1F25",
        Face = "#5E5CE6",
        FaceDim = "#201F4E",
        Scan = "#D2D1FF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#5E5CE6",
        Window = "#09090B",
        WindowStroke = "#222229",
        TitleBar = "#0C0C0F",
        Sidebar = "#060608",
        SidebarStroke = "#1F1F25",
        Element = "#101013",
        ElementHover = "#18181D",
        ElementActive = "#1F1F26",
        Text = "#F5F5F7",
        SubText = "#8B8B94",
        Accent = "#5E5CE6",
        AccentText = "#FFFFFF",
        Outline = "#222229",
        Shadow = "#000000",
        Highlight = "#F2F2FF",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.055,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.0795,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.1404,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.494,
        ScanDuration = 0.92,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 9,
    },
}

FaceIDLib.Presets["Rose"] = {
    Name = "Rose",
    Label = "Rose",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#080707",
        PanelStroke = "#2A2627",
        Face = "#FF375F",
        FaceDim = "#661A29",
        Scan = "#FFA5B7",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF375F",
        Window = "#0D0C0C",
        WindowStroke = "#302C2D",
        TitleBar = "#121010",
        Sidebar = "#0A0909",
        SidebarStroke = "#2A2627",
        Element = "#161415",
        ElementHover = "#221F20",
        ElementActive = "#2D2829",
        Text = "#F5F5F7",
        SubText = "#948B8D",
        Accent = "#FF375F",
        AccentText = "#FFFFFF",
        Outline = "#302C2D",
        Shadow = "#000000",
        Highlight = "#FFF2F5",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.048,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.072,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.134,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.64,
        ScanDuration = 1.15,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 7,
    },
}

FaceIDLib.Presets["RoseGlow"] = {
    Name = "RoseGlow",
    Label = "Rose Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050405",
        PanelStroke = "#251F20",
        Face = "#FF375F",
        FaceDim = "#571320",
        Scan = "#FFC3CF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF375F",
        Window = "#0B0909",
        WindowStroke = "#292224",
        TitleBar = "#0F0C0D",
        Sidebar = "#080607",
        SidebarStroke = "#251F20",
        Element = "#131010",
        ElementHover = "#1D1819",
        ElementActive = "#261F21",
        Text = "#F5F5F7",
        SubText = "#948B8D",
        Accent = "#FF375F",
        AccentText = "#FFFFFF",
        Outline = "#292224",
        Shadow = "#000000",
        Highlight = "#FFF2F5",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.0528,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.0763,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.1447,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.608,
        ScanDuration = 1.058,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 7,
    },
}

FaceIDLib.Presets["Amber"] = {
    Name = "Amber",
    Label = "Amber",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#080707",
        PanelStroke = "#2A2826",
        Face = "#FFB340",
        FaceDim = "#66491D",
        Scan = "#FFDDA9",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FFB340",
        Window = "#0D0D0C",
        WindowStroke = "#302F2C",
        TitleBar = "#121110",
        Sidebar = "#0A0909",
        SidebarStroke = "#2A2826",
        Element = "#161614",
        ElementHover = "#22211F",
        ElementActive = "#2D2B28",
        Text = "#F5F5F7",
        SubText = "#94908B",
        Accent = "#FFB340",
        AccentText = "#0B0B0D",
        Outline = "#302F2C",
        Shadow = "#000000",
        Highlight = "#FFFAF2",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.054,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.078,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.126,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.55,
        ScanDuration = 1.05,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 8,
    },
}

FaceIDLib.Presets["AmberGlow"] = {
    Name = "AmberGlow",
    Label = "Amber Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050504",
        PanelStroke = "#25231F",
        Face = "#FFB340",
        FaceDim = "#573D16",
        Scan = "#FFE8C6",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FFB340",
        Window = "#0B0A09",
        WindowStroke = "#292622",
        TitleBar = "#0F0E0C",
        Sidebar = "#080706",
        SidebarStroke = "#25231F",
        Element = "#131210",
        ElementHover = "#1D1B18",
        ElementActive = "#26231F",
        Text = "#F5F5F7",
        SubText = "#94908B",
        Accent = "#FFB340",
        AccentText = "#0B0B0D",
        Outline = "#292622",
        Shadow = "#000000",
        Highlight = "#FFFAF2",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.0594,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.0827,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.1361,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.522,
        ScanDuration = 0.966,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 8,
    },
}

FaceIDLib.Presets["Slate"] = {
    Name = "Slate",
    Label = "Slate",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070708",
        PanelStroke = "#26262A",
        Face = "#8E8E93",
        FaceDim = "#39393B",
        Scan = "#D9D9E5",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#8E8E93",
        Window = "#0C0C0D",
        WindowStroke = "#2C2C30",
        TitleBar = "#101012",
        Sidebar = "#09090A",
        SidebarStroke = "#26262A",
        Element = "#141416",
        ElementHover = "#1F1F22",
        ElementActive = "#28282D",
        Text = "#F5F5F7",
        SubText = "#8B8B94",
        Accent = "#8E8E93",
        AccentText = "#0B0B0D",
        Outline = "#2C2C30",
        Shadow = "#000000",
        Highlight = "#F2F2FF",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.058,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.082,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.122,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.6,
        ScanDuration = 1.1,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 9,
    },
}

FaceIDLib.Presets["SlateGlow"] = {
    Name = "SlateGlow",
    Label = "Slate Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040405",
        PanelStroke = "#1F1F25",
        Face = "#8E8E93",
        FaceDim = "#303032",
        Scan = "#FAFAFF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#8E8E93",
        Window = "#09090B",
        WindowStroke = "#222229",
        TitleBar = "#0C0C0F",
        Sidebar = "#060608",
        SidebarStroke = "#1F1F25",
        Element = "#101013",
        ElementHover = "#18181D",
        ElementActive = "#1F1F26",
        Text = "#F5F5F7",
        SubText = "#8B8B94",
        Accent = "#8E8E93",
        AccentText = "#0B0B0D",
        Outline = "#222229",
        Shadow = "#000000",
        Highlight = "#F2F2FF",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.0638,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.0869,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.1318,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.57,
        ScanDuration = 1.012,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 9,
    },
}

FaceIDLib.Presets["Matrix"] = {
    Name = "Matrix",
    Label = "Matrix",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070807",
        PanelStroke = "#262A27",
        Face = "#00FF41",
        FaceDim = "#05661E",
        Scan = "#8CFFAA",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#00FF41",
        Window = "#0C0D0C",
        WindowStroke = "#2C302D",
        TitleBar = "#101211",
        Sidebar = "#090A09",
        SidebarStroke = "#262A27",
        Element = "#141615",
        ElementHover = "#1F2220",
        ElementActive = "#282D2A",
        Text = "#F5F5F7",
        SubText = "#8B948D",
        Accent = "#00FF41",
        AccentText = "#0B0B0D",
        Outline = "#2C302D",
        Shadow = "#000000",
        Highlight = "#F2FFF6",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.05,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.075,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.13,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.52,
        ScanDuration = 1,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 7,
    },
}

FaceIDLib.Presets["MatrixGlow"] = {
    Name = "MatrixGlow",
    Label = "Matrix Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040505",
        PanelStroke = "#1F2521",
        Face = "#00FF41",
        FaceDim = "#005716",
        Scan = "#B2FFC6",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#00FF41",
        Window = "#090B09",
        WindowStroke = "#222924",
        TitleBar = "#0C0F0D",
        Sidebar = "#060807",
        SidebarStroke = "#1F2521",
        Element = "#101311",
        ElementHover = "#181D19",
        ElementActive = "#1F2621",
        Text = "#F5F5F7",
        SubText = "#8B948D",
        Accent = "#00FF41",
        AccentText = "#0B0B0D",
        Outline = "#222924",
        Shadow = "#000000",
        Highlight = "#F2FFF6",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.055,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.0795,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.1404,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.494,
        ScanDuration = 0.92,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 7,
    },
}

FaceIDLib.Presets["Crystal"] = {
    Name = "Crystal",
    Label = "Crystal",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070808",
        PanelStroke = "#262A2A",
        Face = "#7DF9FF",
        FaceDim = "#356466",
        Scan = "#C4FCFF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#7DF9FF",
        Window = "#0C0D0D",
        WindowStroke = "#2C3030",
        TitleBar = "#101212",
        Sidebar = "#090A0A",
        SidebarStroke = "#262A2A",
        Element = "#141616",
        ElementHover = "#1F2222",
        ElementActive = "#282D2D",
        Text = "#F5F5F7",
        SubText = "#8B9394",
        Accent = "#7DF9FF",
        AccentText = "#0B0B0D",
        Outline = "#2C3030",
        Shadow = "#000000",
        Highlight = "#F2FEFF",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.048,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.072,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.134,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.64,
        ScanDuration = 1.15,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 8,
    },
}

FaceIDLib.Presets["CrystalGlow"] = {
    Name = "CrystalGlow",
    Label = "Crystal Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040505",
        PanelStroke = "#1F2525",
        Face = "#7DF9FF",
        FaceDim = "#2B5557",
        Scan = "#D8FDFF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#7DF9FF",
        Window = "#090B0B",
        WindowStroke = "#222829",
        TitleBar = "#0C0F0F",
        Sidebar = "#060808",
        SidebarStroke = "#1F2525",
        Element = "#101313",
        ElementHover = "#181C1D",
        ElementActive = "#1F2626",
        Text = "#F5F5F7",
        SubText = "#8B9394",
        Accent = "#7DF9FF",
        AccentText = "#0B0B0D",
        Outline = "#222829",
        Shadow = "#000000",
        Highlight = "#F2FEFF",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.0528,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.0763,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.1447,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.608,
        ScanDuration = 1.058,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 8,
    },
}

FaceIDLib.Presets["Ember"] = {
    Name = "Ember",
    Label = "Ember",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#080707",
        PanelStroke = "#2A2726",
        Face = "#FF6B22",
        FaceDim = "#662E12",
        Scan = "#FFBC9C",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF6B22",
        Window = "#0D0C0C",
        WindowStroke = "#302D2C",
        TitleBar = "#121110",
        Sidebar = "#0A0909",
        SidebarStroke = "#2A2726",
        Element = "#161514",
        ElementHover = "#22201F",
        ElementActive = "#2D2A28",
        Text = "#F5F5F7",
        SubText = "#948E8B",
        Accent = "#FF6B22",
        AccentText = "#0B0B0D",
        Outline = "#302D2C",
        Shadow = "#000000",
        Highlight = "#FFF6F2",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.054,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.078,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.126,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.55,
        ScanDuration = 1.05,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 9,
    },
}

FaceIDLib.Presets["EmberGlow"] = {
    Name = "EmberGlow",
    Label = "Ember Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050504",
        PanelStroke = "#25211F",
        Face = "#FF6B22",
        FaceDim = "#57240C",
        Scan = "#FFD3BD",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#FF6B22",
        Window = "#0B0A09",
        WindowStroke = "#292422",
        TitleBar = "#0F0D0C",
        Sidebar = "#080706",
        SidebarStroke = "#25211F",
        Element = "#131110",
        ElementHover = "#1D1918",
        ElementActive = "#26221F",
        Text = "#F5F5F7",
        SubText = "#948E8B",
        Accent = "#FF6B22",
        AccentText = "#0B0B0D",
        Outline = "#292422",
        Shadow = "#000000",
        Highlight = "#FFF6F2",
    },
    Geometry = {
        Scale = 0.66,
        Thickness = 0.0594,
        ArmLength = 0.252,
        Inset = 0.032,
        CornerRadius = 0.166,
        EyeWidth = 0.0827,
        EyeHeight = 0.134,
        EyeOffsetX = 0.198,
        EyeOffsetY = -0.026,
        NoseWidth = 0.042,
        NoseHeight = 0.3,
        NoseOffsetY = 0.066,
        SmileWidth = 0.3,
        SmileDepth = 0.1361,
        SmileOffsetY = 0.17,
        SmileThickness = 0.044,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.522,
        ScanDuration = 0.966,
        HoldAfterScan = 0.25,
        SuccessDuration = 0.95,
        FadeOut = 0.62,
        FailShake = 9,
    },
}

FaceIDLib.Presets["Void"] = {
    Name = "Void",
    Label = "Void",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#070708",
        PanelStroke = "#26262A",
        Face = "#7D7AFF",
        FaceDim = "#353366",
        Scan = "#C5C3FF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#7D7AFF",
        Window = "#0C0C0D",
        WindowStroke = "#2C2C30",
        TitleBar = "#101012",
        Sidebar = "#09090A",
        SidebarStroke = "#26262A",
        Element = "#141416",
        ElementHover = "#1F1F22",
        ElementActive = "#28282D",
        Text = "#F5F5F7",
        SubText = "#8B8B94",
        Accent = "#7D7AFF",
        AccentText = "#0B0B0D",
        Outline = "#2C2C30",
        Shadow = "#000000",
        Highlight = "#F3F2FF",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.058,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.082,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.122,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.6,
        ScanDuration = 1.1,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 7,
    },
}

FaceIDLib.Presets["VoidGlow"] = {
    Name = "VoidGlow",
    Label = "Void Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#040405",
        PanelStroke = "#1F1F25",
        Face = "#7D7AFF",
        FaceDim = "#2B2957",
        Scan = "#D8D7FF",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#7D7AFF",
        Window = "#09090B",
        WindowStroke = "#222229",
        TitleBar = "#0C0C0F",
        Sidebar = "#060608",
        SidebarStroke = "#1F1F25",
        Element = "#101013",
        ElementHover = "#18181D",
        ElementActive = "#1F1F26",
        Text = "#F5F5F7",
        SubText = "#8B8B94",
        Accent = "#7D7AFF",
        AccentText = "#0B0B0D",
        Outline = "#222229",
        Shadow = "#000000",
        Highlight = "#F3F2FF",
    },
    Geometry = {
        Scale = 0.63,
        Thickness = 0.0638,
        ArmLength = 0.246,
        Inset = 0.035,
        CornerRadius = 0.174,
        EyeWidth = 0.0869,
        EyeHeight = 0.13,
        EyeOffsetX = 0.192,
        EyeOffsetY = -0.024,
        NoseWidth = 0.046,
        NoseHeight = 0.292,
        NoseOffsetY = 0.063,
        SmileWidth = 0.292,
        SmileDepth = 0.1318,
        SmileOffsetY = 0.168,
        SmileThickness = 0.048,
        SmileSegments = 28,
    },
    Animation = {
        FadeIn = 0.57,
        ScanDuration = 1.012,
        HoldAfterScan = 0.28,
        SuccessDuration = 1,
        FadeOut = 0.66,
        FailShake = 7,
    },
}

FaceIDLib.Presets["Pearl"] = {
    Name = "Pearl",
    Label = "Pearl",
    Mode = "Light",
    Glow = false,
    Colors = {
        Panel = "#FAFAFF",
        PanelStroke = "#D5D5E0",
        Face = "#8E8E93",
        FaceDim = "#45456A",
        Scan = "#85858C",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#8E8E93",
        Window = "#F1F1FE",
        WindowStroke = "#CDCDD7",
        TitleBar = "#EAEAF6",
        Sidebar = "#E3E3F1",
        SidebarStroke = "#D5D5E0",
        Element = "#E1E1ED",
        ElementHover = "#D4D4E4",
        ElementActive = "#C8C8DB",
        Text = "#18181D",
        SubText = "#7E7E85",
        Accent = "#8E8E93",
        AccentText = "#0B0B0D",
        Outline = "#CDCDD7",
        Shadow = "#7E7E8C",
        Highlight = "#FFFFFF",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.05,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.075,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.13,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.52,
        ScanDuration = 1,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 8,
    },
}

FaceIDLib.Presets["PearlDeep"] = {
    Name = "PearlDeep",
    Label = "Pearl Deep",
    Mode = "Light",
    Glow = true,
    Colors = {
        Panel = "#FAFAFF",
        PanelStroke = "#D5D5E0",
        Face = "#8E8E93",
        FaceDim = "#45456A",
        Scan = "#85858C",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#8E8E93",
        Window = "#E7E7FE",
        WindowStroke = "#CDCDD7",
        TitleBar = "#EAEAF6",
        Sidebar = "#E3E3F1",
        SidebarStroke = "#D5D5E0",
        Element = "#E1E1ED",
        ElementHover = "#D4D4E4",
        ElementActive = "#C8C8DB",
        Text = "#18181D",
        SubText = "#7E7E85",
        Accent = "#8E8E93",
        AccentText = "#0B0B0D",
        Outline = "#CDCDD7",
        Shadow = "#7E7E8C",
        Highlight = "#FFFFFF",
    },
    Geometry = {
        Scale = 0.68,
        Thickness = 0.055,
        ArmLength = 0.256,
        Inset = 0.03,
        CornerRadius = 0.158,
        EyeWidth = 0.0795,
        EyeHeight = 0.138,
        EyeOffsetX = 0.204,
        EyeOffsetY = -0.028,
        NoseWidth = 0.04,
        NoseHeight = 0.308,
        NoseOffsetY = 0.069,
        SmileWidth = 0.308,
        SmileDepth = 0.1404,
        SmileOffsetY = 0.172,
        SmileThickness = 0.041,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.494,
        ScanDuration = 0.92,
        HoldAfterScan = 0.22,
        SuccessDuration = 0.9,
        FadeOut = 0.58,
        FailShake = 8,
    },
}

FaceIDLib.Presets["Cocoa"] = {
    Name = "Cocoa",
    Label = "Cocoa",
    Mode = "Dark",
    Glow = false,
    Colors = {
        Panel = "#080707",
        PanelStroke = "#2A2826",
        Face = "#C08A4E",
        FaceDim = "#4D3821",
        Scan = "#FFDFBB",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#C08A4E",
        Window = "#0D0D0C",
        WindowStroke = "#302E2C",
        TitleBar = "#121110",
        Sidebar = "#0A0909",
        SidebarStroke = "#2A2826",
        Element = "#161514",
        ElementHover = "#22211F",
        ElementActive = "#2D2B28",
        Text = "#F5F5F7",
        SubText = "#94908B",
        Accent = "#C08A4E",
        AccentText = "#0B0B0D",
        Outline = "#302E2C",
        Shadow = "#000000",
        Highlight = "#FFF9F2",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.048,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.072,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.134,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.64,
        ScanDuration = 1.15,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 9,
    },
}

FaceIDLib.Presets["CocoaGlow"] = {
    Name = "CocoaGlow",
    Label = "Cocoa Glow",
    Mode = "Dark",
    Glow = true,
    Colors = {
        Panel = "#050504",
        PanelStroke = "#25221F",
        Face = "#C08A4E",
        FaceDim = "#412F1B",
        Scan = "#FFE9D2",
        Success = "#30D158",
        Fail = "#FF453A",
        Warn = "#FF9F0A",
        Info = "#0A84FF",
        Glow = "#C08A4E",
        Window = "#0B0A09",
        WindowStroke = "#292622",
        TitleBar = "#0F0E0C",
        Sidebar = "#080706",
        SidebarStroke = "#25221F",
        Element = "#131110",
        ElementHover = "#1D1A18",
        ElementActive = "#26231F",
        Text = "#F5F5F7",
        SubText = "#94908B",
        Accent = "#C08A4E",
        AccentText = "#0B0B0D",
        Outline = "#292622",
        Shadow = "#000000",
        Highlight = "#FFF9F2",
    },
    Geometry = {
        Scale = 0.7,
        Thickness = 0.0528,
        ArmLength = 0.26,
        Inset = 0.028,
        CornerRadius = 0.152,
        EyeWidth = 0.0763,
        EyeHeight = 0.14,
        EyeOffsetX = 0.208,
        EyeOffsetY = -0.03,
        NoseWidth = 0.038,
        NoseHeight = 0.314,
        NoseOffsetY = 0.071,
        SmileWidth = 0.314,
        SmileDepth = 0.1447,
        SmileOffsetY = 0.175,
        SmileThickness = 0.039,
        SmileSegments = 30,
    },
    Animation = {
        FadeIn = 0.608,
        ScanDuration = 1.058,
        HoldAfterScan = 0.32,
        SuccessDuration = 1.05,
        FadeOut = 0.7,
        FailShake = 9,
    },
}

FaceIDLib.ThemeOrder = {
    "IOSDark",
    "IOSDarkGlow",
    "IOSLight",
    "IOSLightDeep",
    "Midnight",
    "MidnightGlow",
    "Ocean",
    "OceanGlow",
    "Lavender",
    "LavenderGlow",
    "Sunset",
    "SunsetGlow",
    "Cyber",
    "CyberGlow",
    "Mono",
    "MonoGlow",
    "Blood",
    "BloodGlow",
    "Gold",
    "GoldGlow",
    "Glass",
    "GlassDeep",
    "NeonGreen",
    "NeonGreenGlow",
    "Forest",
    "ForestGlow",
    "Ice",
    "IceGlow",
    "Grape",
    "GrapeGlow",
    "Rose",
    "RoseGlow",
    "Amber",
    "AmberGlow",
    "Slate",
    "SlateGlow",
    "Matrix",
    "MatrixGlow",
    "Crystal",
    "CrystalGlow",
    "Ember",
    "EmberGlow",
    "Void",
    "VoidGlow",
    "Pearl",
    "PearlDeep",
    "Cocoa",
    "CocoaGlow",
}

FaceIDLib.IconStyles = {}

FaceIDLib.IconStyles["Classic"] = {
    Name = "Classic",
    Label = "Classic",
    Scale = 0.62,
    Thickness = 0.052,
    ArmLength = 0.235,
    Inset = 0.055,
    EyeWidth = 0.048,
    EyeHeight = 0.115,
    EyeOffsetX = 0.135,
    EyeOffsetY = 0.02,
    NoseWidth = 0.045,
    NoseHeight = 0.1,
    NoseOffsetY = 0.075,
    SmileWidth = 0.4,
    SmileDepth = 0.11,
    SmileOffsetY = 0.165,
    SmileThickness = 0.05,
    SmileSegments = 26,
}

FaceIDLib.IconStyles["Compact"] = {
    Name = "Compact",
    Label = "Compact",
    Scale = 0.66,
    Thickness = 0.062,
    ArmLength = 0.215,
    Inset = 0.062,
    EyeWidth = 0.056,
    EyeHeight = 0.108,
    EyeOffsetX = 0.125,
    EyeOffsetY = 0.02,
    NoseWidth = 0.052,
    NoseHeight = 0.094,
    NoseOffsetY = 0.068,
    SmileWidth = 0.37,
    SmileDepth = 0.1,
    SmileOffsetY = 0.155,
    SmileThickness = 0.058,
    SmileSegments = 24,
}

FaceIDLib.IconStyles["Wide"] = {
    Name = "Wide",
    Label = "Wide",
    Scale = 0.58,
    Thickness = 0.05,
    ArmLength = 0.26,
    Inset = 0.045,
    EyeWidth = 0.045,
    EyeHeight = 0.122,
    EyeOffsetX = 0.15,
    EyeOffsetY = 0.02,
    NoseWidth = 0.042,
    NoseHeight = 0.108,
    NoseOffsetY = 0.08,
    SmileWidth = 0.45,
    SmileDepth = 0.122,
    SmileOffsetY = 0.172,
    SmileThickness = 0.046,
    SmileSegments = 28,
}

FaceIDLib.IconStyles["Thin"] = {
    Name = "Thin",
    Label = "Thin",
    Scale = 0.64,
    Thickness = 0.038,
    ArmLength = 0.24,
    Inset = 0.052,
    EyeWidth = 0.036,
    EyeHeight = 0.12,
    EyeOffsetX = 0.138,
    EyeOffsetY = 0.02,
    NoseWidth = 0.034,
    NoseHeight = 0.104,
    NoseOffsetY = 0.076,
    SmileWidth = 0.405,
    SmileDepth = 0.112,
    SmileOffsetY = 0.166,
    SmileThickness = 0.036,
    SmileSegments = 26,
}

FaceIDLib.IconStyles["Bold"] = {
    Name = "Bold",
    Label = "Bold",
    Scale = 0.6,
    Thickness = 0.068,
    ArmLength = 0.225,
    Inset = 0.062,
    EyeWidth = 0.062,
    EyeHeight = 0.11,
    EyeOffsetX = 0.13,
    EyeOffsetY = 0.02,
    NoseWidth = 0.058,
    NoseHeight = 0.096,
    NoseOffsetY = 0.072,
    SmileWidth = 0.38,
    SmileDepth = 0.104,
    SmileOffsetY = 0.16,
    SmileThickness = 0.064,
    SmileSegments = 26,
}

FaceIDLib.IconStyles["Tall"] = {
    Name = "Tall",
    Label = "Tall",
    Scale = 0.58,
    Thickness = 0.052,
    ArmLength = 0.25,
    Inset = 0.048,
    EyeWidth = 0.046,
    EyeHeight = 0.128,
    EyeOffsetX = 0.14,
    EyeOffsetY = 0.02,
    NoseWidth = 0.044,
    NoseHeight = 0.112,
    NoseOffsetY = 0.082,
    SmileWidth = 0.4,
    SmileDepth = 0.118,
    SmileOffsetY = 0.176,
    SmileThickness = 0.048,
    SmileSegments = 26,
}

FaceIDLib.IconStyles["Round"] = {
    Name = "Round",
    Label = "Round",
    Scale = 0.64,
    Thickness = 0.058,
    ArmLength = 0.23,
    Inset = 0.06,
    EyeWidth = 0.054,
    EyeHeight = 0.116,
    EyeOffsetX = 0.134,
    EyeOffsetY = 0.02,
    NoseWidth = 0.05,
    NoseHeight = 0.1,
    NoseOffsetY = 0.074,
    SmileWidth = 0.395,
    SmileDepth = 0.118,
    SmileOffsetY = 0.164,
    SmileThickness = 0.056,
    SmileSegments = 30,
}

FaceIDLib.IconStyles["Sharp"] = {
    Name = "Sharp",
    Label = "Sharp",
    Scale = 0.62,
    Thickness = 0.044,
    ArmLength = 0.245,
    Inset = 0.05,
    EyeWidth = 0.042,
    EyeHeight = 0.122,
    EyeOffsetX = 0.142,
    EyeOffsetY = 0.02,
    NoseWidth = 0.04,
    NoseHeight = 0.106,
    NoseOffsetY = 0.078,
    SmileWidth = 0.415,
    SmileDepth = 0.108,
    SmileOffsetY = 0.168,
    SmileThickness = 0.044,
    SmileSegments = 22,
}

FaceIDLib.IconStyles["Micro"] = {
    Name = "Micro",
    Label = "Micro",
    Scale = 0.68,
    Thickness = 0.056,
    ArmLength = 0.22,
    Inset = 0.066,
    EyeWidth = 0.05,
    EyeHeight = 0.106,
    EyeOffsetX = 0.126,
    EyeOffsetY = 0.02,
    NoseWidth = 0.048,
    NoseHeight = 0.092,
    NoseOffsetY = 0.066,
    SmileWidth = 0.36,
    SmileDepth = 0.096,
    SmileOffsetY = 0.152,
    SmileThickness = 0.052,
    SmileSegments = 24,
}

FaceIDLib.IconStyles["Soft"] = {
    Name = "Soft",
    Label = "Soft",
    Scale = 0.6,
    Thickness = 0.06,
    ArmLength = 0.228,
    Inset = 0.058,
    EyeWidth = 0.058,
    EyeHeight = 0.112,
    EyeOffsetX = 0.132,
    EyeOffsetY = 0.02,
    NoseWidth = 0.054,
    NoseHeight = 0.098,
    NoseOffsetY = 0.072,
    SmileWidth = 0.385,
    SmileDepth = 0.114,
    SmileOffsetY = 0.162,
    SmileThickness = 0.06,
    SmileSegments = 30,
}

FaceIDLib.IconStyles["Aero"] = {
    Name = "Aero",
    Label = "Aero",
    Scale = 0.56,
    Thickness = 0.046,
    ArmLength = 0.27,
    Inset = 0.042,
    EyeWidth = 0.04,
    EyeHeight = 0.126,
    EyeOffsetX = 0.152,
    EyeOffsetY = 0.02,
    NoseWidth = 0.038,
    NoseHeight = 0.11,
    NoseOffsetY = 0.084,
    SmileWidth = 0.46,
    SmileDepth = 0.126,
    SmileOffsetY = 0.178,
    SmileThickness = 0.042,
    SmileSegments = 28,
}

FaceIDLib.IconStyles["Dense"] = {
    Name = "Dense",
    Label = "Dense",
    Scale = 0.66,
    Thickness = 0.054,
    ArmLength = 0.232,
    Inset = 0.052,
    EyeWidth = 0.05,
    EyeHeight = 0.118,
    EyeOffsetX = 0.136,
    EyeOffsetY = 0.02,
    NoseWidth = 0.046,
    NoseHeight = 0.102,
    NoseOffsetY = 0.076,
    SmileWidth = 0.398,
    SmileDepth = 0.106,
    SmileOffsetY = 0.166,
    SmileThickness = 0.052,
    SmileSegments = 28,
}

local Renderer = {}
Renderer.__index = Renderer

local function bar(parent, zIndex)
    return create("Frame", {
        Name = "Bar",
        BackgroundColor3 = Color3new(1, 1, 1),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0, 0),
        ZIndex = zIndex or 2,
        Parent = parent,
    })
end

local function softBox(parent, color, transparency)
    local frame = create("Frame", {
        Name = "Soft",
        BackgroundColor3 = color or Color3new(0, 0, 0),
        BackgroundTransparency = transparency or 0.5,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = parent,
    })
    return frame
end

function Renderer.new(options)
    local self = setmetatable({}, Renderer)
    self.Gui = options.Gui
    self.Config = options.Config
    self.Alpha = 0
    self.ScaleFactor = 1
    self.OffsetX = 0
    self.OffsetY = 0
    self.Reveal = 0
    self.LitColor = Color3new(1, 1, 1)
    self.DimColor = Color3new(0.3, 0.3, 0.3)
    self.ScanVisible = false
    self.ScanProgress = 0
    self.Rings = {}
    self.Parts = {}
    self:buildRoot()
    self:buildPanel()
    self:buildIcon()
    self:buildScan()
    self:buildText()
    self:layout()
    self:applyColors()
    self:applyAlpha()
    return self
end

function Renderer:buildRoot()
    self.Root = create("Frame", {
        Name = "FaceIDRoot",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2fromOffset(0, 0),
        AnchorPoint = Vector2new(0.5, 0),
        ZIndex = 50,
        Parent = self.Gui,
    })
    self.Holder = create("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2fromOffset(0, 0),
        AnchorPoint = Vector2new(0.5, 0),
        Position = UDim2fromScale(0.5, 0),
        Parent = self.Root,
    })
end

function Renderer:buildPanel()
    local config = self.Config
    self.GlowFrame = create("Frame", {
        Name = "Glow",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        ZIndex = 1,
        Parent = self.Holder,
    })
    roundCornersScale(self.GlowFrame, 0.5)
    self.GlowStroke = create("UIStroke", {
        Parent = self.GlowFrame,
        Thickness = 18,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
    })
    self.Panel = create("Frame", {
        Name = "Panel",
        BackgroundColor3 = Color3new(0.05, 0.05, 0.06),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0),
        Position = UDim2fromScale(0.5, 0),
        ClipsDescendants = true,
        ZIndex = 3,
        Parent = self.Holder,
    })
    roundCorners(self.Panel, config.Panel.CornerRadius)
    self.PanelStroke = create("UIStroke", {
        Parent = self.Panel,
        Thickness = config.Panel.StrokeThickness,
        Transparency = config.Panel.StrokeTransparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
    })
    self.Shadow = create("Frame", {
        Name = "Shadow",
        BackgroundColor3 = Color3new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0),
        Position = UDim2new(0.5, 0, 0, 10),
        ZIndex = 0,
        Parent = self.Holder,
    })
    roundCorners(self.Shadow, config.Panel.CornerRadius)
    self.IconBox = create("Frame", {
        Name = "IconBox",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        ZIndex = 5,
        Parent = self.Panel,
    })
    self.Bloom = create("Frame", {
        Name = "Bloom",
        BackgroundColor3 = Color3new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        ZIndex = 2,
        Parent = self.Panel,
    })
    roundCornersScale(self.Bloom, 0.5)
    self.RingHolder = create("Frame", {
        Name = "Rings",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        Size = UDim2fromScale(1, 1),
        ZIndex = 2,
        Parent = self.Panel,
    })
end

function Renderer:addPart(kind, order)
    local frame = bar(self.IconBox, 6)
    local part = {
        Frame = frame,
        Kind = kind,
        Order = order,
        Corner = create("UICorner", {
            Parent = frame,
            CornerRadius = UDimnew(0.5, 0),
        }),
    }
    table.insert(self.Parts, part)
    return part
end

function Renderer:buildIcon()
    local config = self.Config
    self.BracketParts = {}
    local corners = {
        { name = "TL", x = 0, y = 0 },
        { name = "TR", x = 1, y = 0 },
        { name = "BL", x = 0, y = 1 },
        { name = "BR", x = 1, y = 1 },
    }
    for _, corner in ipairs(corners) do
        local horizontal = self:addPart("Bracket", corner.y)
        local vertical = self:addPart("Bracket", corner.y)
        horizontal.CornerName = corner.name .. "H"
        vertical.CornerName = corner.name .. "V"
        horizontal.Anchor = corner
        vertical.Anchor = corner
        table.insert(self.BracketParts, horizontal)
        table.insert(self.BracketParts, vertical)
    end
    self.ArcSegmentsCount = math.max(2, math.floor(config.Icon.ArcSegments or 7))
    self.ArcParts = {}
    for _, corner in ipairs(corners) do
        for index = 1, self.ArcSegmentsCount do
            local part = self:addPart("Arc", corner.y)
            part.CornerName = corner.name
            part.Anchor = corner
            part.Index = index
            table.insert(self.ArcParts, part)
        end
    end
    self.LeftEye = self:addPart("Eye", 0.42)
    self.RightEye = self:addPart("Eye", 0.42)
    self.Nose = self:addPart("Nose", 0.52)
    self.NoseHook = self:addPart("Nose", 0.58)
    self.SmileParts = {}
    for index = 1, config.Icon.SmileSegments do
        local part = self:addPart("Smile", 0.62)
        part.Index = index
        table.insert(self.SmileParts, part)
    end
end

function Renderer:buildScan()
    self.ScanLine = create("Frame", {
        Name = "ScanLine",
        BackgroundColor3 = Color3new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Size = UDim2fromScale(1, 0),
        Position = UDim2fromScale(0.5, 0),
        ZIndex = 8,
        Parent = self.Panel,
    })
    self.ScanBand = create("Frame", {
        Name = "ScanBand",
        BackgroundColor3 = Color3new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 1),
        Size = UDim2fromScale(1, 0),
        Position = UDim2fromScale(0.5, 0),
        ZIndex = 7,
        Parent = self.Panel,
    })
    self.ScanGradient = create("UIGradient", {
        Parent = self.ScanBand,
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.6, 0.55),
            NumberSequenceKeypoint.new(1, 0.05),
        }),
    })
end

function Renderer:buildText()
    self.TextHolder = create("Frame", {
        Name = "TextHolder",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0),
        Size = UDim2new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 20,
        Parent = self.Holder,
    })
    addList(self.TextHolder, Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Center)
    self.TitleLabel = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2new(1, 0, 0, 16),
        Font = fontFromName(self.Config.Text.Font),
        Text = self.Config.Text.Title or "",
        TextColor3 = Color3new(1, 1, 1),
        TextSize = self.Config.Text.Size or 14,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 20,
        Parent = self.TextHolder,
    })
    self.SubLabel = create("TextLabel", {
        Name = "Sub",
        BackgroundTransparency = 1,
        Size = UDim2new(1, 0, 0, 14),
        Font = Enum.Font.Gotham,
        Text = self.Config.Text.Subtitle or "",
        TextColor3 = Color3new(0.6, 0.6, 0.6),
        TextSize = self.Config.Text.SubSize or 12,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 20,
        Parent = self.TextHolder,
    })
    self.TextHolder.Visible = self.Config.Text.Enabled and true or false
end

function Renderer:layout()
    local config = self.Config
    local panelSize = config.Panel.Size
    local iconSize = panelSize * config.Icon.Scale
    local icon = config.Icon
    local thickness = maxn(1, icon.Thickness * iconSize)
    local arm = icon.ArmLength * iconSize
    local inset = icon.Inset * iconSize
    local glowSize = icon.Glow or 0

    self.Panel.Size = UDim2fromOffset(panelSize, panelSize)
    self.Panel.Position = UDim2fromScale(0.5, 0)
    self.Panel.BackgroundTransparency = config.Panel.Transparency
    self.PanelStroke.Thickness = config.Panel.StrokeThickness
    self.PanelStroke.Transparency = config.Panel.StrokeTransparency
    local corner = self.Panel:FindFirstChildOfClass("UICorner")
    if corner then
        corner.CornerRadius = UDimnew(0, config.Panel.CornerRadius)
    end
    local shadowCorner = self.Shadow:FindFirstChildOfClass("UICorner")
    if shadowCorner then
        shadowCorner.CornerRadius = UDimnew(0, config.Panel.CornerRadius)
    end
    self.Shadow.Size = UDim2fromOffset(panelSize + 4, panelSize + 4)
    self.Shadow.Position = UDim2new(0.5, 0, 0, 12)
    self.Shadow.Visible = config.Panel.Shadow and true or false
    self.Holder.Size = UDim2fromOffset(panelSize, panelSize)
    self.IconBox.Size = UDim2fromOffset(iconSize, iconSize)
    self.Bloom.Size = UDim2fromOffset(iconSize * 0.82, iconSize * 0.82)
    self.GlowFrame.Size = UDim2fromOffset(panelSize * 0.94, panelSize * 0.94)
    self.GlowStroke.Thickness = 12 + glowSize * 40

    local arcRadius = maxn(thickness, (icon.CornerRadius or 0.132) * iconSize)
    local strokeRadius = maxn(thickness * 0.5, arcRadius - thickness * 0.5)
    local armEnd = math.max(inset + arm, inset + arcRadius + thickness * 2)
    local armLength = math.max(thickness * 2, armEnd - (inset + arcRadius))
    for _, part in ipairs(self.BracketParts) do
        local frame = part.Frame
        local anchor = part.Anchor
        local horizontal = string.sub(part.CornerName, -1) == "H"
        local leftX = inset
        local rightX = iconSize - inset - thickness
        local topY = inset
        local bottomY = iconSize - inset - thickness
        if horizontal then
            frame.AnchorPoint = Vector2new(0, 0)
            frame.Position = UDim2fromOffset(
                anchor.x == 0 and (inset + arcRadius) or (iconSize - inset - arcRadius - armLength),
                anchor.y == 0 and topY or bottomY
            )
            frame.Size = UDim2fromOffset(armLength, thickness)
            part.Order = ((anchor.y == 0 and topY or bottomY) + thickness * 0.5) / iconSize
        else
            frame.AnchorPoint = Vector2new(0, 0)
            frame.Position = UDim2fromOffset(
                anchor.x == 0 and leftX or rightX,
                anchor.y == 0 and (inset + arcRadius) or (iconSize - inset - arcRadius - armLength)
            )
            frame.Size = UDim2fromOffset(thickness, armLength)
            part.Order = ((anchor.y == 0 and (inset + arcRadius) or (iconSize - inset - arcRadius - armLength)) + armLength * 0.5) / iconSize
        end
        part.Corner.CornerRadius = UDimnew(0, thickness * (icon.CapRadius or 0.5))
    end

    local segments = self.ArcSegmentsCount
    for _, part in ipairs(self.ArcParts) do
        local anchor = part.Anchor
        local centerX = anchor.x == 0 and (inset + arcRadius) or (iconSize - inset - arcRadius)
        local centerY = anchor.y == 0 and (inset + arcRadius) or (iconSize - inset - arcRadius)
        local base = 180
        if anchor.x == 1 and anchor.y == 0 then
            base = 270
        elseif anchor.x == 1 and anchor.y == 1 then
            base = 0
        elseif anchor.x == 0 and anchor.y == 1 then
            base = 90
        end
        local step = (math.pi * 0.5) / segments
        local angleFrom = math.rad(base) + step * (part.Index - 1)
        local angleTo = angleFrom + step
        local fromX = centerX + math.cos(angleFrom) * strokeRadius
        local fromY = centerY + math.sin(angleFrom) * strokeRadius
        local toX = centerX + math.cos(angleTo) * strokeRadius
        local toY = centerY + math.sin(angleTo) * strokeRadius
        local midX = (fromX + toX) * 0.5
        local midY = (fromY + toY) * 0.5
        local length = Geometry.distance(Vector2new(fromX, fromY), Vector2new(toX, toY)) + thickness * 0.75
        local angle = math.deg(math.atan2(toY - fromY, toX - fromX))
        part.Frame.AnchorPoint = Vector2new(0.5, 0.5)
        part.Frame.Position = UDim2fromOffset(midX, midY)
        part.Frame.Size = UDim2fromOffset(length, thickness)
        part.Frame.Rotation = angle
        part.Corner.CornerRadius = UDimnew(0, thickness * 0.5)
        part.Order = midY / iconSize
    end

    local eyeWidth = maxn(1, icon.EyeWidth * iconSize)
    local eyeHeight = maxn(1, icon.EyeHeight * iconSize)
    local eyeCenterY = iconSize * (0.5 + (icon.EyeOffsetY or 0.02) - 0.06)
    local eyeOffsetX = icon.EyeOffsetX * iconSize
    self.LeftEye.Frame.AnchorPoint = Vector2new(0.5, 0.5)
    self.LeftEye.Frame.Position = UDim2fromOffset(iconSize * 0.5 - eyeOffsetX, eyeCenterY)
    self.LeftEye.Frame.Size = UDim2fromOffset(eyeWidth, eyeHeight)
    self.LeftEye.Corner.CornerRadius = UDimnew(0, eyeWidth * 0.5)
    self.RightEye.Frame.AnchorPoint = Vector2new(0.5, 0.5)
    self.RightEye.Frame.Position = UDim2fromOffset(iconSize * 0.5 + eyeOffsetX, eyeCenterY)
    self.RightEye.Frame.Size = UDim2fromOffset(eyeWidth, eyeHeight)
    self.RightEye.Corner.CornerRadius = UDimnew(0, eyeWidth * 0.5)
    self.LeftEye.Order = (eyeCenterY + eyeHeight * 0.5) / iconSize
    self.RightEye.Order = self.LeftEye.Order

    local noseWidth = maxn(1, icon.NoseWidth * iconSize)
    local noseHeight = maxn(1, icon.NoseHeight * iconSize)
    local noseTop = iconSize * (0.28 + (icon.NoseOffsetY or 0.066))
    self.Nose.Frame.AnchorPoint = Vector2new(0.5, 0)
    self.Nose.Frame.Position = UDim2fromOffset(iconSize * 0.5, noseTop)
    self.Nose.Frame.Size = UDim2fromOffset(noseWidth, noseHeight)
    self.Nose.Corner.CornerRadius = UDimnew(0, noseWidth * 0.5)
    self.Nose.Order = (noseTop + noseHeight * 0.45) / iconSize
    local hookScale = icon.NoseHook or 0
    local hookLength = noseWidth * (icon.NoseHookLength or 1.9) * hookScale
    local hookAngle = -(icon.NoseHookAngle or 42)
    self.NoseHook.Frame.AnchorPoint = Vector2new(0.5, 0.5)
    self.NoseHook.Frame.Position = UDim2fromOffset(
        iconSize * 0.5 + noseWidth * 0.5 - hookLength * 0.5 * math.cos(math.rad(hookAngle)),
        noseTop + noseHeight - noseWidth * 0.15 - hookLength * 0.5 * math.sin(math.rad(hookAngle))
    )
    self.NoseHook.Frame.Size = UDim2fromOffset(hookLength, noseWidth)
    self.NoseHook.Frame.Rotation = hookAngle
    self.NoseHook.Corner.CornerRadius = UDimnew(0, noseWidth * 0.5)
    self.NoseHook.Order = (noseTop + noseHeight) / iconSize
    self.NoseHook.Frame.Visible = hookScale > 0.03

    local smileWidth = icon.SmileWidth * iconSize
    local smileDepth = icon.SmileDepth * iconSize * (icon.SmileCurve or 1)
    local smileThickness = maxn(1, icon.SmileThickness * iconSize)
    local smileY = iconSize * 0.5 + icon.SmileOffsetY * iconSize
    local startX = iconSize * 0.5 - smileWidth * 0.5
    local endX = iconSize * 0.5 + smileWidth * 0.5
    local segments = #self.SmileParts
    local points = {}
    for index = 0, segments do
        local alpha = index / segments
        local inverse = 1 - alpha
        local x = inverse * inverse * startX + 2 * inverse * alpha * (iconSize * 0.5) + alpha * alpha * endX
        local y = inverse * inverse * smileY + 2 * inverse * alpha * (smileY + smileDepth * 2) + alpha * alpha * smileY
        table.insert(points, Vector2new(x, y))
    end
    for index, part in ipairs(self.SmileParts) do
        local from = points[index]
        local to = points[index + 1]
        local midX = (from.X + to.X) * 0.5
        local midY = (from.Y + to.Y) * 0.5
        local length = Geometry.distance(from, to) + smileThickness * 0.85
        local angle = math.deg(math.atan2(to.Y - from.Y, to.X - from.X))
        part.Frame.AnchorPoint = Vector2new(0.5, 0.5)
        part.Frame.Position = UDim2fromOffset(midX, midY)
        part.Frame.Size = UDim2fromOffset(length, smileThickness)
        part.Frame.Rotation = angle
        part.Corner.CornerRadius = UDimnew(0, smileThickness * 0.5)
        part.Order = (midY / iconSize) * 0.92 + 0.06
    end

    self.IconSizePixels = iconSize
    self.TextHolder.Position = UDim2new(0.5, 0, 0, panelSize + (self.Config.Text.Gap or 10))
    self.TitleLabel.TextSize = self.Config.Text.Size or 14
    self.SubLabel.TextSize = self.Config.Text.SubSize or 12
    self.TitleLabel.Font = fontFromName(self.Config.Text.Font)
    self.TitleLabel.Text = self.Config.Text.Title or ""
    self.SubLabel.Text = self.Config.Text.Subtitle or ""
    self:applyPosition()
end

function Renderer:applyPosition()
    local config = self.Config
    local position = config.Position
    self.Root.Position = UDim2new(position.AnchorX, position.OffsetX, position.AnchorY, position.OffsetY)
    self.Holder.Position = UDim2fromScale(0.5, 0)
end

function Renderer:applyColors()
    local colors = self.Config.Colors
    self.Panel.BackgroundColor3 = colors.Panel
    self.PanelStroke.Color = colors.PanelStroke
    self.Shadow.BackgroundColor3 = colors.Shadow
    self.Shadow.BackgroundTransparency = self.Config.Panel.ShadowTransparency
    self.GlowStroke.Color = colors.Glow or colors.Face

    local dimColor = colors.FaceDim or shadeColor(colors.Face, -0.55)
    self.LitColor = colors.Face
    self.DimColor = dimColor

    for _, part in ipairs(self.Parts) do
        local lit = clamp01(self.Reveal * 1.15 - (part.Order or 0))
        local color = lerpColor(dimColor, colors.Face, lit)
        part.Frame.BackgroundColor3 = color
        part.Frame.BackgroundTransparency = 1 - self.Alpha * (0.55 + 0.45 * lit)
    end

    self.ScanLine.BackgroundColor3 = colors.Scan or colors.Face
    self.ScanBand.BackgroundColor3 = colors.Scan or colors.Face
    self.Bloom.BackgroundColor3 = colors.Face
    self.TitleLabel.TextColor3 = parseColor(self.Config.Text.Color, Color3new(1, 1, 1))
    self.SubLabel.TextColor3 = parseColor(self.Config.Text.SubColor, Color3new(0.6, 0.6, 0.6))
    for _, ring in ipairs(self.Rings) do
        if ring.Stroke then
            ring.Stroke.Color = colors.Success or colors.Face
        end
    end
end

function Renderer:setReveal(progress)
    self.Reveal = clamp01(progress)
    local colors = self.Config.Colors
    local dimColor = self.DimColor
    for _, part in ipairs(self.Parts) do
        local local_alpha = clamp01((self.Reveal - (part.Order or 0) * 0.85) / 0.18)
        local color = lerpColor(dimColor, self.LitColor, local_alpha)
        part.Frame.BackgroundColor3 = color
    end
    self.Bloom.BackgroundTransparency = 1 - 0.10 * self.Reveal * self.Alpha
    self.GlowStroke.Transparency = 1 - 0.18 * self.Reveal * self.Alpha
end

function Renderer:setAlpha(alpha)
    self.Alpha = clamp01(alpha)
    self.Panel.BackgroundTransparency = 1 - (1 - self.Config.Panel.Transparency) * self.Alpha
    self.PanelStroke.Transparency = 1 - (1 - self.Config.Panel.StrokeTransparency) * self.Alpha
    self.Shadow.BackgroundTransparency = 1 - (1 - self.Config.Panel.ShadowTransparency) * self.Alpha
    for _, part in ipairs(self.Parts) do
        local lit = clamp01(self.Reveal * 1.15 - (part.Order or 0))
        part.Frame.BackgroundTransparency = 1 - self.Alpha * (0.55 + 0.45 * lit)
    end
    self.ScanLine.BackgroundTransparency = 1 - self.Alpha
    self.ScanBand.BackgroundTransparency = 1 - self.Alpha * 0.6
    self.TextHolder.Visible = (self.Config.Text.Enabled and self.Alpha > 0.02) and true or false
    self.TitleLabel.TextTransparency = 1 - self.Alpha
    self.SubLabel.TextTransparency = 1 - self.Alpha * 0.85
end

function Renderer:applyAlpha()
    self:setAlpha(self.Alpha)
    self:setReveal(self.Reveal)
end

function Renderer:setScale(scale)
    self.ScaleFactor = scale
    local holderScale = self.Holder:FindFirstChildOfClass("UIScale")
    if not holderScale then
        holderScale = create("UIScale", {
            Name = "HolderScale",
            Parent = self.Holder,
        })
    end
    holderScale.Scale = scale
end

function Renderer:setScan(progress, visible)
    self.ScanProgress = clamp01(progress)
    self.ScanVisible = visible and true or false
    local panelSize = self.Config.Panel.Size
    local y = self.ScanProgress * panelSize
    self.ScanLine.Visible = self.ScanVisible
    self.ScanBand.Visible = self.ScanVisible
    self.ScanLine.Position = UDim2new(0.5, 0, 0, y)
    self.ScanLine.Size = UDim2new(1, 0, 0, 2)
    self.ScanBand.Position = UDim2new(0.5, 0, 0, y)
    self.ScanBand.Size = UDim2new(1, 0, 0, panelSize * 0.32)
    self.ScanLine.Size = UDim2new(1, 0, 0, maxn(1, panelSize * 0.008))
end

function Renderer:setColorOverride(kind)
    local colors = self.Config.Colors
    if kind == "success" then
        for _, part in ipairs(self.Parts) do
            part.Frame.BackgroundColor3 = colors.Success
        end
        self.Bloom.BackgroundColor3 = colors.Success
    elseif kind == "fail" then
        for _, part in ipairs(self.Parts) do
            part.Frame.BackgroundColor3 = colors.Fail
        end
        self.Bloom.BackgroundColor3 = colors.Fail
    else
        self:applyColors()
    end
end

function Renderer:createRing()
    local ring = create("Frame", {
        Name = "Ring",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        Size = UDim2fromScale(0.9, 0.9),
        ZIndex = 2,
        Parent = self.Panel,
    })
    roundCornersScale(ring, 0.5)
    local stroke = create("UIStroke", {
        Parent = ring,
        Thickness = 2,
        Transparency = 0,
        Color = self.Config.Colors.Success,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    table.insert(self.Rings, { Frame = ring, Stroke = stroke, Life = 0 })
    return ring
end

function Renderer:updateRings(delta, speed)
    for index = #self.Rings, 1, -1 do
        local ring = self.Rings[index]
        ring.Life = ring.Life + delta * (speed or 1)
        local alpha = clamp01(ring.Life)
        ring.Frame.Size = UDim2fromScale(0.9 + alpha * 0.75, 0.9 + alpha * 0.75)
        ring.Stroke.Transparency = clamp01(alpha)
        ring.Frame.Rotation = ring.Frame.Rotation + delta * 12
        if ring.Life >= 1 then
            ring.Frame:Destroy()
            table.remove(self.Rings, index)
        end
    end
end

function Renderer:destroyRings()
    for index = #self.Rings, 1, -1 do
        local ring = self.Rings[index]
        if ring.Frame then
            ring.Frame:Destroy()
        end
        table.remove(self.Rings, index)
    end
end

function Renderer:setText(title, subtitle)
    if title then
        self.TitleLabel.Text = tostring(title)
    end
    if subtitle then
        self.SubLabel.Text = tostring(subtitle)
    end
end

function Renderer:destroy()
    if self.Root then
        self.Root:Destroy()
        self.Root = nil
    end
    self.Parts = {}
    self.Rings = {}
end
local Executor = {}
Executor.__index = Executor

local function waitSeconds(seconds)
    seconds = seconds or 0
    if seconds <= 0 then
        return
    end
    if type(task) == "table" and type(task.wait) == "function" then
        task.wait(seconds)
    elseif type(wait) == "function" then
        wait(seconds)
    else
        RunService.Heartbeat:Wait()
    end
end

function Executor.describeError(err)
    local text = tostring(err)
    text = text:gsub("\n", " ")
    if #text > 220 then
        text = text:sub(1, 220) .. "..."
    end
    return text
end

function Executor.compile(source, chunkName)
    if type(source) ~= "string" or source == "" then
        return nil, "source is empty"
    end
    local compiler = getLoadstring()
    if not compiler then
        return nil, "loadstring unavailable in this executor"
    end
    local success, fn, err = pcall(compiler, source, chunkName or "=FaceIDLib.Chunk")
    if not success then
        return nil, Executor.describeError(fn)
    end
    if not fn then
        return nil, Executor.describeError(err)
    end
    return fn
end

function Executor.runString(source, chunkName)
    local fn, compileError = Executor.compile(source, chunkName)
    if not fn then
        return false, compileError
    end
    local success, result = pcall(fn)
    if not success then
        return false, Executor.describeError(result)
    end
    return true, result
end

function Executor.runUrl(url)
    if type(url) ~= "string" or url == "" then
        return false, "url is empty"
    end
    local body = httpFetch(url)
    if type(body) ~= "string" or body == "" then
        return false, "failed to download script"
    end
    return Executor.runString(body, "=" .. tostring(url))
end

function Executor.runModule(module)
    if not isInstance(module) then
        return false, "invalid module"
    end
    local success, result = pcall(function()
        return require(module)
    end)
    if not success then
        return false, Executor.describeError(result)
    end
    return true, result
end

function Executor.runFunction(fn, ...)
    if not isFunction(fn) then
        return false, "invalid function"
    end
    local success, result = pcall(fn, ...)
    if not success then
        return false, Executor.describeError(result)
    end
    return true, result
end

function Executor.runFile(path)
    if type(path) ~= "string" or path == "" then
        return false, "path is empty"
    end
    local ok, body = pcall(function()
        return readfile(path)
    end)
    if not ok or type(body) ~= "string" then
        return false, "failed to read file"
    end
    return Executor.runString(body, "=" .. path)
end

function Executor.runEntry(entry, context)
    if entry == nil then
        return false, "no entry"
    end
    local kind = type(entry)
    if kind == "function" then
        return Executor.runFunction(entry, context)
    end
    if kind == "Instance" then
        return Executor.runModule(entry)
    end
    if kind == "table" then
        if entry.Url then
            return Executor.runUrl(entry.Url)
        end
        if entry.Source then
            return Executor.runString(entry.Source, entry.Name and ("=" .. tostring(entry.Name)) or nil)
        end
        if entry.Function then
            return Executor.runFunction(entry.Function, context)
        end
        if entry.Module then
            return Executor.runModule(entry.Module)
        end
        if entry.File then
            return Executor.runFile(entry.File)
        end
        return false, "unknown table entry"
    end
    if kind == "string" then
        if entry:match("^https?://") then
            return Executor.runUrl(entry)
        end
        return Executor.runString(entry)
    end
    return false, "unsupported entry type"
end

function Executor.runList(list, context, options)
    local results = {}
    options = options or {}
    for index, entry in ipairs(list or {}) do
        local success, err = Executor.runEntry(entry, context)
        table.insert(results, {
            Index = index,
            Ok = success,
            Result = err,
        })
        if not success and not options.ContinueOnError then
            break
        end
        if options.Delay and options.Delay > 0 then
            waitSeconds(options.Delay)
        end
    end
    return results
end

function Executor.executeConfig(config, context, callbacks)
    config = config or {}
    callbacks = callbacks or {}
    local entries = {}
    if config.Source then
        table.insert(entries, { Source = config.Source, Name = "AutoExec.Source" })
    end
    if config.Url then
        table.insert(entries, { Url = config.Url })
    end
    if config.Function then
        table.insert(entries, { Function = config.Function })
    end
    if config.Module then
        table.insert(entries, { Module = config.Module })
    end
    if type(config.Chain) == "table" then
        for _, entry in ipairs(config.Chain) do
            table.insert(entries, entry)
        end
    end
    if #entries == 0 then
        return false, "nothing to execute"
    end
    local retries = floor(tonumber(config.Retries) or 0)
    local retryDelay = tonumber(config.RetryDelay) or 1.5
    for index, entry in ipairs(entries) do
        local attempt = 0
        local success, err = false, "unknown"
        repeat
            attempt = attempt + 1
            success, err = Executor.runEntry(entry, context)
            if not success and attempt <= retries then
                waitSeconds(retryDelay)
            end
        until success or attempt > retries
        if type(callbacks.OnEntry) == "function" then
            callbacks.OnEntry(index, entry, success, err)
        end
        if not success then
            if type(callbacks.OnError) == "function" then
                callbacks.OnError(err, entry)
            end
            return false, err
        end
    end
    if type(callbacks.OnDone) == "function" then
        callbacks.OnDone()
    end
    return true
end

function Executor.hasExecutorEnvironment()
    if type(identifyexecutor) == "function" then
        local success, name = pcall(identifyexecutor)
        if success and type(name) == "string" then
            return true, name
        end
    end
    if type(getexecutorname) == "function" then
        local success, name = pcall(getexecutorname)
        if success and type(name) == "string" then
            return true, name
        end
    end
    local compiler = getLoadstring()
    return compiler ~= nil, compiler ~= nil and "lua" or "studio"
end

FaceIDLib.Executor = Executor
local FaceID = {}
FaceID.__index = FaceID
FaceIDLib.FaceID = FaceID

function FaceID.new(config)
    local self = setmetatable({}, FaceID)
    self._rawConfig = deepCopy(config or {})
    self._config = FaceIDLib.resolveConfig(self._rawConfig)
    self._signals = {}
    for _, eventName in next, FaceIDLib.Events do
        self._signals[eventName] = Signal.new()
    end
    self._state = State.Idle
    self._stateTime = 0
    self._pendingResult = nil
    self._scanDone = false
    self._destroyed = false
    self._visible = false
    self._loopConnection = nil
    self._holdingAlpha = 0
    self._scale = 1
    self._shakeOffset = 0
    self:_buildGui()
    self:_fire("Loaded")
    if self._config.AutoShow then
        self:Show()
    end
    return self
end

function FaceID:_buildGui()
    local config = self._config
    self._gui = makeScreenGui("FaceIDLib_Face", config.DisplayOrder)
    self._gui.IgnoreGuiInset = config.IgnoreGuiInset
    if config.Parent then
        pcall(function()
            self._gui.Parent = config.Parent
        end)
    end
    self._render = Renderer.new({
        Gui = self._gui,
        Config = config,
    })
    self._sound = create("Sound", {
        Parent = self._gui,
        Volume = config.Sound.Volume or 0.4,
        Playing = false,
    })
end

function FaceID:_fire(eventName, ...)
    local signal = self._signals[eventName]
    if signal then
        signal:Fire(...)
    end
end

function FaceID:On(eventName, callback)
    local signal = self._signals[eventName]
    if not signal then
        return {
            Disconnect = noop,
        }
    end
    return signal:Connect(callback)
end

function FaceID:Once(eventName, callback)
    local signal = self._signals[eventName]
    if not signal then
        return {
            Disconnect = noop,
        }
    end
    return signal:Once(callback)
end

function FaceID:_startLoop()
    self:_stopLoop()
    local function step(delta)
        if self._destroyed then
            return
        end
        local success, err = pcall(function()
            self:_update(delta)
        end)
        if not success then
            warn(FaceIDLib.Prefix .. " animation error: " .. tostring(err))
            self:_stopLoop()
        end
    end
    if RunService:IsClient() or true then
        local ok, connection = pcall(function()
            return RunService.RenderStepped:Connect(step)
        end)
        if ok and connection then
            self._loopConnection = connection
            return
        end
    end
    self._loopConnection = RunService.Heartbeat:Connect(step)
end

function FaceID:_stopLoop()
    if self._loopConnection then
        pcall(function()
            self._loopConnection:Disconnect()
        end)
        self._loopConnection = nil
    end
end

function FaceID:_update(delta)
    local config = self._config
    local anim = config.Animation
    self._stateTime = self._stateTime + delta
    if self._state == State.Showing then
        local duration = maxn(anim.FadeIn, 0.001)
        local alpha = clamp01(self._stateTime / duration)
        local eased = Easing.fast(anim.Easing or "QuintOut", alpha)
        self._render:setAlpha(eased)
        self._render:setScale(lerp(anim.FadeInScale, 1, eased))
        if alpha >= 1 then
            self:_enterScanning()
        end
    elseif self._state == State.Scanning then
        local delay = anim.ScanDelay or 0
        local duration = maxn(anim.ScanDuration, 0.05)
        if self._stateTime < delay then
            self._render:setAlpha(1)
            return
        end
        local scanAlpha = clamp01((self._stateTime - delay) / duration)
        local eased = Easing.fast("SineOut", scanAlpha)
        self._render:setReveal(eased)
        self._render:setScan(eased, scanAlpha < 0.995)
        if scanAlpha >= 1 and not self._scanDone then
            self._scanDone = true
            self._render:setReveal(1)
            self._render:setScan(1, false)
            self:_fire("ScanFinished")
            self:_maybeExec("AfterScan")
        end
        if self._stateTime >= delay + duration + (anim.HoldAfterScan or 0) then
            self:_resolve()
        end
    elseif self._state == State.Success then
        local duration = maxn(anim.SuccessDuration, 0.05)
        local alpha = clamp01(self._stateTime / duration)
        local pulse = 1 + sin(alpha * pi) * (anim.SuccessPulse - 1) * 0.30
        self._render:setScale(pulse)
        self._render:setAlpha(1)
        self._render:setReveal(1)
        self._render:updateRings(delta, 1.5)
        if alpha >= 1 then
            if config.AutoHideOnComplete then
                self:Hide()
            else
                self._state = State.Idle
                self._render:setScale(1)
                self:_stopLoop()
            end
        end
    elseif self._state == State.Fail then
        local duration = maxn(anim.FailDuration, 0.1)
        local alpha = clamp01(self._stateTime / duration)
        local decay = 1 - alpha
        self._shakeOffset = sin(self._stateTime * 46) * (anim.FailShake or 7) * decay
        self._render.Holder.Position = UDim2fromOffset(self._shakeOffset, 0)
        self._render:setAlpha(1)
        self._render:setReveal(1)
        if alpha >= 1 then
            self._render.Holder.Position = UDim2fromOffset(0, 0)
            self:Hide()
        end
    elseif self._state == State.Hiding then
        local duration = maxn(anim.FadeOut, 0.001)
        local alpha = clamp01(self._stateTime / duration)
        local eased = Easing.fast(anim.EasingOut or "CubicIn", alpha)
        self._render:setAlpha(1 - eased)
        self._render:setScale(lerp(1, anim.FadeOutScale, eased))
        if alpha >= 1 then
            self:_finishHide()
        end
    end
end

function FaceID:_enterScanning()
    self._state = State.Scanning
    self._stateTime = 0
    self._scanDone = false
    self._render:setAlpha(1)
    self._render:setScale(1)
    self._render:setReveal(0)
    self._render:setScan(0, true)
    self:_fire("Shown")
    self:_fire("ScanStarted")
    self:_maybeExec("AfterShow")
    self:_playSound(self._config.Sound.ScanId)
end

function FaceID:_resolve()
    if self._pendingResult == true then
        self:Success()
    elseif self._pendingResult == false then
        self:Fail()
    else
        if self._config.Animation.Loop then
            self:Show()
        else
            self:Hide()
        end
    end
end

function FaceID:_finishHide()
    self._state = State.Idle
    self._visible = false
    self._pendingResult = nil
    self._render:setAlpha(0)
    self._render:setScale(1)
    self._render:setScan(0, false)
    self._render.Holder.Position = UDim2fromOffset(0, 0)
    self:_stopLoop()
    self:_fire("Hidden")
    self:_fire("Completed")
    self:_maybeExec("AfterComplete")
    if self._config.Animation.Loop then
        self:Show()
    end
end

function FaceID:_playSound(soundId)
    if not self._config.Sound.Enabled then
        return
    end
    if type(soundId) ~= "string" or soundId == "" then
        return
    end
    pcall(function()
        self._sound.SoundId = soundId
        self._sound.Volume = self._config.Sound.Volume or 0.4
        self._sound:Play()
    end)
end

function FaceID:Show()
    if self._destroyed then
        return self
    end
    self:_stopLoop()
    self._state = State.Showing
    self._stateTime = 0
    self._scanDone = false
    self._visible = true
    self._shakeOffset = 0
    self._render:setColorOverride("normal")
    self._render:setAlpha(0)
    self._render:setReveal(0)
    self._render:setScan(0, false)
    self._render:setScale(self._config.Animation.FadeInScale)
    self._render:destroyRings()
    self:_startLoop()
    return self
end

function FaceID:Scan()
    if self._destroyed then
        return self
    end
    if self._state == State.Idle then
        self:Show()
        return self
    end
    self:_enterScanning()
    return self
end

function FaceID:Success()
    if self._destroyed then
        return self
    end
    self._state = State.Success
    self._stateTime = 0
    self._visible = true
    self._render:setReveal(1)
    self._render:setScan(0, false)
    self._render:setColorOverride("success")
    self._render:createRing()
    self:_fire("Success")
    self:_playSound(self._config.Sound.SuccessId)
    if not self._loopConnection then
        self:_startLoop()
    end
    return self
end

function FaceID:Fail()
    if self._destroyed then
        return self
    end
    self._state = State.Fail
    self._stateTime = 0
    self._visible = true
    self._render:setReveal(1)
    self._render:setScan(0, false)
    self._render:setColorOverride("fail")
    self:_fire("Fail")
    self:_playSound(self._config.Sound.FailId)
    if not self._loopConnection then
        self:_startLoop()
    end
    return self
end

function FaceID:Verify(options)
    options = options or {}
    self._pendingResult = options.Success ~= false
    if options.Theme then
        self:SetTheme(options.Theme)
    end
    if options.Title or options.Subtitle then
        self._render:setText(options.Title, options.Subtitle)
    end
    local visible = self._visible and self._state ~= State.Idle and self._state ~= State.Hiding
    if visible then
        if self._state == State.Scanning or self._state == State.Success or self._state == State.Fail then
            self:_resolve()
        end
        return self
    end
    if options.Delay and options.Delay > 0 then
        local thread = coroutine.create(function()
            local elapsed = 0
            while elapsed < options.Delay do
                RunService.Heartbeat:Wait()
                elapsed = elapsed + RunService.Heartbeat:Wait()
            end
            self:Show()
        end)
        coroutine.resume(thread)
        return self
    end
    self:Show()
    return self
end

function FaceID:Hide()
    if self._destroyed then
        return self
    end
    if not self._visible then
        return self
    end
    self._state = State.Hiding
    self._stateTime = 0
    if not self._loopConnection then
        self:_startLoop()
    end
    return self
end

function FaceID:Stop()
    if self._destroyed then
        return self
    end
    self:_stopLoop()
    self._state = State.Idle
    self._stateTime = 0
    self._visible = false
    self._render:setAlpha(0)
    self:_fire("Hidden")
    return self
end

function FaceID:IsVisible()
    return self._visible
end

function FaceID:GetRenderer()
    return self._render
end

function FaceID:GetGui()
    return self._gui
end

function FaceID:GetState()
    return self._state
end

function FaceID:GetConfig()
    return deepCopy(self._config)
end

function FaceID:ApplyConfig(partial)
    if type(partial) ~= "table" then
        return self
    end
    deepMerge(self._rawConfig, partial)
    self._config = FaceIDLib.resolveConfig(self._rawConfig)
    self._render.Config = self._config
    self._render:layout()
    self._render:applyColors()
    self._render:setAlpha(self._render.Alpha)
    self._render:setReveal(self._render.Reveal)
    self:_fire("ConfigChanged", self._config)
    return self
end

function FaceID:SetTheme(themeName)
    if not FaceIDLib.Presets[themeName] then
        return self
    end
    self._rawConfig.Theme = themeName
    self._config = FaceIDLib.resolveConfig(self._rawConfig)
    self._render.Config = self._config
    self._render:layout()
    self._render:applyColors()
    self._render:setAlpha(self._render.Alpha)
    self._render:setReveal(self._render.Reveal)
    self:_fire("ThemeChanged", themeName)
    return self
end

function FaceID:GetTheme()
    return self._config.Theme
end

function FaceID:SetIconStyle(styleName)
    self._rawConfig.IconStyle = styleName
    return self:ApplyConfig({})
end

function FaceID:SetColor(key, value)
    if not key then
        return self
    end
    self._rawConfig.Colors = self._rawConfig.Colors or {}
    self._rawConfig.Colors[key] = typeof(value) == "Color3" and color3ToHex(value) or value
    return self:ApplyConfig({})
end

function FaceID:SetColors(palette)
    self._rawConfig.Colors = self._rawConfig.Colors or {}
    for key, value in next, palette or {} do
        self._rawConfig.Colors[key] = typeof(value) == "Color3" and color3ToHex(value) or value
    end
    return self:ApplyConfig({})
end

function FaceID:SetSize(size)
    self._rawConfig.Panel = self._rawConfig.Panel or {}
    self._rawConfig.Panel.Size = size
    return self:ApplyConfig({})
end

function FaceID:SetCornerRadius(radius)
    self._rawConfig.Panel = self._rawConfig.Panel or {}
    self._rawConfig.Panel.CornerRadius = radius
    return self:ApplyConfig({})
end

function FaceID:SetTransparency(alpha)
    self._rawConfig.Panel = self._rawConfig.Panel or {}
    self._rawConfig.Panel.Transparency = alpha
    return self:ApplyConfig({})
end

function FaceID:SetPosition(anchorX, anchorY)
    self._rawConfig.Position = self._rawConfig.Position or {}
    self._rawConfig.Position.AnchorX = anchorX
    self._rawConfig.Position.AnchorY = anchorY
    return self:ApplyConfig({})
end

function FaceID:SetText(title, subtitle)
    self._render:setText(title, subtitle)
    return self
end

function FaceID:Execute(source)
    local success, err = Executor.runString(source, "=FaceID.Execute")
    self:_fire("Executed", success, err)
    return success, err
end

function FaceID:ExecuteUrl(url)
    local success, err = Executor.runUrl(url)
    self:_fire("Executed", success, err)
    return success, err
end

function FaceID:RunAutoExec()
    return self:_maybeExec("Manual", true)
end

function FaceID:_maybeExec(trigger, force)
    local auto = self._config.AutoExec
    if not auto or not auto.Enabled then
        return false
    end
    if not force then
        local when = auto.When or "AfterComplete"
        if when ~= trigger then
            return false
        end
    end
    local payload = deepCopy(auto)
    local function body()
        if payload.Delay and payload.Delay > 0 then
            local elapsed = 0
            while elapsed < payload.Delay do
                RunService.Heartbeat:Wait()
                elapsed = elapsed + 0.05
            end
        end
        Executor.executeConfig(payload, self, {
            OnEntry = function(index, entry, success, err)
                if not success and not payload.Silent then
                    warn(FaceIDLib.Prefix .. " auto exec entry " .. tostring(index) .. " failed: " .. tostring(err))
                end
            end,
            OnError = function(err)
                self:_fire("Executed", false, err)
            end,
            OnDone = function()
                self:_fire("Executed", true, nil)
            end,
        })
    end
    safeSpawn(body)
    return true
end

function FaceID:Destroy()
    if self._destroyed then
        return
    end
    self._destroyed = true
    self:_stopLoop()
    self._render:destroy()
    if self._gui then
        pcall(function()
            self._gui:Destroy()
        end)
        self._gui = nil
    end
    self:_fire("Destroyed")
    for _, signal in next, self._signals do
        signal:Destroy()
    end
end
local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function newNotificationLayer(parent)
    local layer = create("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2new(1, 0),
        Position = UDim2new(1, -16, 0, 60),
        Size = UDim2fromOffset(300, 600),
        ZIndex = 400,
        Parent = parent,
    })
    addList(layer, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right)
    return layer
end

function Window.new(options)
    local self = setmetatable({}, Window)
    self.Options = options or {}
    self.ThemeName = self.Options.Theme or FaceIDLib.Defaults.Theme
    self.Preset = FaceIDLib.getPreset(self.ThemeName)
    self.Theme = FaceIDLib.resolvePalette(self.Preset.Colors)
    self.Tabs = {}
    self.TabsByName = {}
    self.SelectedTab = nil
    self.Bindings = {}
    self.Connections = {}
    self.Destroyed = false
    self.Pages = {}
    self.Elements = {}
    self.SearchText = ""
    self.Minimized = false
    self.Visible = true
    self:_build()
    self:_bindInput()
    if self.Options.StartVisible == false then
        self:Hide()
    end
    if self.Options.BuildDefault then
        self:_buildDefaultLayout()
    end
    return self
end

function Window:_build()
    local preset = self.Preset
    self.Gui = makeScreenGui("FaceIDLib_Window", 998)
    self.Gui.Name = "FaceIDLib_Window"
    self.Root = create("Frame", {
        Name = "Main",
        BackgroundColor3 = self.Theme.Window,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        Size = UDim2fromOffset(
            self.Options.Size and self.Options.Size.X or 580,
            self.Options.Size and self.Options.Size.Y or 400
        ),
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = self.Gui,
    })
    roundCorners(self.Root, 14)
    self.RootStroke = create("UIStroke", {
        Parent = self.Root,
        Thickness = 1,
        Color = self.Theme.WindowStroke,
        Transparency = 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    self.Shadow = create("Frame", {
        Name = "Shadow",
        BackgroundColor3 = self.Theme.Shadow,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2new(0.5, 0, 0.5, 8),
        Size = UDim2fromOffset(self.Root.Size.X.Offset + 10, self.Root.Size.Y.Offset + 10),
        ZIndex = 9,
        Parent = self.Gui,
    })
    roundCorners(self.Shadow, 18)
    self.TitleBar = create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = self.Theme.TitleBar,
        BorderSizePixel = 0,
        Size = UDim2new(1, 0, 0, 44),
        ZIndex = 12,
        Parent = self.Root,
    })
    self.TitleAccent = create("Frame", {
        Name = "Accent",
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2new(0, 3, 0, 18),
        Position = UDim2new(0, 14, 0, 13),
        ZIndex = 13,
        Parent = self.TitleBar,
    })
    roundCorners(self.TitleAccent, 2)
    self.TitleLabel = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(26, 0),
        Size = UDim2new(1, -160, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = self.Options.Title or "FaceIDLib",
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
        Parent = self.TitleBar,
    })
    self.SubLabel = create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(26, 22),
        Size = UDim2new(1, -160, 0, 16),
        Font = Enum.Font.Gotham,
        Text = self.Options.Subtitle or ("v" .. FaceIDLib.Version),
        TextColor3 = self.Theme.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
        Parent = self.TitleBar,
    })
    self.MinButton = create("TextButton", {
        Name = "Minimize",
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Position = UDim2new(1, -72, 0, 8),
        Size = UDim2fromOffset(26, 26),
        Text = "",
        ZIndex = 14,
        Parent = self.TitleBar,
    })
    roundCorners(self.MinButton, 7)
    self.MinGlyph = create("Frame", {
        BackgroundColor3 = self.Theme.SubText,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        Size = UDim2fromOffset(10, 2),
        ZIndex = 15,
        Parent = self.MinButton,
    })
    roundCorners(self.MinGlyph, 1)
    self.CloseButton = create("TextButton", {
        Name = "Close",
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Position = UDim2new(1, -40, 0, 8),
        Size = UDim2fromOffset(26, 26),
        Text = "",
        ZIndex = 14,
        Parent = self.TitleBar,
    })
    roundCorners(self.CloseButton, 7)
    self.CloseGlyphH = create("Frame", {
        BackgroundColor3 = self.Theme.SubText,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        Size = UDim2fromOffset(10, 2),
        Rotation = 45,
        ZIndex = 15,
        Parent = self.CloseButton,
    })
    roundCorners(self.CloseGlyphH, 1)
    self.CloseGlyphV = create("Frame", {
        BackgroundColor3 = self.Theme.SubText,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        Size = UDim2fromOffset(10, 2),
        Rotation = -45,
        ZIndex = 15,
        Parent = self.CloseButton,
    })
    roundCorners(self.CloseGlyphV, 1)
    self.Sidebar = create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = self.Theme.Sidebar,
        BorderSizePixel = 0,
        Position = UDim2fromOffset(0, 44),
        Size = UDim2new(0, 150, 1, -44),
        ZIndex = 11,
        Parent = self.Root,
    })
    self.SidebarStroke = create("Frame", {
        Name = "SidebarEdge",
        BackgroundColor3 = self.Theme.SidebarStroke,
        BorderSizePixel = 0,
        Position = UDim2new(1, -1, 0, 0),
        Size = UDim2new(0, 1, 1, 0),
        ZIndex = 12,
        Parent = self.Sidebar,
    })
    self.SearchBox = create("Frame", {
        Name = "SearchBox",
        BackgroundColor3 = self.Theme.Element,
        BorderSizePixel = 0,
        Position = UDim2fromOffset(8, 8),
        Size = UDim2new(1, -16, 0, 26),
        Visible = self.Options.ShowSearch ~= false,
        ZIndex = 13,
        Parent = self.Sidebar,
    })
    roundCorners(self.SearchBox, 7)
    self.SearchInput = create("TextBox", {
        Name = "Input",
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(10, 0),
        Size = UDim2new(1, -16, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search",
        PlaceholderColor3 = self.Theme.SubText,
        Text = "",
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 14,
        Parent = self.SearchBox,
    })
    self.TabList = create("ScrollingFrame", {
        Name = "TabList",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2fromOffset(8, (self.Options.ShowSearch ~= false) and 42 or 8),
        Size = UDim2new(1, -16, 1, (self.Options.ShowSearch ~= false) and -84 or -50),
        CanvasSize = UDim2new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Outline,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 13,
        Parent = self.Sidebar,
    })
    addList(self.TabList, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Left)
    addPadding(self.TabList, 0, 0, 2, 6)
    self.Footer = create("TextLabel", {
        Name = "Footer",
        BackgroundTransparency = 1,
        Position = UDim2new(0, 12, 1, -30),
        Size = UDim2new(1, -24, 0, 18),
        Font = Enum.Font.Gotham,
        Text = FaceIDLib.Name .. " v" .. FaceIDLib.Version,
        TextColor3 = self.Theme.SubText,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
        Parent = self.Sidebar,
    })
    self.Content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(150, 44),
        Size = UDim2new(1, -150, 1, -44),
        ClipsDescendants = true,
        ZIndex = 11,
        Parent = self.Root,
    })
    newNotificationLayer(self.Gui)
    self:Bind(self.Root, "BackgroundColor3", "Window")
    self:Bind(self.RootStroke, "Color", "WindowStroke")
    self:Bind(self.Shadow, "BackgroundColor3", "Shadow")
    self:Bind(self.TitleBar, "BackgroundColor3", "TitleBar")
    self:Bind(self.Sidebar, "BackgroundColor3", "Sidebar")
    self:Bind(self.SidebarStroke, "BackgroundColor3", "SidebarStroke")
    self:Bind(self.TitleLabel, "TextColor3", "Text")
    self:Bind(self.SubLabel, "TextColor3", "SubText")
    self:Bind(self.TitleAccent, "BackgroundColor3", "Accent")
    self:Bind(self.MinButton, "BackgroundColor3", "Element")
    self:Bind(self.CloseButton, "BackgroundColor3", "Element")
    self:Bind(self.MinGlyph, "BackgroundColor3", "SubText")
    self:Bind(self.CloseGlyphH, "BackgroundColor3", "SubText")
    self:Bind(self.CloseGlyphV, "BackgroundColor3", "SubText")
    self:Bind(self.SearchBox, "BackgroundColor3", "Element")
    self:Bind(self.SearchInput, "TextColor3", "Text")
    self:Bind(self.SearchInput, "PlaceholderColor3", "SubText")
    self:Bind(self.Footer, "TextColor3", "SubText")
    self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self:Search(self.SearchInput.Text)
    end)
    self.MinButton.MouseEnter:Connect(function()
        quickTween(self.MinButton, 0.15, { BackgroundTransparency = 0 })
    end)
    self.MinButton.MouseLeave:Connect(function()
        quickTween(self.MinButton, 0.15, { BackgroundTransparency = 1 })
    end)
    self.CloseButton.MouseEnter:Connect(function()
        quickTween(self.CloseButton, 0.15, { BackgroundColor3 = self.Theme.Fail, BackgroundTransparency = 0 })
    end)
    self.CloseButton.MouseLeave:Connect(function()
        quickTween(self.CloseButton, 0.15, { BackgroundColor3 = self.Theme.Element, BackgroundTransparency = 1 })
    end)
    self.MinButton.MouseButton1Click:Connect(function()
        self:SetMinimized(not self.Minimized)
    end)
    self.CloseButton.MouseButton1Click:Connect(function()
        self:Hide()
    end)
    self:_makeDraggable()
end

function Window:_makeDraggable()
    local dragging = false
    local startMouse = nil
    local startPos = nil
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startMouse = Vector2new(input.Position.X, input.Position.Y)
            startPos = self.Root.Position
        end
    end)
    self.TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    self.DragConnection = UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = Vector2new(input.Position.X, input.Position.Y) - startMouse
            self.Root.Position = UDim2new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            self.Shadow.Position = UDim2new(
                self.Root.Position.X.Scale, self.Root.Position.X.Offset,
                self.Root.Position.Y.Scale, self.Root.Position.Y.Offset + 8
            )
        end
    end)
end

function Window:_bindInput()
    self.InputConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        local key = self.Options.ToggleKey
        if key and input.KeyCode == keyCodeFromName(key) then
            if self.Visible then
                self:Hide()
            else
                self:Show()
            end
        end
    end)
end

function Window:Bind(instance, property, colorKey)
    table.insert(self.Bindings, {
        Instance = instance,
        Property = property,
        Key = colorKey,
    })
    pcall(function()
        instance[property] = self.Theme[colorKey]
    end)
    return instance
end

function Window:ApplyTheme()
    for _, binding in ipairs(self.Bindings) do
        pcall(function()
            binding.Instance[binding.Property] = self.Theme[binding.Key]
        end)
    end
    for _, element in ipairs(self.Elements) do
        if element.ApplyTheme then
            element:ApplyTheme(self.Theme)
        end
    end
    for _, tab in ipairs(self.Tabs) do
        tab:ApplyTheme()
    end
end

function Window:SetTheme(themeName)
    local preset = FaceIDLib.getPreset(themeName)
    if not preset then
        return self
    end
    self.ThemeName = preset.Name
    self.Preset = preset
    self.Theme = FaceIDLib.resolvePalette(preset.Colors)
    self:ApplyTheme()
    return self
end

function Window:CreateTab(name, icon)
    local tab = setmetatable({}, Tab)
    tab.Window = self
    tab.Name = name or "Tab"
    tab.Index = #self.Tabs + 1
    tab.Elements = {}
    tab.Button = create("TextButton", {
        Name = "Tab_" .. tostring(name),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Size = UDim2new(1, 0, 0, 32),
        Text = "",
        ZIndex = 14,
        LayoutOrder = tab.Index,
        Parent = self.TabList,
    })
    roundCorners(tab.Button, 8)
    tab.Indicator = create("Frame", {
        Name = "Indicator",
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0, 0.5),
        Position = UDim2new(0, 0, 0.5, 0),
        Size = UDim2new(0, 3, 0.42, 0),
        BackgroundTransparency = 1,
        ZIndex = 15,
        Parent = tab.Button,
    })
    roundCorners(tab.Indicator, 2)
    tab.Label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(14, 0),
        Size = UDim2new(1, -22, 1, 0),
        Font = Enum.Font.GothamMedium,
        Text = name or "Tab",
        TextColor3 = self.Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
        Parent = tab.Button,
    })
    tab.Page = create("ScrollingFrame", {
        Name = "Page_" .. tostring(name),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2fromScale(1, 1),
        CanvasSize = UDim2new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Outline,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        ZIndex = 12,
        Parent = self.Content,
    })
    addList(tab.Page, Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Left)
    addPadding(tab.Page, 12, 12, 12, 16)
    tab.Button.MouseEnter:Connect(function()
        if self.SelectedTab ~= tab then
            quickTween(tab.Button, 0.15, { BackgroundTransparency = 0.5 })
        end
    end)
    tab.Button.MouseLeave:Connect(function()
        if self.SelectedTab ~= tab then
            quickTween(tab.Button, 0.15, { BackgroundTransparency = 1 })
        end
    end)
    tab.Button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    table.insert(self.Tabs, tab)
    self.TabsByName[name] = tab
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    return tab
end

function Window:SelectTab(tab)
    if not tab then
        return self
    end
    for _, other in ipairs(self.Tabs) do
        other.Page.Visible = other == tab
        quickTween(other.Button, 0.15, {
            BackgroundTransparency = other == tab and 0.2 or 1,
        })
        other.Label.TextColor3 = other == tab and self.Theme.Text or self.Theme.SubText
        other.Indicator.BackgroundTransparency = other == tab and 0 or 1
    end
    self.SelectedTab = tab
    return self
end

function Window:Search(text)
    self.SearchText = trim(tostring(text or "")):lower()
    for _, tab in ipairs(self.Tabs) do
        tab:ApplyFilter(self.SearchText)
    end
end

function Window:Notify(options)
    if type(options) == "string" then
        options = { Text = options }
    end
    options = options or {}
    local kind = options.Type or "Info"
    local color = self.Theme.Success
    if kind == "Error" then
        color = self.Theme.Fail
    elseif kind == "Warning" or kind == "Warn" then
        color = self.Theme.Warn
    elseif kind == "Info" then
        color = self.Theme.Info
    end
    local card = create("Frame", {
        Name = "Notification",
        BackgroundColor3 = self.Theme.TitleBar,
        BorderSizePixel = 0,
        Size = UDim2fromOffset(280, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 401,
        Parent = self.Gui.Notifications,
    })
    roundCorners(card, 10)
    addPadding(card, 12, 12, 10, 12)
    local stripe = create("Frame", {
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2new(0, 3, 1, 0),
        Position = UDim2fromOffset(-8, 0),
        BackgroundTransparency = 1,
        ZIndex = 402,
        Parent = card,
    })
    roundCorners(stripe, 2)
    local title = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2new(1, -8, 0, 16),
        Font = Enum.Font.GothamSemibold,
        Text = options.Title or kind,
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        ZIndex = 402,
        Parent = card,
    })
    local body = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(0, 20),
        Size = UDim2new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = options.Text or "",
        TextColor3 = self.Theme.SubText,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        ZIndex = 402,
        Parent = card,
    })
    card.BackgroundTransparency = 1
    quickTween(card, 0.25, { BackgroundTransparency = 0.05 })
    quickTween(stripe, 0.25, { BackgroundTransparency = 0 })
    quickTween(title, 0.25, { TextTransparency = 0 })
    quickTween(body, 0.25, { TextTransparency = 0 })
    local duration = options.Duration or 3.5
    local thread = coroutine.create(function()
        local elapsed = 0
        while elapsed < duration do
            elapsed = elapsed + RunService.Heartbeat:Wait()
        end
        quickTween(card, 0.3, { BackgroundTransparency = 1 })
        quickTween(stripe, 0.3, { BackgroundTransparency = 1 })
        quickTween(title, 0.3, { TextTransparency = 1 })
        quickTween(body, 0.3, { TextTransparency = 1 })
        local fade = 0
        while fade < 0.32 do
            fade = fade + RunService.Heartbeat:Wait()
        end
        card:Destroy()
    end)
    coroutine.resume(thread)
    return card
end

function Window:Dialog(options)
    options = options or {}
    local overlay = create("Frame", {
        Name = "Dialog",
        BackgroundColor3 = self.Theme.Shadow,
        BackgroundTransparency = 1,
        Size = UDim2fromScale(1, 1),
        ZIndex = 500,
        Parent = self.Gui,
    })
    local card = create("Frame", {
        BackgroundColor3 = self.Theme.TitleBar,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2fromScale(0.5, 0.5),
        Size = UDim2fromOffset(320, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 501,
        Parent = overlay,
    })
    roundCorners(card, 12)
    addPadding(card, 16, 16, 16, 16)
    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2new(1, 0, 0, 18),
        Font = Enum.Font.GothamSemibold,
        Text = options.Title or "Confirm",
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 502,
        Parent = card,
    })
    local message = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(0, 24),
        Size = UDim2new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = options.Text or "",
        TextColor3 = self.Theme.SubText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 502,
        Parent = card,
    })
    local buttonRow = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(0, 0),
        Size = UDim2new(1, 0, 0, 30),
        ZIndex = 502,
        Parent = card,
    })
    local function placeRow()
        buttonRow.Position = UDim2fromOffset(0, message.AbsoluteSize.Y + 40)
    end
    placeRow()
    message:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeRow)
    local function close(result)
        quickTween(overlay, 0.2, { BackgroundTransparency = 1 })
        quickTween(card, 0.2, { BackgroundTransparency = 1 })
        local connection
        connection = RunService.Heartbeat:Connect(function()
            overlay:Destroy()
            connection:Disconnect()
        end)
        if options.Callback then
            options.Callback(result)
        end
    end
    local yes = create("TextButton", {
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(1, 0),
        Position = UDim2new(1, 0, 0, 0),
        Size = UDim2fromOffset(90, 28),
        Font = Enum.Font.GothamMedium,
        Text = options.ConfirmText or "Confirm",
        TextColor3 = self.Theme.AccentText,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 503,
        Parent = buttonRow,
    })
    roundCorners(yes, 7)
    local no = create("TextButton", {
        BackgroundColor3 = self.Theme.Element,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(1, 0),
        Position = UDim2new(1, -96, 0, 0),
        Size = UDim2fromOffset(90, 28),
        Font = Enum.Font.GothamMedium,
        Text = options.CancelText or "Cancel",
        TextColor3 = self.Theme.Text,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 503,
        Parent = buttonRow,
    })
    roundCorners(no, 7)
    yes.MouseButton1Click:Connect(function()
        close(true)
    end)
    no.MouseButton1Click:Connect(function()
        close(false)
    end)
    quickTween(overlay, 0.2, { BackgroundTransparency = 0.45 })
    quickTween(card, 0.2, { BackgroundTransparency = 0 })
    return overlay
end

function Window:SetMinimized(state)
    self.Minimized = state and true or false
    local height = self.Root.Size.Y.Offset
    local target = self.Minimized and 44 or (self.Options.Size and self.Options.Size.Y or 400)
    quickTween(self.Root, 0.25, { Size = UDim2fromOffset(self.Root.Size.X.Offset, target) })
    self.Sidebar.Visible = not self.Minimized
    self.Content.Visible = not self.Minimized
    return self
end

function Window:Show()
    self.Visible = true
    self.Root.Visible = true
    self.Shadow.Visible = true
    self.Root.BackgroundTransparency = 1
    quickTween(self.Root, 0.2, { BackgroundTransparency = 0 })
    return self
end

function Window:Hide()
    self.Visible = false
    self.Root.Visible = false
    self.Shadow.Visible = false
    return self
end

function Window:Toggle()
    if self.Visible then
        return self:Hide()
    end
    return self:Show()
end

function Window:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    if self.DragConnection then
        self.DragConnection:Disconnect()
    end
    if self.InputConnection then
        self.InputConnection:Disconnect()
    end
    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    if self.Gui then
        self.Gui:Destroy()
    end
end

function Tab:CreateSection(title, description)
    local section = setmetatable({}, Section)
    section.Tab = self
    section.Window = self.Window
    section.Title = title or "Section"
    section.Index = #self.Elements + 1
    section.Container = create("Frame", {
        Name = "Section_" .. tostring(title),
        BackgroundColor3 = self.Window.Theme.Element,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = section.Index,
        ZIndex = 13,
        Parent = self.Page,
    })
    roundCorners(section.Container, 10)
    addPadding(section.Container, 10, 10, 10, 10)
    section.Header = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2new(1, 0, 0, 18),
        Font = Enum.Font.GothamSemibold,
        Text = title or "Section",
        TextColor3 = self.Window.Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0,
        ZIndex = 14,
        Parent = section.Container,
    })
    section.Description = nil
    if description and description ~= "" then
        section.Description = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            Text = description,
            TextColor3 = self.Window.Theme.SubText,
            TextSize = 10,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 0,
            ZIndex = 14,
            Parent = section.Container,
        })
    end
    section.Body = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
        ZIndex = 13,
        Parent = section.Container,
    })
    addList(section.Body, Enum.FillDirection.Vertical, 6)
    addPadding(section.Body, 0, 0, 6, 0)
    table.insert(self.Elements, section)
    self.Window.Elements[#self.Window.Elements + 1] = section
    section:ApplyTheme(self.Window.Theme)
    return section
end

function Section:ApplyTheme(theme)
    self.Theme = theme or self.Window.Theme
    self.Container.BackgroundColor3 = self.Theme.Element
    self.Header.TextColor3 = self.Theme.Text
    if self.Description then
        self.Description.TextColor3 = self.Theme.SubText
    end
end

function Section:CreateDivider()
    local divider = create("Frame", {
        BackgroundColor3 = self.Theme.Outline,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Size = UDim2new(1, 0, 0, 1),
        ZIndex = 14,
        Parent = self.Body,
    })
    return divider
end

function Section:CreateSpace(height)
    return create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2new(1, 0, 0, height or 6),
        ZIndex = 14,
        Parent = self.Body,
    })
end

function Tab:ApplyFilter(text)
    for _, section in ipairs(self.Elements) do
        local sectionMatch = text == "" or (section.Title and section.Title:lower():find(text, 1, true) ~= nil)
        local anyVisible = sectionMatch
        for _, element in ipairs(section.Body:GetChildren()) do
            if element:IsA("Frame") and element:GetAttribute("ElementName") then
                local name = tostring(element:GetAttribute("ElementName")):lower()
                local match = text == "" or sectionMatch or name:find(text, 1, true) ~= nil
                element.Visible = match
                if match then
                    anyVisible = true
                end
            end
        end
        section.Container.Visible = anyVisible
    end
end

function Tab:ApplyTheme()
    for _, section in ipairs(self.Elements) do
        section:ApplyTheme(self.Window.Theme)
    end
end
local function elementBase(section, name, height)
    local theme = section.Theme
    local row = create("Frame", {
        Name = "Element_" .. tostring(name),
        BackgroundColor3 = theme.Element,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2new(1, 0, 0, height),
        ZIndex = 14,
        Parent = section.Body,
    })
    row:SetAttribute("ElementName", name or "")
    roundCorners(row, 8)
    local label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(10, 0),
        Size = UDim2new(1, -110, 1, 0),
        Font = Enum.Font.Gotham,
        Text = name or "",
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
        Parent = row,
    })
    return row, label
end

function Section:CreateLabel(text, description)
    local row, label = elementBase(self, text or "Label", description and 34 or 24)
    label.Size = UDim2new(1, -20, 1, 0)
    if description then
        local sub = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2fromOffset(10, 18),
            Size = UDim2new(1, -20, 0, 14),
            Font = Enum.Font.Gotham,
            Text = description,
            TextColor3 = self.Theme.SubText,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 15,
            Parent = row,
        })
        local api = {}
        function api:Set(value)
            label.Text = tostring(value)
            return self
        end
        function api:SetSubtitle(value)
            sub.Text = tostring(value)
            return self
        end
        function api:Get()
            return label.Text
        end
        function api:ApplyTheme(theme)
            label.TextColor3 = theme.Text
            sub.TextColor3 = theme.SubText
        end
        return api
    end
    local api = {}
    function api:Set(value)
        label.Text = tostring(value)
        return self
    end
    function api:Get()
        return label.Text
    end
    function api:ApplyTheme(theme)
        label.TextColor3 = theme.Text
    end
    return api
end

function Section:CreateParagraph(title, text)
    local row = create("Frame", {
        Name = "Element_" .. tostring(title),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 14,
        Parent = self.Body,
    })
    row:SetAttribute("ElementName", tostring(title or ""))
    local heading = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2new(1, 0, 0, 16),
        Font = Enum.Font.GothamSemibold,
        Text = title or "",
        TextColor3 = self.Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
        Parent = row,
    })
    local body = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(0, 18),
        Size = UDim2new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        Text = text or "",
        TextColor3 = self.Theme.SubText,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 15,
        Parent = row,
    })
    local api = {}
    function api:Set(value)
        body.Text = tostring(value)
        return self
    end
    function api:SetTitle(value)
        heading.Text = tostring(value)
        return self
    end
    function api:ApplyTheme(theme)
        heading.TextColor3 = theme.Text
        body.TextColor3 = theme.SubText
    end
    return api
end

function Section:CreateButton(options)
    options = options or {}
    local row, label = elementBase(self, options.Name or options.Text or "Button", 32)
    label.Size = UDim2new(0.55, -10, 1, 0)
    local button = create("TextButton", {
        Name = "Action",
        BackgroundColor3 = options.Accent and self.Theme.Accent or self.Theme.ElementActive,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(1, 0.5),
        Position = UDim2new(1, -6, 0.5, 0),
        Size = UDim2fromOffset(options.ButtonWidth or 96, 24),
        Font = Enum.Font.GothamMedium,
        Text = options.ButtonText or "Run",
        TextColor3 = options.Accent and self.Theme.AccentText or self.Theme.Text,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 16,
        Parent = row,
    })
    roundCorners(button, 7)
    button.MouseEnter:Connect(function()
        quickTween(button, 0.12, { BackgroundTransparency = 0 })
    end)
    button.MouseLeave:Connect(function()
        quickTween(button, 0.12, { BackgroundTransparency = 0.15 })
    end)
    button.MouseButton1Click:Connect(function()
        if options.Callback then
            local ok, err = pcall(options.Callback)
            if not ok then
                warn(FaceIDLib.Prefix .. " button callback error: " .. tostring(err))
            end
        end
    end)
    local api = { Button = button }
    function api:SetText(value)
        button.Text = tostring(value)
        return self
    end
    function api:SetEnabled(state)
        button.Active = state and true or false
        button.BackgroundTransparency = state and 0.15 or 0.6
        return self
    end
    function api:ApplyTheme(theme)
        label.TextColor3 = theme.Text
        button.BackgroundColor3 = options.Accent and theme.Accent or theme.ElementActive
        button.TextColor3 = options.Accent and theme.AccentText or theme.Text
    end
    return api
end

function Section:CreateToggle(options)
    options = options or {}
    local row, label = elementBase(self, options.Name or "Toggle", 34)
    local value = options.Value == true
    local switch = create("Frame", {
        Name = "Switch",
        BackgroundColor3 = value and self.Theme.Accent or self.Theme.Outline,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(1, 0.5),
        Position = UDim2new(1, -8, 0.5, 0),
        Size = UDim2fromOffset(34, 18),
        ZIndex = 16,
        Parent = row,
    })
    roundCorners(switch, 9)
    local knob = create("Frame", {
        Name = "Knob",
        BackgroundColor3 = Color3new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0, 0.5),
        Position = value and UDim2new(1, -15, 0.5, 0) or UDim2new(0, 3, 0.5, 0),
        Size = UDim2fromOffset(12, 12),
        ZIndex = 17,
        Parent = switch,
    })
    roundCorners(knob, 6)
    local clickArea = create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2fromScale(1, 1),
        Text = "",
        ZIndex = 18,
        Parent = row,
    })
    local api = { Value = value }
    local listeners = {}
    local function paint()
        api.Value = value
        quickTween(switch, 0.16, {
            BackgroundColor3 = value and self.Theme.Accent or self.Theme.Outline,
        })
        quickTween(knob, 0.16, {
            Position = value and UDim2new(1, -15, 0.5, 0) or UDim2new(0, 3, 0.5, 0),
        })
    end
    function api:Set(newValue, silent)
        value = newValue and true or false
        paint()
        if not silent then
            for _, callback in ipairs(listeners) do
                pcall(callback, value)
            end
        end
        return self
    end
    function api:Get()
        return value
    end
    function api:OnChanged(callback)
        table.insert(listeners, callback)
        return self
    end
    clickArea.MouseButton1Click:Connect(function()
        api:Set(not value)
    end)
    clickArea.MouseEnter:Connect(function()
        quickTween(row, 0.12, { BackgroundTransparency = 0.55 })
    end)
    clickArea.MouseLeave:Connect(function()
        quickTween(row, 0.12, { BackgroundTransparency = 1 })
    end)
    function api:ApplyTheme(theme)
        label.TextColor3 = theme.Text
        switch.BackgroundColor3 = value and theme.Accent or theme.Outline
        row.BackgroundColor3 = theme.Element
    end
    return api
end

function Section:CreateSlider(options)
    options = options or {}
    local row, label = elementBase(self, options.Name or "Slider", 44)
    local minValue = options.Min or 0
    local maxValue = options.Max or 100
    local value = clampn(options.Value or minValue, minValue, maxValue)
    local step = options.Step or 1
    local suffix = options.Suffix or ""
    local decimals = options.Decimals or 0
    label.Position = UDim2fromOffset(10, 3)
    label.Size = UDim2new(1, -110, 0, 16)
    local valueLabel = create("TextLabel", {
        Name = "Value",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2new(1, 0),
        Position = UDim2new(1, -10, 0, 3),
        Size = UDim2fromOffset(90, 16),
        Font = Enum.Font.Gotham,
        Text = "",
        TextColor3 = self.Theme.SubText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 16,
        Parent = row,
    })
    local track = create("Frame", {
        Name = "Track",
        BackgroundColor3 = self.Theme.Outline,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0, 0.5),
        Position = UDim2new(0, 10, 1, -12),
        Size = UDim2new(1, -20, 0, 4),
        ZIndex = 16,
        Parent = row,
    })
    roundCorners(track, 2)
    local fill = create("Frame", {
        Name = "Fill",
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2fromScale(0, 1),
        ZIndex = 17,
        Parent = track,
    })
    roundCorners(fill, 2)
    local knob = create("Frame", {
        Name = "Knob",
        BackgroundColor3 = Color3new(1, 1, 1),
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0.5, 0.5),
        Position = UDim2new(0, 0, 0.5, 0),
        Size = UDim2fromOffset(12, 12),
        ZIndex = 18,
        Parent = track,
    })
    roundCorners(knob, 6)
    local api = { Value = value }
    local listeners = {}
    local function format(number)
        if decimals <= 0 then
            return tostring(math.floor(number + 0.5)) .. suffix
        end
        return string.format("%." .. decimals .. "f", number) .. suffix
    end
    local function paint()
        api.Value = value
        local alpha = (value - minValue) / maxn(maxValue - minValue, 0.0001)
        fill.Size = UDim2fromScale(alpha, 1)
        knob.Position = UDim2new(alpha, 0, 0.5, 0)
        valueLabel.Text = format(value)
    end
    function api:Set(newValue, silent)
        value = clampn(tonumber(newValue) or minValue, minValue, maxValue)
        if step and step > 0 then
            value = minValue + math.floor((value - minValue) / step + 0.5) * step
            value = clampn(value, minValue, maxValue)
        end
        paint()
        if not silent then
            for _, callback in ipairs(listeners) do
                pcall(callback, value)
            end
        end
        return self
    end
    function api:Get()
        return value
    end
    function api:OnChanged(callback)
        table.insert(listeners, callback)
        return self
    end
    local dragging = false
    local function updateFromInput(positionX)
        local absolute = track.AbsolutePosition.X
        local width = maxn(track.AbsoluteSize.X, 1)
        local alpha = clamp01((positionX - absolute) / width)
        api:Set(minValue + (maxValue - minValue) * alpha)
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input.Position.X)
        end
    end)
    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromInput(input.Position.X)
        end
    end)
    table.insert(self.Window.Connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateFromInput(input.Position.X)
        end
    end))
    table.insert(self.Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    paint()
    if options.Callback then
        table.insert(listeners, options.Callback)
    end
    function api:ApplyTheme(theme)
        label.TextColor3 = theme.Text
        valueLabel.TextColor3 = theme.SubText
        track.BackgroundColor3 = theme.Outline
        fill.BackgroundColor3 = theme.Accent
        row.BackgroundColor3 = theme.Element
    end
    return api
end

function Section:CreateInput(options)
    options = options or {}
    local row, label = elementBase(self, options.Name or "Input", 34)
    label.Size = UDim2new(0.45, -10, 1, 0)
    local box = create("Frame", {
        Name = "Box",
        BackgroundColor3 = self.Theme.Window,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(1, 0.5),
        Position = UDim2new(1, -8, 0.5, 0),
        Size = UDim2fromOffset(options.Width or 210, 24),
        ZIndex = 16,
        Parent = row,
    })
    roundCorners(box, 6)
    local textBox = create("TextBox", {
        Name = "Input",
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(8, 0),
        Size = UDim2new(1, -16, 1, 0),
        Font = Enum.Font.Gotham,
        PlaceholderText = options.Placeholder or "Enter text",
        PlaceholderColor3 = self.Theme.SubText,
        Text = options.Value or "",
        TextColor3 = self.Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 17,
        Parent = box,
    })
    local api = {}
    local listeners = {}
    function api:Get()
        return textBox.Text
    end
    function api:Set(value)
        textBox.Text = tostring(value or "")
        return self
    end
    function api:OnSubmit(callback)
        table.insert(listeners, callback)
        return self
    end
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and options.Callback then
            pcall(options.Callback, textBox.Text)
        end
        for _, callback in ipairs(listeners) do
            pcall(callback, textBox.Text, enterPressed)
        end
    end)
    function api:ApplyTheme(theme)
        label.TextColor3 = theme.Text
        box.BackgroundColor3 = theme.Window
        textBox.TextColor3 = theme.Text
        textBox.PlaceholderColor3 = theme.SubText
        row.BackgroundColor3 = theme.Element
    end
    return api
end

function Section:CreateKeybind(options)
    options = options or {}
    local row, label = elementBase(self, options.Name or "Keybind", 34)
    local current = keyCodeFromName(options.Value or options.Default or "RightShift")
    local listening = false
    local button = create("TextButton", {
        Name = "Key",
        BackgroundColor3 = self.Theme.ElementActive,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(1, 0.5),
        Position = UDim2new(1, -8, 0.5, 0),
        Size = UDim2fromOffset(96, 24),
        Font = Enum.Font.GothamMedium,
        Text = tostring(current.Name),
        TextColor3 = self.Theme.Text,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 16,
        Parent = row,
    })
    roundCorners(button, 7)
    local api = { Value = current }
    local listeners = {}
    local connection
    button.MouseButton1Click:Connect(function()
        listening = true
        button.Text = "Press a key"
        button.TextColor3 = self.Theme.Accent
        if connection then
            connection:Disconnect()
        end
        connection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then
                return
            end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            listening = false
            current = input.KeyCode
            api.Value = current
            button.Text = tostring(current.Name)
            button.TextColor3 = self.Theme.Text
            connection:Disconnect()
            if options.Callback then
                pcall(options.Callback, current)
            end
            for _, callback in ipairs(listeners) do
                pcall(callback, current)
            end
        end)
        table.insert(self.Window.Connections, connection)
    end)
    function api:Get()
        return current
    end
    function api:Set(key)
        current = type(key) == "string" and keyCodeFromName(key) or key
        button.Text = tostring(current.Name)
        return self
    end
    function api:OnChanged(callback)
        table.insert(listeners, callback)
        return self
    end
    function api:ApplyTheme(theme)
        label.TextColor3 = theme.Text
        button.BackgroundColor3 = theme.ElementActive
        if not listening then
            button.TextColor3 = theme.Text
        end
        row.BackgroundColor3 = theme.Element
    end
    return api
end

function Section:CreateRow()
    local row = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2new(1, 0, 0, 34),
        ZIndex = 14,
        Parent = self.Body,
    })
    addList(row, Enum.FillDirection.Horizontal, 6)
    row:SetAttribute("ElementName", "row")
    local api = {}
    function api:Add(component)
        if type(component) == "table" and component.Button then
            component.Button.Parent = row
        end
        return self
    end
    return api
end
local function popupLayer(window)
    if window.PopupLayer and window.PopupLayer.Parent then
        return window.PopupLayer
    end
    local layer = create("Frame", {
        Name = "Popups",
        BackgroundTransparency = 1,
        Size = UDim2fromScale(1, 1),
        ZIndex = 600,
        Parent = window.Gui,
    })
    window.PopupLayer = layer
    return layer
end

local function closePopups(window)
    local layer = popupLayer(window)
    for _, child in ipairs(layer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

function Section:CreateDropdown(options)
    options = options or {}
    local row, label = elementBase(self, options.Name or "Dropdown", 34)
    label.Size = UDim2new(0.45, -10, 1, 0)
    local items = {}
    for index, item in ipairs(options.Items or {}) do
        items[index] = tostring(item)
    end
    local selected = options.Value or items[1] or ""
    local button = create("TextButton", {
        Name = "Drop",
        BackgroundColor3 = self.Theme.Window,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(1, 0.5),
        Position = UDim2new(1, -8, 0.5, 0),
        Size = UDim2fromOffset(210, 24),
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 11,
        TextColor3 = self.Theme.Text,
        AutoButtonColor = false,
        ZIndex = 16,
        Parent = row,
    })
    roundCorners(button, 6)
    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(9, 0),
        Size = UDim2new(1, -26, 1, 0),
        Font = Enum.Font.Gotham,
        Text = tostring(selected),
        TextColor3 = self.Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
        Parent = button,
    })
    local caret = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2new(1, 0.5),
        Position = UDim2new(1, -7, 0.5, 0),
        Size = UDim2fromOffset(12, 12),
        Font = Enum.Font.GothamBold,
        Text = "v",
        TextColor3 = self.Theme.SubText,
        TextSize = 9,
        ZIndex = 17,
        Parent = button,
    })
    local api = { Value = selected }
    local listeners = {}
    local open = false
    local popup = nil
    local function close()
        open = false
        if popup then
            popup:Destroy()
            popup = nil
        end
    end
    local function choose(value)
        api.Value = value
        button:FindFirstChildOfClass("TextLabel").Text = tostring(value)
        close()
        if options.Callback then
            pcall(options.Callback, value)
        end
        for _, callback in ipairs(listeners) do
            pcall(callback, value)
        end
    end
    local function openPopup()
        closePopups(self.Window)
        local layer = popupLayer(self.Window)
        local listHeight = math.min(#items * 26 + 8, 180)
        popup = create("Frame", {
            Name = "DropdownPopup",
            BackgroundColor3 = self.Theme.TitleBar,
            BorderSizePixel = 0,
            Position = UDim2fromOffset(button.AbsolutePosition.X, button.AbsolutePosition.Y + button.AbsoluteSize.Y + 4),
            Size = UDim2fromOffset(button.AbsoluteSize.X, listHeight),
            ZIndex = 601,
            Parent = layer,
        })
        roundCorners(popup, 8)
        create("UIStroke", {
            Parent = popup,
            Thickness = 1,
            Color = self.Theme.WindowStroke,
        })
        local scroll = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2fromOffset(4, 4),
            Size = UDim2new(1, -8, 1, -8),
            CanvasSize = UDim2new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = self.Theme.Outline,
            ZIndex = 602,
            Parent = popup,
        })
        addList(scroll, Enum.FillDirection.Vertical, 2)
        for _, item in ipairs(items) do
            local option = create("TextButton", {
                BackgroundColor3 = self.Theme.Element,
                BackgroundTransparency = item == selected and 0.55 or 1,
                BorderSizePixel = 0,
                Size = UDim2new(1, 0, 0, 24),
                Font = Enum.Font.Gotham,
                Text = tostring(item),
                TextColor3 = item == selected and self.Theme.Accent or self.Theme.Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                ZIndex = 603,
                Parent = scroll,
            })
            addPadding(option, 9, 9, 0, 0)
            option.MouseEnter:Connect(function()
                quickTween(option, 0.1, { BackgroundTransparency = 0.45 })
            end)
            option.MouseLeave:Connect(function()
                quickTween(option, 0.1, { BackgroundTransparency = item == selected and 0.55 or 1 })
            end)
            option.MouseButton1Click:Connect(function()
                choose(item)
            end)
        end
        open = true
    end
    button.MouseButton1Click:Connect(function()
        if open then
            close()
        else
            openPopup()
        end
    end)
    function api:Get()
        return api.Value
    end
    function api:Set(value)
        api.Value = tostring(value)
        button:FindFirstChildOfClass("TextLabel").Text = api.Value
        return self
    end
    function api:SetItems(newItems)
        items = {}
        for index, item in ipairs(newItems or {}) do
            items[index] = tostring(item)
        end
        return self
    end
    function api:OnChanged(callback)
        table.insert(listeners, callback)
        return self
    end
    function api:ApplyTheme(theme)
        label.TextColor3 = theme.Text
        button.BackgroundColor3 = theme.Window
        button.TextColor3 = theme.Text
        caret.TextColor3 = theme.SubText
        row.BackgroundColor3 = theme.Element
    end
    return api
end

function Section:CreateColorPicker(options)
    options = options or {}
    local row, label = elementBase(self, options.Name or "Color", 34)
    label.Size = UDim2new(0.45, -10, 1, 0)
    local value = parseColor(options.Value or options.Default or "#34C759")
    local button = create("TextButton", {
        Name = "Swatch",
        BackgroundColor3 = value,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(1, 0.5),
        Position = UDim2new(1, -8, 0.5, 0),
        Size = UDim2fromOffset(118, 24),
        Font = Enum.Font.Gotham,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 16,
        Parent = row,
    })
    roundCorners(button, 6)
    local swatchChip = create("Frame", {
        BackgroundColor3 = value,
        BorderSizePixel = 0,
        AnchorPoint = Vector2new(0, 0.5),
        Position = UDim2fromOffset(6, 0),
        Size = UDim2fromOffset(16, 16),
        ZIndex = 17,
        Parent = button,
    })
    roundCorners(swatchChip, 4)
    local hexLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2fromOffset(26, 0),
        Size = UDim2new(1, -30, 1, 0),
        Font = Enum.Font.Gotham,
        Text = color3ToHex(value),
        TextColor3 = self.Theme.Text,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
        Parent = button,
    })
    local api = { Value = value }
    local listeners = {}
    local function notify()
        hexLabel.Text = color3ToHex(value)
        swatchChip.BackgroundColor3 = value
        button.BackgroundColor3 = value
        if options.Callback then
            pcall(options.Callback, value)
        end
        for _, callback in ipairs(listeners) do
            pcall(callback, value)
        end
    end
    local function openPicker()
        closePopups(self.Window)
        local layer = popupLayer(self.Window)
        local panel = create("Frame", {
            Name = "ColorPopup",
            BackgroundColor3 = self.Theme.TitleBar,
            BorderSizePixel = 0,
            Position = UDim2fromOffset(
                math.max(16, button.AbsolutePosition.X - 210),
                button.AbsolutePosition.Y + button.AbsoluteSize.Y + 6
            ),
            Size = UDim2fromOffset(232, 246),
            ZIndex = 601,
            Parent = layer,
        })
        roundCorners(panel, 10)
        create("UIStroke", {
            Parent = panel,
            Thickness = 1,
            Color = self.Theme.WindowStroke,
        })
        local h, s, v = Color3toHSV(value)
        local field = create("Frame", {
            Name = "Field",
            BackgroundColor3 = Color3fromHSV(h, 1, 1),
            BorderSizePixel = 0,
            Position = UDim2fromOffset(10, 10),
            Size = UDim2fromOffset(212, 130),
            ClipsDescendants = true,
            ZIndex = 602,
            Parent = panel,
        })
        roundCorners(field, 6)
        create("Frame", {
            BackgroundColor3 = Color3new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2fromScale(1, 1),
            ZIndex = 603,
            Parent = field,
        }).BackgroundTransparency = 0
        local whiteOverlay = field:FindFirstChildWhichIsA("Frame")
        create("UIGradient", {
            Parent = whiteOverlay,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        })
        local blackOverlay = create("Frame", {
            BackgroundColor3 = Color3new(0, 0, 0),
            BorderSizePixel = 0,
            Size = UDim2fromScale(1, 1),
            ZIndex = 604,
            Parent = field,
        })
        create("UIGradient", {
            Parent = blackOverlay,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        })
        local fieldKnob = create("Frame", {
            BackgroundColor3 = Color3new(1, 1, 1),
            BorderSizePixel = 0,
            AnchorPoint = Vector2new(0.5, 0.5),
            Size = UDim2fromOffset(10, 10),
            ZIndex = 605,
            Parent = field,
        })
        roundCorners(fieldKnob, 5)
        create("UIStroke", {
            Parent = fieldKnob,
            Thickness = 1,
            Color = Color3new(0, 0, 0),
            Transparency = 0.4,
        })
        local hueBar = create("Frame", {
            Name = "HueBar",
            BackgroundColor3 = Color3new(1, 1, 1),
            BorderSizePixel = 0,
            Position = UDim2fromOffset(10, 150),
            Size = UDim2fromOffset(212, 14),
            ZIndex = 602,
            Parent = panel,
        })
        roundCorners(hueBar, 4)
        local hueGradient = create("UIGradient", {
            Parent = hueBar,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
        })
        local hueKnob = create("Frame", {
            BackgroundColor3 = Color3new(1, 1, 1),
            BorderSizePixel = 0,
            AnchorPoint = Vector2new(0.5, 0.5),
            Position = UDim2new(h, 0, 0.5, 0),
            Size = UDim2fromOffset(8, 20),
            ZIndex = 604,
            Parent = hueBar,
        })
        roundCorners(hueKnob, 4)
        create("UIStroke", {
            Parent = hueKnob,
            Thickness = 1,
            Color = Color3new(0, 0, 0),
            Transparency = 0.4,
        })
        local preview = create("Frame", {
            BackgroundColor3 = value,
            BorderSizePixel = 0,
            Position = UDim2fromOffset(10, 176),
            Size = UDim2fromOffset(44, 26),
            ZIndex = 602,
            Parent = panel,
        })
        roundCorners(preview, 6)
        local hexBox = create("TextBox", {
            BackgroundColor3 = self.Theme.Window,
            BorderSizePixel = 0,
            Position = UDim2fromOffset(60, 176),
            Size = UDim2fromOffset(122, 26),
            Font = Enum.Font.Gotham,
            Text = color3ToHex(value),
            TextColor3 = self.Theme.Text,
            TextSize = 11,
            ClearTextOnFocus = false,
            ZIndex = 602,
            Parent = panel,
        })
        roundCorners(hexBox, 6)
        addPadding(hexBox, 8, 8, 0, 0)
        local apply = create("TextButton", {
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0,
            Position = UDim2fromOffset(188, 176),
            Size = UDim2fromOffset(34, 26),
            Font = Enum.Font.GothamBold,
            Text = "OK",
            TextColor3 = self.Theme.AccentText,
            TextSize = 10,
            AutoButtonColor = false,
            ZIndex = 602,
            Parent = panel,
        })
        roundCorners(apply, 6)
        local function refresh()
            hueBar.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            field.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            fieldKnob.Position = UDim2new(s, 0, 1 - v, 0)
            hueKnob.Position = UDim2new(h, 0, 0.5, 0)
            value = Color3.fromHSV(h, s, v)
            preview.BackgroundColor3 = value
            hexBox.Text = color3ToHex(value)
            api.Value = value
            swatchChip.BackgroundColor3 = value
            button.BackgroundColor3 = value
            hexLabel.Text = color3ToHex(value)
        end
        local draggingField = false
        local draggingHue = false
        local function updateField(x, y)
            s = clamp01((x - field.AbsolutePosition.X) / maxn(field.AbsoluteSize.X, 1))
            v = 1 - clamp01((y - field.AbsolutePosition.Y) / maxn(field.AbsoluteSize.Y, 1))
            refresh()
        end
        local function updateHue(x)
            h = clamp01((x - hueBar.AbsolutePosition.X) / maxn(hueBar.AbsoluteSize.X, 1))
            refresh()
        end
        field.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingField = true
                updateField(input.Position.X, input.Position.Y)
            end
        end)
        hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingHue = true
                updateHue(input.Position.X)
            end
        end)
        local moveConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            if draggingField then
                updateField(input.Position.X, input.Position.Y)
            elseif draggingHue then
                updateHue(input.Position.X)
            end
        end)
        local endConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingField = false
                draggingHue = false
            end
        end)
        hexBox.FocusLost:Connect(function()
            local parsed = parseColor(hexBox.Text)
            local ph, ps, pv = Color3toHSV(parsed)
            h, s, v = ph, ps, pv
            refresh()
        end)
        apply.MouseButton1Click:Connect(function()
            notify()
            moveConnection:Disconnect()
            endConnection:Disconnect()
            panel:Destroy()
        end)
        refresh()
    end
    button.MouseButton1Click:Connect(openPicker)
    function api:Get()
        return value
    end
    function api:Set(newValue)
        value = typeof(newValue) == "Color3" and newValue or parseColor(newValue)
        swatchChip.BackgroundColor3 = value
        button.BackgroundColor3 = value
        hexLabel.Text = color3ToHex(value)
        return self
    end
    function api:OnChanged(callback)
        table.insert(listeners, callback)
        return self
    end
    function api:ApplyTheme(theme)
        label.TextColor3 = theme.Text
        hexLabel.TextColor3 = theme.Text
        row.BackgroundColor3 = theme.Element
    end
    return api
end

function Section:CreateMultiDropdown(options)
    options = options or {}
    local drop = self:CreateDropdown({
        Name = options.Name,
        Items = options.Items,
        Value = options.Value,
    })
    local selected = {}
    if type(options.Value) == "table" then
        for _, item in ipairs(options.Value) do
            selected[tostring(item)] = true
        end
    end
    local api = {
        Value = selected,
        Dropdown = drop,
    }
    function api:IsSelected(item)
        return selected[tostring(item)] == true
    end
    function api:Toggle(item)
        local key = tostring(item)
        selected[key] = not selected[key] or nil
        return self
    end
    function api:SelectedList()
        local list = {}
        for key, state in pairs(selected) do
            if state then
                table.insert(list, key)
            end
        end
        return list
    end
    return api
end
FaceIDLib.Themes = FaceIDLib.Presets

function FaceIDLib.new(config)
    if config == FaceIDLib then
        config = nil
    end
    return FaceID.new(config)
end

function FaceIDLib:New(config)
    return FaceID.new(config)
end

function FaceIDLib:CreateFace(config)
    return FaceID.new(config)
end

function FaceIDLib:CreateWindow(options)
    return Window.new(options)
end

function FaceIDLib:CreatePanel(options)
    options = options or {}
    local faceConfig = deepCopy(options.Face or {})
    if faceConfig.AutoShow == nil then
        faceConfig.AutoShow = true
    end
    if faceConfig.AutoHideOnComplete == nil then
        faceConfig.AutoHideOnComplete = true
    end
    local face = FaceID.new(faceConfig)
    local window = Window.new({
        Title = options.Title or "FaceIDLib",
        Subtitle = options.Subtitle or ("v" .. tostring(FaceIDLib.Version or "3.0.0")),
        Theme = options.Theme or faceConfig.Theme or FaceIDLib.Defaults.Theme,
        Size = options.Size or { X = 620, Y = 440 },
        StartVisible = options.StartVisible,
        BuildDefault = false,
    })
    window.Face = face

    local tabLook = window:CreateTab("外观", nil)
    local sectionLook = tabLook:CreateSection("面板")
    sectionLook:CreateSlider({
        Name = "尺寸",
        Min = 72,
        Max = 320,
        Value = faceConfig.Panel and faceConfig.Panel.Size or FaceIDLib.Defaults.Panel.Size,
        Step = 1,
        Decimals = 0,
        Callback = function(value)
            face:SetSize(value)
        end,
    })
    sectionLook:CreateSlider({
        Name = "圆角",
        Min = 0,
        Max = 160,
        Value = faceConfig.Panel and faceConfig.Panel.CornerRadius or FaceIDLib.Defaults.Panel.CornerRadius,
        Step = 1,
        Decimals = 0,
        Callback = function(value)
            face:SetCornerRadius(value)
        end,
    })
    sectionLook:CreateSlider({
        Name = "透明度",
        Min = 0,
        Max = 0.95,
        Value = faceConfig.Panel and faceConfig.Panel.Transparency or FaceIDLib.Defaults.Panel.Transparency,
        Step = 0.01,
        Decimals = 2,
        Callback = function(value)
            face:SetTransparency(value)
        end,
    })
    local sectionIcon = tabLook:CreateSection("图标")
    sectionIcon:CreateSlider({
        Name = "图标缩放",
        Min = 0.2,
        Max = 1,
        Value = FaceIDLib.Defaults.Icon.Scale,
        Step = 0.01,
        Decimals = 2,
        Callback = function(value)
            face:ApplyConfig({ Icon = { Scale = value } })
        end,
    })
    sectionIcon:CreateSlider({
        Name = "线条粗细",
        Min = 0.01,
        Max = 0.15,
        Value = FaceIDLib.Defaults.Icon.Thickness,
        Step = 0.001,
        Decimals = 3,
        Callback = function(value)
            face:ApplyConfig({ Icon = { Thickness = value } })
        end,
    })
    sectionIcon:CreateToggle({
        Name = "显示文字",
        Value = FaceIDLib.Defaults.Text.Enabled,
        Callback = function(state)
            face:ApplyConfig({ Text = { Enabled = state } })
        end,
    })
    local sectionPlay = tabLook:CreateSection("演示")
    sectionPlay:CreateButton({
        Name = "成功验证",
        Text = "Face ID 成功",
        Accent = true,
        ButtonText = "运行",
        Callback = function()
            face:Verify({ Success = true })
        end,
    })
    sectionPlay:CreateButton({
        Name = "失败验证",
        ButtonText = "运行",
        Callback = function()
            face:Verify({ Success = false })
        end,
    })
    sectionPlay:CreateButton({
        Name = "连播",
        ButtonText = "循环",
        Callback = function()
            face:ApplyConfig({ Animation = { Loop = true } })
            face:Show()
        end,
    })

    local tabTheme = window:CreateTab("主题", nil)
    local sectionTheme = tabTheme:CreateSection("预设")
    sectionTheme:CreateDropdown({
        Name = "主题",
        Items = FaceIDLib.themeNames(),
        Value = faceConfig.Theme or FaceIDLib.Defaults.Theme,
        Callback = function(name)
            face:SetTheme(name)
            window:SetTheme(name)
        end,
    })
    sectionTheme:CreateDropdown({
        Name = "图标风格",
        Items = FaceIDLib.styleNames(),
        Value = faceConfig.IconStyle or FaceIDLib.Defaults.IconStyle,
        Callback = function(name)
            face:SetIconStyle(name)
        end,
    })
    local sectionColors = tabTheme:CreateSection("颜色")
    sectionColors:CreateColorPicker({
        Name = "面容线条",
        Value = "#34C759",
        Callback = function(color)
            face:SetColor("Face", color)
        end,
    })
    sectionColors:CreateColorPicker({
        Name = "面板底色",
        Value = "#070807",
        Callback = function(color)
            face:SetColor("Panel", color)
        end,
    })
    sectionColors:CreateColorPicker({
        Name = "成功色",
        Value = "#34C759",
        Callback = function(color)
            face:SetColor("Success", color)
        end,
    })
    sectionColors:CreateColorPicker({
        Name = "失败色",
        Value = "#FF453A",
        Callback = function(color)
            face:SetColor("Fail", color)
        end,
    })

    local tabRun = window:CreateTab("脚本", nil)
    local sectionRun = tabRun:CreateSection("加载完自动执行")
    sectionRun:CreateToggle({
        Name = "启用",
        Value = false,
        Callback = function(state)
            face:ApplyConfig({ AutoExec = { Enabled = state } })
        end,
    })
    sectionRun:CreateInput({
        Name = "脚本链接",
        Placeholder = "https://raw.githubusercontent.com/...",
        Callback = function(text)
            face:ApplyConfig({ AutoExec = { Url = text, Enabled = true } })
        end,
    })
    sectionRun:CreateButton({
        Name = "立即跑链接",
        ButtonText = "执行",
        Accent = true,
        Callback = function()
            local cfg = face:GetConfig()
            local url = cfg.AutoExec and cfg.AutoExec.Url or ""
            if url ~= "" then
                face:ExecuteUrl(url)
            end
        end,
    })
    sectionRun:CreateButton({
        Name = "验证并执行",
        ButtonText = "运行",
        Callback = function()
            face:Verify({ Success = true })
        end,
    })

    local tabAbout = window:CreateTab("关于", nil)
    local sectionAbout = tabAbout:CreateSection("FaceIDLib")
    sectionAbout:CreateLabel("单文件 UI 库", "面容 ID 动画 + 控制面板 + 主题 + 自动脚本加载")
    sectionAbout:CreateParagraph("调用方式", "local lib = loadstring(game:HttpGet(url))() local face = lib.new({ Theme = \"IOSDark\" }) face:Verify({ Success = true })")
    sectionAbout:CreateParagraph("配置项", "Theme / IconStyle / Panel / Icon / Colors / Animation / Position / Text / Sound / AutoExec / Window")
    sectionAbout:CreateParagraph("数量", tostring(#FaceIDLib.ThemeOrder) .. " 套主题," .. tostring(#FaceIDLib.styleNames()) .. " 种图标风格")
    return window, face
end

function FaceIDLib:Load(url, config)
    if type(url) ~= "string" or url == "" then
        return FaceID.new(config)
    end
    local body = httpFetch(url)
    if type(body) ~= "string" or body == "" then
        warn(FaceIDLib.Prefix .. " cannot fetch " .. tostring(url))
        return FaceID.new(config)
    end
    local fn, compileError = Executor.compile(body, "=" .. tostring(url))
    if not fn then
        warn(FaceIDLib.Prefix .. " compile error: " .. tostring(compileError))
        return FaceID.new(config)
    end
    local ok, result = pcall(fn)
    if not ok then
        warn(FaceIDLib.Prefix .. " load error: " .. tostring(result))
        return FaceID.new(config)
    end
    return result
end

function FaceIDLib.Play(config)
    local face = FaceID.new(config)
    face:Verify({ Success = true })
    return face
end

local autoEnvironment = nil
pcall(function()
    if type(getgenv) == "function" then
        autoEnvironment = getgenv()
    end
end)
if type(autoEnvironment) ~= "table" then
    autoEnvironment = _G
end
FaceIDLib.Environment = autoEnvironment
FaceIDLib.Settings = FaceIDLib.Settings or {}
FaceIDLib.Settings.NoAutoStart = FaceIDLib.Settings.NoAutoStart or false

pcall(function()
    autoEnvironment.FaceIDLib = FaceIDLib
end)

local function runningInExecutor()
    local ok, kind = pcall(function()
        return typeof(script)
    end)
    if not ok then
        return true
    end
    if kind == "Instance" then
        return false
    end
    return true
end

local suppressAutoStart = FaceIDLib.Settings.NoAutoStart
pcall(function()
    if autoEnvironment.FaceIDLibNoAutoStart then
        suppressAutoStart = true
    end
end)

if not suppressAutoStart and runningInExecutor() then
    local userConfig = nil
    pcall(function()
        local candidate = autoEnvironment.FaceIDConfig
        if type(candidate) == "table" then
            userConfig = candidate
        end
    end)
    local instance = FaceID.new(userConfig)
    FaceIDLib.Instance = instance
    autoEnvironment.FaceID = instance
end

return FaceIDLib
