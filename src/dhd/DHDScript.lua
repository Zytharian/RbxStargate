--------
--	DHD Script
--	version 20.7
--------
--  scripting by Legend26
--  modeling by andy6a6, Flames911
--  bugfixes by hello234561, PossessedSpaceman
-- (Stargates up to version 19.5 authored solely by Ganondude)
--------
--  Released: 		December 29, 2018
--  Last Updated: 	April 22, 2023
--------


----
--------
-- Do not alter anything in this script.
--------
----


local ALL

local config = require(script.DHDConfig)

local isDialing = false
local clicked = {}

local hasGui = {}
local currentGuis = 0
local guidingAddress
local stopGuidePulse

local locatorPrefix = "rbxassetid://"
local numButtons

local this = {
	Model = nil,
	MainPart = nil,
	ConnectedTo = nil,

	DialMode = nil,

	VERSION_MAJOR = 20,
	VERSION_MINOR = 7,
}

--------

--[[
DHD Functions

	deactivate()
	connectTo()
	lightButton(number symbol, bool lightUp)		-- if symbol == nil then activator is assumed
	pulse(number symbol)							-- if symbol == nil then activator is assumed
	stopPulse()
	updateGuide()
	doGui(Player player)
	canDial()
	dial(Stargate stargate, number symbol)
	onMouseClick(Player player, BasePart button)
	onStateChanged(Stargate sg, sg.GateState state)
	playSound(Int id, BasePart parent, bool isActivator)
]]--

function deactivate()
	isDialing = false
	clicked = {}
	guidingAddress = nil

	stopPulse()

	for i=1, numButtons do
		lightButton(i, false)
	end
	lightButton(nil, false)
end

function connectTo()
	local sg = ALL[1]:FindByProximity(this.MainPart.Position, config.maxDistance)
	if (not sg) then return end

	while (sg.DHD) do -- if sg already has a DHD, find another gate
		sg = sg:FindByProximity(this.MainPart.Position,config.maxDistance)
		wait(1)
	end

	this.ConnectedTo = sg
	sg.DHD = this

	deactivate()
	sg:OnStateChanged(onStateChanged)
	proximityHelper()
end

function lightButton(symbol, lightUp)
	if (symbol) then
		local mid = config.mid:FindFirstChild(symbol)
		local sym = config.symbols:FindFirstChild(symbol)
		local edg = config.edges:FindFirstChild(symbol)

		if (mid) then
			mid.Transparency = config.midTransparency[lightUp]
			mid.Material = config.midMaterial[lightUp]
			if (config.midColor) then
				mid.Color = config.midColor[lightUp]
			end
		end
		if (sym) then
			sym.Color = config.symColor[lightUp]
			sym.Material = config.symMaterial[lightUp]
		end
		if (edg) then
			edg.Color = config.edgeColor[lightUp]
			edg.Material = config.edgeMaterial[lightUp]
		end
	else
		local decal = this.MainPart:FindFirstChild(config.activatorDecalName)
		if (decal) then
			decal.Transparency = config.activatorDecalTrans[lightUp]
		end
		this.MainPart.Color = config.activatorColour[lightUp]
		this.MainPart.Material = config.activatorMaterial[lightUp]
	end
end

function pulse(symbol)
	local go = true

	if (stopGuidePulse) then
		stopGuidePulse()
		warn("DHD: pulse() called without stopping ongoing pulse.")
	end

	local parts = {}
	if (not symbol) then
		table.insert(parts, {part = this.Model.Activator, material = config.activatorMaterial.hintOverride})
	else
		local symbolPart = config.symbols:FindFirstChild(symbol)
		local edgePart   = config.edges:FindFirstChild(symbol)

		if (symbolPart) then
			table.insert(parts, {part = symbolPart, material = config.symMaterial.hintOverride})
		end
		if (edgePart) then
			table.insert(parts, {part = edgePart, material = config.edgeMaterial.hintOverride})
		end
		if (not symbolPart) and (not edgePart) then
			local midPart = config.mid:FindFirstChild(symbol)
			table.insert(parts, {part = midPart, material = config.midMaterial.hintOverride})
		end
	end

	for _,v in pairs(parts) do
		v.originalColor = v.part.Color
	end

	coroutine.wrap(function()
		local guideColor = config.activatorColour[true]
		local towardsGuide = true

		for i,btn in pairs(parts) do
			-- Material is restored later by lightSymbol(x, false)
			if (btn.material) then
				btn.part.Material = btn.material
			end
		end

		while go do
			local max = 33

			for i=0, max do
				if (not go) then break end
				for _,btn in pairs(parts) do
					btn.part.Color = btn.originalColor:Lerp(guideColor, towardsGuide and i/max or 1-(i/max))
					local decal = btn.part:FindFirstChild(config.activatorDecalName)
					if (decal) then
						decal.Transparency = towardsGuide and i/max	or 1-(i/max)
						decal.Transparency = math.min(decal.Transparency, config.activatorDecalTrans[true])
					end
				end
				wait()
			end

			if (not symbol) and (not towardsGuide) then wait(1.5) end
			towardsGuide = not towardsGuide
		end
	end)()

	stopGuidePulse = function()
		go = false
		lightButton(symbol, false)
		stopGuidePulse = nil
		return symbol
	end
end

function stopPulse()
	if (stopGuidePulse) then
		stopGuidePulse()
	end
end

function updateGuide()
	if (not guidingAddress) then return end

	local stargate = this.ConnectedTo
	local current = stargate:GetDialedSymbols()
	local nextSym = guidingAddress[#current + 1]

	for i=1,#current do
		local already = current[i]
		if (guidingAddress[i] ~= already) then
			lightButton(guidingAddress[i], false)
			guidingAddress = nil
			return
		end
	end

	-- We can't click symbols twice unless the activator does it for us.
	if (nextSym and clicked[nextSym] and (not config.activatorInputsOrigin or nextSym ~= stargate.Origin.Value)) then
		guidingAddress = nil
		return
	end

	if
		((config.activatorInputsOrigin) and (#current == #guidingAddress - 1) and (nextSym == stargate.Origin.Value)) or
		(#current == #guidingAddress) or
		(not nextSym)
	then
		pulse(nil)
		guidingAddress = nil
		return
	end

	if (guidingAddress) then
		if (nextSym > 0) and (nextSym <= numButtons) then
			pulse(nextSym)
		else
			guidingAddress = nil
		end
	end
end

function doGui(player)
	if (hasGui[player]) or (not player.Character) or (not player.Character.PrimaryPart) then return end
	hasGui[player] = true
	currentGuis = currentGuis + 1

	local stargate = this.ConnectedTo

	local activeGui = script[config.dialingGui]:Clone()

	local guiMain = activeGui.Main
	local destinationSelectedRemote = activeGui.DestinationSelected
	local findDialableRemote = activeGui.FindDialable

	local addressSelected
	local signal
	signal = destinationSelectedRemote.OnServerEvent:connect(function (selPlayer, address)
		if (player ~= selPlayer) or (addressSelected) then return end
		addressSelected = address -- the index in finalDialable
		signal:disconnect()
	end)

	local finalDialable = {}
	for _,v in pairs(stargate:FindDialable()) do
		if (v.PlaceId == 0 or config.displayInterplace) then
			table.insert(finalDialable, {v.DialAddress, v.Name})
		end
	end
	findDialableRemote.OnServerInvoke = (function (selPlayer)
		if (selPlayer ~= player) or (addressSelected) then return end
		return finalDialable
	end)

	activeGui.Parent = player.PlayerGui

	local dist
	local timer = config.maxGUITime
	repeat
		dist = (player.Character.PrimaryPart.Position - this.MainPart.Position).magnitude
		timer = timer - 0.1
		wait(0.1)
	until (addressSelected) or (guidingAddress)
		or (stargate.State ~= stargate.GateState.IDLE)
		or (not player.Character) or (not player.Character.PrimaryPart)
		or (dist > config.maxClickDistance) or (timer < 0)

	if (not guidingAddress) and (finalDialable[addressSelected]) and (stargate.State == stargate.GateState.IDLE) then
		guidingAddress = finalDialable[addressSelected][1] -- select the address
		updateGuide()
	end

	currentGuis = currentGuis - 1
	hasGui[player] = nil
	activeGui:Destroy()
end

function proximityHelper()
	if (not config.bigButtonHintEnabled) or (not config.enableDialHints) then return end

	local sg = this.ConnectedTo
	local userNearByTime = 0

	while (true) do
		wait(1)

		--If there is no guide and the gate is inactive then go through each character, and check if they're near to the DHD.
		if (not guidingAddress) and (currentGuis == 0) and (sg.State == sg.GateState.IDLE) then

			local foundCloseBy = false
			for _,player in pairs(game.Players:GetPlayers()) do
				if (player.Character) and (player.Character.PrimaryPart) then
					local delta = (player.Character.PrimaryPart.Position - this.MainPart.Position)
					local distSqr = delta.X^2 + delta.Y^2 + delta.Z^2

					if (distSqr < config.bigButtonHintProximity^2) then
						foundCloseBy = true
						userNearByTime = userNearByTime + 1 -- (the wait interval)
						break
					end
				end
			end

			if (not foundCloseBy) then
				userNearByTime = 0
			end

			if (userNearByTime > config.bigButtonHintWait) then
				if (not stopGuidePulse) then
					pulse(nil)
				end
			else
				stopPulse()
				lightButton(nil, false)
			end

		else
			userNearByTime = 0
		end
	end
end

function canDial()
	local stargate = this.ConnectedTo

	return (
		stargate.State == stargate.GateState.IDLE or
	    stargate.State == stargate.GateState.DIALING
	)
end

function dial(stargate, symbol)
	local originalDialMode = stargate.DialMode.Value
	stargate.DialMode.Value = this.DialMode.Value
	stargate:Dial(symbol)
	stargate.DialMode.Value = originalDialMode
end

function onMouseClick(player,button)
	local stargate = this.ConnectedTo

	if (not stargate) or (not player) or (not player.Character) or (not player.Character.PrimaryPart)
		or (isDialing) or (not canDial())
	then
		return
	end

	isDialing = true

	local isActivator = (button == this.MainPart)
	local symbol = (isActivator) and stargate.Origin.Value or tonumber(button.Name)

	local s = "DHD: clicked; symbol=" .. symbol .. "; isActivator=" .. tostring(isActivator)

	if (not isActivator) then
		local maxDialLength = stargate.MaxDialLength.Value
		if (clicked[symbol]) then
			print(s .. "; unable to input")
		elseif (#stargate:GetDialedSymbols() < (config.activatorInputsOrigin and maxDialLength-1 or maxDialLength)) then
			print(s)

			stopPulse()
			lightButton(nil, false) -- proximity hint may be running on activator, reset button here

			local randSound = math.random(#config.dialPressed)
			playSound(config.dialPressed[randSound], button, false)

			dial(stargate, symbol)
			updateGuide()
		end
		isDialing = false

	elseif (stargate.State == stargate.GateState.DIALING) then
		print(s)

		stopPulse()

		playSound(config.activated, button, true)
		wait(0.5)

		-- Ensure we can still dial the gate after the wait()
		if (canDial()) then
			if (config.activatorInputsOrigin) and (#stargate:GetDialedSymbols() < stargate.MaxDialLength.Value) then
				dial(stargate, symbol)
				updateGuide()
			end

			stargate:Connect()
		end
		isDialing = false

	elseif (config.enableDialHints) and (stargate.State == stargate.GateState.IDLE) and (not guidingAddress) then
		-- The proximity hint may be running. Cancel it here.
		stopPulse()
		lightButton(nil, false)

		-- Allow multiple users to have the dialing gui up at once.
		isDialing = false
		doGui(player)
	else
		isDialing = false
	end
end

function onStateChanged(sg, state)
	if (state == sg.GateState.DEACTIVATING or state == sg.GateState.INCOMING) then
		deactivate()

	elseif (state == sg.GateState.DIALING or state == sg.GateState.PRE_CONNECTING or state == sg.GateState.CONNECTING) then
		stopPulse()

		local dialed = sg:GetDialedSymbols()
		clicked = {}

		for i=1, #dialed do
			clicked[dialed[i]] = true
			lightButton(dialed[i], true)
		end

		if (state == sg.GateState.PRE_CONNECTING or state == sg.GateState.CONNECTING) then
			lightButton(nil, true)

			local originPartOfAddr = false
			for i=1, #dialed - 1 do
				if (dialed[i] == sg.Origin.Value) then originPartOfAddr = true end
			end
	
			if (not originPartOfAddr) and (config.activatorInputsOrigin) then
				lightButton(sg.Origin.Value, false)
			end
		end
	end
end

function playSound(id, parent, isActivator)
	local s = Instance.new("Sound")
	s.MaxDistance = config.soundMaxDistance
	s.EmitterSize = config.emitterSize
	s.Volume = isActivator and config.activatedVolume or config.dialPressedVolume
	s.SoundId = locatorPrefix .. id
	s.Ended:Connect(function () s:Destroy() end)
	s.Parent = parent

	s:Play()
end

--------
-- Main
--------

local model = script.Parent

for _,v in pairs(model:GetChildren()) do
	if (v:IsA("BasePart")) then
		v.Anchored = true 	-- script can unanchor them again later if necessary; all parts should be anchored initially
	end
end

if (model) and (model:IsA("Model")) then
	this.Model = model

	this.MainPart = model:FindFirstChild("Activator")
	assert(this.MainPart,"DHD activator not found.")

	this.DialMode = model:FindFirstChild("DialMode")
	assert(this.DialMode,"DHD dial mode setting not found.")

	-- remove any existing click detectors then set up new ones
	for _,clickModel in pairs({config.mid, config.symbols, config.edges, model}) do
		for _,v in pairs(clickModel:GetChildren()) do
			if (v:IsA("BasePart")) and (tonumber(v.Name) or v == this.MainPart) then
				local c = v:FindFirstChild("ClickDetector")
				if (c) then c:Destroy() end
				c = Instance.new("ClickDetector")
				c.MaxActivationDistance = config.maxClickDistance
				c.MouseClick:connect(function(player) onMouseClick(player,v) end)
				c.Parent = v
			end
		end
	end

	-- Assume same for the symbols and edges
	numButtons = #config.mid:GetChildren()

	deactivate()

	while (not _G.Stargates) do
		wait(0.1)
	end
	ALL = _G.Stargates.All

	-- add button identifier to PlayerGui unless it's already there
	if (config.enableButtonIdentifier) then
		if (not _G.Stargates.DHDButtonIdentifier) then
			local clone = script[config.buttonIdGui]:Clone()
			_G.Stargates.DHDButtonIdentifier = clone
			clone.Parent = game.StarterGui
		end

		local bId = _G.Stargates.DHDButtonIdentifier
		local tag = Instance.new("ObjectValue")
		tag.Value = this.Model
		tag.Parent = bId.DHDs
	end

	-- add our assets to the stargate preload list
	local assets = _G.Stargates.Assets

	assets:AddSounds(config.activated)
	assets:AddSounds(config.dialPressed)

	if (assets.AddVersion) then
		assets:AddVersion("DHD", this.VERSION_MAJOR, this.VERSION_MINOR)
	end

	wait(2) -- give all the stargates 2s to register themselves
	if (ALL) and (#ALL > 0) then
		connectTo()
	end
end