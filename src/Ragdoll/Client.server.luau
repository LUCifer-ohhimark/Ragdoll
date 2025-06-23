local RagdollM = script.Parent
local ragdollRE = RagdollM.RagdollRE
local motorRE = RagdollM.MotorRE

local camera = workspace.CurrentCamera :: Camera

ragdollRE.OnClientEvent:Connect(function(humanoid: Humanoid)
    camera.CameraSubject = humanoid
end)

motorRE.OnClientEvent:Connect(function(character: Model, enabled: boolean)
    for _, v in character:GetDescendants() do
        if v.Name == "RootJoint" or v.Name == "Neck" then 
            continue 
        end

        if v:IsA("Motor6D") then 
            v.Enabled = enabled
        end

        if v:IsA("BallSocketConstraint") then 
            v.Enabled = not enabled 
        end
    end
end)