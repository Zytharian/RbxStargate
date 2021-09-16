-- Legend26, Ganondude

----
--------
-- Do not alter anything in this script.
--------
----

-- Script Globals
local module = {}

local this = nil
local config = nil
local priv = nil

local locatorPrefix = "rbxassetid://"

local stopHorizonAnim = false

local horizon = nil

local fakeSymbols = {}

--------

--[[
Part Spawning Functions

	spawnHorizon(function onHorizonTouched)
	spawnRipple()
	spawnVortex(function onVortexTouched)
]]--

function module:spawnHorizon(onHorizonTouched)
	local c = this:GetCenter()
	local r = this:GetRadius()

	local p = Instance.new("Part")
	p.Name = "EventHorizon"
	p.Anchored = true
	p.CanCollide = false
	p.Locked = true
	p.Archivable = true -- This MUST be true or animFakeHorizon() will fail (it clones the existing horizon)
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(r*config.horizonSizeMultiplier, r*config.horizonSizeMultiplier, 0.2)
	p.Color = self:toColor(config.horizonColour[1])
	p.Material = Enum.Material.Fabric
	p.Reflectance = 0
	p.Transparency = 1

	p.CFrame = c

	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Brick
	m.Scale = config.scalet
	m.Parent = p

	local l = Instance.new("SpotLight")
	l.Angle = config.horizonLightAngle
	l.Brightness = config.horizonLightBrightness
	l.Color = self:toColor(config.horizonColour[3])
	l.Range = config.horizonLightRange
	l.Parent = p

	local s = self:spawnSoundInstance(config.wormholeAmbient, p)
	s.Looped = true

	local d1 = Instance.new("Decal")
	d1.Name = "eh_front"
	d1.Face = "Front"
	d1.Parent = p

	local d2 = Instance.new("Decal")
	d2.Name = "eh_back"
	d2.Face = "Back"
	d2.Parent = p

	p.Anchored = true

	local f = function()
		local minBright = config.horizonLightBrightness*0.8
		local maxBright = config.horizonLightBrightness*1.2

		local minRange = config.horizonLightRange*0.8
		local maxRange = config.horizonLightRange*1.2

		while (p.Parent) do
			l.Brightness = l.Brightness + (math.random()/2)*math.random(-1,1)
			l.Brightness = (l.Brightness < minBright) and minBright or ((l.Brightness > maxBright) and maxBright or l.Brightness)

			l.Range = l.Range + math.random(-1,1)/2
			l.Range = (l.Range < minRange) and minRange or ((l.Range > maxRange) and maxRange or l.Range)

			wait(1/config.animFPS)
		end
	end

	spawn(f)

	p.Touched:connect(onHorizonTouched)

	p.Parent = this.Model

	return p
end

function module:spawnRipple()
	local c = this:GetCenter()
	local r = this:GetRadius()

	local p = Instance.new("Part")
	p.Name = "Ripple"
	p.Anchored = true
	p.CanCollide = false
	p.Locked = true
	p.Archivable = false
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.new(1,1,1)
	p.Color = self:toColor(config.horizonColour[1])
	p.Material = Enum.Material.Glass
	p.Reflectance = 0
	p.Transparency = 0
	p.Parent = this.Model

	p.CFrame = c

	if (horizon) then
		p.Color = horizon.Color
		p.Material = horizon.Material
		p.Reflectance = horizon.Reflectance
	end

	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.FileMesh
	m.MeshId = "http://www.roblox.com/asset/?id=3270017"	-- ring
	m.Scale = Vector3.new(0.5,0.5,0.25)
	m.Parent = p

	p.Parent = this.Model

	local randSound = math.random(#config.wormholeTransport)
	self:spawnSoundInstance(config.wormholeTransport[randSound], p)

	return p
end

function module:spawnVortex(primary, onVortexTouched)
	-- Have to rely on the MeshPart being part of the gate model since MeshPart.MeshId is not scriptable
	local p

	if (primary) then
		p = this.Model.VortexMain:Clone()
		p.Transparency = 0.6

		local l = Instance.new("PointLight")
		l.Brightness = 0
		l.Color = self:toColor(config.horizonColour[2])
		l.Range = 0
		l.Parent = p

		p.Touched:connect(onVortexTouched)
	else
		p = this.Model.VortexSecond:Clone()
		p.Transparency = 0
	end

	local r = this:GetRadius()
	p.Size = Vector3.new(r*config.vortexSizeMultiplier, 1, r*config.vortexSizeMultiplier)
	p.Locked = true
	p.Archivable = false
	p.Parent = this.Model

	return p
end

--------

--[[
Animation Functions

	animHorizon()
	animRipple(Vector3 pos)
	animVortex(onVortexTouched)
	animPreVortex()
	animPostVortex()
	animDeactivation()
	animFakeHorizon(number fadeToDecalId, number animLength)

	animDial(number symbol, number chevron, number mode)
	animDialMilkyWay(number symbol, number chevron, number mode)
	animDialPegasus(number symbol, number chevron, number mode)
	placeFakeSymbol(number symbol, number loc)
	animLock(number n)

	lightChevron(boolean on, number n)

	calculateRollDistance(symbolTop, symbol, dialDir)
	calculateDialTime(number current, table symbols, number mode)
]]--

function module:animHorizon()
	stopHorizonAnim = false

	local front = horizon.eh_front
	local back = horizon.eh_back

	local a = 1
	local b = #config.animIdActive
	local c = config.horizonAnimLoopStep

	front.Transparency = 0
	back.Transparency = 0.2

	horizon.Sound.Volume = 2
	horizon.Sound:Play()

	while (horizon.Parent) and (not stopHorizonAnim) do
		for i = a,b,c do
			if (not horizon.Parent) or (stopHorizonAnim) then break end

			front.Texture = locatorPrefix..config.animIdActive[i]
			back.Texture = locatorPrefix..config.animIdActive[i]

			wait(1/config.horizonAnimFPS)
		end

		a,b = b,a
	end

	front.Transparency = 0
	back.Transparency = 0
end

function module:animRipple(pos)
	local ripple = self:spawnRipple()

	ripple.Sound:Play()

	local travelBlockSound = this.Model:FindFirstChild("TravelBlockSound", true)
	if (this:IsBlocked()) and (travelBlockSound) and (travelBlockSound:IsA("IntValue")) then
		self:playGateSound(travelBlockSound.Value)
	end

	for i = 1,10 do
		if (this.State ~= this.GateState.ACTIVE_INCOMING) and (this.State ~= this.GateState.ACTIVE_OUTGOING) then break end

		local cf = this:GetCenter()
		ripple.CFrame = cf*CFrame.new(pos.x,pos.y,0) + cf.lookVector*0.1
		ripple.Mesh.Scale = ripple.Mesh.Scale + Vector3.new(0.5,0.5,0)

		wait(0.1)
	end

	ripple:Destroy()
end

function module:animVortex(onVortexTouched)
	local vortex = self:spawnVortex(true, onVortexTouched)
	local vortex2 = self:spawnVortex(false, nil)

	local rotateFactor = 1
	local angleFactor = -math.pi/2

	local startTime = tick()
	local initialVelocity = 60
	local initialPosition = 0
	local initialAccel = 50
	local jerk = -320
	local position = 0;

	vortex.PointLight.Brightness = config.vortexLightBrightness
	vortex.PointLight.Range = config.vortexLightRange

	while position >= 0 do

		local delta = tick() - startTime
		local acceleration = 0

		position = initialPosition + (initialVelocity * delta) + (0.5 * initialAccel * delta^2) + ((1/6) * jerk * delta^3)

		vortex.Size = Vector3.new(vortex.Size.x,position,vortex.Size.z)
		vortex2.Size = vortex.Size

		local cf = this:GetCenter()
		vortex.CFrame = cf*CFrame.Angles(angleFactor, rotateFactor*delta, 0) + cf.lookVector*vortex.size.Y/2
		vortex2.CFrame = vortex.CFrame

		wait(0.05)
	end

	vortex:Destroy()
	vortex2:Destroy()
end

function module:animPreVortex()
	local r = this:GetRadius()

	local front = horizon:FindFirstChild("eh_front")
	local back = horizon:FindFirstChild("eh_back")

	local colour = self:toColor(config.horizonColour[1])
	horizon.Color = colour
	horizon.SpotLight.Color = colour

	self:playGateSound(config.wormholeStartup)

	local animTime = config.horizonActivateAnimTime

	local animStepTime = animTime / #config.animIdInit
	for i=#config.animIdInit, 1, -1 do
		front.Texture = locatorPrefix..config.animIdInit[i]
		back.Texture = front.Texture
		wait(animStepTime)
	end

	local colour = self:toColor(config.horizonColour[2])
	horizon.Color = colour
	horizon.SpotLight.Color = colour
end

function module:animPostVortex()
	self:animFakeHorizon(config.animIdActive[1], config.horizonActivateFadeInTime)

	local colour = self:toColor(config.horizonColour[3])
	horizon.Color = colour
	horizon.SpotLight.Color = colour
end

function module:animDeactivation()

	-- For pegasus dialing animation
	for _,v in pairs(fakeSymbols) do
		v:Destroy()
	end
	fakeSymbols = {}

	for i = 1, config.numSymbols do
		local symbol = config:getSymbol(i)
		if (symbol) then
			symbol.Color = self:toColor(config.symbolColour[false])
			symbol.Material = config.symbolMat[false]
			symbol.Transparency = 0

			local decal = symbol:FindFirstChild("Decal")
			if (decal) then decal.Transparency = 0 end
		end
	end

	if (horizon) then
		local front = horizon:FindFirstChild("eh_front")
		local back = horizon:FindFirstChild("eh_back")

		horizon.Sound:Stop()
		self:playGateSound(config.wormholeClose)

		wait(config.horizonDeactivateAnimStartOffset)

		self:animFakeHorizon(config.animIdInit[1], config.horizonDeactivateFadeInTime)

		stopHorizonAnim = true

		local animStepTime = config.horizonDeactivateFadeOutTime / #config.animIdInit
		for i=1, #config.animIdInit do
			front.Texture = locatorPrefix..config.animIdInit[i]
			back.Texture = front.Texture
			wait(animStepTime)
		end

		self:removeHorizon()

		wait(0.1) -- Pause a small amount before darkening chevrons
	end

	for i=1, config.numChevrons do
		self:lightChevron(false, i)
	end
end

function module:animFakeHorizon(fadeToDecalId, animLength)
	if (not horizon) then error("No horizon") return end

	local front = horizon:FindFirstChild("eh_front")
	local back = horizon:FindFirstChild("eh_back")

	local tempHorizon = horizon:Clone()
	local tempFront = tempHorizon:FindFirstChild("eh_front")
	local tempBack = tempHorizon:FindFirstChild("eh_back")
	local tempMesh = tempHorizon:FindFirstChild("Mesh")

	tempHorizon.Name = "FakeHorizon"
	tempHorizon.SpotLight:Destroy()
	tempMesh.Scale = tempMesh.Scale + Vector3.new(0,0,config.fakeHorizonZAdjust)
	tempHorizon.Parent = horizon.Parent

	tempFront.Texture = locatorPrefix..fadeToDecalId
	tempBack.Texture = tempFront.Texture
	tempFront.Transparency = 1
	tempBack.Transparency = 1

	local fadeStepTime = animLength / 20
	for i=19,0,-1 do
		tempFront.Transparency = i/10/2
		tempBack.Transparency = tempFront.Transparency + 0.2

		if (i >= 10) then
			front.Transparency = 1 - (i-10)/10
			back.Transparency = front.Transparency + 0.2
		end

		wait(fadeStepTime)
	end

	front.Texture = locatorPrefix..fadeToDecalId
	back.Texture = front.Texture
	front.Transparency = 0
	back.Transparency = 0.2

	tempHorizon:Destroy()
end

function module:animDial(symbol, chevron, mode)
	if (mode > 3) then
		mode = 3
	elseif (mode < 1) then
		mode = 1
	end

	if (config.dialModeAnim == 1) then
		self:animDialMilkyWay(symbol, chevron, mode)
	elseif (config.dialModeAnim == 2) then
		self:animDialPegasus(symbol, chevron, mode)
	end
end

function module:animDialMilkyWay(symbol, chevron, mode)
	if (mode == 1) or (mode == 2) then
		local chev = config:getChevronLight(chevron)

		self:playGateSound(config.incomingLock, chev)
		wait(0.2)  -- Give audio file a slight amount of time so it's sync'd properly
		self:lightChevron(true, chevron)
		wait(0.3)

	elseif (mode == 3) then
		local c = this:GetCenter()
		local cframeMap = priv.getRotatingPartInfo()

		local symbolPart = config:getSymbol(symbol)
		if (not symbolPart) then
			symbolPart = config:getSymbol(1)
			print("Dialed symbol " .. symbol .. " not found, defaulting to symbol 1")
		end

		local count = 0  -- to prevent continuous rotation

		local rollSound

		local distToSymbol = self:calculateRollDistance(priv.getTopSymbol(), symbol, priv.dialDir)
		if distToSymbol >= config.distBeforeRollSound then
			rollSound = self:playGateSound(config.ringRoll)
		end

		repeat
			-- Move us one symbol forward or backward
			local symbolStep = (2*math.pi)/config.numSymbols
			local rotationStep = symbolStep/config.ringRotationSpeed

			-- How far we are from the original top symbol
			-- This assumes that the original top symbol matches with the rotation part original CFrames
			local symbolDist = module:symbolDistance(priv.getTopSymbol(true), priv.getTopSymbol(), config.numSymbols)

			for i = 1, config.ringRotationSpeed do
				-- Angle to rotate each part relative to the gate and its original CFrame
				local zAdjust = rotationStep*i*priv.dialDir + (-1*symbolDist*symbolStep)

				for rotPart,rotPartCFrame in pairs(cframeMap) do
					rotPart.CFrame = (c*CFrame.Angles(0,0,zAdjust)):toWorldSpace(c:toObjectSpace(rotPartCFrame))
				end

				count = count + rotationStep

				wait()
			end

			-- Update the top symbol
			local topSymbol = priv.getTopSymbol()
			topSymbol = topSymbol + (priv.dialDir * -1)
			if (topSymbol < 1) then topSymbol = config.numSymbols end
			if (topSymbol > config.numSymbols) then topSymbol = 1 end

			priv.setTopSymbol(topSymbol)

		until (priv.getTopSymbol() == symbol)
			or (count > 2*math.pi) -- Something went wrong here, stop rotating

		priv.dialDir = priv.dialDir*-1

		if rollSound then
			rollSound:Stop()
		end

		self:animLock(chevron)
		symbolPart.Color = self:toColor(config.symbolColour[true])

	end
end

function module:animDialPegasus(symbol, chevron, mode)
	if (mode == 1) then
		local startSymbol = {1,5,9,21,25,29,33,13,17}
		local endSymbol =   {4,8,12,24,28,32,36,16,20}

		local diff = endSymbol[chevron] - startSymbol[chevron]

		for i = startSymbol[chevron], endSymbol[chevron] do
			wait(0.5 / diff) -- Intentionally placed first

			local symbolPart = config:getSymbol(i)
			symbolPart.Color = self:toColor(config.symbolColour[true])
			symbolPart.Material = config.symbolMat[true]
		end

		local chevPart = config:getChevronLight(chevron)
		self:playGateSound(config.incomingLock, chevPart)

		self:lightChevron(true,chevron)

	elseif (mode == 2) then
		local chevSymbols = {4,8,12,24,28,32,36,16,20}

		self:placeFakeSymbol(symbol, chevSymbols[chevron])

		local chevPart = config:getChevronLight(chevron)
		self:playGateSound(config.chevronLock, chevPart)

		self:lightChevron(true,chevron)

		wait(0.5)

	elseif (mode == 3) then

		local rollSound = self:playGateSound(config.ringRoll)

		local chevSymbols = {[0] = 36,4,8,12,24,28,32,36,16,20}

		local prev

		local a = chevSymbols[chevron-1]
		local b = chevSymbols[chevron]
		local c = (math.abs(a-b) > 18) and b or b + (36*priv.dialDir)
		c = (a > c and priv.dialDir > 0) and a + c or c

		local copy = self:placeFakeSymbol(symbol, a)
		prev = a

		for i = a,c,priv.dialDir do
			i = (i < 1) and i + 36 or (i > 36) and i - 36 or i

			local symbolPart = config:getSymbol(i)
			symbolPart.Transparency = 1
			symbolPart.Decal.Transparency = 1
			copy.CFrame = symbolPart.CFrame

			copy.Transparency = 0
			copy.Decal.Transparency = 0

			for cidx=1, chevron - 1 do
				if (i == chevSymbols[cidx]) then
					copy.Transparency = 1
					copy.Decal.Transparency = 1
				end

				if (prev == chevSymbols[cidx]) then
					prev = nil
					break
				end
			end

			if (prev) then
				local prevPart = config:getSymbol(prev)
				prevPart.Transparency = 0
				prevPart.Decal.Transparency = 0
			end

			wait(config.ringRotationSpeed * 0.03)

			prev = i
		end

		rollSound:Stop()
		self:playGateSound(config.chevronLock, config:getChevronLight(chevron))

		priv.dialDir = priv.dialDir*-1

		self:lightChevron(true,chevron)

		wait(0.2)
	end
end

function module:placeFakeSymbol(symbol, loc)
	local copy = config:getSymbol(symbol):Clone()

	copy.Name = "FakeSymbol" .. symbol
	copy.Parent = this.Model
	this.Archivable = false
	copy.Color = self:toColor(config.symbolColour[true])
	copy.Material = config.symbolMat[true]
	copy.Transparency = 0
	copy.Decal.Transparency = 0

	table.insert(fakeSymbols, copy)

	local atCurrent = config:getSymbol(loc)
	atCurrent.Decal.Transparency = 1
	atCurrent.Transparency = 1
	copy.CFrame = atCurrent.CFrame

	return copy
end

function module:animLock(n)
	local c = this:GetCenter()
	local lockParts = config:getLockingParts()

	self:lightChevron(true,config.topChevron)

	local topChev = config:getChevronLight(config.topChevron)
	self:playGateSound(config.chevronLock, topChev)

	for dir = -1,1,2 do
		for step = 1,6 do
			local u = (c*CFrame.Angles(-math.pi/2,0,0)).lookVector

			for i = 1,#lockParts do
				lockParts[i][1].CFrame = lockParts[i][1].CFrame + (u*dir*lockParts[i][2])/24
			end

			wait(0.1)
		end

		self:lightChevron(true,n)
		wait(0.1)
	end

	if (n < config.topChevron) then
		self:lightChevron(false,config.topChevron)
	end
end

function module:lightChevron(on,num)
	on = (type(on) == "boolean") and on or false	-- [on] must be boolean

	local chevLight = config:getChevronLight(num)
	local sideLight = config:getChevronSideLight(num)

	chevLight.Color = self:toColor(config.chevColour[on])
	chevLight.Reflectance = config.chevRefl[on]
	chevLight.Transparency = config.chevTrans[on]
	chevLight.Material = config.chevMat[on]
	chevLight.PointLight.Enabled = on

	sideLight.Color = self:toColor(config.lightColour[on])
	sideLight.Reflectance = config.lightRefl[on]
	sideLight.Transparency = config.lightTrans[on]
	sideLight.Material = config.lightMat[on]
end

function module:calculateRollDistance(symbolTop, symbol, dialDir)
	local distToSymbol

	if symbol == symbolTop then
		distToSymbol = config.numSymbols

	elseif dialDir == -1 then
		if (symbol > symbolTop) then
			distToSymbol = 	symbol - symbolTop
		else
			distToSymbol = (config.numSymbols - symbolTop) + symbol
		end

	else -- dialDir == 1
		if (symbol > symbolTop) then
			distToSymbol = (config.numSymbols - symbol) + symbolTop
		else
			distToSymbol = symbolTop - symbol
		end
	end

	return distToSymbol
end

function module:calculateDialTime(topSymbol, dialQueue, chevronsLocked, mode)
	if (mode <= 2) then return #dialQueue * 0.5 end

	local timePerSymStep = config.ringRotationSpeed * 0.03

	local totalTime = 0
	local tempDD = priv.dialDir

	if (config.dialModeAnim == 1) then
		local lockTime = 1.4

		for i = 1, #dialQueue do
			local toDial = dialQueue[i]

			local symbolDist = self:calculateRollDistance(topSymbol, toDial, tempDD)

			-- Mitigate issue where the timing would be much longer than it should be
			-- It's better to be incorrect by providing a shorter time than longer here
			if (symbolDist == config.numSymbols) then
				symbolDist = 0
			end

			local steps = symbolDist * timePerSymStep

			totalTime = totalTime + steps + lockTime

			tempDD = tempDD * -1
			topSymbol = toDial
		end
	else
		local lockTime = 0.2
		local chevSymbols = {[0] = 36,4,8,12,24,28,32,36,16,20}
		local currChev = chevronsLocked + 1

		for i = 1, #dialQueue do
			local toDial = dialQueue[i]

			local a = chevSymbols[currChev-1]
			local b = chevSymbols[currChev]
			local c = math.abs(a - b)
			local d = math.min(c, math.abs(36 - c))

			if tempDD > 0 then
				d = d + 36
			else
				d = 36 - d
			end

			totalTime = totalTime + (timePerSymStep * d) + lockTime

			tempDD = tempDD * -1
			currChev = currChev + 1
		end
	end

	return totalTime
end

--------

--[[
Utility Functions

	self:toColor(string or Color3 c)
	self:symbolDistance(int anchor, int target, int numSymbols)
]]--

function module:toColor(c)
	if (type(c) == "string") then
		return BrickColor.new(c).Color
	else
		return c
	end
end

function module:symbolDistance(anchor, target, numSymbols)
	return (numSymbols - anchor + target) % numSymbols
end

--------

--[[
Horizon Functions

	addHorizon(function onHorizonTouched)
	removeHorizon()
]]--

function module:addHorizon(onHorizonTouched)
	if (horizon) then error("Horizon already exists") end

	horizon = self:spawnHorizon(onHorizonTouched)
end

function module:removeHorizon()
	if (not horizon) then error("Horizon does not exist") end

	horizon:Destroy()
	horizon = nil
end

--------

--[[
Sound Functions

	spawnSoundInstance(id, parent)
	playGateSound(id, loop, customParent=this.Model)
]]--

function module:spawnSoundInstance(id, parent)
	local s = Instance.new("Sound")

	if id ~= "" then
		s.SoundId = locatorPrefix .. id
	end

	s.Volume = config.soundVolume
	s.EmitterSize = config.soundEmitterSize
	s.MaxDistance = config.soundMaxDistance
	s.Archivable = false
	s.Parent = parent

	return s
end

function module:playGateSound(id, customParent)
	local c = this:GetCenter()
	local p
	local s

	if (customParent) then
		s = self:spawnSoundInstance(id, customParent)
		p = s -- when s stops, delete s instead of its parent
	else
		p = Instance.new("Part")
		p.Name = "SoundEmitter"
		p.CFrame = c
		p.Transparency = 1
		p.Size = Vector3.new(0,0,0)
		p.Anchored = true
		p.CanCollide = false
		p.Archivable = false
		p.Parent = this.Model

		s = self:spawnSoundInstance(id, p)
	end

	s:Play()

	s.Ended:connect(function()
		p:Destroy()
	end)
	s.Stopped:connect(function()
		p:Destroy()
	end)

	return s
end


--------
--[[
Initialize Functions

	initialize(this, config, privateAPI)
]]--

function module:initialize(givenThis, givenConfig, givenPrivAPI)
	this = givenThis
	config = givenConfig
	priv = givenPrivAPI
end

-- Return completed module
return module

-- Legend26, Ganondude