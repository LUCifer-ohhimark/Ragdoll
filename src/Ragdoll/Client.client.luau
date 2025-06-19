local RagdollM = script.Parent
local ragdollRE = RagdollM.RagdollRE

local camera = workspace.CurrentCamera :: Camera
local camCFrame = camera.CFrame
camera:GetPropertyChangedSignal("CFrame"):Connect(function()
    camCFrame = camera.CFrame
end)

ragdollRE.OnClientEvent:Connect(function(humanoid: Humanoid)
    camera.CameraType = Enum.CameraType.Attach
    camera.CameraSubject = humanoid
    camera.CFrame = camCFrame
    camera.CameraType = Enum.CameraType.Custom
end)