-- Legend26

local screenGui = script.Parent
local sharedScript = screenGui:WaitForChild("GateRemoteShared", 3)
local uiScript = script:WaitForChild("GateRemoteUI", 1)
local remoteEvent = screenGui:WaitForChild("RemoteEvent", 1)

if not script.Parent then return end
assert(sharedScript and uiScript and remoteEvent, "Required tool structure not found")

local constModule = require(sharedScript)
local guiModule = require(uiScript)

local liveGui = nil
local addressList = nil

function onRemoteEventFired(eventType, state, name, addresses)
	if eventType == constModule.ServerEventType.GateChanged then
		setGuiGate(state, name, addresses)
	elseif eventType == constModule.ServerEventType.GateStateUpdate then
		setGuiState(state)
	else
		error("Gate Remote: Unknown event type from server: " .. tostring(eventType))
	end
end

function onDialClick(address)
	remoteEvent:FireServer(constModule.ClientEventType.Dial, address)
end

function onRemoteActivated()
	local addrs = filter(addressList, function(addr) return addr.remote end)
	liveGui:setAddresses(addrs, onDialClick)
end

function onLocalActivated()
	local addrs = filter(addressList, function(addr) return not addr.remote end)
	liveGui:setAddresses(addrs, onDialClick)
end

function setGuiGate(state, name, addresses)
	addressList = addresses or {}

	table.sort(addressList, function(a, b) return a.name:upper() < b.name:upper() end)

	setGuiState(state)
	liveGui:setTitle(name)
	liveGui:resetFilterSelection()
	liveGui:setFilterEnabled(some(addressList, function(addr) return addr.remote end))
	onLocalActivated()

	liveGui:displayInScreenGui(screenGui)
end

function setGuiState(state)
	liveGui:setState(
		state and getStateString(state) or "",
		state == constModule.GateState.OutgoingBlocked
	)
end

function getStateString(state)
	local rs = constModule.GateState

	if rs.Idle == state then
		return "Idle"
	elseif rs.Busy == state then
		return "Busy"
	elseif rs.Disabled == state then
		return "Disabled"
	elseif rs.Dialing == state then
		return "Dialing"
	elseif rs.Incoming == state then
		return "Incoming"
	elseif rs.Outgoing == state then
		return "Outgoing"
	elseif rs.OutgoingBlocked == state then
		return "BLOCKED"
	else
		error("Unknown state " .. tostring(state))
	end
end

function some(tbl, cb)
	for _,v in pairs(tbl) do
		if (cb(v)) then
			return true
		end
	end

	return false
end

function filter(tbl, cb)
	local result = {}

	for _,v in pairs(tbl) do
		if cb(v) then
			table.insert(result, v)
		end
	end

	return result
end

function main()
	liveGui = guiModule:createGui({
		onRemoteActivated = onRemoteActivated,
		onLocalActivated = onLocalActivated
	})

	remoteEvent.OnClientEvent:Connect(onRemoteEventFired)
	remoteEvent:FireServer(constModule.ClientEventType.Ready)
end

main()