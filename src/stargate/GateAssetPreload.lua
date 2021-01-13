-- Legend26

local locatorPrefix = "rbxassetid://"
local outputPrefix = "Stargate: "

local contentProvider = game:GetService("ContentProvider")
local rs = game:GetService("ReplicatedStorage")

local remote = rs:WaitForChild("GetStargateAssets", 120)

function localPrint(str)
	print(outputPrefix .. str)
end

function loadDecals(data)
	local decals = {}

	localPrint("Loading " .. #data.Decals .. " images")

	for _,v in pairs(data.Decals) do
		local d = Instance.new("Decal")
		d.Texture = locatorPrefix .. v
		table.insert(decals, d)
	end

	contentProvider:PreloadAsync(decals)

	local part = Instance.new("Part")
	part.Name = "_StargateImagePreloaderContainer"
	part.Transparency = 1
	part.Position = Vector3.new(0, workspace.FallenPartsDestroyHeight or -500, 0)
	part.Size = Vector3.new(1,1,1)
	part.Anchored = true
	part.CanCollide = false
	part.Archivable = false
	for _,v in pairs(decals) do
		v.Transparency = 0.999
		v.Parent = part
	end
	part.Parent = workspace
end

function loadSounds(data)
	local sounds = {}

	localPrint("Loading " .. #data.Sounds .. " sounds")

	for _,v in pairs(data.Sounds) do
		local s = Instance.new("Sound")
		s.SoundId = locatorPrefix .. v
		table.insert(sounds, s)
	end

	contentProvider:PreloadAsync(sounds)
end

function outputVersions(data)
	for _,v in pairs(data.Versions) do
		localPrint("Found " .. v)
	end
end

if (not remote) then
	localPrint("Unable to preload assets")
else
	local data = remote:InvokeServer()
	loadDecals(data)
	loadSounds(data)
	outputVersions(data)
	localPrint("Loading complete")
end
script:Destroy()

-- Legend26