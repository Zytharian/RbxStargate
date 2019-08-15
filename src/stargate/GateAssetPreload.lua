-- Legend26

local locatorPrefix = "rbxassetid://"
local outputPrefix = "[" .. script.Name .. "] "

local contentProvider = game:GetService("ContentProvider")
local rs = game:GetService("ReplicatedStorage")

local remote = rs:WaitForChild("GetStargateAssets", 120)

function loadSounds(data)
	local sounds = {}

	print(outputPrefix .. "Loading " .. #data.Sounds .. " sounds")

	for _,v in pairs(data.Sounds) do
		local s = Instance.new("Sound")
		s.SoundId = locatorPrefix .. v
		table.insert(sounds, s)
	end

	contentProvider:PreloadAsync(sounds)
end

function loadDecals(data)
	local decals = {}

	print(outputPrefix .. "Loading " .. #data.Decals .. " decals")

	for _,v in pairs(data.Decals) do
		local d = Instance.new("Decal")
		d.Texture = locatorPrefix .. v
		table.insert(decals, d)
	end

	contentProvider:PreloadAsync(decals)
end

if (not remote) then
	print(outputPrefix .. "Unable to preload assets")
else
	local data = remote:InvokeServer()
	loadDecals(data)
	loadSounds(data)
	print(outputPrefix .. "Loading complete")
end

-- Legend26