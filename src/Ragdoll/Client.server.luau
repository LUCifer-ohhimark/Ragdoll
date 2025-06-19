local RagdollM = script.Parent
local ragdollRE = RagdollM.RagdollRE

local camera = workspace.CurrentCamera :: Camera

ragdollRE.OnClientEvent:Connect(function(humanoid: Humanoid)
    camera.CameraSubject = humanoid
end)