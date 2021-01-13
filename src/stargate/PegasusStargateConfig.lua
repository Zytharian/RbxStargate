--------
--  Stargate Config (Pegasus)
--  This script defines a stargate's configuration.
--  Legend26, Ganondude
--------
local model = script.Parent.Parent
local config = {
--------

--[[
Dial modes:
	1 = incoming wormhole  (default for incoming)
	2 = fast dial sequence
	3 = slow dial sequence (default for dialing)
]]--

--------
-- Inter-Place Teleport Settings:
--------

-- Addresses used to teleport to other places:
teleportAddresses = {
--	{string address, number placeId, string name}
	{"1,11,5,16,12,9",	202996,		"Stargate Galaxy"},
	{"31,13,8,7,34,2",	15947100,	"Anquietas Videum"},
	{"7,9,12,16,5,11",	137819,		"Abydos"},
};

--------
-- Basic Settings:
--------
maxTime = 60;						-- The maximum amount of time the gate will stay open under normal circumstances (in seconds).
minTime = 20;						-- The minimum amount of time the gate will stay open under normal circumstances (in seconds).

maxLength = 9;						-- The maximum address length accepted as input by the Stargate.
minLength = 7;						-- The minimum address length accepted as input by the Stargate.

maxDistance = math.huge;			-- The maximum distance allowed between two connected Stargates. (math.huge for no limit)

cooldownTime = 0;					-- The minimum amount of time that must elapse after an outgoing gate shuts down before it can dial out again (in seconds).

dialModeAnim = 2;					-- 1 for Milky Way and 2 for Pegasus gate animations

--------
-- Aesthetic Settings:
--------
horizonColour =   {"Light Royal blue", "Medium Royal blue", "Dark Royal blue"};  -- initial, vortex, open

symbolColour =    {[true] = "Pastel light blue",	[false] = Color3.fromRGB(31,56,60)};  -- true when gate is active, false otherwise
symbolMat =       {[true] = Enum.Material.Neon,		[false] = Enum.Material.Metal};

chevColour =      {[true] = "Toothpaste",			[false] = Color3.fromRGB(0,12,20)};
chevRefl =        {[true] = 0.4, 					[false] = 0};
chevTrans =       {[true] = 0,						[false] = 0.23};
chevMat =         {[true] = Enum.Material.Neon,		[false] = Enum.Material.Glass};

lightColour =     {[true] = "Toothpaste", 			[false] = Color3.fromRGB(0,36,61)};
lightRefl =       {[true] = 0.4, 					[false] = 0};
lightTrans =      {[true] = 0,						[false] = 0.1};
lightMat =        {[true] = Enum.Material.Neon,		[false] = Enum.Material.SmoothPlastic};

-- texture ids to be used in the animation of the event horizon
animIdInit =   {
	2639963238,2639963626,2639963979,2639964463,2639964785,2639965020,2639965165,2639965340,2639965523,2639965820,
	2639965966,2639966240,2639966480,2639966604,2639966860,2639967076,2639967230,2639967360
};
animIdActive = {
	2642454290,2642454476,2642454708,2642454887,2664085722,2642455304,2642455575,2664086307,2642455968,2642456194,
	2642456770,2642457039,2642457243,2642457446,2642457684,2642458052,2642458212,2642458456,2642458683,2642458885,
	2642459078,2642459270,2642459502,2642459797,2642459990,2642460176,2642460341,2642460584,2642460899,2642461170,
	2642461441,2642461623,2642462071,2642462260,2642462576,2642462818,2642463047,2642463302,2642463543,2642463756,
	2642464014,2642464268,2642464508,2642464682,2642464858,2642465131
};
animFPS = 18;

positionZAxisAdjust = -0.16;		-- Adjust the wormhole position's Z axis (relative to the gate)

horizonSizeMultiplier = 1.4;		-- Horizon Size XY axes = gateRadius * multiplier
vortexSizeMultiplier = 1.7;			-- Vortex Size XZ axes = gateRadius * multiplier

scalet = Vector3.new(1.25,1.25,0);	-- Event horizon mesh scale with custom textures.

--------
-- Light Settings
--------
chevronLightBrightness = 2;
chevronLightRange = 8;

horizonLightAngle = 120;
horizonLightBrightness = 3;
horizonLightRange = 32;

vortexLightBrightness = 3;
vortexLightRange = 32;

--------
-- Sound settings
--------
wormholeTransport = {162037473, 162037485, 162037491, 162037498, 162037506, 162037511, 162037517, 162037521};
wormholeAmbient = 162026522;
wormholeClose = 162025450;
wormholeStartup = 2676625201;	-- pegasus
dialFail = 162025511;			-- pegasus

chevronLock = 2676625455;		-- pegasus
incomingLock = 2676623998;		-- pegasus
ringRoll = 2676629832;			-- pegasus

soundMaxDistance = 200;
soundEmitterSize = 10;
soundVolume = 0.25;				-- exception: the volume for wormholeAmbient is hardcoded to 2.
distBeforeRollSound = 5;		-- Only applies to Milky Way dial mode 3 animation

--------
-- Advanced Settings:
--------
incomingMode = 1;					-- The dialing mode to be used for incoming animations.

topChevron = 7;						-- The number of the chevron at the top of the gate.
numChevrons = 9;					-- The number of chevrons in the gate.

numSymbols = #model.Ring:GetChildren()-1;  -- The number of symbols in the gate

localScript = "LocalStargate";		-- The name of the local script copied into a transporting player. (Child of this script.)
preloadScript = "GateAssetPreload"; -- The name of the local script copied into game.StarterPlayer.StarterPlayerScripts to preload gate assets.

ringRotationSpeed = 2;				-- # steps it takes to rotate to the next symbol (lower is faster, must be > 0)

--------
-- Animation Settings:
--------
horizonAnimLoopStep = 2;
horizonAnimFPS = 18;

horizonActivateAnimTime = 1.5;
horizonActivateFadeInTime = 0.6;

horizonDeactivateAnimStartOffset = 0.6;
horizonDeactivateFadeInTime = 1;
horizonDeactivateFadeOutTime = 0.6;

fakeHorizonZAdjust = 0.2; 			-- adjusts the fake horizon mesh scale's Z size from scalet's Z size

--------
-- *Value object settings
--------
address =  model:FindFirstChild "Address";
dialMode = model:FindFirstChild "DialMode";
network =  model:FindFirstChild "Network";
origin =   model:FindFirstChild "Origin";
priority = model:FindFirstChild "Priority";
["9SymbolCode"] = model:FindFirstChild "9SymbolCode";
networkAccessPoint = model:FindFirstChild "NetworkAccessPoint";
addressHidden = model:FindFirstChild "AddressHidden";
maxDialLength = model:FindFirstChild "MaxDialLength";

--------
} -- end of config table

--------
--[[
Get Functions

	getChevronContainer(int chevronNumber)
	getChevron(int chevronNumber)
	getChevronLight(int chevronNumber)
	getChevronSideLight(int chevronNumber)
	getSymbol(int symbolNumber)

	getLockingParts()
	getRotatingParts()

]]--

function config:getChevronContainer(chevronNumber)
	local containerName = "Front_Chevron_" .. tostring(chevronNumber)

	return model.Front_Chevrons[containerName]
end

function config:getChevron(chevronNumber)
	return model.Back_Chevrons["Back_Chevron_" .. tostring(chevronNumber)].Chevron
end

function config:getChevronLight(chevronNumber)
	return config:getChevronContainer(chevronNumber).Light
end

function config:getChevronSideLight(chevronNumber)
	return config:getChevronContainer(chevronNumber).Front_Chevron_Side_Light
end

function config:getSymbol(symbolNumber)
	local symbolName = "Symbol" .. tostring(symbolNumber)

	if model:FindFirstChild("Ring") then
		return model.Ring:FindFirstChild(symbolName)
	else
		return nil
	end
end

function config:getLockingParts()
	local container = config:getChevronContainer(config.topChevron)

	return {
		{container.Glass, 1},
		{container.Light, 1},
		{container.Chevron, -1},
		{container.Front_Chevron_Side_Light, -1}
	}
end;

function config:getRotatingParts()
	return model.Ring:GetChildren()
end

--------
return config