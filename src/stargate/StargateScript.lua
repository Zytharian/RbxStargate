--------
--  Stargate Script
--  version 20.7
--------
--  scripting by Legend26
--  modeling by andy6a6, Flames911
--  vortex mesh by devSparkle
-- (Stargates up to version 19.5 authored solely by Ganondude)
--------
--  Released: 		December 29, 2018
--  Last Updated: 	April 22, 2023
--------
--  This script drives the stargate's operations.
--------

--[[
Indicators:
'N'		-- new in version 20 and does not exist in Ganondude's Stargates
'B'		-- exists only for backwards compatibility

FSM means Finite State Machine.

--------
Global Stargate API:
N	_G.Stargates
		- All
		- Assets
			- Sounds
			- Decals
			- Versions
			- AddSounds(array of Int)
			- AddDecals(array of Int)
			- AddVersion(string,number,number)
		- FindStargate(model or string)	-- returns: Stargate or nil		-- given a Stargate's name or model, returns the gate's _G.Stargates.All object

B	_G.all_Stargates						-- Same as _G.Stargates.All

--------
Data is indexed with a dot operator (.)
	Ex. Stargate.Model
	Ex. Stargate.MainPart

All data is read-only.

--------
public data

	Model					-- type: Model 					-- the Stargate's model
	MainPart				-- type: BasePart 				-- the Stargate's main part
	ConnectedTo				-- type: Stargate or nil		-- the Stargate to which this Stargate is currently connected (nil if not connected)

	Address					-- type: StringValue			-- the object containing the Stargate's address value
	Network					-- type: IntValue				-- the object containing the Stargate's network value
	Origin					-- type: IntValue				-- the object containing the Stargate's origin value
	9SymbolCode				-- type: StringValue			-- the object containing the Stargate's 9 symbol code value
N	NetworkAccessPoint		-- type: BooleanValue			-- the object determining whether the Stargate is a network access point
N	AddressHidden			-- type: BooleanValue			-- the object determining whether the Stargate's address should be hidden
N	MaxDialLength			-- type: IntValue				-- the object determining how many symbols the Stargate can dial including Point of Origin

N	State					-- type: GateState Enum			-- the Stargate's current FSM state
B	Active					-- type: BoolValue				-- the object containing the Stargate's active value
	DialMode				-- type: IntValue				-- the object containing the Stargate's dialing mode value
	Priority				-- type: IntValue				-- the object containing the Stargate's priority value (lower is more important)

	LongDistance			-- type: number					-- the placeid for an inter-place teleport (if current dial is inter-place, otherwise 0)

N	VERSION_MAJOR			-- type:number					-- Stargate major version
N	VERSION_MINOR			-- type:number					-- Stargate minor version

N	GateState				-- type: Enum					-- all possible FSM states
		-- Enum values: IDLE, INCOMING, DIALING, PRE_CONNECTING, CONNECTING, CONNECTION_FAILED,
		--              ACTIVATING_OUTGOING, ACTIVATING_INCOMING, ACTIVE_INCOMING, ACTIVE_OUTGOING,
		--              DEACTIVATING, DISABLED

--------
Methods are called with a colon operator (:)
	Ex. Stargate:IsActive()
--------
public methods

	IsActive()				-- returns: boolean				-- true if the Stargate is active (not in dialing or idle state)
B	IsBusy()				-- returns: boolean				-- true if the Stargate is performing either the dialing or incoming animation
	IsBlocked()				-- returns: boolean				-- true if the Stargate has something blocking travel through it

	GetCenter()				-- returns: CFrame				-- CFrame at the center of the Stargate, facing forward
	GetRadius()				-- returns: number				-- the approximate radius of the Stargate (measured from chevrons)
B	GetVelocity()			-- returns: Vector3, Vector3	-- returns 0,0,0 and 0,0,0; for v19.5 backward compatability only

	Incoming(Stargate)		-- returns: nil					-- used by another Stargate to dial in
	Ripple(Vector3)			-- returns: nil					-- plays a Ripple animation at the position passed in (position in object coordinates)

	FindByProximity(Vector3, number)
							-- returns: Stargate or nil		-- finds the closest Stargate to [Vector3 position] within [number range] (returns nil if no Stargate found)

N	FindDialable(bool, bool)-- returns: array of			-- finds all stargates this gate can dial within the configuration's minLength and maxLength settings
							{Stargate, DialAddress, PlaceId=0, Name}
N	Dial(table OR number)	-- returns: nil					-- dials the stargate using the symbol(s) passed to the method
N	GetDialedSymbols()		-- returns: array of number		-- returns a list of symbols (in order) that have been or are currently being dialed

N	Connect()				-- returns: nil					-- attempts to connect to another stargate using the dialed symbols
N	Activate()				-- returns: nil					-- activates the wormhole; used by gates dialing into this one after they call Incoming(Stargate)
N	Deactivate()			-- returns: nil					-- deactivates the gate
N	SetDisabled(bool,bool)	-- returns: nil					-- call only when gate is in IDLE or DISABLED states, can be used to stop a gate from being dialed or dialing out

N	InvalidateCache()		-- returns: nil					-- deletes any data currently cached internally (use when gate is moved or when the available addresses change)

N	GetStateName(number)	-- returns: string or ""		-- gets the name of a gate state, for debugging

--------
Events work slightly differently from Roblox events.
	Ex.
	local disconnect = Stargate:OnStateChanged(function (Stargate, NewState) ... end)
	disconnect() -- to stop receiving the event
--------
public events

N	OnStateChanged(h)		-- args: Stargate,NewState				-- fired when the Stargate's FSM state is changed
N   OnChevronLocked(h)		-- args: Stargate,ChevronNumber,Symbol	-- fired when a symbol is locked

]]--


----
--------
-- Do not alter anything in this script.
--------
----

local API
local ALL 						-- API.All

local config = require(script.StargateConfig)
local anim = require(script.StargateAnims)

local animShared = {
	getTopSymbol = nil,
	setTopSymbol = nil,
	dialDir = -1,
}

local isDialAnimPlaying = false
local isIncomingDialAnimPlaying = false
local isTransporting = false
local shimDebounce = false

local dialQueue = {}
local currentDialed = {}
local currentInput = 0			-- Chevron to lock for dial animation

local activeTimer = 0

local cache = {
	center = nil,
	radius = nil,
	originalTopSymbol = nil,
	topSymbol = nil,
	dialable = nil,
	mainPartCFrame = nil,
	rotatePartCFrameMap = nil,
}

local GateState = {
	IDLE=1, INCOMING=2, DIALING=3, CONNECTING=4, CONNECTION_FAILED=5, ACTIVATING_INCOMING=6,
	ACTIVATING_OUTGOING=7, ACTIVE_INCOMING=8, ACTIVE_OUTGOING=9, DEACTIVATING=10, DISABLED=11,
	PRE_CONNECTING=12,
}

local stateHandlers = {}
local chevronLockedHandlers = {}

-- Used by long-running Stargate API functions to prevent halting in the middle of something
-- when the calling script is destroyed. Especially a problem with tools when the player dies.
local thisBindableFunction = Instance.new("BindableFunction")
thisBindableFunction.OnInvoke = function(callback) return callback() end
local executeInThisContext = function(callback) thisBindableFunction:Invoke(callback) end

-- Functions in 'this' must not use "self" and should instead use the "this" variable.
-- This is due to how the "this" metatable is set up.
-- 'this' should not be exposed by any code below. Instead, 'exported' should be used.
local exported = {}
local this
this = {

	-- Public Data
	Model = nil,
	MainPart = nil,
	ConnectedTo = nil,

	Address = nil,
	Network = nil,
	Origin = nil,
	["9SymbolCode"] = nil,
	NetworkAccessPoint = nil,
	AddressHidden = nil,
	MaxDialLength = nil,

	State = nil,
	Active = nil,
	DialMode = nil,
	Priority = nil,

	LongDistance = nil,

	VERSION_MAJOR = 20,
	VERSION_MINOR = 7,

	GateState = nil,

	-- Functions
	IsActive = function() return isActive() end,
	IsBlocked = function() return isBlocked() end,

	IsBusy = function() return isBusy() end,

	GetCenter = function() return getCenter() end,
	GetRadius = function() return getRadius() end,
	GetVelocity = function() return Vector3.new(0,0,0), Vector3.new(0,0,0) end,

	Incoming = function(_, sg) executeInThisContext(function() incoming(sg) end) end,
	Ripple = function(_, pos) executeInThisContext(function() anim:animRipple(pos) end) end,

	FindByProximity = function(_, pos, rng) return findByProximity(pos,rng) end,

	FindDialable = function(_, ignoreMaxDialLength, ignoreHidden) return findDialable(ignoreMaxDialLength, ignoreHidden) end,
	Dial = function(_, symbol) executeInThisContext(function() dial(symbol) end) end,
	GetDialedSymbols = function() local x={} for k,v in pairs(currentDialed) do x[k]=v end return x end,
	Connect = function() executeInThisContext(function() connect() end) end,
	Activate = function() executeInThisContext(function() activate() end) end,
	Deactivate = function() executeInThisContext(function() deactivate() end) end,
	SetDisabled = function(_, locked, tryDeactivate) executeInThisContext(function() setDisabled(locked, tryDeactivate) end) end,

	InvalidateCache = function() for k,v in pairs(cache) do cache[k] = nil end end,

	GetStateName = function(_, stateToName)
		for name,state in pairs(GateState) do
			if state == stateToName then return name end
		end
	end,

	-- Events
	OnStateChanged = function(_, h) return onStateChanged(h) end,
	OnChevronLocked = function(_, h) return onChevronLocked(h) end,
}

--------

--[[
Status Functions

	isActive()
	isBusy()

	isBlocked()

	keepDialing()

	atLeastVer20(Stargate sg)
	onStateChanged(Function handler)
	onChevronLocked(Function handler)
]]--

function isActive()
	return (this.State ~= GateState.IDLE) and (this.State ~= GateState.DIALING) and (this.State ~= GateState.PRE_CONNECTING)
end

function isBusy()
	return (isDialAnimPlaying) or (isIncomingDialAnimPlaying)
end

function isBlocked()
	local blockTypes = {"TravelBlock","Iris","Shield"}

	for i = 1,#blockTypes do
		local block = this.Model:FindFirstChild(blockTypes[i],true)
		if (block) and ((block:IsA("BasePart") and block.CanCollide) or (block:FindFirstChild("Closed") and block.Closed.Value)
			or (block:FindFirstChild("Active") and block.Active.Value))
		then
			return true
		end
	end

	return false
end

function keepDialing()
	return (this.State == GateState.DIALING or this.State == GateState.PRE_CONNECTING or this.State == GateState.CONNECTING)
		and (#dialQueue > 0)
end

function atLeastVer20(sg)
	return sg.VERSION_MAJOR and sg.VERSION_MAJOR >= 20
end

function onStateChanged(handler)
	return connectHandler(stateHandlers, handler)
end

function onChevronLocked(handler)
	return connectHandler(chevronLockedHandlers, handler)
end

--------

--[[
Get Functions
	getCenter()
	getRadius()
	getRotatingPartInfo()
	getTopSymbol(Bool original)

	Note: these methods store their results in the cache.
]]--

function getCenter()
	if (cache.center) and (cache.mainPartCFrame == this.MainPart.CFrame) then return cache.center end

	local chev1 = config:getChevron(1).Position
	local chev2 = config:getChevron(2).Position
	local chev3 = config:getChevron(3).Position
	local chevT = config:getChevron(config.topChevron).Position

	local mid = (chev1 + chev3)/2
	local dir = (mid - chev2).unit

	local cpos = chev2 + dir*getRadius()	-- center position

	local bk = (chev1 - cpos):Cross(chev3 - cpos).unit	-- z
	local up = (chevT - cpos).unit						-- y
	local rt = up:Cross(bk).unit						-- x

	local center = CFrame.new(cpos.x,cpos.y,cpos.z, rt.x,up.x,bk.x, rt.y,up.y,bk.y, rt.z,up.z,bk.z)
	center = center * CFrame.new(0, 0, config.positionZAxisAdjust)

	cache.mainPartCFrame = this.MainPart.CFrame
	cache.center = center

	return center
end

function getRadius()
	if (cache.radius) and (cache.mainPartCFrame == this.MainPart.CFrame) then return cache.radius end

	local chev1 = config:getChevron(1).Position
	local chev2 = config:getChevron(2).Position

	local a = (chev1 - chev2).magnitude
	local A = (2*math.pi)/config.numChevrons
	local B = (math.pi - A)/2

	local r = (math.sin(B)*a)/math.sin(A)

	local radius = math.floor(r*1e3 + 0.5)/1e3	-- round to three decimal places
	cache.radius = radius

	cache.mainPartCFrame = this.MainPart.CFrame
	return radius
end

function getRotatingPartInfo()
	if (cache.rotatePartCFrameMap) and (cache.mainPartCFrame == this.MainPart.CFrame) then return cache.rotatePartCFrameMap end

	local map = {}

	for _,v in pairs(config:getRotatingParts()) do
		map[v] = v.CFrame
	end

	cache.rotatePartCFrameMap = map
	return map
end

function getTopSymbol(original)
	if not original and cache.topSymbol then return cache.topSymbol end
	if original and cache.originalTopSymbol then return cache.originalTopSymbol end

	local topChev = config:getChevronLight(config.topChevron)

	local num = 1
	local par = config:getSymbol(num)
	local dst = (topChev.Position - par.Position).magnitude

	for i=2,config.numSymbols do
		local curSym = config:getSymbol(i)
		local curDst = (curSym.Position - topChev.Position).magnitude

		if (curDst < dst) then
			num = i
			par = curSym
			dst = curDst
		end
	end

	cache.topSymbol = num
	cache.originalTopSymbol = num
	return num
end

--------

--[[
Set Functions
	setTopSymbol(number symbol) -- note: this method interfaces with the cache

	setState(State state)

	setGateLocked(bool locked)
]]--

function setTopSymbol(num)
	cache.topSymbol = tonumber(num)
end

function setState(state)
	if (type(state) ~= "number") then error("State must be a number") end
	this.State = state
	fireHandlers(stateHandlers, "OnStateChanged", {exported, state})
end

function setDisabled(locked, tryDeactivate)
	if (this.State ~= GateState.IDLE) and (this.State ~= GateState.DISABLED) then

		if (tryDeactivate) then
			deactivate()
		else
			error("Stargate must be in IDLE or DISABLED states. State=" .. this.State)
		end
	end

	if (this.State == GateState.IDLE) or (this.State == GateState.DISABLED)  then
		this.State = locked and GateState.DISABLED or GateState.IDLE
	end
end

--------

--[[
State Transition Functions

	dial(table OR number symbol)				-- returns immediately
	incoming(Stargate sg)
	connect()
	connectTo(Stargate sg)
	activate([function tpCallback])
	activeOutgoing()
	deactivate()

	Unless otherwise noted, the functions above return only once the animation has completed.
]]--

function dial(param)
	local symbolsToDial = type(param) == "table" and param or {param}

	if (#symbolsToDial == 0) then
		return
	end

	if (this.State ~= GateState.IDLE) and (this.State ~= GateState.DIALING) then
		error("Stargate must be in IDLE or DIALING states. State=" .. this.State)
	end

	local totalDialSymbolCount = #currentDialed + #symbolsToDial
	if (totalDialSymbolCount > config.maxLength) then
		error("Cannot dial more than " .. config.maxLength .. " symbols (hard limit)")
	end

	if (totalDialSymbolCount > this.MaxDialLength.Value) then
		error("Cannot dial more than " .. this.MaxDialLength.Value .. " symbols (soft limit)")
	end

	for _,symbol in pairs(symbolsToDial) do
		if (type(symbol) ~= "number") or (math.floor(symbol) ~= symbol) or (symbol < 1) or (symbol > config.numSymbols) then
			error("Invalid input symbol " .. tostring(symbol))
		end

		-- Do this before changing state so that state change handlers see the symbol
		table.insert(dialQueue, symbol)
		table.insert(currentDialed, symbol)
	end

	setState(GateState.DIALING)

	if (not isDialAnimPlaying) then
		isDialAnimPlaying = true

		local mode = this.DialMode.Value

		-- Spin off dial animation to another coroutine if not already running
		coroutine.wrap(function()
			while (keepDialing()) do
				currentInput = currentInput + 1
				local currentSymbol = dialQueue[1]
				anim:animDial(currentSymbol, currentInput, mode)
				fireHandlers(chevronLockedHandlers, "OnChevronLocked", {exported, currentInput, currentSymbol})
				table.remove(dialQueue,1)
			end
			isDialAnimPlaying = false
		end)()
	end
end

function incoming(sg)
	if (this.State ~= GateState.IDLE) and (this.State ~= GateState.DIALING) and (this.State ~= GateState.PRE_CONNECTING) then
		error("Cannot receive incoming wormhole")
	end

	setState(GateState.INCOMING)
	isIncomingDialAnimPlaying = true

	while (isDialAnimPlaying) do
		wait()
	end

	anim:animDeactivation() -- Resets chevrons + symbols (has no horizon at this time so anim completes instantly)

	this.ConnectedTo = sg or exported

	-- do incoming animation (the symbols "dialed" here don't matter) just the chevrons
	for _,w in pairs({1,2,3,8,9,4,5,6,7}) do
		anim:animDial(w, w, config.incomingMode)
	end

	isIncomingDialAnimPlaying = false
end

function connect()
	if (this.State ~= GateState.DIALING) then
		error("Stargate must be in DIALING state. State=" .. this.State)
	end
	setState(GateState.PRE_CONNECTING)

	local connected
	for _,v in pairs(findDialable(false, true)) do
		if (arrayEqual(currentDialed, v.DialAddress)) then

			print("Stargate: found address match")

			if (v.PlaceId ~= 0) then
				this.LongDistance = v.PlaceId
				connected = exported
			else
				connected = v.Stargate
			end
		end
	end

	local dialTimeLeft
	if (#dialQueue > 0) then
		-- Note: If connect() is called during the chevron lock anim when a repeated symbol is chosen (e.g. 1,1,...)
		-- then this result to be several seconds off since it assumes that the ring is still rotating
		-- This is rare, and not that important, so I'm leaving it for later.
		local topSymbol = getTopSymbol() -- currentDialed[#currentDialed - #dialQueue] or getTopSymbol()
		dialTimeLeft = anim:calculateDialTime(topSymbol, dialQueue, #currentDialed-#dialQueue, this.DialMode.Value)
	else
		dialTimeLeft = 0
	end

	local completeTime = tick() + dialTimeLeft
	local approximateIncomingTime = 9*0.5
	while (isDialAnimPlaying) do
		if (connected) and (connected.Model == this.Model or not connected:IsActive())
			and (completeTime - tick() <= approximateIncomingTime)
		then
			break
		end

		if (this.State ~= GateState.PRE_CONNECTING) then
			return
		end

		wait()
	end

	if (this.State ~= GateState.PRE_CONNECTING) then
		return
	end

	if (not connected) or (connected.Model ~= this.Model and connected:IsActive()) then
		print("Stargate: connection failed")

		anim:playGateSound(config.dialFail, false)

		setState(GateState.CONNECTION_FAILED)
		deactivate()

	else
		print("Stargate: connection successful")

		connectTo(connected)
	end

end

function connectTo(sg)
	setState(GateState.CONNECTING)

	this.ConnectedTo = sg

	if (sg.Model ~= this.Model) then -- gates use self connections when dialing for an inter-place teleport
		sg:Incoming(exported)

		-- This is for backwards compatibility
		-- sg:Incoming() completes the incoming dial animation before returning on v20
		if (not atLeastVer20(sg)) then
			local n = 0
			repeat
				n = n + 1
				wait(0.1)
			until (not sg:IsBusy()) or (n > 100) -- give gate being dialed time (10s) to complete incoming animation
		end
	end

	while (isDialAnimPlaying) do
		wait()
	end

	if (sg.ConnectedTo.Model == this.Model) then -- prevents two gates simultaneously dialing into one

		shimDebounce = true
		this.Active.Value = true
		shimDebounce = false

		if (sg.Model ~= this.Model) and (atLeastVer20(sg)) then
			-- Spin off another coroutine to avoid waiting for the other gate's activation anim
			coroutine.wrap(function()
				sg:Activate()
			end)()
		else
			sg.Active.Value = true
		end

		activate()
	else
		deactivate()
	end
end

function activate(tpCallback)
	if (this.State ~= GateState.INCOMING) and (this.State ~= GateState.CONNECTING) then
		error("Stargate must be in INCOMING or CONNECTING states. State=" .. this.State)
	end

	local isIncoming = this.State == GateState.INCOMING

	setState(isIncoming and GateState.ACTIVATING_INCOMING or GateState.ACTIVATING_OUTGOING)

	shimDebounce = true
	this.Active.Value = true
	shimDebounce = false

	-- On incoming, dial anim may be playing so check for this
	if (isIncoming) then
		while (isIncomingDialAnimPlaying) do
			wait()
		end
	end

	isTransporting = true  -- prevents travel during activation sequence

	anim:addHorizon(tpCallback or onHorizonTouched)
	anim:animPreVortex()

	if (this:IsBlocked()) then
		wait(1.4)
	else
		anim:animVortex(onVortexTouched)
	end

	wait(0.2)
	anim:animPostVortex()

	isTransporting = false

	-- Spin off animating the horizon to another coroutine
	coroutine.wrap(function()
		anim:animHorizon()
	end)()

	if (isIncoming) then
		setState(GateState.ACTIVE_INCOMING)
	else
		activeOutgoing()
	end
end

function activeOutgoing()
	if (this.State ~= GateState.ACTIVATING_OUTGOING) then
		error("Stargate must be in ACTIVATING state. State=" .. this.State)
	end

	setState(GateState.ACTIVE_OUTGOING)

	local sg = this.ConnectedTo

	activeTimer = config.minTime
	local n = 0

	if (atLeastVer20(sg)) then
		while (sg.State == sg.GateState.ACTIVATING_INCOMING) do
			wait()
		end
	end

	while ((activeTimer > 0) and (n <= config.maxTime)) or (n <= config.minTime) do

		if (this.State ~= GateState.ACTIVE_OUTGOING) or (not sg:IsActive())
			or (atLeastVer20(sg) and sg.Model ~= this.Model and sg.State ~= sg.GateState.ACTIVE_INCOMING)
		then
			break
		end

		activeTimer = activeTimer - 0.5
		n = n + 0.5
		wait(0.5)
	end

	-- Shut down other gate
	if (atLeastVer20(sg)) then
		if (sg.State == sg.GateState.ACTIVE_INCOMING and sg.Model ~= this.Model) then
			-- Use a coroutine to avoid waiting for its deactivate animation
			coroutine.wrap(function()
				sg:Deactivate()
			end)()
		end
	else
		sg.Active.Value = false
	end

	shimDebounce = true
	this.Active.Value = false
	shimDebounce = false

	-- Shut down this gate
	-- Note: Deactivate() could have been called sooner, so check state here.
	if (this.State == GateState.ACTIVE_OUTGOING) then
		deactivate()
	end
end

function deactivate()
	if (this.State ~= GateState.ACTIVE_INCOMING) and (this.State ~= GateState.ACTIVE_OUTGOING)
		and (this.State ~= GateState.DIALING) and (this.State ~= GateState.IDLE)
		and (this.State ~= GateState.CONNECTION_FAILED) then
		warn("Stargate must be in ACTIVE_INCOMING, ACTIVE_OUTGOING, CONNECTION_FAILED, DIALING, or IDLE states. State=" .. this.State)
		return
	end

	local cooldownTimer = (this.State == GateState.ACTIVE_OUTGOING) and config.cooldownTime or 0

	setState(GateState.DEACTIVATING)

	-- If we're canceling DIALING then wait for the anim to finish
	while (isDialAnimPlaying) do wait() end

	this.ConnectedTo = nil
	this.LongDistance = 0

	isDialAnimPlaying = false
	isTransporting = false

	dialQueue = {}
	currentDialed = {}
	currentInput = 0

	animShared.dialDir = -1

	activeTimer = 0

	anim:animDeactivation()  -- this removes the horizon

	while(cooldownTimer > 0) do
		wait(1)
		cooldownTimer = cooldownTimer - 1
	end

	shimDebounce = true
	this.Active.Value = false
	shimDebounce = false

	setState(GateState.IDLE)
end

--------

--[[
Transport Functions

	getPartToMove(BasePart hit)
	transport(BasePart part, Stargate sg, boolean activeBlock)
]]--

function getPartToMove(hit)
	if (hit == nil) or (hit.Parent == nil) or (not hit:IsA("BasePart")) then return end

	local par = hit.Parent


	if (par == game.Workspace) then
		return hit
	else
		if (par:IsA("Model")) then

			if (par:FindFirstChild("Humanoid")) and (par:FindFirstChild("Torso") or par:FindFirstChild("HumanoidRootPart")) or par.PrimaryPart then
				return par:FindFirstChild("HumanoidRootPart") or par.PrimaryPart,true
			end

			-- We assume the primary part will be usually set to the engine for vehicles
			if (par.PrimaryPart) then
				return par.PrimaryPart
			end

			local skateboard = par:FindFirstChild("SkateboardPlatform")
			if (skateboard) then return skateboard end

			local vSeat = par:FindFirstChild("VehicleSeat")
			if (vSeat) then return vSeat end

			local engine = par:FindFirstChild("Engine",true)
			if (engine) then return engine end

			return hit
		elseif (par:IsA("Accoutrement")) or (par:IsA("BackpackItem")) then
			if (not par.Parent:FindFirstChild("Humanoid")) then
				return par:FindFirstChild("Handle")
			end
		elseif (par.Parent:IsA("Model")) then
			local engine = par.Parent:FindFirstChild("Engine",true)
			if (engine) then return engine end
		end
	end

	return nil
end

function transport(part,sg,activeBlock)
	if (part == nil) then return end

	local from = getCenter()

	local vel = part.Velocity
	local rotVel = part.RotVelocity
	part.Velocity = Vector3.new(0,0,0)

	local d = from.lookVector:Dot(part.CFrame.p - from.p)	-- dot product to find distance from [part] to [from]

	local pos = from:pointToObjectSpace(part.Position + from.lookVector*-d)
	coroutine.wrap(function() anim:animRipple(pos) end)()

	------
	------

	if (sg == nil) then return end

	local to = sg:GetCenter()
	coroutine.wrap(function() this.ConnectedTo:Ripple(pos*Vector3.new(-1,1,1)) end)()

	local newCf = (to*CFrame.Angles(0,math.pi,0)):toWorldSpace(from:toObjectSpace(part.CFrame)) + to.lookVector*d	-- the vector addition places the object at the event horizon

	if (activeBlock) then
		part.CFrame = CFrame.new(0, (workspace.FallenPartsDestroyHeight - 500), 0)
	else
		if (part.Name == "Engine") then
			part.CFrame = newCf + (to.lookVector*part.Size.Z)/2

			local bg = part:FindFirstChild("BodyGyro")
			if (bg) then bg.cframe = part.CFrame end
		elseif ((part.className == "SkateboardPlatform") or (part.className == "VehicleSeat")) and (part.Parent.Parent) then
			if (part.Parent.Parent == game.Workspace) then
				part.Parent:MoveTo(newCf.p)
			elseif (part.Parent.Parent:FindFirstChild("Humanoid")) then
				part.Parent.Parent:MoveTo(newCf.p)
			end
		else
			part.CFrame = newCf
		end

		part.Velocity = (to*CFrame.Angles(0,math.pi,0)):vectorToWorldSpace(from:vectorToObjectSpace(vel))
		part.RotVelocity = rotVel
	end
end

--------

--[[
OnTouched Functions

	onHorizonTouched(BasePart hit)
	onVortexTouched(BasePart hit)
]]--

function onHorizonTouched(hit)
	if (this.State ~= GateState.ACTIVE_OUTGOING) or (isTransporting) or (isBlocked()) or (hit:IsDescendantOf(this.Model)) then return end
	isTransporting = true

	local movePart,hmn = getPartToMove(hit)

	if (not movePart) or ((movePart.Position - getCenter().p).magnitude > getRadius()*1.5) then isTransporting = false return end
	print("Stargate: transporting "..movePart.Name)

	local ff = movePart:FindFirstChild("ForceField")
	if (not ff) and (movePart.Parent ~= game.Workspace) then ff = movePart.Parent:FindFirstChild("ForceField") end

	local activeBlock = this.ConnectedTo:IsBlocked() and (not ff)

	if (hmn) then
		if (this.LongDistance >= 1) then

			local player = game.Players:GetPlayerFromCharacter(movePart.Parent)
			if (player) then
				player.Character:Destroy()
				player.Character = nil

				game:GetService("TeleportService"):TeleportToSpawnByName(this.LongDistance, "StargateSpawn", player)

				coroutine.wrap(function ()
					wait(20)
					if (player.Parent) then
						player:LoadCharacter()
					end
				end)()
			end

		elseif (not movePart.Parent:FindFirstChild(config.localScript)) and (not activeBlock) then
			local scr = script:FindFirstChild(config.localScript):Clone()

			local sync = Instance.new("CFrameValue")
			sync.Name = "Sync"
			sync.Value = movePart.CFrame
			sync.Parent = scr

			scr.Disabled = false
			scr.Parent = movePart

			game:GetService("Debris"):AddItem(scr, 5)
		end
	end

	if (this.LongDistance < 1) then
		local ff = movePart:FindFirstChild("ForceField")
		if (not ff) and (movePart.Parent ~= game.Workspace) then ff = movePart.Parent:FindFirstChild("ForceField") end

		transport(movePart, this.ConnectedTo, activeBlock)
	else
		transport(movePart,nil,false)
	end

	activeTimer = config.maxTime/4	-- keeps the gate open a little longer if objects are going through/shuts it down faster if nothing's going through
	isTransporting = false
end

function onVortexTouched(hit)
	if (not isActive()) or (hit == nil) or (hit.Anchored) or (hit:IsDescendantOf(this.Model)) then return end

	if (hit.Parent == game.Workspace) then
		hit:Destroy()
	else
		if (not hit.Parent:FindFirstChild("ForceField")) then
			if (hit.Parent:IsA("Model")) then
				if (hit.Parent:FindFirstChild("Humanoid")) then
					hit.Parent.Humanoid:TakeDamage(20)
				end

				hit:Destroy()
			elseif (hit.Parent:IsA("Accoutrement") or hit.Parent:IsA("BackpackItem")) and (not hit.Parent.Parent:FindFirstChild("Forcefield")) then
				if (hit.Name == "Handle") then
					hit.Parent:Destroy()
				else
					hit:Destroy()
				end
			end
		end
	end
end

--------

--[[
OnChanged Functions

	onActiveChanged()

	For backwards compatibility only. Please use Stargate API for any new work.
]]--

function onActiveChanged()
	if (shimDebounce) then return end

	if (not this.Active.Value) and
		((this.State == GateState.ACTIVE_OUTGOING) or (this.State == GateState.ACTIVE_INCOMING))
	then
		deactivate()
	elseif (this.Active.Value) and (this.State == GateState.INCOMING) then
		activate()
	end
end

--------

--[[
Utility Functions

	arrayEqual(Array a, Array b)
	stringToArray(String s)
	makeReadOnly(Table t)
	copyDialableTable(Table t)
	connectHandler(Table allHandlers, Function handler)
	fireHandlers(Table allHandlers, string name, Table args)
]]--

function arrayEqual(a, b)
	if (#a ~= #b) then
		return false
	end
	for i=1, #a do
		if (a[i] ~= b[i]) then
			return false
		end
	end
	return true
end

function stringToArray(s)
	local arr = {}

	for i in s:gmatch("%w+") do
		local n = tonumber(i)
		if (n == nil) then
			return nil
		end

		table.insert(arr, n)
	end

	return arr
end

function makeReadOnly(t)
	local meta = {
		__index = function(_,idx)
			return t[idx]
		end;
		__newindex = function(_,idx,val)
			error("This table is read-only")
		end;
		__metatable = "The metatable is locked"
	}

	local ro = {}
	setmetatable(ro, meta)

	return ro
end

function copyDialableTable(t)
	local copy = {}
	for k,v in pairs(t) do
		local copyAddr = {}
		for i=1,#v.DialAddress do
			copyAddr[i] = v.DialAddress[i]
		end
		copy[k] = {Stargate = v.Stargate, DialAddress = copyAddr, PlaceId = v.PlaceId, Name = v.Name}
	end
	return copy
end

function connectHandler(allHandlers, newHandler)
	if (type(newHandler) ~= "function") then
		error("Handler must be a function")
	end

	allHandlers[newHandler] = true

	return function()
		allHandlers[newHandler] = nil
	end
end

function fireHandlers(allHandlers, name, args)
	local failed = {}
	for k,_ in pairs(allHandlers) do
		local isOk, err = pcall(k, table.unpack(args))
		if (not isOk) then
			warn("Stargate " .. name .. " handler error: " .. err)
			warn("Stargate: Disconnecting handler due to previous error")
			table.insert(failed, k)
		end
	end
	for _,v in pairs(failed) do
		allHandlers[v] = nil
	end
end

--------

--[[
Search Functions

	findByProximity(Vector3 pos, number range)
	findDialable()
	findAllPossibleDialable()
	findStargate(model or string)
]]--

function findByProximity(pos,range)
	local includeSelf = (pos ~= nil)

	pos = pos or getCenter().p
	range = range or config.maxDistance

	local dist = range
	local temp

	for k,v in pairs(ALL) do
		if (v.Model ~= this.Model) or (includeSelf) then
			local d = (pos - v:GetCenter().p).magnitude
			if (d <= dist) then
				dist = d
				temp = v
			end
		end
	end

	return temp,dist
end

function findDialable(ignoreMaxDialLength, ignoreHidden)
	local dialable = findAllPossibleDialable()
	local valid = {}

	for _,v in pairs(dialable) do
		local okToAdd = true

		if (not ignoreMaxDialLength) and (#v.DialAddress > this.MaxDialLength.Value) then
			okToAdd = false
		end

		if (not ignoreHidden) and (v.Stargate and v.Stargate.AddressHidden and v.Stargate.AddressHidden.Value) then
			okToAdd = false
		end

		if (okToAdd) then
			table.insert(valid, v)
		end
	end

	return valid
end

function findAllPossibleDialable()
	if (cache.dialable) then return copyDialableTable(cache.dialable) end

	local availableAddrs = {}

	for _,sg in pairs(ALL) do
		if (sg.Model ~= this.Model) then

			local address = stringToArray(sg.Address.Value)

			-- Forgive blank network values for backwards compatibility
			local targetNetwork = sg.Network.Value == "" and this.Network.Value or tonumber(sg.Network.Value)

			if (address and targetNetwork) then
				local dialAddress

				if (targetNetwork == this.Network.Value) then -- 7 symbol
					dialAddress = address
					table.insert(dialAddress, this.Origin.Value)
				elseif (sg.NetworkAccessPoint.Value) then -- 9 or 8 symbol
					local code = stringToArray(sg["9SymbolCode"].Value)
					if (code) and (#code == 8) then
						table.insert(code, this.Origin.Value)
						dialAddress = code
					else
						dialAddress = address
						table.insert(dialAddress, targetNetwork)
						table.insert(dialAddress, this.Origin.Value)
					end
				end

				local dist = (sg:GetCenter().p - getCenter().p).magnitude
				if (dialAddress) and (dist <= config.maxDistance) then
					table.insert(availableAddrs, {Stargate=sg, DialAddress=dialAddress, PlaceId=0, Name=tostring(sg)})
				end
			end
		end
	end

	table.sort(availableAddrs,(function (a,b)
		return a.Stargate.Priority.Value < b.Stargate.Priority.Value
	end))

	-- Remove duplicates, respecting priority
	local dialableAddrs = {}
	for _,entry in pairs(availableAddrs) do
		local skip = false

		for _,toCheck in pairs(availableAddrs) do
			if (entry ~= toCheck) and (arrayEqual(entry.DialAddress, toCheck.DialAddress))
				and (entry.Stargate.Priority.Value >= toCheck.Stargate.Priority.Value)
			then
				skip = true
				break
			end
		end

		if (not skip) then
			table.insert(dialableAddrs, entry)
		end
	end

	-- Add inter-place addresses only if they don't overlap with an in-game gate address
	for _,v in pairs(config.teleportAddresses) do
		local skip = false
		local addr = stringToArray(v[1])

		if (addr) then
			table.insert(addr, this.Origin.Value)

			for _,o in pairs(dialableAddrs) do
				if (arrayEqual(o.DialAddress, addr)) then
					skip = true
					break
				end
			end

			if (not skip) then
				table.insert(dialableAddrs, {Stargate=nil, DialAddress=addr, PlaceId=v[2], Name=v[3]})
			end
		end
	end

	-- Remove violations of config.minLength, config.maxLength, or have symbols < 1 or > config.numSymbols
	local iOffset = 0
	for i=1, #dialableAddrs do
		local entry = dialableAddrs[i - iOffset]

		if (#entry.DialAddress < config.minLength or #entry.DialAddress > config.maxLength) then
			table.remove(dialableAddrs, i)
			iOffset = iOffset + 1
		end

		for _,v in pairs(entry.DialAddress) do
			if (v < 1 or v > config.numSymbols) then
				table.remove(dialableAddrs, i)
				iOffset = iOffset + 1
			end
		end
	end

	cache.dialable = dialableAddrs
	return copyDialableTable(dialableAddrs)
end

function findStargate(modelOrName)
	if not modelOrName then
		return nil
	elseif (type(modelOrName) == "string") then
		local name = modelOrName
		for _,gate in pairs(ALL) do
			if (tostring(gate) == name) then
				return gate
			end
		end
	else
		local model = modelOrName
		for _,gate in pairs(ALL) do
			if (gate.Model == model) then
				return gate
			end
		end
	end
end

--------
-- Main
--------
if (_G.all_Stargates == nil) then -- For backwards compatibility
	_G["all_Stargates"] = {}
end
ALL = _G.all_Stargates

if (_G.Stargates == nil) then
	_G.Stargates = {
		All = ALL;
		Assets = nil;
		FindStargate = nil;
	}
end
API = _G.Stargates

if (not API.Assets) then
	local contains = function(tbl, check)
		for _,v in pairs(tbl) do
			if (v == check) then return true end
		end
		return false
	end
	local addTo = function(tbl, toAdd)
		if (type(toAdd) == "table") then
			for _,v in pairs(toAdd) do
				if (not contains(tbl, v)) then table.insert(tbl, v) end
			end
		else
			if (not contains(tbl, toAdd)) then table.insert(tbl, toAdd) end
		end
	end

	API.Assets = {
		Sounds = {};
		Decals = {};
		Versions = {};
		AddSounds = function(_, sounds) addTo(API.Assets.Sounds, sounds) end;
		AddDecals = function(_, decals) addTo(API.Assets.Decals, decals) end;
		AddVersion =
			function(_, model, major, minor)
				addTo(API.Assets.Versions, model .. " v" .. major .. "." .. minor)
			end;
	}

	local rs = game:GetService("ReplicatedStorage")
	local preloadeRemoteName = "GetStargateAssets"
	local remote = rs:FindFirstChild(preloadeRemoteName)

	if (remote) then
		remote:Destroy()
		remote = nil
	end

	remote = Instance.new("RemoteFunction")
	remote.Name = preloadeRemoteName
	remote.OnServerInvoke = function(player)
		return {
			Decals = API.Assets.Decals;
			Sounds = API.Assets.Sounds;
			Versions = API.Assets.Versions;
		}
	end
	remote.Parent = rs

	local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")

	if (sps) then
		if sps:FindFirstChild(config.preloadScript) then
			sps[config.preloadScript]:Destroy()
		end
		script[config.preloadScript]:Clone().Parent = sps
	end
end

-- Add all assets from the Stargate config
API.Assets:AddDecals(config.animIdInit)
API.Assets:AddDecals(config.animIdActive)

API.Assets:AddSounds(config.wormholeTransport)
API.Assets:AddSounds(config.wormholeAmbient)
API.Assets:AddSounds(config.wormholeClose)
API.Assets:AddSounds(config.wormholeStartup)
API.Assets:AddSounds(config.dialFail)

API.Assets:AddSounds(config.chevronLock)
API.Assets:AddSounds(config.incomingLock)
API.Assets:AddSounds(config.ringRoll)

if (API.Assets.AddVersion) then
	API.Assets:AddVersion("Stargate", this.VERSION_MAJOR, this.VERSION_MINOR)
end
--------

if (not API.FindStargate) then
	API.FindStargate = function(_,arg) return findStargate(arg) end
end
--------

local model = script.Parent
if (model) and (model:IsA("Model")) then
	this.Model = model

	-- Set to the back top chevron, since no animation moves it
	this.MainPart = config:getChevron(config.topChevron)
	assert(this.MainPart, "Stargate main part not found." .. script:GetFullName())

	this.Address = config.address
	this.Network = config.network
	this.Origin =  config.origin

	this.DialMode = config.dialMode
	this.Priority = config.priority

	this["9SymbolCode"] = config["9SymbolCode"]
	this.NetworkAccessPoint = config.networkAccessPoint
	this.AddressHidden = config.addressHidden
	this.MaxDialLength = config.maxDialLength

	-- Randomly choose an origin. The DHD's activator will automatically input this for the user.
	if (this.Origin.Value < 1 or this.Origin.Value > config.numSymbols) then
		this.Origin.Value = math.random(1, config.numSymbols)
	end

	-- If no address, randomly generate one with symbols [1,36] (so Pegasus gates can dial them)
	if (this.Address.Value == "") then
		for i = 1, 6 do
			local symbol
			repeat
				symbol = math.random(1, 36)
			until (not this.Address.Value:find(tostring(symbol), 1, false)) and (tostring(symbol) ~= this.Network.Value)
			this.Address.Value = this.Address.Value .. tostring(symbol)
			if (i ~= 6) then
				this.Address.Value = this.Address.Value .. ","
			end
		end
	end

	this.Active = this.Model:FindFirstChild("Active")
	if (not this.Active) then
		this.Active = Instance.new("BoolValue")
		this.Active.Name = "Active"
		this.Active.Parent = this.Model
	end
	this.Active.Value = false
	this.Active.Changed:connect(onActiveChanged)

	if (config.maxTime < config.minTime) then config.maxTime = config.minTime end
	if (config.maxLength < config.minLength) then config. maxLength = config.minLength end

	local p = this.Model:FindFirstChild("EventHorizon")
	if (p) then p:Destroy() end	-- get rid of extra event horizon

	local p = this.Model:FindFirstChild("Vortex")
	if (p) then p:Destroy() end	-- get rid of extra vortex

	local p = this.Model:FindFirstChild("Centre_Reference_Delete")
	if (p) then p:Destroy() end -- get rid of center reference

	for i = 1,config.numChevrons do
		local chev = config:getChevronLight(i)

		if chev:FindFirstChild("PointLight") then chev.PointLight:Destroy() end
		if chev:FindFirstChild("Sound") then chev.Sound:Destroy() end

		local l = Instance.new("PointLight")
		l.Brightness = config.chevronLightBrightness
		l.Color = BrickColor.new(config.chevColour[true]).Color
		l.Enabled = false
		l.Archivable = false
		l.Range = config.chevronLightRange
		l.Parent = chev
	end

	animShared.getTopSymbol = getTopSymbol
	animShared.setTopSymbol = setTopSymbol
	animShared.getRotatingPartInfo = getRotatingPartInfo
	anim:initialize(this, config, animShared)

	--

	local exportedMeta = {
		__index = function(tbl, idx)
			return this[idx]
		end;
		__newindex = function(tbl, idx, val)
			if (this[idx]) then
				error("This table's values are unmodifiable once written")
			else
				this[idx] = val
			end
		end;
		__tostring = function(tbl)
			return (tbl.Model) and tbl.Model.Name or "Stargate"
		end;
		__metatable = "The metatable is locked";
	}

	setmetatable(exported, exportedMeta)

	setState(GateState.IDLE)
	this.GateState = makeReadOnly(GateState)

	table.insert(ALL,exported)

	--

	deactivate()

	game.Workspace.DescendantRemoving:connect(function(d)
		if (d == this.Model) then
			for k,v in pairs(ALL) do
				if (v == exported) then  -- Compare with 'exported' since that is what we insert to ALL
					table.remove(ALL,k)
					break
				end
			end

			this.Model = nil
		end
	end)

end
