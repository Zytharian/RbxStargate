--------
--	DHD Config (Milky Way)
--  This script defines a DHD's configuration.
--  Legend26, Ganondude
--------
local model = script.Parent.Parent
local config = {
--------

--------
-- Basic Settings:
--------
activatorInputsOrigin = true;	-- If true, pressing the activator dials the gate origin and activates the gate

maxDistance = 100;				-- The maximum distance allowed between the DHD and its connected Stargate. (If 0 then no limit.)

maxClickDistance = 10;			-- The maximum distance at which a player can activate the buttons on the DHD.

enableButtonIdentifier = true;	-- Whether mousing over the DHD button display the symbol # to the user

enableDialHints = true;			-- If true the DHD will assist with dialing
maxGUITime = 10;				-- The maximum amount of time the dialing GUI will be active.
displayInterplace = false;		-- If true, inter-place addresses will be displayed

bigButtonHintEnabled = true;	-- Whether the big button proximity pulsing is enabled.
bigButtonHintProximity = 7;		-- Distance a user must be to start the big button pulse hint.
bigButtonHintWait = 3;			-- The time a user must be within the distance for the big button to pulse.

--------
-- Advanced Settings:
--------
dialingGui = "DHDGui";					-- The GUI presented to players if (enableDialHints == true).
buttonIdGui = "DHDButtonIdentifier";	-- The GUI that identifies DHD buttons for the player
activatorDecalName = "Decal";

mid = model.MidPart;
symbols = model.Symbols;
edges   = model.Edges;

--------
-- Aesthetic Settings:
--------

-- true when button has been clicked, false otherwise
-- hintOverride is used during the DHD dial hint; use Neon if hint must be visible in darkness
activatorColour =		{[true] = BrickColor.new("Cork").Color,	[false] = Color3.fromRGB(151,0,0)};
activatorMaterial =		{[true] = Enum.Material.Neon,			[false] = Enum.Material.Glass,			hintOverride = nil};
activatorDecalTrans =	{[true] = 0.3,							[false] = 0};

midTransparency =		{[true] = 0,							[false] = 0};
midMaterial =			{[true] = Enum.Material.Marble,			[false] = Enum.Material.Marble,			hintOverride = nil};

symColor =				{[true] = BrickColor.new("Cork").Color,	[false] = Color3.fromRGB(105,102,92)};
symMaterial =			{[true] = Enum.Material.Neon,			[false] = Enum.Material.Metal,			hintOverride = Enum.Material.SmoothPlastic};

edgeColor =				{[true] = BrickColor.new("Cork").Color,	[false] = Color3.fromRGB(99,95,98)};
edgeMaterial =			{[true] = Enum.Material.Neon,			[false] = Enum.Material.Metal,			hintOverride = Enum.Material.SmoothPlastic};

--------
-- Sound settings
--------
activated = 162037932;
dialPressed = {162029794, 162029804, 162029814, 162029830, 162029837, 162029851, 162029858};

activatedVolume = 0.5;
dialPressedVolume = 0.15;

emitterSize = 5;
soundMaxDistance = 50;

--------
-- *Value object settings
--------
dialMode = model:FindFirstChild "DialMode";

--------
} -- end of config table
return config
--------