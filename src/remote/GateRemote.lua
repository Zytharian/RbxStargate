--------
--  Gate Remote Script
--  version 2
--------
--  scripting by Legend26
--  modeling and textures by andy6a6
--------
--  Released: 		January 12, 2021
--  Last Updated: 	January 12, 2021
--------

local config = {
	maxDistanceFromGate = 50;
	travelBlockDetection = true;
	allowInterplace = false;
}

local tool = script.Parent
local handle = tool:FindFirstChild "Handle"
local guiScript = script:FindFirstChild "GateRemoteLocal"
local sharedScript = script:FindFirstChild "GateRemoteShared"

assert(
	tool and handle and guiScript and sharedScript,
	"Required tool structure not found"
)

local constModule = require(sharedScript)

local live = nil

function onEquipped()
	local player = game.Players:GetPlayerFromCharacter(tool.Parent)

	if not player or handle.Parent ~= tool then
		return
	end

	setupGui(player)
	mainLoop()
end

function setupGui(player)
	live = {
		player = player;
		gui = Instance.new "ScreenGui";
		event = Instance.new "RemoteEvent";
		clientReady = false;
		gate = nil;
		cachedAddresses = {};
		cachedRemoteState = nil,
	}

	live.event.Name = "RemoteEvent"
	live.event.Parent = live.gui
	live.event.OnServerEvent:connect(onRemoteEventFired)

	sharedScript:Clone().Parent = live.gui

	local guiScriptCopy = guiScript:Clone()
	guiScriptCopy.Disabled = false
	guiScriptCopy.Parent = live.gui

	live.gui.Parent = player:FindFirstChild "PlayerGui"
end

function onRemoteEventFired(player, clientEventType, clientAddressToDial)
	if not live or live.player ~= player then
		return
	end

	if clientEventType == constModule.ClientEventType.Ready then
		live.clientReady = true
		doClientUpdates(true)
	elseif live.clientReady and clientEventType == constModule.ClientEventType.Dial then
		attemptDial(clientAddressToDial)
	else
		warn("Gate Remote: Unknown event type from " .. player.Name .. " is " .. tostring(clientEventType))
	end
end

function attemptDial(clientAddressToDial)
	for _,addr in pairs(live.cachedAddresses) do
		if tableEqualShallow(addr, clientAddressToDial) then
			dial(live.gate, addr)
		end
	end
end

function tableEqualShallow(left, right)
	for i,v in pairs(left) do
		if v ~= right[i] then return false end
	end

	for i,v in pairs(right) do
		if v ~= left[i] then return false end
	end

	return true
end

function dial(gate, addr)
	if gate.State ~= gate.GateState.IDLE or gate.MaxDialLength.Value < #addr then
		return
	end

	gate:Dial(addr)
	gate:Connect()
end

function mainLoop()
	local loopCachedLive = live

	while live and loopCachedLive == live do
		if live.clientReady then
			doClientUpdates()
		end
		wait(0.5)
	end
end

function doClientUpdates(forceSendEvent)
	local allGates = _G.Stargates.All

	local closestGate =
		allGates and
		allGates[1] and
		allGates[1]:FindByProximity(handle.Position, config.maxDistanceFromGate)

	if closestGate and not gateVersionCompatible(closestGate) then
		closestGate = nil
	end

	if forceSendEvent then
		handleCurrentGateChanged(closestGate)
	elseif not live.gate and not closestGate then
		return
	elseif live.gate and closestGate and live.gate == closestGate then
		handleUpdateGateStatus()
	else
		handleCurrentGateChanged(closestGate)
	end
end

function handleUpdateGateStatus()
	local remoteState = mapGateStateToRemoteState(live.gate)

	if live.cachedRemoteState == remoteState then
		return
	end

	live.cachedRemoteState = remoteState

	live.event:FireClient(
		live.player,
		constModule.ServerEventType.GateStateUpdate,
		remoteState
	)
end

function handleCurrentGateChanged(newGate)
	live.gate = newGate
	live.cachedAddresses = {}
	live.cachedRemoteState = nil

	if not newGate then
		live.event:FireClient(live.player, constModule.ServerEventType.GateChanged)
		return
	end

	local addresses = newGate:FindDialable()
	local remoteState = mapGateStateToRemoteState(newGate)
	local remoteAddresses = {}

	for _,v in pairs(addresses) do
		local entry = {
			name = v.Name;
			address = v.DialAddress;
			remote = v.PlaceId and v.PlaceId ~= 0;
		}

		if config.allowInterplace or not entry.remote then
			table.insert(remoteAddresses, entry)
			table.insert(live.cachedAddresses, entry.address)
		end
	end

	live.cachedRemoteState = remoteState

	live.event:FireClient(
		live.player,
		constModule.ServerEventType.GateChanged,
		remoteState,
		tostring(live.gate),
		remoteAddresses
	)
end

function mapGateStateToRemoteState(gate)
	local state = gate.State
	local gs = gate.GateState
	local rs = constModule.GateState

	if gs.IDLE == state then
		return rs.Idle
	elseif gs.DIALING == state or gs.PRE_CONNECTING == state or gs.CONNECTING == state then
		return rs.Dialing
	elseif gs.ACTIVE_INCOMING == state then
		return rs.Incoming
	elseif gs.ACTIVE_OUTGOING == state then
		return
			(config.travelBlockDetection and connectedGateBlocked(gate)) and
			rs.OutgoingBlocked or
			rs.Outgoing
	elseif gs.DISABLED == state then
		return rs.Disabled
	else
		return rs.Busy
	end
end

function connectedGateBlocked(gate)
	return
		gate.ConnectedTo and
		gate.ConnectedTo ~= gate and
		gate.ConnectedTo:IsBlocked()
end

function onParentChanged()
	if not tool.Parent or handle.Parent ~= tool then
		cleanup()
	end
end

function cleanup()
	if live then
		live.gui:Destroy()
	end

	live = nil
end

gateVersionCompatible = (function()
	local warned = false
	local warnFn = function(ok)
		if warned then return end
		warned = true
		warn("Gate Remotes require Stargates v20.5+")
	end
	return function(sg)
		if sg.VERSION_MAJOR and sg.VERSION_MINOR and
			(sg.VERSION_MAJOR ~= 20 or sg.VERSION_MINOR >= 5)
		then
			return true
		end
		warnFn()
		return false
	end
end)()

function main()
	tool.Equipped:Connect(onEquipped)
	tool.Unequipped:Connect(cleanup)
	tool:GetPropertyChangedSignal("Parent"):Connect(onParentChanged)
	handle:GetPropertyChangedSignal("Parent"):Connect(onParentChanged)

	local assets = _G.Stargates.Assets
	if assets.AddVersion then
		assets:AddVersion("Gate Remote", 2, 0)
	end
end

main()