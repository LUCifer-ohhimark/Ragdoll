local RagdollM = script.Parent
local ragdollRF = RagdollM.RagdollRF

local camera = workspace.CurrentCamera

ragdollRF.OnClientInvoke = function(humanoid: Humanoid)
    camera.CameraSubject = humanoid
end