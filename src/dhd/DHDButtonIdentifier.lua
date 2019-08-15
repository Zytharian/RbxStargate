-- Legend26, Ganondude

local gui = script.Parent
local frame = gui.Frame
local textLabel = frame.TextLabel
local DHDs = gui.DHDs

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

function hasToolEquipped()
	if not (player.Character) then return false end

	for k,v in pairs(player.Character:GetChildren()) do
		if (v:IsA("Tool")) then
			return true
		end
	end

	return false
end

function isDHD(target)
	if (target.Parent.Name == "DHD") then return true end

	for _,v in pairs(DHDs:GetChildren()) do
		if (target:IsDescendantOf(v.Value)) then
			return true
		end
	end

	return false
end

function positionFrame()
	frame.Position = UDim2.new(0,mouse.X - frame.Size.X.Offset*0.5,0,mouse.Y - frame.Size.Y.Offset*1.25)
end

function identifyTarget()
	local target = mouse.Target
	if (not target) then frame.Visible = false return end

	local toolEquipped = hasToolEquipped()
	local clicker = target:FindFirstChild("ClickDetector")

	if (clicker) and (not toolEquipped) and (tonumber(target.Name)) and (isDHD(target))
		and ((player.Character.PrimaryPart.Position - target.Position).magnitude <= clicker.MaxActivationDistance)
	then
		textLabel.Text = target.Name
		positionFrame()
		frame.Visible = true
	elseif (frame.Visible) and (not toolEquipped) and (target.Name == "Mid" or target.Name == "Base") and (isDHD(target)) then
		positionFrame()
	else
		frame.Visible = false
	end
end

--

frame.Visible = false

while (gui.Parent) do
	identifyTarget()
	wait()
end

-- Legend26, Ganondude