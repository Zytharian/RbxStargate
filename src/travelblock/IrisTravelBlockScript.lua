--------
--	Travel Block
--	compatible with Stargates version 20
--------
--  scripting by Legend26
--------
--  Released: 		December 29, 2018
--  Last Updated: 	December 23, 2022
--------

local range = 50
local maxActivationDistance = 10

local buttonColor =	{[true] = Color3.fromRGB(145,126,172),	[false] = Color3.fromRGB(116,115,117)}
local buttonMat =	{[true] = Enum.Material.Neon,			[false] = Enum.Material.Glass}

----
--------
-- Do not alter anything below.
--------
----

local ALL

local button = script.Parent.Button
local gate

local anims = require(script.Parent.BlockAnims)

--------

function buttonState(on)
	button.Color = buttonColor[on]
	button.Material = buttonMat[on]
end

--------
-- Main
--------

repeat wait(1) until _G.all_Stargates
ALL = _G.all_Stargates

repeat
	wait(1)
	gate = ALL[1]:FindByProximity(button.Position, range)
until (gate)

if (not gate.VERSION_MAJOR) or (gate.VERSION_MAJOR < 20) then
	error("This travel block does not work for Stargates under version 20.")
end

local cd = Instance.new("ClickDetector")
cd.MaxActivationDistance = maxActivationDistance
cd.Parent = button

local closed = anims:initialize(gate)

closed.Changed:connect(function()
	buttonState(closed.Value)
end)
buttonState(closed.Value)

cd.MouseClick:connect(function ()
	closed.Value = not closed.Value
end)