-- Legend26

-- Configuration settings
local shieldLightColour = "Sand blue"			-- This is the colour of the PointLight in the shield.
local shieldLightBrightness = 1					-- This is the brightness of the PointLight in the shield.
local shieldLightRange = 16						-- This is the range of the PointLight in the shield.

local hitSoundId = 162026290
local shieldOpenId = 162026257
local shieldShutId = 162026276
local shieldLoopId = 162026243
local shieldDecalId = 2679727960

local soundEmitterSize = 10
local soundMaxDistance = 200
local soundVolume = 0.5

local gateCenterAdjust = CFrame.new(0,0,-0.13)

----
--------
-- Do not alter anything below.
--------
----

local module = {}

local locatorPrefix = "rbxassetid://"

local busyWithAnim = false
local currentCloseState = false

local shield = Instance.new("Model")
shield.Name = "Shield"
shield.Archivable = false

local closed = Instance.new("BoolValue")
closed.Name = "Closed"
closed.Parent = shield

function module:createSound(id, parent, name)
	local sound = Instance.new("Sound")
	sound.SoundId = locatorPrefix .. id
	sound.Name = name
	sound.EmitterSize = soundEmitterSize
	sound.MaxDistance = soundMaxDistance
	sound.Volume = soundVolume
	sound.Parent = parent
	return sound
end

function module:generate(gateCF)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Transparency = 1
	part.Size = Vector3.new(20,0.2,20)
	part.Locked = true

	local sm = Instance.new("CylinderMesh")
	sm.Scale = Vector3.new(1.2,0.25,1.2)
	sm.Parent = part

	local light = Instance.new("PointLight")
	light.Brightness = 0
	light.Color = BrickColor.new(shieldLightColour).Color
	light.Enabled = true
	light.Range = shieldLightRange
	light.Parent = part

	local soundValue = Instance.new("IntValue")
	soundValue.Name = "TravelBlockSound"
	soundValue.Value = hitSoundId
	soundValue.Parent = part

	self:createSound(shieldOpenId, part, "TravelBlockOpenSound")
	self:createSound(shieldShutId, part, "TravelBlockShutSound")
	local loopSound = self:createSound(shieldLoopId, part, "TravelBlockLoopSound")
	loopSound.Looped = true
	loopSound.Volume = 1

	local frontDecal = Instance.new("Decal")
	frontDecal.Name = "FrontDecal"
	frontDecal.Face = Enum.NormalId.Top
	frontDecal.Texture = locatorPrefix .. shieldDecalId
	frontDecal.Transparency = 1
	frontDecal.Parent = part

	local backDecal = Instance.new("Decal")
	backDecal.Name = "BackDecal"
	backDecal.Face = Enum.NormalId.Bottom
	backDecal.Texture = locatorPrefix .. shieldDecalId
	backDecal.Transparency = 1
	backDecal.Parent = part

	part.CFrame = (gateCF*CFrame.Angles(-math.pi/2,0,0)):toWorldSpace(gateCF:toObjectSpace(gateCF))

	part.Parent = shield
	shield.PrimaryPart = part
end

function module:transition(closed)
	local step = 20
	local t = (closed) and {step,0,-1} or {0,step,1}

	local p = shield.PrimaryPart
	p.CanCollide = closed

	for i = t[1],t[2],t[3] do
		p.FrontDecal.Transparency = i/step
		p.BackDecal.Transparency = i/step
		p.PointLight.Brightness = p.PointLight.Brightness + shieldLightBrightness/-step*t[3]
		wait()
	end
end

function module:open()
	if (busyWithAnim) or (currentCloseState == false) then return end
	busyWithAnim = true

	currentCloseState = false
	closed.Value = false

	local sound = shield.PrimaryPart.TravelBlockOpenSound

	shield.PrimaryPart.TravelBlockLoopSound:Stop()
	sound:Play()
	self:transition(false)

	if (sound.IsPlaying) then
		sound.Ended:wait()
	end

	wait(1)
	busyWithAnim = false
end

function module:shut()
	if (busyWithAnim) or (currentCloseState == true) then return end
	busyWithAnim = true

	currentCloseState = true
	closed.Value = true

	local sound = shield.PrimaryPart.TravelBlockShutSound

	sound:Play()
	self:transition(true)

	if (sound.IsPlaying) then
		sound.Ended:wait()
	end
	shield.PrimaryPart.TravelBlockLoopSound:Play()

	wait(1)
	busyWithAnim = false
end

--------
--[[
Initialize Functions

	initialize(Stargate gate)
]]--

function module:initialize(gate)
	local gateCF = gate:GetCenter() * gateCenterAdjust
	self:generate(gateCF)

	local changedDebounce = false
	closed.Changed:connect(function()
		if (busyWithAnim) then
			changedDebounce = true
			closed.Value = currentCloseState
			changedDebounce = false
			return
		end

		if (closed.Value == currentCloseState) then return end

		if (closed.Value) then
			self:shut()
		else
			self:open()
		end
	end)

	shield.Parent = gate.Model
	closed.Value = false

	return closed
end

-- Return completed module
return module

-- Legend26