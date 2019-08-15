--------
--	Shutdown Button
--	compatible with Stargates version 20
--------
--  scripting by Legend26
--------
--  Released: 		December 29, 2018
--  Last Updated: 	December 29, 2018
--------

local range = 50
local maxActivationDistance = 10

local buttonColor =	{[true] = Color3.fromRGB(170,87,87),	[false] = Color3.fromRGB(66,26,26)}
local buttonMat =	{[true] = Enum.Material.Neon,			[false] = Enum.Material.Glass}

local shutdownOutgoingOnly = true

----
--------
-- Do not alter anything below.
--------
----

local ALL

local button = script.Parent.Button
local gate

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

if (not gate.VERSION_MAJOR) and (not gate.VERSION_MAJOR >= 20) then
	error("This shutdown button does not work for Stargates under version 20.")
end

local cd = Instance.new("ClickDetector")
cd.MaxActivationDistance = maxActivationDistance
cd.Parent = button

gate:OnStateChanged(function(_, _)
	if (gate.State == gate.GateState.ACTIVE_OUTGOING)
		or (not shutdownOutgoingOnly and gate.State == gate.GateState.ACTIVE_INCOMING)
	then
		buttonState(true)
	else
		buttonState(false)
	end
end)
buttonState(false)

cd.MouseClick:connect(function ()
	if (gate.State == gate.GateState.ACTIVE_OUTGOING)
		or (not shutdownOutgoingOnly and gate.State == gate.GateState.ACTIVE_INCOMING)
	then
		gate:Deactivate()
	end
end)
