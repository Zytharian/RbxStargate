--------
--	DHD Config (Milky Way)
--	version 20.2
--------
--  scripting by Legend26
--  modeling by andy6a6
-- (Stargates up to version 19.5 authored solely by Ganondude)
--------
--  Released: 		December 29, 2018
--  Last Updated: 	February 16, 2019
--------
--  This script defines a DHD's configuration.
--------
local model = script.Parent
local config = {
--------

--------
-- Basic Settings:
--------
maxLength = 7;					-- The maximum address length accepted as input by the DHD _including_ the activator origin input. (Can be modified by other plugins)
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
activatorColour =		{[true] = BrickColor.new("Cork").Color,	[false] = Color3.fromRGB(151,0,0)};
activatorMaterial =		{[true] = Enum.Material.Neon,			[false] = Enum.Material.Glass};
activatorDecalTrans =	{[true] = 0.3,							[false] = 0};

midTransparency =		{[true] = 0,							[false] = 0};
midMaterial =			{[true] = Enum.Material.Marble,			[false] = Enum.Material.Marble};

symColor =				{[true] = BrickColor.new("Cork").Color,	[false] = Color3.fromRGB(105,102,92)};
symMaterial =			{[true] = Enum.Material.Neon,			[false] = Enum.Material.Metal};

edgeColor =				{[true] = BrickColor.new("Cork").Color,	[false] = Color3.fromRGB(99,95,98)};
edgeMaterial =			{[true] = Enum.Material.Neon,			[false] = Enum.Material.Metal};

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