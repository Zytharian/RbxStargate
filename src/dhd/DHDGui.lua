-- Legend26, Ganondude

local addresses = nil

local backg_col = Color3.new(0,0,0)
local bordr_col = Color3.new(1,1,1)

local trans = 0

--

local player = game.Players.LocalPlayer

local gui = script.Parent
local main = gui:WaitForChild("Main",1)
local close_btn = main:WaitForChild("CancelButton",1)
local destSelected = gui:WaitForChild("DestinationSelected",1)
local findDialable = gui:WaitForChild("FindDialable",1)

if (not main or not close_btn or not destSelected or not findDialable) then
	error("DHDGui: Required objects not found")
end

local backg_inv = Color3.new(1 - backg_col.r,1 - backg_col.g,1 - backg_col.b)
local bordr_inv = Color3.new(1 - bordr_col.r,1 - bordr_col.g,1 - bordr_col.b)

function onMouseInOut(frame,out)
	if (not frame) then return end

	frame.BackgroundColor3 = (out) and backg_col or backg_inv
	frame.BorderColor3 = (out) and bordr_col or bordr_inv

	for k,v in pairs(frame:GetChildren()) do
		v.BackgroundColor3 = (out) and backg_col or backg_inv
		v.BorderColor3 = (out) and bordr_col or bordr_inv

		if (v:IsA("TextLabel")) then
			v.TextColor3 = (out) and bordr_col or bordr_inv
		end
	end
end

function onEntrySelected(n)
	if (not main.Visible) then return end
	destSelected:FireServer(n)
	main.Visible = false
end

function createListEntry(frame,n)
	local entry = addresses[n]
	if (not frame) or (not entry) then return end

	local name = Instance.new("TextLabel",frame)
	name.Name = "Name"
	name.BackgroundColor3 = backg_col
	name.BackgroundTransparency = trans
	name.BorderColor3 = bordr_col
	name.Position = UDim2.new(0,0,0,0)
	name.Size = UDim2.new(1,0,0.5,0)
	name.Text = entry[2]
	name.TextColor3 = bordr_col
	name.TextScaled = true

	for i,v in pairs(entry[1]) do
		local sym = Instance.new("TextLabel",frame)
		sym.Name = "Symbol"..i
		sym.BackgroundColor3 = backg_col
		sym.BackgroundTransparency = trans
		sym.BorderColor3 = bordr_col
		sym.Text = v
		sym.TextColor3 = bordr_col
		sym.TextScaled = true

		local x = 1 / #entry[1]

		sym.Position = UDim2.new(x*(i - 1),0,0.5,0)
		sym.Size = UDim2.new(x,0,0.5,0)
	end

	local btn = Instance.new("TextButton",frame)
	btn.Name = "SelectButton"
	btn.BackgroundColor3 = backg_col
	btn.BackgroundTransparency = 1
	btn.BorderColor3 = bordr_col
	btn.Position = UDim2.new(0,0,0,0)
	btn.Size = UDim2.new(1,0,1,0)
	btn.Text = ""

	btn.MouseButton1Click:connect(function() onEntrySelected(n) end)
end

function refreshList()
	addresses = findDialable:InvokeServer()

	local numRows = 5
	local numCols = math.ceil(#addresses/numRows)

	main.BackgroundTransparency = 0.4
	main.Position = UDim2.new(0.5 - 0.1*numCols,0,0.25,0)
	main.Size = UDim2.new(0.2*numCols,0,0.5,0)
	main.Visible = false

	for k,v in pairs(main:GetChildren()) do
		if (v:IsA("Frame")) then
			v:Destroy()
		end
	end

	for c = 0,numCols-1 do
		for r = 0,numRows-1 do
			local n = r + numRows*c + 1

			if (n <= #addresses) then
				local f = Instance.new("Frame",main)
				f.Name = "Frame"..n
				f.BackgroundColor3 = backg_col
				f.BackgroundTransparency = trans
				f.BorderColor3 = bordr_col

				local ofs = 0.03	--size offset
				f.Position = UDim2.new(1/numCols*c + ofs/2,0,0.2*r + ofs/2,0)
				f.Size = UDim2.new(1/numCols - ofs,0,1/numRows - ofs,0)

				createListEntry(f,n)

				f.MouseEnter:connect(function() onMouseInOut(f,false) end)
				f.MouseLeave:connect(function() onMouseInOut(f,true) end)
			end
		end
	end
end

close_btn.MouseButton1Click:connect(function()
	destSelected:FireServer(0) -- nothing was chosen (no index 0 exists in the list so this is fine)
	main.Visible = false
end)

refreshList()
main.Visible = true

-- Legend26, Ganondude