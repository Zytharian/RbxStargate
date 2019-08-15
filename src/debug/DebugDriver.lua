-- Legend26

local dat = require(script.DebugVars)
local debugVars = dat.debugVars
local debugActions = dat.debugActions

------
------

local debugGui = script.DebugGui

local setDebugVar = Instance.new("RemoteFunction", game.ReplicatedStorage)
local listDebugVars = Instance.new("RemoteFunction", game.ReplicatedStorage)
local debugVarUpdated = Instance.new("RemoteEvent", game.ReplicatedStorage)

local invokeDebugAction = Instance.new("RemoteFunction", game.ReplicatedStorage)
local listDebugActions = Instance.new("RemoteFunction", game.ReplicatedStorage)

setDebugVar.Name = "SetDebugVar"
listDebugVars.Name = "ListDebugVars"
debugVarUpdated.Name = "DebugVarUpdated"

invokeDebugAction.Name = "InvokeDebugAction"
listDebugActions.Name = "ListDebugActions"

function getVar(var)
	for _,v in pairs(debugVars) do
		if v.name == var then
			return v
		end
	end
end

setDebugVar.OnServerInvoke = (function (player, var, val)
	local spec = getVar(var)
	if (not spec) then return end

	if (spec.datatype == "number") then
		val = tonumber(val)

		if (val == nil) then -- could not convert to number, don't change the value
			val = _G.debugVars[var]
		end

		if (spec.min) and (spec.min > val) then
			val = spec.min
		end

		if (spec.max) and (spec.max < val) then
			val = spec.max
		end
	end

	if (spec.datatype == "boolean") then
		val = val:lower()

		if (val == "true") or (val == "t") or (val == "1") then
			val = true
		elseif (val == "false") or (val == "f") or (val == "0") then
			val = false
		else
			val = _G.debugVars[var]
		end
	end

	_G.debugVars[var] = val
	debugVarUpdated:FireAllClients(var, val)
end)

listDebugVars.OnServerInvoke = (function (player)
	local currentVarDefs = {}

	for _,v in pairs(debugVars) do
		table.insert(currentVarDefs, {
			name = v.name,
			default = v.default,
			datatype = v.datatype,
			value = _G.debugVars[v.name],
			min = v.min,
			max = v.max,
			tooltip = v.tooltip
		})
	end

	return currentVarDefs
end)

invokeDebugAction.OnServerInvoke = (function (player, actionName)
	local action = debugActions[actionName]

	if (action) then
		action(player)
	end
end)

listDebugActions.OnServerInvoke = (function (player)
	local currentActionDefs = {}

	for k,v in pairs(debugActions) do
		table.insert(currentActionDefs, k)
	end

	return currentActionDefs
end)

------
------
_G.debugVars = {}
for _,v in pairs(debugVars) do
	_G.debugVars[v.name] = v.default
end

debugGui = debugGui:Clone()
debugGui.Parent = game.StarterGui

-- Legend26