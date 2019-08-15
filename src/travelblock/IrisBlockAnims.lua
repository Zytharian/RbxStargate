-- Legend26, Ganondude

-- Configuration settings

local iriscolour = Color3.fromRGB(102,98,101)		-- This is the colour of the iris.
local iriscolour2= Color3.fromRGB(99,95,98)
local irismaterial = "Plastic"			-- This is the material of the iris.

local hitSoundId = 162026284
local shieldOpenId = 162029942
local shieldShutId = 162026264

local soundEmitterSize = 10
local soundMaxDistance = 200
local soundVolume = 0.5

local gateCenterAdjust = CFrame.new(0,0,-0.50)
local gateRadiusAdjust = -1

local bladeOutwardAngle = math.pi/1.94

----
--------
-- Do not alter anything below.
--------
----

local module = {}

local locatorPrefix = "rbxassetid://"

local busyWithAnim = false
local currentCloseState = true

local ta

local shield = Instance.new("Model")
shield.Name = "Iris"
shield.Archivable = false

local closed = Instance.new("BoolValue")
closed.Name = "Closed"
closed.Parent = shield
closed.Value = true

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

function module:generate(gateCF, radius)
	local part = Instance.new("WedgePart")
	part.Name = "IPart"
	part.Anchored = true
	part.BottomSurface = 0
	part.TopSurface = 0
	part.Color = iriscolour
	part.Material = irismaterial
	part.Size = Vector3.new(0.2,radius,radius/5)
	part.CFrame = gateCF

	local sm = Instance.new("SpecialMesh")
	--sm.MeshType = "Wedge"
	sm.MeshType = "FileMesh"
	sm.MeshId = "rbxassetid://2691488595"
	sm.Scale = Vector3.new(0.2,1.35,1)
	sm.Parent = part

	local cfrot = CFrame.Angles(-math.pi/2,0,0)
	if (math.abs(gateCF.lookVector.Y + 1) < 0.01) then
		cfrot = CFrame.Angles(0,0,0)
	elseif (math.abs(gateCF.lookVector.Y - 1) < 0.01) then
		cfrot = CFrame.Angles(math.pi,0,0)
	end

	ta = {}
	local angle = 2*math.pi/(2*math.floor(radius))

	local cloneCount = 1

	for i = 0,2*math.pi,angle do
		local np = part:clone()

		cloneCount = cloneCount + 1
		if (cloneCount % 2 == 0) then np.Color = iriscolour2 end

		local rot = CFrame.Angles(0,-math.pi/1.61,bladeOutwardAngle)

		local cf = CFrame.new(part.Position + Vector3.new(radius/2.8*math.sin(i),0,radius/2.8*math.cos(i)), part.Position) * rot		-- 5.2
		local cf2 = CFrame.new(part.Position + Vector3.new(radius/1.3*math.sin(i),0,radius/1.3*math.cos(i)), part.Position) * rot		-- 11.4

		np.CFrame = (gateCF*cfrot):toWorldSpace(gateCF:toObjectSpace(cf))

		np.Parent = shield
		table.insert(ta,{np,((gateCF*cfrot):toWorldSpace(gateCF:toObjectSpace(cf2))):toObjectSpace(np.CFrame),(gateCF*cfrot):toObjectSpace(cf2)})
		wait()
	end

	local centerPart = Instance.new("Part")
	centerPart.Name = "SoundEmitterPart"
	centerPart.Anchored = true
	centerPart.CanCollide = false
	centerPart.Transparency = 1
	centerPart.Size = Vector3.new(0,0,0)
	centerPart.CFrame = gateCF
	centerPart.TopSurface = 0
	centerPart.BottomSurface = 0
	centerPart.Parent = shield

	shield.PrimaryPart = centerPart

	local soundValue = Instance.new("IntValue")
	soundValue.Name = "TravelBlockSound"
	soundValue.Value = hitSoundId
	soundValue.Parent = centerPart

	self:createSound(shieldOpenId, centerPart, "TravelBlockOpenSound")
	self:createSound(shieldShutId, centerPart, "TravelBlockShutSound")

	shield.PrimaryPart = centerPart
end

local d = 1
local o,c = 1,80

function module:final(t,c)
	for i,v in pairs(shield:GetChildren()) do
		if (v:IsA("BasePart")) and (v.Name ~= "SoundEmitterPart") then
			v.Transparency = t
			v.CanCollide = c
		end
	end
end

function module:transition(close, gateCF)
	if (d == c) then self:final(0,true) end

	local pAngle = 0
	local pAngleChange = 0
	local offset = 0
	local twistOffset = 0;
	local startTime = tick()

	if close then
		pAngleChange = 1
		offset = -0.04
		twistOffset = 0.02
	else
		offset = -0.02
		pAngleChange = -1
		twistOffset = 0.02
	end

	repeat

		local delta = tick() - startTime

		for i,v in ipairs(ta) do
			v[1].CFrame = (gateCF*v[3]*CFrame.Angles((math.pi/180)*d,twistOffset + (0.000 * delta) ,offset + (pAngleChange * delta * 0.005) )):toWorldSpace(v[2]) -- the 250 was originally 180
		end

		wait()

		d = (close) and d - 1 or d + 1
		if (d < 1) then d = 360
		elseif (d > 360) then d = 1
		end
	until (d <= o) or (d >= c)
	if (d == c) then self:final(1,false) end
end

function module:open(gateCF)
	if (busyWithAnim) or (currentCloseState == false) then return end
	busyWithAnim = true

	currentCloseState = false
	closed.Value = false

	local sound = shield.PrimaryPart.TravelBlockOpenSound

	sound:Play()
	self:transition(false, gateCF)

	if (sound.IsPlaying) then
		sound.Ended:wait()
	end

	wait(1)
	busyWithAnim = false
end

function module:shut(gateCF)
	if (busyWithAnim) or (currentCloseState == true) then return end
	busyWithAnim = true

	currentCloseState = true
	closed.Value = true

	local sound = shield.PrimaryPart.TravelBlockShutSound

	sound:Play()
	self:transition(true, gateCF)

	if (sound.IsPlaying) then
		sound.Ended:wait()
	end

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
	local radius = gate:GetRadius() + gateRadiusAdjust
	self:generate(gateCF, radius)

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
			self:shut(gateCF)
		else
			self:open(gateCF)
		end
	end)

	shield.Parent = gate.Model
	closed.Value = false

	return closed
end

-- Return completed module
return module

-- Legend26, Ganondude