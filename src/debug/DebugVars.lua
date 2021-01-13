-- Legend26

local debugVars = {
--[[
	{name = "positionZAxisAdjust",
		default = -0.15, datatype = "number"};

	{name = "horizonAnimLoopStep",
		default = 2,      datatype = "number", min = 0, max = 46,
		tooltip = "1 = all loop decals, 2 = half, 3 = 1/3, so on"};

	{name = "horizonAnimFPS",
		default = 18,      datatype = "number", min = 1, max = 30};

	{name = "horizonActivateAnimTime",
		default = 1.5,  datatype = "number", min = 0, max = 5,
		tooltip = "Wait time between showing partialy formed horizon + playing the sound and running the vortex animation"};

	{name = "horizonActivateFadeInTime",
		default = 0.6,      datatype = "number", min = 0, max = 5};

	{name = "horizonDeactivateFadeInTime",
		default = 1,      datatype = "number", min = 0, max = 5};

	{name = "horizonDeactivateFadeOutTime",
		default = 0.6,    datatype = "number", min = 0, max = 5};

	{name = "horizonDeactivateAnimStartOffset",
		default = 0.6,    datatype = "number", min = 0, max = 5};

	{name = "fakeHorizonZAdjust",
		default = 1,   datatype = "number", min = -5, max = 5};

	{name = "fakeHorizonXYAdjust",
		default = 0,   datatype = "number", min = -5, max = 5};

	{name = "vortexStepsBeforeFullRotation",
		default = 60,   datatype = "number", min = 1};

	{name = "vortexStepCount",
		default = 10,   datatype = "number", min = 1,
		tooltip = "Number of steps for the growth and decline phase"};

	{name = "vortexMaxStepTime",
		default = 0, datatype = "number", min = 0, max = 1,
		tooltip = "Max wait time between vortex steps except for peak"};

	{name = "vortexPeakAnimSteps",
		default = 20,   datatype = "number", min = 0, max = 100,
		tooltip = "# steps at the vortex's peak"};

	{name = "vortexPeakAnimStepTime",
		default = 0, datatype = "number", min = 0, max = 1,
		tooltip = "Time between vortex peak steps"};

	{name = "soundMaxDistance",
		default = 200,  datatype = "number", min = 1, max = 10000,};

	{name = "soundEmitterSize",
		default = 10,    datatype = "number", min = 1, max = 5,};

	{name = "soundVolume",
		default = 0.25,    datatype = "number", min = 0, max = 2,};

	{name = "distBeforeRollSound",
		default = 5,    datatype = "number", min = 1, max = 39,};

	{name = "ringRotationSpeed",
		default = 3,    datatype = "number", min = 1, max = 10}; --note: use 3 for MW, 2 for pegasus
]]--
}

local debugActions = {
	deactivateAllGates = (function()
		for k,v in pairs(_G.all_Stargates) do
			if (v.VERSION_MAJOR) then
				coroutine.wrap(function() v:Deactivate() end)()
			else
				v.Active.Value = false
			end
		end
	end);

	invalidateCaches = (function()
		for k,v in pairs(_G.all_Stargates) do
			if (v.InvalidateCache) then
				v:InvalidateCache()
			end
		end
	end);

	clockTimeToggle = (function()
		game.Lighting.ClockTime = game.Lighting.ClockTime ~= 14 and 14 or 0
	end);

	forcefieldSelf = (function(player)
		if (player.Character) then
			local ff = player.Character:FindFirstChild("ForceField")
			if (ff) then
				ff:Destroy()
			else
				Instance.new("ForceField", player.Character)
			end
		end
	end);

	switchDialModes = (function()
		for k,v in pairs(_G.all_Stargates) do
			local dm = v.DialMode
			dm.Value = dm.Value > 1 and dm.Value - 1 or 3

			if (v.DHD) then
				v.DHD.DialMode.Value = dm.Value
			end
		end
	end)
}

return { debugVars = debugVars, debugActions = debugActions }

-- Legend26