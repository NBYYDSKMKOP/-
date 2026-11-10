local FaceIDLib = {}
FaceIDLib.__index = FaceIDLib

FaceIDLib.Version = "1.0.0"
FaceIDLib.Build = "2026.11.10"
FaceIDLib.License = "MIT"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Signal = {}
local Util = {}
local Color = {}
local Ease = {}
local Draw = {}
local Theme = {}
local Config = {}
local Components = {}
local Loader = {}

local PI = math.pi
local TAU = PI * 2
local RAD = math.rad
local DEG = math.deg
local FLOOR = math.floor
local CEIL = math.ceil
local ABS = math.abs
local MIN = math.min
local MAX = math.max
local SQRT = math.sqrt
local SIN = math.sin
local COS = math.cos
local RANDOM = math.random

local STRING_FORMAT = string.format
local STRING_GSUB = string.gsub
local STRING_SUB = string.sub
local STRING_LOWER = string.lower

local TABLE_INSERT = table.insert
local TABLE_REMOVE = table.remove
local TABLE_CONCAT = table.concat
local TABLE_SORT = table.sort
local TABLE_PACK = table.pack or function(...)
	return { n = select("#", ...), ... }
end

FaceIDLib._instances = setmetatable({}, { __mode = "k" })
FaceIDLib._themes = {}
FaceIDLib._defaultTheme = "iOSDark"

FaceIDLib.isClient = RunService:IsClient()

function FaceIDLib.isSupported()
	if not FaceIDLib.isClient then
		return false, "FaceIDLib can only run on the client (LocalScript or a client-side ModuleScript)."
	end
	local ok = pcall(function()
		return Players.LocalPlayer
	end)
	if not ok then
		return false, "Unable to get LocalPlayer; make sure this script runs on the client."
	end
	if not Players.LocalPlayer then
		return false, "LocalPlayer is not ready yet; try again later."
	end
	return true
end

local MATH_ATAN2 = math.atan2 or function(y, x)
	return math.atan(y, x)
end

Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._handlers = {}
	self._firing = false
	return self
end

function Signal:Connect(fn)
	if type(fn) ~= "function" then
		error("[FaceIDLib] Signal:Connect expects a function, got " .. typeof(fn), 2)
	end
	local signal = self
	local entry = { fn = fn, alive = true }
	TABLE_INSERT(signal._handlers, entry)
	return {
		Connected = true,
		Disconnect = function()
			if not entry.alive then
				return
			end
			entry.alive = false
			local list = signal._handlers
			for i = #list, 1, -1 do
				if list[i] == entry then
					TABLE_REMOVE(list, i)
					break
				end
			end
		end,
		IsConnected = function()
			return entry.alive
		end,
	}
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		if conn then
			conn:Disconnect()
		end
		fn(...)
	end)
	return conn
end

function Signal:Fire(...)
	local list = self._handlers
	if #list == 0 then
		return
	end

	local snapshot = {}
	for i = 1, #list do
		snapshot[i] = list[i]
	end
	self._firing = true
	for i = 1, #snapshot do
		local entry = snapshot[i]
		if entry.alive then
			local ok, err = pcall(entry.fn, ...)
			if not ok then
				warn("[FaceIDLib] Event callback error: " .. tostring(err))
			end
		end
	end
	self._firing = false
end

function Signal:Wait(timeout)
	local fired = false
	local packed = nil
	local conn = self:Connect(function(...)
		fired = true
		packed = table.pack(...)
	end)
	local startClock = os.clock()
	while not fired do
		if timeout and (os.clock() - startClock) >= timeout then
			break
		end
		task.wait()
	end
	conn:Disconnect()
	if packed then
		return table.unpack(packed, 1, packed.n)
	end
	return nil
end

function Signal:DisconnectAll()
	for i = #self._handlers, 1, -1 do
		self._handlers[i].alive = false
		self._handlers[i] = nil
	end
	self._handlers = {}
end

function Signal:Destroy()
	self:DisconnectAll()
	self._handlers = nil
end

Util._uid = 0

function Util.uid(prefix)
	Util._uid = Util._uid + 1
	return (prefix or "id") .. "_" .. tostring(Util._uid) .. "_" .. tostring(FLOOR(os.clock() * 1000))
end

function Util.new(className, props, parent)
	local inst = Instance.new(className)
	if props then
		for key, value in pairs(props) do
			local ok = pcall(function()
				inst[key] = value
			end)
			if not ok then
				warn("[FaceIDLib] Failed to set property " .. className .. "." .. tostring(key))
			end
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function Util.apply(inst, props)
	if not inst or not props then
		return inst
	end
	for key, value in pairs(props) do
		pcall(function()
			inst[key] = value
		end)
	end
	return inst
end

function Util.deepCopy(source)
	if type(source) ~= "table" then
		return source
	end
	local copy = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			copy[key] = Util.deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

function Util.deepMerge(base, override)
	local result = Util.deepCopy(base)
	if type(override) ~= "table" then
		return result
	end
	for key, value in pairs(override) do
		if type(value) == "table" and type(result[key]) == "table" and not Util.isArray(value) then
			result[key] = Util.deepMerge(result[key], value)
		else
			if type(value) == "table" then
				result[key] = Util.deepCopy(value)
			else
				result[key] = value
			end
		end
	end
	return result
end

function Util.isArray(tbl)
	if type(tbl) ~= "table" then
		return false
	end
	local count = 0
	local total = 0
	for key in pairs(tbl) do
		total = total + 1
		if type(key) == "number" and key >= 1 and key == FLOOR(key) then
			count = count + 1
		else
			return false
		end
	end
	return total > 0 and count == total
end

function Util.count(tbl)
	local n = 0
	for _ in pairs(tbl) do
		n = n + 1
	end
	return n
end

function Util.keys(tbl)
	local out = {}
	for key in pairs(tbl) do
		TABLE_INSERT(out, key)
	end
	return out
end

function Util.map(tbl, fn)
	local out = {}
	for key, value in pairs(tbl) do
		local r = fn(value, key)
		if r ~= nil then
			out[key] = r
		end
	end
	return out
end

function Util.filter(tbl, fn)
	local out = {}
	for key, value in pairs(tbl) do
		if fn(value, key) then
			out[key] = value
		end
	end
	return out
end

function Util.find(tbl, fn)
	for key, value in pairs(tbl) do
		if fn(value, key) then
			return value, key
		end
	end
	return nil
end

function Util.mapRange(value, inMin, inMax, outMin, outMax)
	if inMax == inMin then
		return outMin
	end
	local t = (value - inMin) / (inMax - inMin)
	return outMin + (outMax - outMin) * t
end

function Util.clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end
	return value
end

function Util.round(value, decimals)
	local mult = 10 ^ (decimals or 0)
	return FLOOR(value * mult + 0.5) / mult
end

function Util.getPath(root, path, default)
	if path == nil or path == "" then
		return root
	end
	local current = root
	for piece in string.gmatch(path, "[^%.]+") do
		if type(current) ~= "table" then
			return default
		end
		current = current[piece]
		if current == nil then
			return default
		end
	end
	return current
end

function Util.toUDim2(value, default)
	if value == nil then
		return default
	end
	if typeof(value) == "UDim2" then
		return value
	end
	if typeof(value) == "Vector2" then
		return UDim2.fromOffset(value.X, value.Y)
	end
	if type(value) == "number" then
		return UDim2.fromOffset(value, value)
	end
	if type(value) == "table" then
		local x = value.X or value.x or value[1]
		local y = value.Y or value.y or value[2]
		if x ~= nil then
			return UDim2.fromOffset(x, y or x)
		end
	end
	return default
end

function Util.tween(instance, tweenInfo, goal)
	local tween = TweenService:Create(instance, tweenInfo, goal)
	local api = {}
	api.instance = tween
	api.Play = function()
		tween:Play()
		return api
	end
	api.Cancel = function()
		tween:Cancel()
		return api
	end
	api.Await = function()
		tween:Play()
		if tween.PlaybackState ~= Enum.PlaybackState.Completed then
			tween.Completed:Wait()
		end
		return api
	end
	api.tween = tween
	return api
end

function Util.awaitAll(list)
	local remaining = #list
	if remaining == 0 then
		return
	end
	local done = false
	for i = 1, #list do
		local tween = list[i]
		if typeof(tween) == "table" and tween.tween then
			tween = tween.tween
		end
		local finished = false
		local function finish()
			if finished then
				return
			end
			finished = true
			remaining = remaining - 1
			if remaining <= 0 then
				done = true
			end
		end
		if tween.PlaybackState == Enum.PlaybackState.Completed then
			finish()
		else
			tween.Completed:Connect(finish)
			tween:Play()
		end
	end
	if not done then
		local start = os.clock()
		while not done do
			if os.clock() - start > 30 then
				break
			end
			task.wait()
		end
	end
end

function Util.newScheduler()
	local scheduler = { _tasks = {} }
	function scheduler:After(delay, fn)
		local token = { cancelled = false }
		TABLE_INSERT(self._tasks, token)
		token.thread = task.delay(delay, function()
			if token.cancelled then
				return
			end
			local ok, err = pcall(fn)
			if not ok then
				warn("[FaceIDLib] Delayed task error: " .. tostring(err))
			end
		end)
		return token
	end
	function scheduler:Every(interval, fn)
		local token = { cancelled = false }
		TABLE_INSERT(self._tasks, token)
		token.thread = task.spawn(function()
			while not token.cancelled do
				task.wait(interval)
				if token.cancelled then
					break
				end
				local ok, err = pcall(fn)
				if not ok then
					warn("[FaceIDLib] Repeating task error: " .. tostring(err))
				end
			end
		end)
		return token
	end
	function scheduler:Cancel(token)
		if token and token.thread then
			token.cancelled = true
			pcall(task.cancel, token.thread)
		end
	end
	function scheduler:Clear()
		for i = #self._tasks, 1, -1 do
			self:Cancel(self._tasks[i])
			self._tasks[i] = nil
		end
	end
	return scheduler
end

function Util.debounce(fn, waitTime)
	local last = 0
	return function(...)
		local now = os.clock()
		if now - last < (waitTime or 0.2) then
			return
		end
		last = now
		return fn(...)
	end
end

function Util.throttle(fn, interval)
	local ready = true
	return function(...)
		if not ready then
			return
		end
		ready = false
		task.delay(interval or 0.2, function()
			ready = true
		end)
		return fn(...)
	end
end

function Util.offsetOf(udim, fallback)
	if type(udim) == "number" then
		return udim
	end
	if typeof(udim) == "UDim" then
		return udim.Offset
	end
	return fallback or 0
end

function Util.toFont(value, default)
	if typeof(value) == "EnumItem" then
		return value
	end
	if type(value) == "string" then
		local ok, font = pcall(function()
			return Enum.Font[value]
		end)
		if ok and font then
			return font
		end
		local ok2, fontFace = pcall(function()
			return Font.fromName(value)
		end)
		if ok2 and fontFace then
			return fontFace
		end
	end
	return default or Enum.Font.GothamMedium
end

function Util.getViewport()
	local camera = Workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
	return size
end

function Util.formatClock(seconds)
	seconds = tonumber(seconds) or 0
	if seconds < 1 then
		return STRING_FORMAT("%dms", FLOOR(seconds * 1000 + 0.5))
	end
	return STRING_FORMAT("%.2fs", seconds)
end

Color.palette = {

	systemRed = Color3.fromRGB(255, 59, 48),
	systemOrange = Color3.fromRGB(255, 149, 0),
	systemYellow = Color3.fromRGB(255, 204, 0),
	systemGreen = Color3.fromRGB(52, 199, 89),
	systemMint = Color3.fromRGB(0, 199, 190),
	systemTeal = Color3.fromRGB(48, 176, 199),
	systemCyan = Color3.fromRGB(50, 173, 230),
	systemBlue = Color3.fromRGB(0, 122, 255),
	systemIndigo = Color3.fromRGB(88, 86, 214),
	systemPurple = Color3.fromRGB(175, 82, 222),
	systemPink = Color3.fromRGB(255, 45, 85),
	systemBrown = Color3.fromRGB(162, 132, 94),

	systemGray = Color3.fromRGB(142, 142, 147),
	systemGray2 = Color3.fromRGB(99, 99, 102),
	systemGray3 = Color3.fromRGB(72, 72, 74),
	systemGray4 = Color3.fromRGB(58, 58, 60),
	systemGray5 = Color3.fromRGB(44, 44, 46),
	systemGray6 = Color3.fromRGB(28, 28, 30),

	white = Color3.fromRGB(255, 255, 255),
	black = Color3.fromRGB(0, 0, 0),
	clear = Color3.fromRGB(0, 0, 0),

	neonGreen = Color3.fromRGB(61, 220, 132),
	neonGreenBright = Color3.fromRGB(122, 255, 170),
	neonGreenDeep = Color3.fromRGB(24, 160, 88),

	failRed = Color3.fromRGB(255, 69, 58),
	failRedDeep = Color3.fromRGB(190, 40, 34),
	warnAmber = Color3.fromRGB(255, 179, 64),
}

function Color.fromHex(value, fallback)
	if type(value) ~= "string" then
		return fallback or Color.palette.black
	end
	local hex = STRING_GSUB(value, "[^%x]", "")
	if #hex == 3 then
		hex = STRING_SUB(hex, 1, 1) .. STRING_SUB(hex, 1, 1)
			.. STRING_SUB(hex, 2, 2) .. STRING_SUB(hex, 2, 2)
			.. STRING_SUB(hex, 3, 3) .. STRING_SUB(hex, 3, 3)
	elseif #hex == 4 then
		hex = STRING_SUB(hex, 1, 3)
	elseif #hex == 8 then
		hex = STRING_SUB(hex, 1, 6)
	end
	if #hex ~= 6 then
		return fallback or Color.palette.black
	end
	local r = tonumber(STRING_SUB(hex, 1, 2), 16)
	local g = tonumber(STRING_SUB(hex, 3, 4), 16)
	local b = tonumber(STRING_SUB(hex, 5, 6), 16)
	if not r or not g or not b then
		return fallback or Color.palette.black
	end
	return Color3.fromRGB(r, g, b)
end

function Color.toHex(color)
	local r = FLOOR(Util.clamp(color.R * 255 + 0.5, 0, 255))
	local g = FLOOR(Util.clamp(color.G * 255 + 0.5, 0, 255))
	local b = FLOOR(Util.clamp(color.B * 255 + 0.5, 0, 255))
	return STRING_FORMAT("%02X%02X%02X", r, g, b)
end

function Color.rgb(r, g, b)
	return Color3.fromRGB(r or 0, g or 0, b or 0)
end

function Color.parse(value, fallback)
	if value == nil then
		return fallback or Color.palette.white
	end
	if typeof(value) == "Color3" then
		return value
	end
	if type(value) == "string" then
		local named = Color.palette[value]
		if named then
			return named
		end
		return Color.fromHex(value, fallback)
	end
	if type(value) == "table" then
		if value.R ~= nil and value.G ~= nil and value.B ~= nil then
			local r, g, b = value.R, value.G, value.B
			if r > 1 or g > 1 or b > 1 then
				return Color3.fromRGB(r, g, b)
			end
			return Color3.new(r, g, b)
		end
		if value[1] ~= nil then
			if value[1] > 1 or (value[2] or 0) > 1 or (value[3] or 0) > 1 then
				return Color3.fromRGB(value[1] or 0, value[2] or 0, value[3] or 0)
			end
			return Color3.new(value[1] or 0, value[2] or 0, value[3] or 0)
		end
		if value.h ~= nil or value.H ~= nil then
			return Color.fromHSV(value.h or value.H, value.s or value.S or 0.5, value.v or value.V or 1)
		end
	end
	return fallback or Color.palette.white
end

function Color.fromHSV(h, s, v)
	h = ((h or 0) % 360) / 360
	s = Util.clamp(s or 0, 0, 1)
	v = Util.clamp(v or 0, 0, 1)
	return Color3.fromHSV(h, s, v)
end

function Color.toHSV(color)
	local h, s, v = Color3.toHSV(color)
	return h * 360, s, v
end

function Color.lerp(a, b, t)
	t = Util.clamp(t or 0, 0, 1)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

function Color.blend(a, b, alpha)
	return Color.lerp(a, b, alpha)
end

function Color.lighten(color, amount)
	amount = Util.clamp(amount or 0.1, 0, 1)
	return Color.lerp(color, Color.palette.white, amount)
end

function Color.darken(color, amount)
	amount = Util.clamp(amount or 0.1, 0, 1)
	return Color.lerp(color, Color.palette.black, amount)
end

function Color.saturate(color, amount)
	local h, s, v = Color.toHSV(color)
	return Color.fromHSV(h, Util.clamp(s + (amount or 0.1), 0, 1), v)
end

function Color.desaturate(color, amount)
	local h, s, v = Color.toHSV(color)
	return Color.fromHSV(h, Util.clamp(s - (amount or 0.1), 0, 1), v)
end

function Color.withValue(color, value)
	local h, s = Color.toHSV(color)
	return Color.fromHSV(h, s, Util.clamp(value, 0, 1))
end

function Color.withHue(color, hue)
	local _, s, v = Color.toHSV(color)
	return Color.fromHSV(hue, s, v)
end

function Color.luminance(color)
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

function Color.isDark(color)
	return Color.luminance(color) < 0.5
end

function Color.invert(color)
	return Color3.new(1 - color.R, 1 - color.G, 1 - color.B)
end

function Color.ramp(colors, t)
	local count = #colors
	if count == 0 then
		return Color.palette.white
	end
	if count == 1 then
		return colors[1]
	end
	t = Util.clamp(t or 0, 0, 1)
	local scaled = t * (count - 1)
	local index = FLOOR(scaled)
	if index >= count - 1 then
		return colors[count]
	end
	local frac = scaled - index
	return Color.lerp(colors[index + 1], colors[index + 2], frac)
end

function Color.sequence(fromColor, toColor, extra)
	local keypoints = {}
	if type(fromColor) == "table" and not fromColor.R then
		for i = 1, #fromColor do
			local item = fromColor[i]
			TABLE_INSERT(keypoints, ColorSequenceKeypoint.new(item.Time, Color.parse(item.Color)))
		end
	else
		TABLE_INSERT(keypoints, ColorSequenceKeypoint.new(0, fromColor))
		TABLE_INSERT(keypoints, ColorSequenceKeypoint.new(1, toColor or fromColor))
	end
	if extra then
		TABLE_INSERT(keypoints, ColorSequenceKeypoint.new(extra.Time, Color.parse(extra.Color)))
	end
	TABLE_SORT(keypoints, function(a, b)
		return a.Time < b.Time
	end)
	return ColorSequence.new(keypoints)
end

function Color.transparencySequence(stops)
	if type(stops) == "number" then
		return NumberSequence.new(stops)
	end
	if type(stops) == "table" then
		local keypoints = {}
		for i = 1, #stops do
			local item = stops[i]
			if type(item) == "table" then
				TABLE_INSERT(keypoints, NumberSequenceKeypoint.new(item[1] or 0, item[2] or 0))
			end
		end
		if #keypoints > 0 then
			return NumberSequence.new(keypoints)
		end
	end
	return NumberSequence.new(0)
end

function Color.applyGradient(instance, colorSequence, rotation, transparencySequence)
	local gradient = Instance.new("UIGradient")
	if typeof(colorSequence) == "ColorSequence" then
		gradient.Color = colorSequence
	end
	if transparencySequence then
		if typeof(transparencySequence) == "NumberSequence" then
			gradient.Transparency = transparencySequence
		end
	end
	gradient.Rotation = rotation or 90
	gradient.Parent = instance
	return gradient
end

function Color.fadeSequence(fromColor, toColor, midColor)
	return Color.sequence({
		{ Time = 0, Color = fromColor },
		{ Time = 0.5, Color = midColor or toColor },
		{ Time = 1, Color = toColor },
	})
end

function Color.describe(color)
	return "#" .. Color.toHex(color)
end

Ease.curves = {}

Ease.curves.linear = function(p)
	return p
end

Ease.curves.quadIn = function(p)
	return p * p
end
Ease.curves.quadOut = function(p)
	return 1 - (1 - p) * (1 - p)
end
Ease.curves.quadInOut = function(p)
	if p < 0.5 then
		return 2 * p * p
	end
	return 1 - ((-2 * p + 2) ^ 2) / 2
end

Ease.curves.cubicIn = function(p)
	return p * p * p
end
Ease.curves.cubicOut = function(p)
	return 1 - (1 - p) ^ 3
end
Ease.curves.cubicInOut = function(p)
	if p < 0.5 then
		return 4 * p * p * p
	end
	return 1 - ((-2 * p + 2) ^ 3) / 2
end

Ease.curves.quartIn = function(p)
	return p ^ 4
end
Ease.curves.quartOut = function(p)
	return 1 - (1 - p) ^ 4
end
Ease.curves.quartInOut = function(p)
	if p < 0.5 then
		return 8 * p ^ 4
	end
	return 1 - ((-2 * p + 2) ^ 4) / 2
end

Ease.curves.quintIn = function(p)
	return p ^ 5
end
Ease.curves.quintOut = function(p)
	return 1 - (1 - p) ^ 5
end
Ease.curves.quintInOut = function(p)
	if p < 0.5 then
		return 16 * p ^ 5
	end
	return 1 - ((-2 * p + 2) ^ 5) / 2
end

Ease.curves.sineIn = function(p)
	return 1 - COS((p * PI) / 2)
end
Ease.curves.sineOut = function(p)
	return SIN((p * PI) / 2)
end
Ease.curves.sineInOut = function(p)
	return -(COS(PI * p) - 1) / 2
end

Ease.curves.expoIn = function(p)
	if p <= 0 then
		return 0
	end
	return 2 ^ (10 * p - 10)
end
Ease.curves.expoOut = function(p)
	if p >= 1 then
		return 1
	end
	return 1 - 2 ^ (-10 * p)
end
Ease.curves.expoInOut = function(p)
	if p <= 0 then
		return 0
	end
	if p >= 1 then
		return 1
	end
	if p < 0.5 then
		return (2 ^ (20 * p - 10)) / 2
	end
	return (2 - 2 ^ (-20 * p + 10)) / 2
end

Ease.curves.circIn = function(p)
	return 1 - SQRT(1 - p * p)
end
Ease.curves.circOut = function(p)
	return SQRT(1 - (p - 1) ^ 2)
end
Ease.curves.circInOut = function(p)
	if p < 0.5 then
		return (1 - SQRT(1 - 4 * p * p)) / 2
	end
	return (SQRT(1 - (-2 * p + 2) ^ 2) + 1) / 2
end

Ease.curves.backIn = function(p, overshoot)
	local c1 = overshoot or 1.70158
	local c3 = c1 + 1
	return c3 * p * p * p - c1 * p * p
end
Ease.curves.backOut = function(p, overshoot)
	local c1 = overshoot or 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (p - 1) ^ 3 + c1 * (p - 1) ^ 2
end
Ease.curves.backInOut = function(p, overshoot)
	local c1 = overshoot or 1.70158
	local c2 = c1 * 1.525
	if p < 0.5 then
		return ((2 * p) ^ 2 * ((c2 + 1) * 2 * p - c2)) / 2
	end
	return (((2 * p - 2) ^ 2 * ((c2 + 1) * (p * 2 - 2) + c2)) + 2) / 2
end

Ease.curves.elasticIn = function(p)
	if p <= 0 then
		return 0
	end
	if p >= 1 then
		return 1
	end
	local c4 = TAU / 3
	return -(2 ^ (10 * p - 10)) * SIN((p * 10 - 10.75) * c4)
end
Ease.curves.elasticOut = function(p)
	if p <= 0 then
		return 0
	end
	if p >= 1 then
		return 1
	end
	local c4 = TAU / 3
	return 2 ^ (-10 * p) * SIN((p * 10 - 0.75) * c4) + 1
end
Ease.curves.elasticInOut = function(p)
	if p <= 0 then
		return 0
	end
	if p >= 1 then
		return 1
	end
	local c5 = TAU / 4.5
	if p < 0.5 then
		return -(2 ^ (20 * p - 10) * SIN((20 * p - 11.125) * c5)) / 2
	end
	return (2 ^ (-20 * p + 10) * SIN((20 * p - 11.125) * c5)) / 2 + 1
end

Ease.curves.bounceOut = function(p)
	local n1 = 7.5625
	local d1 = 2.75
	if p < 1 / d1 then
		return n1 * p * p
	elseif p < 2 / d1 then
		p = p - 1.5 / d1
		return n1 * p * p + 0.75
	elseif p < 2.5 / d1 then
		p = p - 2.25 / d1
		return n1 * p * p + 0.9375
	end
	p = p - 2.625 / d1
	return n1 * p * p + 0.984375
end
Ease.curves.bounceIn = function(p)
	return 1 - Ease.curves.bounceOut(1 - p)
end
Ease.curves.bounceInOut = function(p)
	if p < 0.5 then
		return (1 - Ease.curves.bounceOut(1 - 2 * p)) / 2
	end
	return (1 + Ease.curves.bounceOut(2 * p - 1)) / 2
end

Ease.curves.smooth = function(p)
	return p * p * (3 - 2 * p)
end
Ease.curves.smoother = function(p)
	return p * p * p * (p * (p * 6 - 15) + 10)
end

Ease.curves.anticipate = function(p)
	return p * p * (2.70158 * p - 1.70158)
end

function Ease.spring(t, damping, frequency)
	t = Util.clamp(t or 0, 0, 1)
	damping = damping or 6
	frequency = frequency or 3
	return 1 - (COS(t * frequency * PI) * (1 - t) ^ damping)
end

function Ease.shake(t, amplitude, cycles)
	t = Util.clamp(t or 0, 0, 1)
	amplitude = amplitude or 6
	cycles = cycles or 8
	return SIN(t * cycles * PI * 2) * amplitude * (1 - t)
end

function Ease.wave(t, cycles)
	return (SIN(t * (cycles or 1) * TAU - PI / 2) + 1) / 2
end

function Ease.pulse(t)
	t = Util.clamp(t or 0, 0, 1)
	if t < 0.5 then
		return t * 2
	end
	return (1 - t) * 2
end

function Ease.get(name, default)
	if type(name) == "function" then
		return name
	end
	if type(name) ~= "string" then
		return default or Ease.curves.linear
	end
	local direct = Ease.curves[name]
	if direct then
		return direct
	end
	local normalized = STRING_LOWER(STRING_GSUB(name, "[^%w]", ""))
	for key, fn in pairs(Ease.curves) do
		if STRING_LOWER(key) == normalized then
			return fn
		end
	end
	return default or Ease.curves.linear
end

function Ease.apply(name, p)
	p = Util.clamp(p or 0, 0, 1)
	return Ease.get(name)(p)
end

Ease.styleMap = {
	linear = Enum.EasingStyle.Linear,
	quad = Enum.EasingStyle.Quad,
	cubic = Enum.EasingStyle.Cubic,
	quart = Enum.EasingStyle.Quart,
	quint = Enum.EasingStyle.Quint,
	sine = Enum.EasingStyle.Sine,
	expo = Enum.EasingStyle.Exponential,
	circ = Enum.EasingStyle.Circular,
	back = Enum.EasingStyle.Back,
	elastic = Enum.EasingStyle.Elastic,
	bounce = Enum.EasingStyle.Bounce,
}

function Ease.toStyleEnum(name, default)
	if type(name) == "EnumItem" then
		return name
	end
	if type(name) == "string" then
		local normalized = STRING_LOWER(name)
		local base = STRING_GSUB(normalized, "inout$", "")
		base = STRING_GSUB(base, "in$", "")
		base = STRING_GSUB(base, "out$", "")
		if Ease.styleMap[base] then
			return Ease.styleMap[base]
		end
		if Ease.styleMap[normalized] then
			return Ease.styleMap[normalized]
		end
	end
	return default or Enum.EasingStyle.Quad
end

function Ease.toDirectionEnum(name, default)
	if type(name) == "EnumItem" then
		return name
	end
	local normalized = STRING_LOWER(tostring(name or ""))
	if STRING_SUB(normalized, -6) == "inout" then
		return Enum.EasingDirection.InOut
	elseif STRING_SUB(normalized, -2) == "in" then
		return Enum.EasingDirection.In
	elseif STRING_SUB(normalized, -3) == "out" then
		return Enum.EasingDirection.Out
	end
	return default or Enum.EasingDirection.Out
end

function Ease.tweenInfo(duration, style, direction, extra)
	local info = TweenInfo.new(
		duration or 0.2,
		Ease.toStyleEnum(style, Enum.EasingStyle.Quad),
		Ease.toDirectionEnum(style or direction, Enum.EasingDirection.Out),
		(extra and extra.RepeatCount) or 0,
		(extra and extra.Reverses) or false,
		(extra and extra.DelayTime) or 0
	)
	return info
end

function Util.lerp(a, b, t)
	return a + (b - a) * t
end

function Util.clamp01(t)
	if t < 0 then
		return 0
	elseif t > 1 then
		return 1
	end
	return t
end

function Util.smoothstep(edge0, edge1, x)
	if edge1 == edge0 then
		return x < edge0 and 0 or 1
	end
	local t = Util.clamp01((x - edge0) / (edge1 - edge0))
	return t * t * (3 - 2 * t)
end

function Util.pingPong(x, length)
	length = length or 1
	local v = x % (length * 2)
	if v > length then
		v = length * 2 - v
	end
	return v / length
end

function Util.lerpAngle(a, b, t)
	local diff = ((b - a + 180) % 360) - 180
	return a + diff * t
end

function Util.lerpVector2(a, b, t)
	return Vector2.new(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t)
end

function Util.lerpVector3(a, b, t)
	return Vector3.new(
		a.X + (b.X - a.X) * t,
		a.Y + (b.Y - a.Y) * t,
		a.Z + (b.Z - a.Z) * t
	)
end

function Util.lerpUDim2(a, b, t)
	local ax, ay = a.X.Offset, a.Y.Offset
	local bx, by = b.X.Offset, b.Y.Offset
	local sx = a.X.Scale + (b.X.Scale - a.X.Scale) * t
	local sy = a.Y.Scale + (b.Y.Scale - a.Y.Scale) * t
	return UDim2.new(sx, ax + (bx - ax) * t, sy, ay + (by - ay) * t)
end

function Util.jitter(strength)
	strength = strength or 1
	return (RANDOM() * 2 - 1) * strength, (RANDOM() * 2 - 1) * strength
end

function Draw.context(originX, originY, scale, zIndex)
	return {
		ox = originX or 0,
		oy = originY or 0,
		scale = scale or 1,
		z = zIndex or 1,
	}
end

function Draw.px(ctx, x, y)
	return ctx.ox + x * ctx.scale, ctx.oy + y * ctx.scale
end

function Draw.len(ctx, value)
	return value * ctx.scale
end

function Draw.line(parent, cx, cy, length, thickness, angle, color, transparency, zIndex, name)
	local line = Instance.new("Frame")
	line.Name = name or "Stroke"
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Size = UDim2.fromOffset(MAX(length, thickness), thickness)
	line.Position = UDim2.fromOffset(cx, cy)
	line.Rotation = angle or 0
	line.BackgroundColor3 = color or Color.palette.white
	line.BackgroundTransparency = transparency or 0
	line.BorderSizePixel = 0
	line.ZIndex = zIndex or 1
	line.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = line

	return line
end

function Draw.between(parent, x1, y1, x2, y2, thickness, color, transparency, zIndex, name)
	local dx = x2 - x1
	local dy = y2 - y1
	local length = SQRT(dx * dx + dy * dy)
	local angle = DEG(MATH_ATAN2(dy, dx))
	return Draw.line(parent, (x1 + x2) / 2, (y1 + y2) / 2, length, thickness, angle, color, transparency, zIndex, name)
end

function Draw.arc(parent, cx, cy, radius, angleStart, angleEnd, thickness, quality, color, transparency, zIndex, namePrefix)
	local fromAngle = RAD(angleStart or 0)
	local toAngle = RAD(angleEnd or 90)
	local sweep = toAngle - fromAngle
	local arcLength = ABS(sweep) * radius

	local segments = quality
	if not segments or segments <= 0 then
		segments = MAX(14, CEIL(arcLength / MAX(thickness * 0.22, 1)))
	end
	segments = MIN(segments, 160)

	local frames = {}

	local segmentLength = (arcLength / segments) * 1.08 + thickness * 0.12
	local stepAngle = sweep / segments

	for i = 0, segments - 1 do
		local angle = fromAngle + stepAngle * (i + 0.5)
		local x = cx + COS(angle) * radius
		local y = cy + SIN(angle) * radius
		local rotation = DEG(angle) + 90
		local frame = Draw.line(
			parent,
			x,
			y,
			segmentLength,
			thickness,
			rotation,
			color,
			transparency,
			zIndex,
			(namePrefix or "Arc") .. tostring(i + 1)
		)
		TABLE_INSERT(frames, frame)
	end
	return frames
end

function Draw.circle(parent, cx, cy, radius, color, transparency, zIndex, name)
	local circle = Instance.new("Frame")
	circle.Name = name or "Circle"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
	circle.Position = UDim2.fromOffset(cx, cy)
	circle.BackgroundColor3 = color or Color.palette.white
	circle.BackgroundTransparency = transparency or 0
	circle.BorderSizePixel = 0
	circle.ZIndex = zIndex or 1
	circle.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle
	return circle
end

function Draw.ring(parent, cx, cy, radius, thickness, color, transparency, zIndex, name)
	local ring = Instance.new("Frame")
	ring.Name = name or "Ring"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Size = UDim2.fromOffset(radius * 2, radius * 2)
	ring.Position = UDim2.fromOffset(cx, cy)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.ZIndex = zIndex or 1
	ring.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = color or Color.palette.white
	stroke.Transparency = transparency or 0
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = ring

	return ring, stroke
end

function Draw.glow(parent, cx, cy, radius, color, layers, zIndex, baseTransparency, spread)
	layers = layers or 6
	baseTransparency = baseTransparency or 0.35
	spread = spread or 0.55
	local frames = {}
	for i = 1, layers do
		local t = i / layers
		local r = radius * (1 + spread * t)
		local thickness = MAX(1.5, radius * 0.09 * (1 - t * 0.6))
		local alpha = Util.clamp(baseTransparency + t * (0.85 - baseTransparency), 0, 1)
		local ring, stroke = Draw.ring(
			parent,
			cx,
			cy,
			r,
			thickness,
			color,
			alpha,
			(zIndex or 1) + i,
			"Glow" .. tostring(i)
		)
		TABLE_INSERT(frames, ring)
	end
	return frames
end

function Draw.softSpot(parent, cx, cy, radius, color, layers, zIndex, strength)
	layers = layers or 8
	strength = strength or 0.12
	local frames = {}
	for i = layers, 1, -1 do
		local t = i / layers
		local r = radius * (0.35 + t * 0.65)
		local alpha = 1 - (0.02 + strength * (1 - t) * 3)
		local circle = Draw.circle(parent, cx, cy, r, color, Util.clamp(alpha, 0, 1), (zIndex or 1) + (layers - i), "Spot" .. tostring(i))
		TABLE_INSERT(frames, circle)
	end
	return frames
end

function Draw.panel(parent, size, cornerRadius, color, transparency, zIndex, name)
	local width = size
	local height = size
	if typeof(size) == "UDim2" then
		width = size.X.Offset
		height = size.Y.Offset
	elseif type(size) == "table" then
		width = size[1] or size.Width or size.width or 100
		height = size[2] or size.Height or size.height or width
	end

	local panel = Instance.new("Frame")
	panel.Name = name or "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Size = UDim2.fromOffset(width, height)
	panel.BackgroundColor3 = color or Color.palette.black
	panel.BackgroundTransparency = transparency or 0
	panel.BorderSizePixel = 0
	panel.ZIndex = zIndex or 1
	panel.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, cornerRadius or 0)
	corner.Parent = panel

	return panel
end

function Draw.shadow(parent, width, height, cornerRadius, spread, color, transparency, zIndex)
	local shadow = Draw.panel(
		parent,
		{ width + spread * 2, height + spread * 2 },
		cornerRadius + spread,
		color or Color.palette.black,
		transparency or 0.55,
		zIndex or 0,
		"Shadow"
	)
	return shadow
end

function Draw.gradientBar(parent, width, height, color, transparency, rotation, zIndex, name)
	local bar = Instance.new("Frame")
	bar.Name = name or "GradientBar"
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Size = UDim2.fromOffset(width, height)
	bar.BackgroundColor3 = color
	bar.BackgroundTransparency = transparency or 0
	bar.BorderSizePixel = 0
	bar.ZIndex = zIndex or 1
	bar.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = bar

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(0.5, color),
		ColorSequenceKeypoint.new(1, color),
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, transparency or 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = rotation or 0
	gradient.Parent = bar

	return bar
end

function Draw.softBar(parent, width, height, color, transparency, zIndex)
	local bar = Instance.new("Frame")
	bar.Name = "SoftBar"
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Size = UDim2.fromOffset(width, height)
	bar.BackgroundColor3 = color
	bar.BackgroundTransparency = 0
	bar.BorderSizePixel = 0
	bar.ZIndex = zIndex or 1
	bar.Parent = parent

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, transparency or 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Color = ColorSequence.new(color)
	gradient.Parent = bar

	return bar
end

function Draw.frostedPanel(parent, width, height, cornerRadius, color, transparency, zIndex)
	local panel = Draw.panel(parent, { width, height }, cornerRadius, color, transparency, zIndex, "Frosted")

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, Util.clamp(transparency - 0.06, 0, 1)),
		NumberSequenceKeypoint.new(0.55, transparency),
		NumberSequenceKeypoint.new(1, Util.clamp(transparency + 0.08, 0, 1)),
	})
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color.lighten(color, 0.12)),
		ColorSequenceKeypoint.new(0.5, color),
		ColorSequenceKeypoint.new(1, Color.darken(color, 0.08)),
	})
	gradient.Parent = panel

	return panel
end

function Draw.stroke(instance, thickness, color, transparency, zIndex)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = color or Color.palette.white
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = instance
	return stroke
end

function Draw.text(parent, props)
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Label"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	label.Size = props.Size or UDim2.fromOffset(200, 20)
	label.Position = props.Position or UDim2.fromOffset(0, 0)
	label.Font = props.Font or Enum.Font.GothamMedium
	label.Text = props.Text or ""
	label.TextColor3 = props.TextColor3 or Color.palette.white
	label.TextTransparency = props.TextTransparency or 0
	label.TextSize = props.TextSize or 14
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
	label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
	label.TextScaled = false
	label.RichText = props.RichText or false
	label.ZIndex = props.ZIndex or 1
	label.Parent = parent

	if props.TextStrokeTransparency ~= nil and props.TextStrokeTransparency < 1 then
		label.TextStrokeTransparency = props.TextStrokeTransparency
		label.TextStrokeColor3 = props.TextStrokeColor3 or Color.palette.black
	end

	if props.Shadow then
		local shadow = label:Clone()
		shadow.Name = "Shadow"
		shadow.TextColor3 = props.ShadowColor or Color.palette.black
		shadow.TextTransparency = props.ShadowTransparency or 0.7
		shadow.ZIndex = label.ZIndex - 1
		shadow.Position = label.Position + UDim2.fromOffset(0, 1)
		shadow.Parent = parent
		return label, shadow
	end

	return label
end

function Draw.checkmark(parent, cx, cy, size, thickness, color, transparency, zIndex)
	local frames = {}
	local framesA = Draw.between(
		parent,
		cx - size * 0.5,
		cy,
		cx - size * 0.08,
		cy + size * 0.42,
		thickness,
		color,
		transparency,
		zIndex,
		"CheckA"
	)
	TABLE_INSERT(frames, framesA)
	local framesB = Draw.between(
		parent,
		cx - size * 0.08,
		cy + size * 0.42,
		cx + size * 0.52,
		cy - size * 0.42,
		thickness,
		color,
		transparency,
		zIndex,
		"CheckB"
	)
	TABLE_INSERT(frames, framesB)
	return frames
end

function Draw.crossmark(parent, cx, cy, size, thickness, color, transparency, zIndex)
	local frames = {}
	local a = Draw.between(
		parent,
		cx - size * 0.5,
		cy - size * 0.5,
		cx + size * 0.5,
		cy + size * 0.5,
		thickness,
		color,
		transparency,
		zIndex,
		"CrossA"
	)
	local b = Draw.between(
		parent,
		cx + size * 0.5,
		cy - size * 0.5,
		cx - size * 0.5,
		cy + size * 0.5,
		thickness,
		color,
		transparency,
		zIndex,
		"CrossB"
	)
	TABLE_INSERT(frames, a)
	TABLE_INSERT(frames, b)
	return frames
end

function Draw.setAlpha(instances, alpha)
	for i = 1, #instances do
		local inst = instances[i]
		if inst and inst.Parent then
			if inst:IsA("Frame") or inst:IsA("TextLabel") or inst:IsA("ImageLabel") then
				pcall(function()
					inst.BackgroundTransparency = alpha
				end)
			end
		end
	end
end

function Draw.setStrokeAlpha(strokes, alpha)
	for i = 1, #strokes do
		local stroke = strokes[i]
		if stroke and stroke.Parent then
			pcall(function()
				stroke.Transparency = alpha
			end)
		end
	end
end

Theme.presets = {}

Theme.presets.iOSDark = {
	Panel = {
		Color = "1A1A1C",
		Transparency = 0.04,
		CornerRadius = 40,
		StrokeColor = "FFFFFF",
		StrokeThickness = 0,
		StrokeTransparency = 0.9,
		ShadowEnabled = true,
		ShadowColor = "000000",
		ShadowSpread = 10,
		ShadowTransparency = 0.55,
	},
	Face = {
		Color = "34C759",
		ColorBright = "6BF08A",
		ColorDim = "1E7A38",
	},
	Halo = { Enabled = true, Color = "34C759" },
	Scan = { Color = "8CFFAB" },
	Caption = { Color = "FFFFFF" },
	Fail = { Color = "FF453A" },
}

Theme.presets.iOSLight = {
	Panel = {
		Color = "FFFFFF",
		Transparency = 0.02,
		CornerRadius = 40,
		StrokeColor = "000000",
		StrokeThickness = 1,
		StrokeTransparency = 0.9,
		ShadowEnabled = true,
		ShadowColor = "000000",
		ShadowSpread = 12,
		ShadowTransparency = 0.78,
	},
	Face = {
		Color = "1C1C1E",
		ColorBright = "000000",
		ColorDim = "8E8E93",
	},
	Halo = { Enabled = false, Color = "1C1C1E" },
	Scan = { Color = "1C1C1E" },
	Caption = { Color = "1C1C1E" },
	Fail = { Color = "FF3B30" },
}

Theme.presets.NeonGreen = {
	Panel = {
		Color = "000000",
		Transparency = 0,
		CornerRadius = 44,
		StrokeColor = "3DDC84",
		StrokeThickness = 0,
		StrokeTransparency = 1,
		ShadowEnabled = true,
		ShadowColor = "000000",
		ShadowSpread = 14,
		ShadowTransparency = 0.35,
	},
	Face = {
		Color = "3DDC84",
		ColorBright = "B4FFCF",
		ColorDim = "0F5C33",
	},
	Halo = { Enabled = true, Color = "3DDC84", Layers = 8, Transparency = 0.25, Spread = 0.75 },
	Scan = { Color = "D6FFE6", Glow = true },
	Caption = { Color = "B4FFCF" },
	Fail = { Color = "FF453A" },
}

Theme.presets.Midnight = {
	Panel = { Color = "0B1220", Transparency = 0.02, CornerRadius = 38, StrokeColor = "3B82F6", StrokeThickness = 1, StrokeTransparency = 0.82, ShadowEnabled = true, ShadowColor = "000000", ShadowSpread = 12, ShadowTransparency = 0.5 },
	Face = { Color = "3B82F6", ColorBright = "93C5FD", ColorDim = "1E3A8A" },
	Halo = { Enabled = true, Color = "3B82F6" },
	Scan = { Color = "BFDBFE" },
	Caption = { Color = "E2E8F0" },
	Fail = { Color = "F87171" },
}

Theme.presets.Ocean = {
	Panel = { Color = "04222B", Transparency = 0.02, CornerRadius = 40, StrokeColor = "2DD4BF", StrokeThickness = 1, StrokeTransparency = 0.85, ShadowEnabled = true, ShadowColor = "000000", ShadowSpread = 12, ShadowTransparency = 0.6 },
	Face = { Color = "2DD4BF", ColorBright = "99F6E4", ColorDim = "0F766E" },
	Halo = { Enabled = true, Color = "2DD4BF" },
	Scan = { Color = "CCFBF1" },
	Caption = { Color = "E0F2F1" },
	Fail = { Color = "FB7185" },
}

Theme.presets.Sunset = {
	Panel = { Color = "2A0F0A", Transparency = 0.02, CornerRadius = 42, StrokeColor = "FB923C", StrokeThickness = 0, StrokeTransparency = 1, ShadowEnabled = true, ShadowColor = "000000", ShadowSpread = 14, ShadowTransparency = 0.55 },
	Face = { Color = "FB923C", ColorBright = "FDE68A", ColorDim = "9A3412" },
	Halo = { Enabled = true, Color = "FB923C", Layers = 7 },
	Scan = { Color = "FFE4C4" },
	Caption = { Color = "FFEDD5" },
	Fail = { Color = "EF4444" },
}

Theme.presets.Lavender = {
	Panel = { Color = "1B1026", Transparency = 0.02, CornerRadius = 44, StrokeColor = "C084FC", StrokeThickness = 1, StrokeTransparency = 0.86, ShadowEnabled = true, ShadowColor = "000000", ShadowSpread = 12, ShadowTransparency = 0.6 },
	Face = { Color = "C084FC", ColorBright = "E9D5FF", ColorDim = "6B21A8" },
	Halo = { Enabled = true, Color = "C084FC" },
	Scan = { Color = "F3E8FF" },
	Caption = { Color = "F5EBFF" },
	Fail = { Color = "FB7185" },
}

Theme.presets.Cyber = {
	Panel = { Color = "05010D", Transparency = 0, CornerRadius = 30, StrokeColor = "22D3EE", StrokeThickness = 1.5, StrokeTransparency = 0.7, ShadowEnabled = true, ShadowColor = "22D3EE", ShadowSpread = 16, ShadowTransparency = 0.82 },
	Face = { Color = "22D3EE", ColorBright = "A5F3FC", ColorDim = "0E7490" },
	Halo = { Enabled = true, Color = "F472B6", Layers = 8, Spread = 0.8 },
	Scan = { Color = "ECFEFF" },
	Caption = { Color = "CFFAFE" },
	Fail = { Color = "FB7185" },
}

Theme.presets.Mono = {
	Panel = { Color = "121212", Transparency = 0, CornerRadius = 36, StrokeColor = "FFFFFF", StrokeThickness = 1, StrokeTransparency = 0.94, ShadowEnabled = true, ShadowColor = "000000", ShadowSpread = 10, ShadowTransparency = 0.5 },
	Face = { Color = "FFFFFF", ColorBright = "FFFFFF", ColorDim = "6B6B6B" },
	Halo = { Enabled = false, Color = "FFFFFF" },
	Scan = { Color = "FFFFFF" },
	Caption = { Color = "FFFFFF" },
	Fail = { Color = "FF453A" },
}

Theme.presets.Blood = {
	Panel = { Color = "150505", Transparency = 0.02, CornerRadius = 40, StrokeColor = "EF4444", StrokeThickness = 1, StrokeTransparency = 0.86, ShadowEnabled = true, ShadowColor = "000000", ShadowSpread = 14, ShadowTransparency = 0.5 },
	Face = { Color = "EF4444", ColorBright = "FCA5A5", ColorDim = "7F1D1D" },
	Halo = { Enabled = true, Color = "EF4444" },
	Scan = { Color = "FEE2E2" },
	Caption = { Color = "FEE2E2" },
	Fail = { Color = "EF4444" },
}

Theme.presets.Gold = {
	Panel = { Color = "17120A", Transparency = 0.02, CornerRadius = 42, StrokeColor = "F5C563", StrokeThickness = 1, StrokeTransparency = 0.8, ShadowEnabled = true, ShadowColor = "000000", ShadowSpread = 12, ShadowTransparency = 0.55 },
	Face = { Color = "F5C563", ColorBright = "FFF3C4", ColorDim = "8A6A16" },
	Halo = { Enabled = true, Color = "F5C563", Layers = 7 },
	Scan = { Color = "FFF9E0" },
	Caption = { Color = "FFF3C4" },
	Fail = { Color = "EF4444" },
}

Theme.presets.Glass = {
	Panel = { Color = "FFFFFF", Transparency = 0.88, CornerRadius = 44, StrokeColor = "FFFFFF", StrokeThickness = 1.4, StrokeTransparency = 0.55, ShadowEnabled = true, ShadowColor = "000000", ShadowSpread = 18, ShadowTransparency = 0.6 },
	Face = { Color = "FFFFFF", ColorBright = "FFFFFF", ColorDim = "CFCFCF" },
	Halo = { Enabled = true, Color = "FFFFFF", Transparency = 0.6, Layers = 5 },
	Scan = { Color = "FFFFFF" },
	Caption = { Color = "FFFFFF" },
	Fail = { Color = "FFB4AB" },
}

Theme.aliases = {
	dark = "iOSDark",
	light = "iOSLight",
	green = "NeonGreen",
	neon = "NeonGreen",
	blue = "Midnight",
	teal = "Ocean",
	orange = "Sunset",
	purple = "Lavender",
	cyberpunk = "Cyber",
	gray = "Mono",
	grey = "Mono",
	red = "Blood",
	champagne = "Gold",
	glassmorphism = "Glass",
}

function Theme.get(name, fallback)
	if type(name) == "table" then
		return name
	end
	if type(name) ~= "string" then
		return Theme.presets[fallback or FaceIDLib._defaultTheme]
	end
	local preset = Theme.presets[name]
	if preset then
		return preset
	end
	local lower = STRING_LOWER(name)
	local alias = Theme.aliases[lower]
	if alias and Theme.presets[alias] then
		return Theme.presets[alias]
	end
	for key, value in pairs(Theme.presets) do
		if STRING_LOWER(key) == lower then
			return value
		end
	end
	return Theme.presets[fallback or FaceIDLib._defaultTheme]
end

function Theme.register(name, data)
	if type(name) ~= "string" or type(data) ~= "table" then
		return false, "Theme.register(name, data) expects a string and a table"
	end
	Theme.presets[name] = data
	return true
end

function Theme.list()
	local names = {}
	for name in pairs(Theme.presets) do
		TABLE_INSERT(names, name)
	end
	TABLE_SORT(names, function(a, b)
		return STRING_LOWER(a) < STRING_LOWER(b)
	end)
	return names
end

Config.defaults = {

	Name = "FaceIDLib",
	Theme = "iOSDark",
	Parent = nil,
	DisplayOrder = 9999,
	IgnoreGuiInset = true,
	Scale = 1,
	AutoScale = true,

	Position = UDim2.new(0.5, 0, 0, 76),
	AnchorPoint = Vector2.new(0.5, 0),

	Panel = {
		Enabled = true,
		Size = 152,
		CornerRadius = 40,
		Color = "1A1A1C",
		Transparency = 0.04,
		StrokeColor = "FFFFFF",
		StrokeThickness = 0,
		StrokeTransparency = 0.9,
		ShadowEnabled = true,
		ShadowColor = "000000",
		ShadowSpread = 10,
		ShadowTransparency = 0.55,
		Padding = 0,
	},

	Face = {
		IconSize = 100,
		IconScale = 0.64,
		Color = "34C759",
		ColorBright = "6BF08A",
		ColorDim = "1E7A38",
		Transparency = 0,
		DimTransparency = 0.10,
		StrokeWidth = 5.4,
		Lighting = true,
		Brackets = {
			Enabled = true,
			Length = 25,
			Thickness = 7.5,
			Inset = 0,
			Corner = 0,
			VerticalScale = 1,
		},
		Eyes = {
			Enabled = true,
			Width = 6.5,
			Height = 15,
			OffsetX = 21,
			OffsetY = -10,
			Tilt = 0,
		},
		Nose = {
			Enabled = true,
			Width = 6.5,
			Height = 24,
			OffsetY = -1,
			Hook = 8,
		},
		Mouth = {
			Enabled = true,
			Width = 38,
			Height = 10,
			OffsetY = 27,
			Thickness = 6.5,
			Curve = 0.85,
		},
	},

	Scan = {
		Enabled = true,
		Color = "8CFFAB",
		Thickness = 2.5,
		BandHeight = 34,
		Duration = 1.15,
		Delay = 0.05,
		Glow = true,
		GlowTransparency = 0.75,
		Easing = "sineInOut",
		RepeatCount = 0,
	},

	Halo = {
		Enabled = true,
		Color = "34C759",
		Layers = 6,
		Radius = 64,
		Thickness = 3,
		Transparency = 0.45,
		Spread = 0.6,
		Pulse = true,
	},

	Caption = {
		Enabled = false,
		Text = "Face ID",
		Color = "FFFFFF",
		Size = 13,
		Font = "GothamMedium",
		OffsetY = 14,
		Transparency = 0.15,
		Shadow = true,
	},

	Animation = {
		FadeIn = 0.55,
		FadeInScaleFrom = 0.86,
		FadeInRise = 10,
		Easing = "backOut",
		FadeOut = 0.62,
		FadeOutScaleTo = 1.08,
		FadeOutRise = -8,
		FadeOutEasing = "cubicInOut",
		HoldAfterScan = 0.18,
		SuccessHold = 0.55,
		FailHold = 0.45,
		ShakeStrength = 9,
		ShakeDuration = 0.42,
		SuccessPulse = 1.06,
		Typing = false,
	},

	Sound = {
		Enabled = false,
		SuccessSoundId = "",
		FailSoundId = "",
		ScanSoundId = "",
		Volume = 0.5,
	},

	Behavior = {
		ModalDim = false,
		DimColor = "000000",
		DimTransparency = 0.55,
		DestroyOnComplete = false,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	},

	AutoExec = {
		Enabled = false,
		When = "Instant",
		Delay = 0,
		Source = nil,
		Module = nil,
		Function = nil,
		ChunkName = "FaceIDAutoExec",
		RunOnce = true,
		Silent = false,
		Sandbox = false,
		Env = nil,
	},

	Callbacks = {
		OnReady = nil,
		OnShown = nil,
		OnScanStart = nil,
		OnScanComplete = nil,
		OnSuccess = nil,
		OnFail = nil,
		OnHidden = nil,
		OnComplete = nil,
		OnError = nil,
	},

	Debug = false,
}

Config.flatAliases = {

	Size = { "Panel", "Size" },
	Width = { "Panel", "Size" },
	Height = { "Panel", "Size" },
	CornerRadius = { "Panel", "CornerRadius" },
	Radius = { "Panel", "CornerRadius" },
	Transparency = { "Panel", "Transparency" },
	BackgroundColor = { "Panel", "Color" },
	BgColor = { "Panel", "Color" },
	PanelColor = { "Panel", "Color" },

	Color = { "Face", "Color" },
	Accent = { "Face", "Color" },
	AccentColor = { "Face", "Color" },
	IconColor = { "Face", "Color" },
	LineWidth = { "Face", "StrokeWidth" },
	StrokeWidth = { "Face", "StrokeWidth" },

	ScanColor = { "Scan", "Color" },
	ScanDuration = { "Scan", "Duration" },

	HaloColor = { "Halo", "Color" },

	Text = { "Caption", "Text" },
	CaptionText = { "Caption", "Text" },
	ShowText = { "Caption", "Enabled" },

	SoundEnabled = { "Sound", "Enabled" },

	X = { "Position", "X" },
	Y = { "Position", "Y" },
}

function Config.applyFlatAliases(input)
	if type(input) ~= "table" then
		return {}
	end
	local output = {}
	for key, value in pairs(input) do
		local target = Config.flatAliases[key]
		if target then
			local group = target[1]
			local field = target[2]
			output[group] = output[group] or {}

			local grouped = input[group]
			if type(grouped) ~= "table" or grouped[field] == nil then
				output[group][field] = value
			end
		else
			output[key] = value
		end
	end
	return output
end

local function num(value, default, minValue, maxValue)
	value = tonumber(value)
	if value == nil then
		return default
	end
	if minValue ~= nil and value < minValue then
		value = minValue
	end
	if maxValue ~= nil and value > maxValue then
		value = maxValue
	end
	return value
end

local function bool(value, default)
	if value == nil then
		return default
	end
	if type(value) == "boolean" then
		return value
	end
	if type(value) == "string" then
		local lower = STRING_LOWER(value)
		if lower == "true" or lower == "1" or lower == "on" or lower == "yes" then
			return true
		elseif lower == "false" or lower == "0" or lower == "off" or lower == "no" then
			return false
		end
	end
	if type(value) == "number" then
		return value ~= 0
	end
	return default
end

Config.bool = bool
Config.num = num

function Config.resolve(userInput, base)
	local input = Config.applyFlatAliases(userInput or {})

	local themeName = input.Theme
	if themeName == nil and base and base.Theme then
		themeName = base.Theme
	end
	themeName = themeName or FaceIDLib._defaultTheme
	local themeData = Theme.get(themeName)
	if type(themeName) ~= "string" then
		themeName = FaceIDLib._defaultTheme
	end

	local resolved = Util.deepMerge(Config.defaults, themeData or {})
	if base then
		resolved = Util.deepMerge(resolved, base)
	end
	resolved = Util.deepMerge(resolved, input)

	resolved.Theme = themeName

	resolved.Panel.Color = Color.parse(resolved.Panel.Color, Color.palette.black)
	resolved.Panel.StrokeColor = Color.parse(resolved.Panel.StrokeColor, Color.palette.white)
	resolved.Panel.ShadowColor = Color.parse(resolved.Panel.ShadowColor, Color.palette.black)
	resolved.Face.Color = Color.parse(resolved.Face.Color, Color.palette.systemGreen)
	resolved.Face.ColorBright = Color.parse(resolved.Face.ColorBright, Color.lighten(resolved.Face.Color, 0.35))
	resolved.Face.ColorDim = Color.parse(resolved.Face.ColorDim, Color.darken(resolved.Face.Color, 0.45))
	resolved.Scan.Color = Color.parse(resolved.Scan.Color, Color.lighten(resolved.Face.Color, 0.5))
	resolved.Halo.Color = Color.parse(resolved.Halo.Color, resolved.Face.Color)
	resolved.Caption.Color = Color.parse(resolved.Caption.Color, Color.palette.white)
	resolved.Behavior.DimColor = Color.parse(resolved.Behavior.DimColor, Color.palette.black)
	if type(resolved.Fail) == "table" then
		resolved.Fail.Color = Color.parse(resolved.Fail.Color, Color.palette.failRed)
	end

	local panel = resolved.Panel
	panel.Size = num(panel.Size, 152, 48, 1024)
	panel.CornerRadius = num(panel.CornerRadius, 40, 0, panel.Size / 2)
	panel.Transparency = Util.clamp01(num(panel.Transparency, 0.04))
	panel.StrokeThickness = num(panel.StrokeThickness, 0, 0, 24)
	panel.StrokeTransparency = Util.clamp01(num(panel.StrokeTransparency, 0.9))
	panel.ShadowSpread = num(panel.ShadowSpread, 10, 0, 80)
	panel.ShadowTransparency = Util.clamp01(num(panel.ShadowTransparency, 0.55))
	panel.Padding = num(panel.Padding, 0, -100, 200)

	local face = resolved.Face
	face.StrokeWidth = num(face.StrokeWidth, 5.4, 0.5, 24)
	face.Transparency = Util.clamp01(num(face.Transparency, 0))
	face.DimTransparency = Util.clamp01(num(face.DimTransparency, 0.10))
	face.IconSize = num(face.IconSize, 100, 40, 400)
	face.IconScale = num(face.IconScale, 0.64, 0.2, 1.2)
	face.Lighting = bool(face.Lighting, true)

	face.Brackets.Length = num(face.Brackets.Length, 21, 4, 48)
	face.Brackets.Thickness = num(face.Brackets.Thickness, 7.5, 0.5, 20)
	face.Brackets.Inset = num(face.Brackets.Inset, 0, -20, 30)
	face.Brackets.Corner = num(face.Brackets.Corner, 0, 0, 40)
	face.Brackets.VerticalScale = num(face.Brackets.VerticalScale, 1, 0.2, 3)

	face.Eyes.Width = num(face.Eyes.Width, 6.5, 0.5, 20)
	face.Eyes.Height = num(face.Eyes.Height, 15, 2, 40)
	face.Eyes.OffsetX = num(face.Eyes.OffsetX, 21, 0, 48)
	face.Eyes.OffsetY = num(face.Eyes.OffsetY, -10, -48, 48)
	face.Eyes.Tilt = num(face.Eyes.Tilt, 0, -45, 45)

	face.Nose.Width = num(face.Nose.Width, 6.5, 0.5, 20)
	face.Nose.Height = num(face.Nose.Height, 24, 0, 40)
	face.Nose.OffsetY = num(face.Nose.OffsetY, -1, -48, 48)
	face.Nose.Hook = num(face.Nose.Hook, 8, 0, 30)

	face.Mouth.Width = num(face.Mouth.Width, 38, 6, 96)
	face.Mouth.Height = num(face.Mouth.Height, 10, 0.5, 40)
	face.Mouth.OffsetY = num(face.Mouth.OffsetY, 27, -48, 60)
	face.Mouth.Thickness = num(face.Mouth.Thickness, 6.5, 0.5, 20)
	face.Mouth.Curve = num(face.Mouth.Curve, 0.85, -1.4, 1.4)

	local scan = resolved.Scan
	scan.Thickness = num(scan.Thickness, 2.5, 0.5, 16)
	scan.BandHeight = num(scan.BandHeight, 34, 0, 200)
	scan.Duration = num(scan.Duration, 1.15, 0.15, 12)
	scan.Delay = num(scan.Delay, 0.05, 0, 12)
	scan.RepeatCount = num(scan.RepeatCount, 0, 0, 50)
	scan.Glow = bool(scan.Glow, true)
	scan.GlowTransparency = Util.clamp01(num(scan.GlowTransparency, 0.75))

	local halo = resolved.Halo
	halo.Layers = num(halo.Layers, 6, 0, 24)
	halo.Radius = num(halo.Radius, 64, 10, 260)
	halo.Thickness = num(halo.Thickness, 3, 0.5, 20)
	halo.Transparency = Util.clamp01(num(halo.Transparency, 0.45))
	halo.Spread = num(halo.Spread, 0.6, 0, 3)
	halo.Pulse = bool(halo.Pulse, true)

	local caption = resolved.Caption
	caption.Size = num(caption.Size, 13, 6, 72)
	caption.OffsetY = num(caption.OffsetY, 14, -50, 120)
	caption.Transparency = Util.clamp01(num(caption.Transparency, 0.15))
	caption.Text = tostring(caption.Text or "")
	caption.Enabled = bool(caption.Enabled, false)

	local anim = resolved.Animation
	anim.FadeIn = num(anim.FadeIn, 0.55, 0, 12)
	anim.FadeOut = num(anim.FadeOut, 0.62, 0, 12)
	anim.FadeInScaleFrom = num(anim.FadeInScaleFrom, 0.86, 0.1, 3)
	anim.FadeOutScaleTo = num(anim.FadeOutScaleTo, 1.08, 0.1, 3)
	anim.FadeInRise = num(anim.FadeInRise, 10, -200, 200)
	anim.FadeOutRise = num(anim.FadeOutRise, -8, -200, 200)
	anim.HoldAfterScan = num(anim.HoldAfterScan, 0.18, 0, 6)
	anim.SuccessHold = num(anim.SuccessHold, 0.55, 0, 6)
	anim.FailHold = num(anim.FailHold, 0.45, 0, 6)
	anim.ShakeStrength = num(anim.ShakeStrength, 9, 0, 80)
	anim.ShakeDuration = num(anim.ShakeDuration, 0.42, 0.05, 4)
	anim.SuccessPulse = num(anim.SuccessPulse, 1.06, 0.8, 1.5)

	resolved.Scale = num(resolved.Scale, 1, 0.2, 4)
	resolved.DisplayOrder = num(resolved.DisplayOrder, 9999, -10000, 100000)
	resolved.AutoScale = bool(resolved.AutoScale, true)

	local sound = resolved.Sound
	sound.Volume = num(sound.Volume, 0.5, 0, 10)
	sound.Enabled = bool(sound.Enabled, false)

	local behavior = resolved.Behavior
	behavior.ModalDim = bool(behavior.ModalDim, false)
	behavior.DimTransparency = Util.clamp01(num(behavior.DimTransparency, 0.55))
	behavior.DestroyOnComplete = bool(behavior.DestroyOnComplete, false)
	behavior.ResetOnSpawn = bool(behavior.ResetOnSpawn, false)

	local auto = resolved.AutoExec
	if type(auto) == "string" then
		auto = { Enabled = true, Source = auto }
		resolved.AutoExec = auto
	end
	auto.Enabled = bool(auto.Enabled, false)
	auto.Delay = num(auto.Delay, 0, 0, 600)
	auto.RunOnce = bool(auto.RunOnce, true)
	auto.Silent = bool(auto.Silent, false)
	auto.When = tostring(auto.When or "Instant")
	if auto.When ~= "Instant" and auto.When ~= "AfterShow" and auto.When ~= "AfterComplete" then
		auto.When = "Instant"
	end

	resolved.Debug = bool(resolved.Debug, false)

	return resolved
end

function Config.validate(resolved)
	local problems = {}
	if resolved.Panel.Size < 60 then
		TABLE_INSERT(problems, "Panel.Size is too small; the icon may not be visible")
	end
	if resolved.Panel.CornerRadius > resolved.Panel.Size / 2 then
		TABLE_INSERT(problems, "Panel.CornerRadius exceeds half of the panel size; it will be clamped to a circle")
	end
	if resolved.Face.StrokeWidth >= resolved.Face.IconSize / 6 then
		TABLE_INSERT(problems, "Face.StrokeWidth is too thick; the facial features will blur together")
	end
	if resolved.Scan.Duration <= 0 then
		TABLE_INSERT(problems, "Scan.Duration must be greater than 0")
	end
	return problems
end

function Config.describe(resolved)
	local lines = {}
	TABLE_INSERT(lines, STRING_FORMAT("Theme = %s", tostring(resolved.Theme)))
	TABLE_INSERT(lines, STRING_FORMAT("Panel = %dpx / radius %d / transparency %.2f", resolved.Panel.Size, resolved.Panel.CornerRadius, resolved.Panel.Transparency))
	TABLE_INSERT(lines, STRING_FORMAT("Icon color = %s / stroke width %.1f", Color.describe(resolved.Face.Color), resolved.Face.StrokeWidth))
	TABLE_INSERT(lines, STRING_FORMAT("Timeline = fade in %.2fs / scan %.2fs / fade out %.2fs", resolved.Animation.FadeIn, resolved.Scan.Duration, resolved.Animation.FadeOut))
	return TABLE_CONCAT(lines, "\n")
end

Components.Z = {
	Halo = 2,
	Shadow = 3,
	Panel = 4,
	Face = 10,
	ScanBand = 24,
	ScanLine = 25,
	Caption = 30,
}

function Components.iconContext(parent, side, cfg)
	return {
		parent = parent,
		cx = side / 2,
		cy = side / 2,
		s = side / cfg.Face.IconSize,
		cfg = cfg,
		top = -cfg.Face.IconSize / 2,
		bottom = cfg.Face.IconSize / 2,
	}
end

local function X(ctx, x)
	return ctx.cx + x * ctx.s
end

local function Y(ctx, y)
	return ctx.cy + y * ctx.s
end

local function L(ctx, value)
	return value * ctx.s
end

local function recordStroke(list, frame, yDesign, ctx, kind)
	if not frame then
		return
	end
	local height = ctx.bottom - ctx.top
	local t = 0
	if height ~= 0 then
		t = (yDesign - ctx.top) / height
	end
	TABLE_INSERT(list, {
		frame = frame,
		t = Util.clamp(t, -0.25, 1.25),
		kind = kind or "stroke",
	})
end

local function recordStrokes(list, frames, yDesign, ctx, kind)
	for i = 1, #frames do
		recordStroke(list, frames[i], yDesign, ctx, kind)
	end
end

function Components.buildPanel(container, cfg)
	local panelCfg = cfg.Panel
	local size = panelCfg.Size

	local group = {}

	if panelCfg.ShadowEnabled then
		local shadow = Draw.panel(
			container,
			{ size + panelCfg.ShadowSpread * 2, size + panelCfg.ShadowSpread * 2 },
			panelCfg.CornerRadius + panelCfg.ShadowSpread,
			panelCfg.ShadowColor,
			panelCfg.ShadowTransparency,
			Components.Z.Shadow,
			"FaceIDShadow"
		)
		shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow.Position = UDim2.fromScale(0.5, 0.5)
		group.shadow = shadow
	end

	local panel = Draw.panel(
		container,
		{ size, size },
		panelCfg.CornerRadius,
		panelCfg.Color,
		panelCfg.Transparency,
		Components.Z.Panel,
		"FaceIDPanel"
	)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.ClipsDescendants = false
	group.panel = panel

	if panelCfg.Transparency < 0.95 then
		local sheen = Instance.new("Frame")
		sheen.Name = "Sheen"
		sheen.AnchorPoint = Vector2.new(0.5, 0.5)
		sheen.Size = UDim2.fromScale(1, 1)
		sheen.Position = UDim2.fromScale(0.5, 0.5)
		sheen.BackgroundTransparency = 1
		sheen.BorderSizePixel = 0
		sheen.ZIndex = Components.Z.Panel + 1
		sheen.Parent = panel

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, panelCfg.CornerRadius)
		corner.Parent = sheen

		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82),
			NumberSequenceKeypoint.new(0.35, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Color = ColorSequence.new(Color.lighten(panelCfg.Color, 0.35))
		gradient.Parent = sheen
		group.sheen = sheen
	end

	if panelCfg.StrokeThickness > 0 and panelCfg.StrokeTransparency < 1 then
		group.stroke = Draw.stroke(
			panel,
			panelCfg.StrokeThickness,
			panelCfg.StrokeColor,
			panelCfg.StrokeTransparency,
			Components.Z.Panel + 2
		)
	end

	return group
end

function Components.buildFace(container, side, cfg)
	local faceCfg = cfg.Face
	local ctx = Components.iconContext(container, side, cfg)
	local strokes = {}
	local parts = {}

	local color = faceCfg.Color
	local dim = faceCfg.ColorDim
	local width = faceCfg.StrokeWidth
	local z = Components.Z.Face

	local half = faceCfg.IconSize / 2

	if faceCfg.Brackets.Enabled then
		local bracketLength = faceCfg.Brackets.Length
		local thickness = faceCfg.Brackets.Thickness * (faceCfg.StrokeWidth / 5.4)
		local inset = faceCfg.Brackets.Inset
		local l = half - inset
		local cornerR = faceCfg.Brackets.Corner
		if not cornerR or cornerR <= 0 then
			cornerR = bracketLength * 0.58
		end
		cornerR = MIN(cornerR, MIN(l * 0.92, bracketLength * 0.92))
		if cornerR < 0.5 then
			cornerR = 0.5
		end
		local verticalScale = faceCfg.Brackets.VerticalScale or 1
		local armH = MAX(bracketLength - cornerR, 1.2)
		local armV = MAX(bracketLength * verticalScale - cornerR, 1.2)
		local bracketFrames = {}

		local cornerDefs = {
			{ sx = -1, sy = -1, a0 = 180, a1 = 270 },
			{ sx = 1, sy = -1, a0 = 270, a1 = 360 },
			{ sx = -1, sy = 1, a0 = 90, a1 = 180 },
			{ sx = 1, sy = 1, a0 = 0, a1 = 90 },
		}

		for index = 1, #cornerDefs do
			local def = cornerDefs[index]
			local sx = def.sx
			local sy = def.sy
			local arcCx = sx * (l - cornerR)
			local arcCy = sy * (l - cornerR)

			local arcFrames = Draw.arc(
				container,
				X(ctx, arcCx),
				Y(ctx, arcCy),
				L(ctx, cornerR),
				def.a0,
				def.a1,
				L(ctx, thickness),
				nil,
				color,
				faceCfg.DimTransparency,
				z,
				"BracketArc" .. tostring(index)
			)
			for k = 1, #arcFrames do
				TABLE_INSERT(bracketFrames, arcFrames[k])
			end
			recordStrokes(strokes, arcFrames, sy * (l - cornerR * 0.35), ctx, "bracket")

			local hFrame = Draw.between(
				container,
				X(ctx, arcCx),
				Y(ctx, sy * l),
				X(ctx, arcCx - sx * armH),
				Y(ctx, sy * l),
				L(ctx, thickness),
				color,
				faceCfg.DimTransparency,
				z,
				"BracketH" .. tostring(index)
			)
			TABLE_INSERT(bracketFrames, hFrame)
			recordStroke(strokes, hFrame, sy * l, ctx, "bracket")

			local vFrame = Draw.between(
				container,
				X(ctx, sx * l),
				Y(ctx, arcCy),
				X(ctx, sx * l),
				Y(ctx, arcCy - sy * armV),
				L(ctx, thickness),
				color,
				faceCfg.DimTransparency,
				z,
				"BracketV" .. tostring(index)
			)
			TABLE_INSERT(bracketFrames, vFrame)
			recordStroke(strokes, vFrame, sy * (l - cornerR) - sy * armV * 0.5, ctx, "bracket")
		end

		parts.brackets = bracketFrames
	end

	if faceCfg.Eyes.Enabled then
		local eyeCfg = faceCfg.Eyes
		local eyeFrames = {}
		for _, direction in ipairs({ -1, 1 }) do
			local eyeX = direction * eyeCfg.OffsetX
			local eyeY = eyeCfg.OffsetY
			local tilt = direction * (eyeCfg.Tilt or 0)
			local frame = Draw.line(
				container,
				X(ctx, eyeX),
				Y(ctx, eyeY),
				L(ctx, eyeCfg.Height),
				L(ctx, eyeCfg.Width),
				90 + tilt,
				color,
				faceCfg.DimTransparency,
				z,
				"Eye" .. (direction < 0 and "L" or "R")
			)
			TABLE_INSERT(eyeFrames, frame)
			recordStroke(strokes, frame, eyeY, ctx, "eye")
		end
		parts.eyes = eyeFrames
	end

	if faceCfg.Nose.Enabled and faceCfg.Nose.Height > 0 then
		local noseCfg = faceCfg.Nose
		local topY = noseCfg.OffsetY - noseCfg.Height / 2
		local bottomY = noseCfg.OffsetY + noseCfg.Height / 2
		local noseFrames = {}

		local stem = Draw.between(
			container,
			X(ctx, 0),
			Y(ctx, topY),
			X(ctx, 0),
			Y(ctx, bottomY),
			L(ctx, noseCfg.Width),
			color,
			faceCfg.DimTransparency,
			z,
			"NoseStem"
		)
		TABLE_INSERT(noseFrames, stem)
		recordStroke(strokes, stem, noseCfg.OffsetY, ctx, "nose")

		local hook = noseCfg.Hook
		if hook > 1 then
			hook = MIN(hook, noseCfg.Height + 2)
			local hookCy = bottomY - hook
			local hookFrames = Draw.arc(
				container,
				X(ctx, 0),
				Y(ctx, hookCy),
				L(ctx, hook),
				0,
				90,
				L(ctx, noseCfg.Width),
				7,
				color,
				faceCfg.DimTransparency,
				z,
				"NoseHook"
			)
			recordStrokes(strokes, hookFrames, bottomY, ctx, "nose")
			parts.noseHook = hookFrames
		end
		parts.nose = noseFrames
	end

	if faceCfg.Mouth.Enabled and faceCfg.Mouth.Height > 0 then
		local mouthCfg = faceCfg.Mouth
		local curve = Util.clamp(mouthCfg.Curve, -1, 1)
		local strength = ABS(curve)
		if strength < 0.08 then
			strength = 0.08
		end
		local chord = MAX(mouthCfg.Width, 2)
		local sag = MAX(mouthCfg.Height * strength, 0.6)
		local radius = (sag * sag + (chord * chord) / 4) / (2 * sag)
		local spreadDeg = DEG(math.asin(MIN(1, (chord / 2) / radius)))
		local mouthFrames

		if curve >= 0 then
			local bottomY = mouthCfg.OffsetY + sag / 2
			local centerY = bottomY - radius
			mouthFrames = Draw.arc(
				container,
				X(ctx, 0),
				Y(ctx, centerY),
				L(ctx, radius),
				90 - spreadDeg,
				90 + spreadDeg,
				L(ctx, mouthCfg.Thickness),
				nil,
				color,
				faceCfg.DimTransparency,
				z,
				"Mouth"
			)
			recordStrokes(strokes, mouthFrames, bottomY - sag * 0.4, ctx, "mouth")
		else

			local topY = mouthCfg.OffsetY - sag / 2
			local centerY = topY + radius
			mouthFrames = Draw.arc(
				container,
				X(ctx, 0),
				Y(ctx, centerY),
				L(ctx, radius),
				270 - spreadDeg,
				270 + spreadDeg,
				L(ctx, mouthCfg.Thickness),
				nil,
				color,
				faceCfg.DimTransparency,
				z,
				"Mouth"
			)
			recordStrokes(strokes, mouthFrames, topY + sag * 0.4, ctx, "mouth")
		end

		parts.mouth = mouthFrames
	end

	return {
		ctx = ctx,
		strokes = strokes,
		parts = parts,
		container = container,
	}
end

function Components.buildScanline(container, side, cfg)
	local scanCfg = cfg.Scan
	local iconSize = cfg.Face.IconSize
	local scale = side / iconSize

	local lineWidth = side * 1.28
	local line = Draw.gradientBar(
		container,
		lineWidth,
		MAX(1, scanCfg.Thickness * scale),
		scanCfg.Color,
		0.05,
		0,
		Components.Z.ScanLine,
		"FaceIDScanLine"
	)
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Visible = false

	local band = Draw.softBar(
		container,
		lineWidth,
		MAX(2, scanCfg.BandHeight * scale),
		scanCfg.Color,
		scanCfg.Glow and 0.82 or 1,
		Components.Z.ScanBand
	)
	band.AnchorPoint = Vector2.new(0.5, 0.5)
	band.Position = UDim2.fromScale(0.5, 0.5)
	band.Visible = false

	if not scanCfg.Glow then
		band.BackgroundTransparency = 1
	end

	local api = {
		line = line,
		band = band,
		scale = scale,
		height = side,
	}

	function api.setProgress(progress)
		local y = -1 + progress * 2
		local pixel = (y * side) / 2
		line.Position = UDim2.new(0.5, 0, 0.5, pixel)
		band.Position = UDim2.new(0.5, 0, 0.5, pixel)
	end

	function api.setVisible(visible)
		line.Visible = visible
		band.Visible = visible and scanCfg.Glow or false
	end

	function api.setTransparency(alpha)
		if line and line.Parent then
			line.BackgroundTransparency = alpha
		end
		if band and band.Parent and scanCfg.Glow then
			band.BackgroundTransparency = Util.clamp(alpha + 0.35, 0, 1)
		end
	end

	return api
end

function Components.buildHalo(container, side, cfg)
	local haloCfg = cfg.Halo
	local scale = side / cfg.Face.IconSize
	local radius = haloCfg.Radius * scale
	local thickness = MAX(1, haloCfg.Thickness * scale)

	local holder = Instance.new("Frame")
	holder.Name = "FaceIDHalo"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(side * 2.4, side * 2.4)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = Components.Z.Halo
	holder.Parent = container

	local center = side * 1.2
	local frames = Draw.glow(
		holder,
		center,
		center,
		radius,
		haloCfg.Color,
		MAX(1, haloCfg.Layers),
		Components.Z.Halo,
		haloCfg.Transparency,
		haloCfg.Spread
	)

	local api = {
		holder = holder,
		frames = frames,
		radius = radius,
		scale = scale,
	}

	function api.setTransparency(alpha)
		for i = 1, #frames do
			local frame = frames[i]
			if frame and frame.Parent then
				local stroke = frame:FindFirstChildOfClass("UIStroke")
				if stroke then
					local base = 0.35 + (i / MAX(1, #frames)) * 0.5
					stroke.Transparency = Util.clamp(alpha + base * 0.65, 0, 1)
				end
			end
		end
	end

	function api.setScale(multiplier)
		for i = 1, #frames do
			local frame = frames[i]
			if frame and frame.Parent then
				local baseRadius = frame.Size.X.Offset / 2
				frame.Size = UDim2.fromOffset(baseRadius * 2 * multiplier, baseRadius * 2 * multiplier)
			end
		end
	end

	return api
end

function Components.buildCaption(container, side, cfg)
	local captionCfg = cfg.Caption

	local label = Draw.text(container, {
		Name = "FaceIDCaption",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, captionCfg.OffsetY),
		Size = UDim2.fromOffset(side * 1.8, captionCfg.Size + 10),
		Text = captionCfg.Text,
		Font = Util.toFont(captionCfg.Font, Enum.Font.GothamMedium),
		TextColor3 = captionCfg.Color,
		TextSize = captionCfg.Size,
		TextTransparency = captionCfg.Transparency,
		ZIndex = Components.Z.Caption,
		Shadow = captionCfg.Shadow,
		ShadowTransparency = 0.75,
	})

	label.Visible = captionCfg.Enabled
	return label
end

function Components.buildDim(container, cfg)
	local behavior = cfg.Behavior
	local dim = Instance.new("Frame")
	dim.Name = "FaceIDDim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.Position = UDim2.fromScale(0, 0)
	dim.BackgroundColor3 = behavior.DimColor
	dim.BackgroundTransparency = behavior.DimTransparency
	dim.BorderSizePixel = 0
	dim.ZIndex = 1
	dim.Visible = behavior.ModalDim
	dim.Parent = container
	return dim
end

local STATE = {
	HIDDEN = "hidden",
	SHOWING = "showing",
	SCANNING = "scanning",
	SUCCESS = "success",
	FAILED = "failed",
	HIDING = "hiding",
}

FaceIDLib.State = STATE

function FaceIDLib.new(userConfig)
	local self = setmetatable({}, FaceIDLib)
	local ok, reason = FaceIDLib.isSupported()
	if not ok then
		error("[FaceIDLib] " .. tostring(reason), 2)
	end
	self:_init(userConfig)
	return self
end

function FaceIDLib:_init(userConfig)
	self._userConfig = Util.deepCopy(userConfig or {})
	self._cfg = Config.resolve(self._userConfig)

	self._state = STATE.HIDDEN
	self._destroyed = false
	self._alpha = 0
	self._scanProgress = -1
	self._animScale = 1
	self._mode = "normal"
	self._serial = 0
	self._autoExecRan = false
	self._lastError = nil
	self._sounds = {}
	self._timers = {}
	self._connections = {}
	self._children = {}
	self._visibleOnce = false

	self.OnReady = Signal.new()
	self.OnShown = Signal.new()
	self.OnScanStart = Signal.new()
	self.OnScanComplete = Signal.new()
	self.OnSuccess = Signal.new()
	self.OnFail = Signal.new()
	self.OnHidden = Signal.new()
	self.OnComplete = Signal.new()
	self.OnError = Signal.new()

	self:_createGui()
	self:_build()
	self:_bindCallbacks()
	self:_bindViewport()

	if self._cfg.Debug then
		print("[FaceIDLib] Initialized\n" .. Config.describe(self._cfg))
	end

	self.OnReady:Fire(self)

	if self._cfg.AutoExec.Enabled and self._cfg.AutoExec.When == "Instant" then
		self:_runAutoExec("Instant")
	end
end

function FaceIDLib:_createGui()
	local cfg = self._cfg
	local parent = cfg.Parent
	local player = Players.LocalPlayer

	self._ownsGui = false
	self._host = nil

	if parent and typeof(parent) == "Instance" and parent:IsA("ScreenGui") then
		self._gui = parent
		self._host = parent
		local dimOrRoot = parent:FindFirstChild("FaceIDRoot")
		if dimOrRoot then
			dimOrRoot:Destroy()
		end
	elseif parent and typeof(parent) == "Instance" and parent:IsA("GuiObject") then
		self._gui = parent
		self._host = parent
	else
		local gui = Instance.new("ScreenGui")
		gui.Name = cfg.Name
		gui.ResetOnSpawn = cfg.Behavior.ResetOnSpawn
		gui.IgnoreGuiInset = cfg.IgnoreGuiInset
		gui.DisplayOrder = cfg.DisplayOrder
		gui.ZIndexBehavior = cfg.Behavior.ZIndexBehavior
		gui.Enabled = true

		local ok = pcall(function()
			gui.Parent = parent or player:WaitForChild("PlayerGui", 10)
		end)
		if not ok or not gui.Parent then
			local playerGui = player:FindFirstChildOfClass("PlayerGui")
			if playerGui then
				gui.Parent = playerGui
			else
				error("[FaceIDLib] PlayerGui not found; cannot create the UI", 2)
			end
		end
		self._gui = gui
		self._host = gui
		self._ownsGui = true
	end
end

function FaceIDLib:_build()
	local cfg = self._cfg
	local host = self._host

	self._dim = Components.buildDim(host, cfg)

	local root = Instance.new("Frame")
	root.Name = "FaceIDRoot"
	root.AnchorPoint = cfg.AnchorPoint or Vector2.new(0.5, 0)
	root.Size = UDim2.fromOffset(cfg.Panel.Size, cfg.Panel.Size)
	root.Position = cfg.Position
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ClipsDescendants = false
	root.Visible = false
	root.ZIndex = Components.Z.Panel
	root.Parent = host
	self._root = root

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = self:_computeScale()
	uiScale.Parent = root
	self._uiScale = uiScale

	if cfg.Halo.Enabled then
		self._halo = Components.buildHalo(root, cfg.Panel.Size, cfg)
		self._halo.setTransparency(1)
	end

	self._panelGroup = Components.buildPanel(root, cfg)
	self._panel = self._panelGroup.panel
	self._shadow = self._panelGroup.shadow

	local padding = cfg.Panel.Padding
	local iconSide = MAX(24, cfg.Panel.Size * (cfg.Face.IconScale or 0.64) - padding * 2)
	local iconGroup = Instance.new("Frame")
	iconGroup.Name = "FaceIDIcon"
	iconGroup.AnchorPoint = Vector2.new(0.5, 0.5)
	iconGroup.Position = UDim2.fromScale(0.5, 0.5)
	iconGroup.Size = UDim2.fromOffset(iconSide, iconSide)
	iconGroup.BackgroundTransparency = 1
	iconGroup.BorderSizePixel = 0
	iconGroup.ClipsDescendants = false
	iconGroup.ZIndex = Components.Z.Face
	iconGroup.Parent = root
	self._iconGroup = iconGroup

	self._face = Components.buildFace(iconGroup, iconSide, cfg)

	if cfg.Scan.Enabled then
		self._scan = Components.buildScanline(iconGroup, iconSide, cfg)
		self._scan.setVisible(false)
	end

	self._caption = Components.buildCaption(root, cfg.Panel.Size, cfg)
	if not cfg.Caption.Enabled then
		self._caption.Visible = false
	end

	self:_render(0, -1, "normal", 0)
	if self._panel then
		self._panel.BackgroundTransparency = 1
	end

	self._panelBaseTransparency = cfg.Panel.Transparency
	if self._panelGroup.stroke then
		self._strokeBase = cfg.Panel.StrokeTransparency
	end
end

function FaceIDLib:_bindCallbacks()
	local callbacks = self._cfg.Callbacks or {}
	local map = {
		OnReady = self.OnReady,
		OnShown = self.OnShown,
		OnScanStart = self.OnScanStart,
		OnScanComplete = self.OnScanComplete,
		OnSuccess = self.OnSuccess,
		OnFail = self.OnFail,
		OnHidden = self.OnHidden,
		OnComplete = self.OnComplete,
		OnError = self.OnError,
	}
	for name, signal in pairs(map) do
		local fn = callbacks[name]
		if type(fn) == "function" then
			local conn = signal:Connect(fn)
			TABLE_INSERT(self._connections, conn)
		end
	end
end

function FaceIDLib:_bindViewport()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local conn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if self._destroyed or not self._uiScale then
			return
		end
		self._uiScale.Scale = self:_computeScale()
	end)
	TABLE_INSERT(self._connections, conn)
end

function FaceIDLib:_computeScale()
	local cfg = self._cfg
	local base = cfg.Scale or 1
	if cfg.AutoScale then
		local viewport = Util.getViewport()
		local factor = viewport.X / 900
		factor = Util.clamp(factor, 0.72, 1.12)
		base = base * factor
	end
	return base * (self._animScale or 1)
end

function FaceIDLib:_refreshScale()
	if self._uiScale then
		self._uiScale.Scale = self:_computeScale()
	end
end

local function compose(alpha, target)
	if alpha <= 0 then
		return 1
	end
	if alpha >= 1 then
		return target
	end
	return 1 - (1 - target) * alpha
end

function FaceIDLib:_render(alpha, scan, mode, shake)
	if self._destroyed then
		return
	end
	local cfg = self._cfg
	alpha = Util.clamp01(alpha or 0)
	scan = scan or -1
	mode = mode or "normal"

	if self._root then
		local base = cfg.Position
		local rise = self._riseOffset or 0
		self._root.Position = UDim2.new(
			base.X.Scale,
			base.X.Offset + (shake or 0),
			base.Y.Scale,
			base.Y.Offset + rise
		)
		self._root.Visible = alpha > 0.001
	end

	self:_refreshScale()

	local panelCfg = cfg.Panel
	if self._panel then
		self._panel.BackgroundTransparency = compose(alpha, panelCfg.Transparency)
	end
	if self._shadow then
		self._shadow.BackgroundTransparency = compose(alpha, panelCfg.ShadowTransparency)
	end
	if self._panelGroup and self._panelGroup.stroke then
		self._panelGroup.stroke.Transparency = compose(alpha, panelCfg.StrokeTransparency)
	end
	if self._panelGroup and self._panelGroup.sheen then
		self._panelGroup.sheen.BackgroundTransparency = compose(alpha, 1)
	end

	local faceCfg = cfg.Face
	local failColor = Color.palette.failRed
	if type(cfg.Fail) == "table" then
		failColor = cfg.Fail.Color
	end

	local litColor = faceCfg.ColorBright
	local dimColor = faceCfg.ColorDim
	if mode == "fail" then
		litColor = failColor
		dimColor = Color.darken(failColor, 0.45)
	elseif mode == "success" then
		litColor = faceCfg.ColorBright
	end

	local strokes = self._face and self._face.strokes or {}
	for i = 1, #strokes do
		local item = strokes[i]
		local frame = item.frame
		if frame and frame.Parent then
			local lit = 0
			if mode == "success" or mode == "fail" then
				lit = 1
			elseif scan >= 2 then
				lit = 1
			elseif scan >= 0 and faceCfg.Lighting then
				lit = Util.smoothstep(item.t - 0.10, item.t + 0.02, scan)
			elseif scan >= 0 and not faceCfg.Lighting then
				lit = 1
			end

			local targetTransparency = Util.lerp(faceCfg.DimTransparency, faceCfg.Transparency, lit)
			frame.BackgroundTransparency = compose(alpha, targetTransparency)

			local color = Color.lerp(dimColor, litColor, lit)
			frame.BackgroundColor3 = color
		end
	end

	if self._caption then
		local captionCfg = cfg.Caption
		if captionCfg.Enabled then
			self._caption.Visible = alpha > 0.01
			self._caption.TextTransparency = compose(alpha, captionCfg.Transparency)
			self._caption.TextColor3 = captionCfg.Color
			if self._caption:FindFirstChild("Shadow") then
				self._caption.Shadow.TextTransparency = compose(alpha, 0.75)
			end
		else
			self._caption.Visible = false
		end
	end

	if self._halo then
		if alpha <= 0.01 then
			self._halo.holder.Visible = false
		else
			self._halo.holder.Visible = true
			self._halo.setTransparency(compose(1, 0) + (1 - alpha))
		end
	end

	if self._dim then
		self._dim.Visible = cfg.Behavior.ModalDim and alpha > 0.01
		self._dim.BackgroundTransparency = compose(alpha, cfg.Behavior.DimTransparency)
	end
end

function FaceIDLib:_startFlow()
	self._serial = self._serial + 1
	return self._serial
end

function FaceIDLib:_cancelled(serial)
	return self._destroyed or self._serial ~= serial
end

function FaceIDLib:_play(duration, easing, update)
	local serial = self._serial
	if duration <= 0 then
		update(1, 1)
		return true
	end
	local easingFn = Ease.get(easing)
	local start = os.clock()
	while true do
		if self:_cancelled(serial) then
			return false
		end
		local raw = (os.clock() - start) / duration
		if raw >= 1 then
			raw = 1
		end
		update(easingFn(raw), raw)
		if raw >= 1 then
			return true
		end
		task.wait()
	end
end

function FaceIDLib:_wait(seconds)
	local serial = self._serial
	if seconds <= 0 then
		return true
	end
	local start = os.clock()
	while os.clock() - start < seconds do
		if self:_cancelled(serial) then
			return false
		end
		task.wait()
	end
	return true
end

function FaceIDLib:Show(options)
	options = options or {}
	local serial = self:_startFlow()
	return self:_showInternal(serial, options)
end

function FaceIDLib:_showInternal(serial, options)
	options = options or {}
	local cfg = self._cfg
	local anim = cfg.Animation

	if self:_cancelled(serial) then
		return false
	end

	if self._state == STATE.SHOWING or self._state == STATE.SCANNING then
		self._alpha = 1
		self:_render(1, self._scanProgress, self._mode, 0)
		return true
	end

	self._state = STATE.SHOWING
	self._mode = "normal"
	self._scanProgress = -1
	self._riseOffset = anim.FadeInRise
	self:_render(0, -1, "normal", 0)

	local duration = options.Instant and 0 or (options.Duration or anim.FadeIn)
	local easing = options.Easing or anim.Easing
	self:_render(0, -1, "normal", 0)

	local completed = self:_play(duration, easing, function(alpha)
		self._alpha = alpha
		self._riseOffset = anim.FadeInRise * (1 - alpha)
		self._animScale = Util.lerp(anim.FadeInScaleFrom, 1, alpha)
		self:_render(alpha, -1, "normal", 0)
	end)

	self._riseOffset = 0
	self._animScale = 1
	self._alpha = 1
	self:_render(1, -1, "normal", 0)

	if self:_cancelled(serial) then
		return false
	end

	self._state = STATE.SCANNING
	self._visibleOnce = true
	self:_playSound(cfg.Sound.ScanSoundId)
	self.OnShown:Fire(self)

	if cfg.AutoExec.Enabled and cfg.AutoExec.When == "AfterShow" then
		self:_runAutoExec("AfterShow")
	end

	return true
end

function FaceIDLib:Hide(options)
	options = options or {}
	local serial = self:_startFlow()
	return self:_hideInternal(serial, options)
end

function FaceIDLib:_hideInternal(serial, options)
	options = options or {}
	local cfg = self._cfg
	local anim = cfg.Animation

	if self._state == STATE.HIDDEN or self._state == STATE.HIDING then
		return true
	end

	self._state = STATE.HIDING
	local duration = options.Instant and 0 or (options.Duration or anim.FadeOut)
	local easing = options.Easing or anim.FadeOutEasing
	local startScale = self._animScale or 1

	local completed = self:_play(duration, easing, function(alpha)
		local remaining = 1 - alpha
		self._alpha = remaining
		self._animScale = Util.lerp(startScale, anim.FadeOutScaleTo, alpha)
		self._riseOffset = anim.FadeOutRise * alpha
		self:_render(remaining, self._scanProgress, self._mode, 0)
	end)

	if self:_cancelled(serial) then
		return false
	end

	self._alpha = 0
	self._animScale = 1
	self._riseOffset = 0
	self._state = STATE.HIDDEN
	self._mode = "normal"
	self._scanProgress = -1
	self:_render(0, -1, "normal", 0)
	if self._root then
		self._root.Visible = false
	end
	if self._scan then
		self._scan.setVisible(false)
	end

	self.OnHidden:Fire(self)
	self.OnComplete:Fire(self, "hidden")

	if cfg.AutoExec.Enabled and cfg.AutoExec.When == "AfterComplete" then
		self:_runAutoExec("AfterComplete")
	end

	if cfg.Behavior.DestroyOnComplete then
		self:Destroy()
	end

	return true
end

function FaceIDLib:Scan(options)
	options = options or {}
	local serial = self:_startFlow()
	task.spawn(function()
		if self._state == STATE.HIDDEN or self._state == STATE.HIDING then
			self:_showInternal(serial)
		end
		self:_scanInternal(serial, options)
	end)
end

function FaceIDLib:_scanInternal(serial, options)
	options = options or {}
	local cfg = self._cfg
	local scanCfg = cfg.Scan
	local scanDuration = options.Duration or scanCfg.Duration
	local scanEasing = options.Easing or scanCfg.Easing

	if self:_cancelled(serial) then
		return false
	end
	if not scanCfg.Enabled then
		self._scanProgress = 2
		self:_render(self._alpha, 2, self._mode, 0)
		return true
	end

	self._state = STATE.SCANNING
	self._scanProgress = 0
	self:_render(self._alpha, 0, "normal", 0)

	if self._scan then
		self._scan.setProgress(0)
		self._scan.setVisible(true)
	end
	self.OnScanStart:Fire(self)

	if scanCfg.Delay > 0 then
		if not self:_wait(scanCfg.Delay) then
			return false
		end
	end

	local repeatCount = scanCfg.RepeatCount or 0
	local totalRuns = 1 + repeatCount

	for run = 1, totalRuns do
		local forward = true
		if run % 2 == 0 then
			forward = false
		end

		local ok = self:_play(scanDuration, scanEasing, function(alpha)
			local progress = alpha
			if not forward then
				progress = 1 - alpha
			end
			self._scanProgress = progress
			self:_render(self._alpha, progress, self._mode, 0)
			if self._scan then
				self._scan.setProgress(progress)
			end
		end)
		if not ok then
			return false
		end
	end

	self._scanProgress = 2
	self:_render(self._alpha, 2, self._mode, 0)

	if self._scan then
		local line = self._scan.line
		if line then
			local tween = TweenService:Create(line, TweenInfo.new(0.18), { BackgroundTransparency = 1 })
			tween:Play()
		end
		local band = self._scan.band
		if band then
			local tween = TweenService:Create(band, TweenInfo.new(0.18), { BackgroundTransparency = 1 })
			tween:Play()
		end
		task.delay(0.24, function()
			if self._scan and not self._destroyed then
				self._scan.setVisible(false)
				if self._scan.line then
					self._scan.line.BackgroundTransparency = 0.05
				end
				if self._scan.band then
					self._scan.band.BackgroundTransparency = cfg.Scan.Glow and 0.82 or 1
				end
			end
		end)
	end

	self.OnScanComplete:Fire(self)
	return true
end

function FaceIDLib:Success(options)
	options = options or {}
	local serial = self:_startFlow()
	task.spawn(function()
		self:_successInternal(serial, options)
	end)
end

function FaceIDLib:_successInternal(serial, options)
	options = options or {}
	local cfg = self._cfg
	local anim = cfg.Animation

	if self:_cancelled(serial) then
		return false
	end
	if self._state == STATE.HIDDEN then
		self:_showInternal(serial, { Instant = true })
	end

	self._state = STATE.SUCCESS
	self._mode = "success"
	self._scanProgress = 2
	self:_playSound(cfg.Sound.SuccessSoundId)

	local fromAlpha = self._alpha
	local pulse = options.Pulse ~= false and anim.SuccessPulse or 1

	self:_play(0.26, "cubicOut", function(alpha)
		self._alpha = Util.lerp(fromAlpha, 1, alpha)
		self._animScale = Util.lerp(1, pulse, alpha)
		self:_render(self._alpha, 2, "success", 0)
		if self._scan then
			self._scan.setVisible(false)
		end
	end)

	if self._halo and cfg.Halo.Pulse and cfg.Halo.Enabled then
		task.spawn(function()
			local holder = self._halo.holder
			if not holder or not holder.Parent then
				return
			end
			self._halo.setTransparency(Util.clamp(cfg.Halo.Transparency - 0.15, 0, 1))
			local startScale = 1
			local targetScale = 1.6
			local start = os.clock()
			while os.clock() - start < 0.6 do
				if self._destroyed then
					return
				end
				local p = (os.clock() - start) / 0.6
				local eased = Ease.apply("cubicOut", p)
				holder.Size = UDim2.fromOffset(
					cfg.Panel.Size * 2.4 * Util.lerp(startScale, targetScale, eased),
					cfg.Panel.Size * 2.4 * Util.lerp(startScale, targetScale, eased)
				)
				self._halo.setTransparency(Util.lerp(0.15, 0.95, eased))
				task.wait()
			end
			holder.Size = UDim2.fromOffset(cfg.Panel.Size * 2.4, cfg.Panel.Size * 2.4)
			self._halo.setTransparency(1)
		end)
	end

	self:_play(0.3, "quadOut", function(alpha)
		self._animScale = Util.lerp(pulse, 1, alpha)
		self:_render(self._alpha, 2, "success", 0)
	end)

	self._animScale = 1
	self:_render(1, 2, "success", 0)
	self.OnSuccess:Fire(self)

	if options.AutoHide then
		self:_wait(anim.SuccessHold)
		self:_hideInternal(self._serial, {})
	end

	return true
end

function FaceIDLib:Fail(options)
	options = options or {}
	local serial = self:_startFlow()
	task.spawn(function()
		self:_failInternal(serial, options)
	end)
end

function FaceIDLib:_failInternal(serial, options)
	options = options or {}
	local cfg = self._cfg
	local anim = cfg.Animation

	if self:_cancelled(serial) then
		return false
	end
	if self._state == STATE.HIDDEN then
		self:_showInternal(serial, { Instant = true })
	end

	self._state = STATE.FAILED
	self._mode = "fail"
	self._scanProgress = 2
	self:_playSound(cfg.Sound.FailSoundId)

	self:_play(0.12, "linear", function(alpha)
		self:_render(self._alpha, 2, "fail", 0)
	end)

	local start = os.clock()
	local shakeDuration = anim.ShakeDuration
	while os.clock() - start < shakeDuration do
		if self:_cancelled(serial) then
			return false
		end
		local p = (os.clock() - start) / shakeDuration
		local offset = Ease.shake(p, anim.ShakeStrength, 9)
		self:_render(self._alpha, 2, "fail", offset)
		task.wait()
	end

	self:_render(self._alpha, 2, "fail", 0)
	self.OnFail:Fire(self)

	if options.AutoHide then
		self:_wait(anim.FailHold)
		self:_hideInternal(self._serial, {})
	end

	return true
end

function FaceIDLib:Verify(options)
	options = options or {}
	local serial = self:_startFlow()

	task.spawn(function()
		local cfg = self._cfg
		local anim = cfg.Animation

		local shown = self:_showInternal(serial)
		if not shown then
			return
		end

		if not self:_wait(0.06) then
			return
		end

		local scanned = self:_scanInternal(serial)
		if not scanned then
			return
		end

		if not self:_wait(anim.HoldAfterScan) then
			return
		end

		local success = options.Success
		if success == nil then
			success = true
		end

		if success then
			self:_successInternal(serial, { Pulse = true })
		else
			self:_failInternal(serial, {})
		end

		if self:_cancelled(serial) then
			return
		end

		local hold = success and anim.SuccessHold or anim.FailHold
		if not self:_wait(hold) then
			return
		end

		self:_hideInternal(serial)

		if options.OnResult then
			pcall(options.OnResult, success)
		end
	end)
end

function FaceIDLib:Reset()
	self:_startFlow()
	self._state = STATE.HIDDEN
	self._mode = "normal"
	self._scanProgress = -1
	self._alpha = 0
	self._animScale = 1
	self._riseOffset = 0
	if self._scan then
		self._scan.setVisible(false)
	end
	self:_render(0, -1, "normal", 0)
	if self._root then
		self._root.Visible = false
	end
end

function FaceIDLib:SetConfig(patch, options)
	options = options or {}
	local wasVisible = self._state ~= STATE.HIDDEN and self._state ~= STATE.HIDING
	local previousScan = self._scanProgress
	local previousMode = self._mode

	self._userConfig = Util.deepMerge(self._userConfig or {}, patch or {})
	self._cfg = Config.resolve(self._userConfig)

	self:_destroyVisual()
	self:_createGui()
	self:_build()

	if options.KeepState ~= false and wasVisible then
		self._alpha = 1
		self._scanProgress = previousScan
		self._mode = previousMode
		self._state = STATE.SCANNING
		self:_render(1, previousScan, previousMode, 0)
	else
		self:Reset()
	end

	if self._cfg.Debug then
		print("[FaceIDLib] Config updated\n" .. Config.describe(self._cfg))
	end

	return self
end

function FaceIDLib:SetTheme(themeName)
	return self:SetConfig({ Theme = themeName })
end

function FaceIDLib:SetColor(color)
	return self:SetConfig({ Face = { Color = color } })
end

function FaceIDLib:SetSize(size)
	return self:SetConfig({ Panel = { Size = size } })
end

function FaceIDLib:SetTransparency(value)
	return self:SetConfig({ Panel = { Transparency = value } })
end

function FaceIDLib:SetCornerRadius(value)
	return self:SetConfig({ Panel = { CornerRadius = value } })
end

function FaceIDLib:SetPosition(position)
	self._cfg.Position = position
	self._userConfig.Position = position
	if self._root then
		self._root.Position = position
	end
	return self
end

function FaceIDLib:SetAlpha(alpha)
	self._alpha = Util.clamp01(alpha or 0)
	self:_render(self._alpha, self._scanProgress, self._mode, 0)
	return self
end

function FaceIDLib:DebugScan(progress)
	if self._scan then
		self._scan.setProgress(Util.clamp01(progress or 0))
		self._scan.setVisible(true)
	end
	self:_render(1, progress or 0, "normal", 0)
end

function FaceIDLib:GetConfig()
	return self._cfg
end

function FaceIDLib:GetState()
	return self._state
end

function FaceIDLib:IsVisible()
	return self._state ~= STATE.HIDDEN and self._state ~= STATE.HIDING
end

function FaceIDLib:GetGui()
	return self._gui
end

function FaceIDLib:GetRoot()
	return self._root
end

function FaceIDLib:GetPanel()
	return self._panel
end

function FaceIDLib:_playSound(id)
	local cfg = self._cfg
	if not cfg.Sound.Enabled or not id or id == "" then
		return
	end
	local soundId = tostring(id)
	if tonumber(soundId) then
		soundId = "rbxassetid://" .. soundId
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = cfg.Sound.Volume
	sound.Parent = SoundService
	TABLE_INSERT(self._sounds, sound)
	sound:Play()

	task.delay(6, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

function FaceIDLib:_destroyVisual()
	for i = #self._connections, 1, -1 do
		local conn = self._connections[i]
		if conn and conn.Disconnect then
			pcall(function()
				conn:Disconnect()
			end)
		end
		self._connections[i] = nil
	end

	local oldRoot = self._root
	if oldRoot and oldRoot.Parent then
		oldRoot:Destroy()
	end
	if self._dim and self._dim.Parent then
		self._dim:Destroy()
	end

	self._root = nil
	self._panel = nil
	self._shadow = nil
	self._panelGroup = nil
	self._iconGroup = nil
	self._face = nil
	self._scan = nil
	self._halo = nil
	self._caption = nil
	self._dim = nil
	self._uiScale = nil
end

function FaceIDLib:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._serial = self._serial + 1

	self:_destroyVisual()

	for i = 1, #self._sounds do
		local sound = self._sounds[i]
		if sound and sound.Parent then
			pcall(function()
				sound:Stop()
				sound:Destroy()
			end)
		end
	end
	self._sounds = {}

	if self._ownsGui and self._gui and self._gui.Parent then
		pcall(function()
			self._gui:Destroy()
		end)
	end

	local signals = {
		"OnReady", "OnShown", "OnScanStart", "OnScanComplete",
		"OnSuccess", "OnFail", "OnHidden", "OnComplete", "OnError",
	}
	for i = 1, #signals do
		local signal = self[signals[i]]
		if signal and signal.Destroy then
			signal:Destroy()
		end
	end

	FaceIDLib._instances[self] = nil
end

function FaceIDLib:_track(instance)
	if instance then
		TABLE_INSERT(self._children, instance)
	end
	return instance
end

local GLOBAL_ENV = (function()
	local ok, env = pcall(function()
		return _G
	end)
	if ok and type(env) == "table" then
		return env
	end
	return {}
end)()

local LOADSTRING_READY, LOADSTRING_REASON = (function()
	local ok, fn = pcall(function()
		return loadstring("return 1", "=probe")
	end)
	if ok and type(fn) == "function" then
		return true, nil
	end
	local ok2, fn2 = pcall(function()
		return load("return 1", "=probe")
	end)
	if ok2 and type(fn2) == "function" then
		return "load", nil
	end
	return false, "String compilation is not available here (loadstring is disabled on the client; enable LoadStringEnabled on the server)"
end)()

FaceIDLib.Loader = FaceIDLib.Loader or {}
local Loader = FaceIDLib.Loader

Loader.Available = LOADSTRING_READY and true or false
Loader.Reason = LOADSTRING_REASON

function Loader.compile(source, chunkName, env)
	if type(source) ~= "string" or #source == 0 then
		return nil, "Source is empty"
	end
	if not LOADSTRING_READY then
		return nil, LOADSTRING_REASON
	end

	local name = chunkName or "=FaceIDAutoExec"
	local chunk

	if loadstring then
		local ok, result, err = pcall(loadstring, source, name)
		if ok and type(result) == "function" then
			chunk = result
		elseif not ok then
			return nil, tostring(result)
		elseif err then
			return nil, tostring(err)
		end
	end

	if not chunk and load then
		local ok, result, err
		if env ~= nil then
			ok, result, err = pcall(load, source, name, "t", env)
		else
			ok, result, err = pcall(load, source, name)
		end
		if ok and type(result) == "function" then
			chunk = result
		elseif not ok then
			return nil, tostring(result)
		elseif err then
			return nil, tostring(err)
		end
	end

	if not chunk then
		return nil, "Compilation failed (syntax error in the source?)"
	end
	return chunk, nil
end

function Loader.buildEnv(self, custom)
	local env = {}

	for key, value in pairs(GLOBAL_ENV) do
		env[key] = value
	end

	env.Players = Players
	env.RunService = RunService
	env.TweenService = TweenService
	env.UserInputService = UserInputService
	env.SoundService = SoundService
	env.GuiService = GuiService
	env.LocalPlayer = Players.LocalPlayer
	env.Workspace = Workspace

	env.FaceID = self
	env.FaceIDLib = FaceIDLib
	env.Lib = self
	env.UI = self
	env.Config = self._cfg
	env.Settings = self._cfg

	env.Signal = Signal
	env.Ease = Ease
	env.Color = Color
	env.Util = Util
	env.Draw = Draw
	env.Components = Components
	env.Theme = Theme

	env.verify = function(options)
		self:Verify(options)
	end
	env.show = function()
		self:Show()
	end
	env.hide = function()
		self:Hide()
	end
	env.success = function()
		self:Success()
	end
	env.fail = function()
		self:Fail()
	end
	env.setColor = function(color)
		self:SetColor(color)
	end
	env.setTheme = function(name)
		self:SetTheme(name)
	end

	if type(custom) == "table" then
		for key, value in pairs(custom) do
			env[key] = value
		end
	end

	env.__index = env
	return setmetatable(env, env)
end

function Loader.execute(self, source, options)
	options = options or {}

	local env = options.Environment
	if env == nil then
		local autoCfg = self._cfg.AutoExec
		if autoCfg.Sandbox then
			env = Loader.buildEnv(self, autoCfg.Env)
		else
			env = autoCfg.Env
		end
	end

	local chunk, err = Loader.compile(source, options.Name, env)
	if not chunk then
		return false, err
	end

	if env ~= nil and setfenv then
		local ok = pcall(setfenv, chunk, env)
		if not ok and self._cfg.Debug then
			warn("[FaceIDLib] setfenv failed; running in the global environment")
		end
	end

	local results = TABLE_PACK(pcall(chunk))
	if not results[1] then
		return false, results[2]
	end

	if #results > 1 then
		return true, results[2]
	end
	return true, nil
end

local function normalizeEntry(entry)
	if type(entry) == "string" then
		return { kind = "source", payload = entry, name = "Source" }
	end
	if type(entry) == "function" then
		return { kind = "function", payload = entry, name = "Function" }
	end
	if typeof and typeof(entry) == "Instance" then
		if entry:IsA("ModuleScript") then
			return { kind = "module", payload = entry, name = entry.Name }
		elseif entry:IsA("LuaSourceContainer") then
			return { kind = "instanceSource", payload = entry, name = entry.Name }
		elseif entry:IsA("Folder") or entry:IsA("Model") then
			return { kind = "container", payload = entry, name = entry.Name }
		end
		return nil
	end
	if type(entry) == "table" then
		if entry.Source then
			return {
				kind = "source",
				payload = entry.Source,
				name = entry.Name or "Source",
				delay = entry.Delay,
			}
		end
		if entry.Module then
			return {
				kind = "module",
				payload = entry.Module,
				name = entry.Name or (entry.Module and entry.Module.Name) or "Module",
				delay = entry.Delay,
			}
		end
		if entry.Function or entry.Callback then
			return {
				kind = "function",
				payload = entry.Function or entry.Callback,
				name = entry.Name or "Function",
				delay = entry.Delay,
			}
		end
		if entry.Instance then
			return normalizeEntry(entry.Instance)
		end
	end
	return nil
end

local function collectEntries(self)
	local cfg = self._cfg.AutoExec
	local entries = {}

	if type(cfg.Function) == "function" then
		TABLE_INSERT(entries, { kind = "function", payload = cfg.Function, name = "AutoExec.Function" })
	end

	if cfg.Module ~= nil then
		local normalized = normalizeEntry(cfg.Module)
		if normalized then
			TABLE_INSERT(entries, normalized)
		end
	end

	if type(cfg.Source) == "string" and #cfg.Source > 0 then
		TABLE_INSERT(entries, { kind = "source", payload = cfg.Source, name = "AutoExec.Source" })
	end

	if type(cfg.Sources) == "table" then
		for _, item in ipairs(cfg.Sources) do
			local normalized = normalizeEntry(item)
			if normalized then
				TABLE_INSERT(entries, normalized)
			end
		end
	end

	if type(cfg.Modules) == "table" then
		for _, item in ipairs(cfg.Modules) do
			local normalized = normalizeEntry(item)
			if normalized then
				TABLE_INSERT(entries, normalized)
			end
		end
	end

	if type(cfg.Scripts) == "table" then
		for _, item in ipairs(cfg.Scripts) do
			local normalized = normalizeEntry(item)
			if normalized then
				TABLE_INSERT(entries, normalized)
			end
		end
	end

	return entries
end

function Loader.runEntry(self, entry)
	local kind = entry.kind
	local payload = entry.payload

	if kind == "source" then
		return Loader.execute(self, payload, { Name = "=" .. tostring(entry.name or "AutoExec") })
	elseif kind == "module" then
		local ok, result = pcall(require, payload)
		if not ok then
			return false, result
		end
		return true, result
	elseif kind == "instanceSource" then
		local source = payload.Source
		if type(source) ~= "string" or #source == 0 then
			return false, "Script " .. payload.Name .. " has no source"
		end
		return Loader.execute(self, source, { Name = "=" .. payload.Name })
	elseif kind == "function" then
		local ok, result = pcall(payload, self, self._cfg)
		if not ok then
			return false, result
		end
		return true, result
	elseif kind == "container" then
		local okAll = true
		local lastErr = nil
		for _, child in ipairs(payload:GetChildren()) do
			local normalized = normalizeEntry(child)
			if normalized then
				local ok, err = Loader.runEntry(self, normalized)
				if not ok then
					okAll = false
					lastErr = err
				end
			end
		end
		return okAll, lastErr
	end

	return false, "Unknown execution type: " .. tostring(kind)
end

function FaceIDLib:_runAutoExec(phase)
	local cfg = self._cfg.AutoExec
	if not cfg.Enabled then
		return false
	end
	self._autoExecRan = self._autoExecRan or {}
	local phaseKey = tostring(phase or "Instant")
	if cfg.RunOnce ~= false and cfg.Once ~= false and self._autoExecRan[phaseKey] then
		return false
	end
	self._autoExecRan[phaseKey] = true

	local entries = collectEntries(self)
	if #entries == 0 then
		if cfg.DebugWarn then
			warn("[FaceIDLib] AutoExec is enabled but there is nothing to run (no source / module / function)")
		end
		return false
	end

	task.spawn(function()
		if (cfg.Delay or 0) > 0 then
			task.wait(cfg.Delay)
		end

		local okCount = 0
		for i = 1, #entries do
			local entry = entries[i]
			if entry.delay and entry.delay > 0 then
				task.wait(entry.delay)
			end

			local ok, result = Loader.runEntry(self, entry)
			if ok then
				okCount = okCount + 1
			else
				local message = "[FaceIDLib] AutoExec failed (" .. tostring(entry.name) .. "): " .. tostring(result)
				self._lastError = message
				if not cfg.Silent then
					warn(message)
				end
				pcall(function()
					self.OnError:Fire(self, message, entry.name)
				end)
			end
		end

		if self._cfg.Debug then
			print(STRING_FORMAT("[FaceIDLib] AutoExec(%s) finished: %d/%d succeeded", tostring(phase), okCount, #entries))
		end
	end)

	return true
end

function FaceIDLib:Execute(source, options)
	return Loader.execute(self, source, options)
end

function FaceIDLib:RequireFolder(folder)
	if not folder or not folder:IsA("Instance") then
		return false, "Not a valid Instance"
	end
	local lastErr = nil
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ModuleScript") then
			local ok, err = pcall(require, child)
			if not ok then
				lastErr = err
			end
		end
	end
	return lastErr == nil, lastErr
end

FaceIDLib.LoadSource = function(source, userConfig)
	local instance = FaceIDLib.new(userConfig or {})
	instance:Execute(source)
	return instance
end

FaceIDLib.VERSION = "1.0.0"
FaceIDLib.BUILD = "2026.11.10"
FaceIDLib.AUTHOR = "FaceIDKit"
FaceIDLib.LICENSE = "MIT"
FaceIDLib.NAME = "FaceIDLib"

FaceIDLib.Signal = Signal
FaceIDLib.Util = Util
FaceIDLib.Color = Color
FaceIDLib.Ease = Ease
FaceIDLib.Draw = Draw
FaceIDLib.Components = Components
FaceIDLib.Theme = Theme
FaceIDLib.Themes = Theme.presets
FaceIDLib.Config = Config

FaceIDLib.Palette = Color.palette
FaceIDLib.Colors = Color.palette

function FaceIDLib.getThemeNames()
	return Theme.list()
end

function FaceIDLib.printThemes()
	local names = Theme.list()
	TABLE_SORT(names)
	print("========== FaceIDLib built-in themes ==========")
	for i = 1, #names do
		local preset = Theme.presets[names[i]]
		local desc = preset and preset.Description or ""
		print(STRING_FORMAT("  %2d. %-14s %s", i, names[i], desc))
	end
	print("===============================================")
	return names
end

function FaceIDLib.describe(config)
	local resolved = Config.resolve(config or {})
	return Config.describe(resolved)
end

FaceIDLib.Create = FaceIDLib.new

function FaceIDLib.AutoRun(userConfig, options)
	userConfig = userConfig or {}
	local instance = FaceIDLib.new(userConfig)
	instance:Verify(options or {})
	return instance
end

function FaceIDLib.LoadAndRun(source, userConfig)
	local instance = FaceIDLib.new(userConfig or {})
	instance:Execute(source)
	return instance
end

function FaceIDLib.Flash(userConfig, duration)
	local instance = FaceIDLib.new(userConfig or {})
	instance:Show()
	task.delay(duration or 1.5, function()
		if not instance._destroyed then
			instance:Hide()
		end
	end)
	return instance
end

function FaceIDLib:PlaySequence(steps)
	local serial = self:_startFlow()

	task.spawn(function()
		for i = 1, #steps do
			if self:_cancelled(serial) then
				return
			end

			local step = steps[i]
			if type(step) == "number" then
				if not self:_wait(step) then
					return
				end
			elseif type(step) == "function" then
				pcall(step, self)
			elseif type(step) == "table" then
				if step.wait then
					if not self:_wait(step.wait) then
						return
					end
				end

				if step.action == "show" then
					self:_showInternal(serial, step.options or {})
				elseif step.action == "hide" then
					self:_hideInternal(serial, step.options or {})
				elseif step.action == "scan" then
					self:_scanInternal(serial, step.options or {})
				elseif step.action == "success" then
					self:_successInternal(serial, step.options or {})
				elseif step.action == "fail" then
					self:_failInternal(serial, step.options or {})
				elseif step.action == "reset" then
					self:Reset()
				end

				if step.color then
					self:SetColor(step.color)
				end
				if step.theme then
					self:SetTheme(step.theme)
				end
				if step.size then
					self:SetSize(step.size)
				end
				if step.corner then
					self:SetCornerRadius(step.corner)
				end
				if step.transparency then
					self:SetTransparency(step.transparency)
				end
				if step.position then
					self:SetPosition(step.position)
				end
				if step.call then
					pcall(step.call, self)
				end
			end
		end
	end)

	return self
end

function FaceIDLib.Demo(config)
	config = config or {}

	local instance = FaceIDLib.new(config)
	local themes = config.Themes or { "iOSDark", "NeonGreen", "Midnight" }
	local index = 0

	local function cycle()
		if instance._destroyed then
			return
		end
		index = index + 1
		if index > #themes then
			index = 1
		end
		instance:SetTheme(themes[index])
		instance:Verify({
			Success = true,
			OnResult = function()
				task.delay(0.8, cycle)
			end,
		})
	end

	task.delay(0.4, cycle)
	return instance
end

function FaceIDLib.Debug(instance)
	if not instance then
		return
	end
	print(STRING_FORMAT("[FaceIDLib] version %s (%s)", FaceIDLib.VERSION, FaceIDLib.BUILD))
	print(Config.describe(instance:GetConfig()))
	return true
end

FaceIDLib.API = {
	{ name = "new(config)", desc = "Create an instance (see the config table in the README)" },
	{ name = "Show(options)", desc = "Fade in and show" },
	{ name = "Hide(options)", desc = "Fade out and hide" },
	{ name = "Scan(options)", desc = "Play the scan animation only" },
	{ name = "Success(options)", desc = "Switch to the success state (all lit up + halo)" },
	{ name = "Fail(options)", desc = "Switch to the failure state (turns red + shakes)" },
	{ name = "Verify(options)", desc = "Full flow: fade in -> scan -> result -> fade out" },
	{ name = "Reset()", desc = "Return to the initial state immediately" },
	{ name = "PlaySequence(steps)", desc = "Play a sequence of actions on a timeline" },
	{ name = "SetConfig(patch)", desc = "Patch the config and rebuild the UI" },
	{ name = "SetTheme(name)", desc = "Switch to another built-in theme" },
	{ name = "SetColor(color)", desc = "Change the main accent color" },
	{ name = "SetSize(px)", desc = "Change the panel size" },
	{ name = "SetCornerRadius(px)", desc = "Change the corner radius" },
	{ name = "SetTransparency(n)", desc = "Change the panel transparency" },
	{ name = "SetPosition(udim2)", desc = "Change the position" },
	{ name = "SetAlpha(n)", desc = "Set the overall visibility directly" },
	{ name = "GetConfig()", desc = "Get the fully resolved config" },
	{ name = "GetState()", desc = "Current state as a string" },
	{ name = "IsVisible()", desc = "Whether it is currently visible" },
	{ name = "Execute(source, options)", desc = "Run a snippet of Lua source manually" },
	{ name = "Destroy()", desc = "Destroy every instance and connection" },
}

FaceIDLib.Events = {
	OnReady = "Instance finished initializing",
	OnShown = "Fade-in finished, right before scanning",
	OnScanStart = "Scan animation started",
	OnScanComplete = "Scan animation finished",
	OnSuccess = "Success state finished playing",
	OnFail = "Failure state finished playing",
	OnHidden = "Fade-out finished",
	OnComplete = "Whole flow finished (carries a reason)",
	OnError = "AutoExec threw an error",
}

FaceIDLib.Changelog = [[
1.0.0  2026.11.10
  - First release
  - Face ID icon drawn purely from geometry (four corner brackets + two eyes + nose + smile arc)
  - Moving scan band + stroke-by-stroke lighting
  - 12 themes / full config table / frame-accurate timeline
  - Built-in AutoExec source loader
]]

local STATIC_METHODS = { "Show", "Hide", "Verify", "Success", "Fail", "Scan", "Reset", "Destroy" }

for i = 1, #STATIC_METHODS do
	local methodName = STATIC_METHODS[i]
	local original = FaceIDLib[methodName]
	if type(original) == "function" then
		FaceIDLib[methodName] = function(self, arg)

			if type(self) == "table" and self._cfg then
				return original(self, arg)
			end

			local userConfig = nil
			if type(self) == "table" then
				userConfig = self
			elseif type(self) == "string" then
				userConfig = { Theme = self }
			end
			local instance = FaceIDLib.new(userConfig or {})
			original(instance, arg)
			return instance
		end
	end
end

return FaceIDLib
