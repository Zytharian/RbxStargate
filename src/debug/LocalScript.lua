-- Legend26

local rs = game.ReplicatedStorage
local gui = script.Parent

local varFrame =    gui:WaitForChild("VarFrame", 1)
local actionFrame = gui:WaitForChild("ActionFrame", 1)
local tooltip = gui:WaitForChild("ToolTip", 1)
local displayButton = gui:WaitForChild("ShowHide", 1)

local robloxTopUIBarYSize = 35

assert(varFrame and actionFrame and tooltip and displayButton, "Some gui components not detected in DebugGui!")

------
------
function showToolTip(text)
	tooltip.Visible = text ~= ""
	tooltip.Text = text
	tooltip.Size = UDim2.new(0, tooltip.TextBounds.X + 10, 0, 25)
end
------
------
function debugVarMain()
	local varTemplate = varFrame.EntryTemplate
	varTemplate.Parent = nil

	local setDebugVar =     rs.SetDebugVar
	local listDebugVars =   rs.ListDebugVars
	local debugVarUpdated = rs.DebugVarUpdated

	local vars = listDebugVars:InvokeServer()
	local nextPos = 0

	for _,v in pairs(vars) do
		local entry = varTemplate:Clone()
		entry.Parent = varFrame

		entry.Name = v.name
		entry.NameLabel.Text = v.name
		entry.Type.Text = v.datatype
		entry.DefaultValue.Text = tostring(v.default)
		entry.Constraint.Text = v.datatype == "number"
			and (v.min and v.min or "?").."-"..(v.max and v.max or "?")
			or "?-?"
		entry.CurrentValue.Text = tostring(v.value)

		entry.Position = UDim2.new(0, 0, 0, varTemplate.Size.Y.Offset*nextPos)

		entry.CurrentValue.FocusLost:Connect(function (enterPressed, input)
			setDebugVar:InvokeServer(v.name, entry.CurrentValue.Text)
		end)

		debugVarUpdated.OnClientEvent:Connect(function (var, val)
			if (var == v.name) then
				entry.CurrentValue.Text = tostring(val)
			end
		end)

		entry.MouseEnter:Connect(function ()
			showToolTip(v.tooltip or "")
		end)

		nextPos = nextPos + 1
	end

	varFrame.Size = UDim2.new(0, varFrame.Size.X.Offset, 0, varTemplate.Size.Y.Offset*#varFrame:GetChildren())
	varFrame.Position = UDim2.new(0, 0, 1, -varFrame.Size.Y.Offset)

	varFrame.MouseLeave:Connect(function ()
		tooltip.Visible = false
	end)

	varFrame.MouseMoved:Connect(function (x, y)
		tooltip.Position = UDim2.new(0, x, 0, y-tooltip.Size.Y.Offset-robloxTopUIBarYSize)
		tooltip.Visible = tooltip.Text ~= ""
	end)
end
------
------
function debugActionMain()
	local actionTemplate = actionFrame.EntryTemplate
	actionTemplate.Parent = nil

	local invokeDebugAction = rs.InvokeDebugAction
	local listDebugActions = rs.ListDebugActions

	local actions = listDebugActions:InvokeServer()
	local nextPos = 0
	for _,v in pairs(actions) do
		local entry = actionTemplate:Clone()
		entry.Parent = actionFrame

		entry.Name = v
		entry.Text = v

		entry.Position = UDim2.new(0, 0, 0, actionTemplate.Size.Y.Offset*nextPos)

		entry.Activated:Connect(function ()
			invokeDebugAction:InvokeServer(v)
		end)

		nextPos = nextPos + 1
	end

	actionFrame.Size = UDim2.new(0, actionFrame.Size.X.Offset, 0, actionTemplate.Size.Y.Offset*#actionFrame:GetChildren())
	actionFrame.Position = UDim2.new(1, -actionFrame.Size.X.Offset, 1, -actionFrame.Size.Y.Offset - 50)
end
------
------
function displayButtonMain()
	displayButton.Activated:Connect(function ()
		varFrame.Visible = not varFrame.Visible
	end)
end
------
------
varFrame.Visible = false
actionFrame.Visible = true

debugVarMain()
debugActionMain()
displayButtonMain()

-- Legend26