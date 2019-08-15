-- Legend26, Ganondude

local sync = script:WaitForChild("Sync", 0.3)
local part = script.Parent

if (sync) then
	local camera = game.Workspace.CurrentCamera
	local cfCam = camera.CoordinateFrame

	if (camera.CameraType == Enum.CameraType.Custom) then
		local char = part.Parent
		local cfTorso = sync.Value

		for i = 1,10 do
			if ((part.CFrame.p - cfTorso.p).magnitude > 10) then
				camera.CameraType = 6	-- Scriptable
				camera.CoordinateFrame = char.PrimaryPart.CFrame:toWorldSpace(cfTorso:toObjectSpace(cfCam))
				camera.Focus = char.Head.CFrame

				wait()

				camera.CameraType = 5	-- Custom
				camera.CameraSubject = char.Humanoid

				break
			end

			wait()
		end
	end
end

script:Destroy()

-- Legend26, Ganondude