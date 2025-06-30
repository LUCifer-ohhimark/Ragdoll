local Players = game.Players
local RagdollM = script.Parent
local ragdollRE = RagdollM.RagdollCloneRE
local clientRagdollRE = RagdollM.ClientRagdollRE

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera :: Camera


local function toggleMotor6D(character: Model, enabled: boolean)
    for _, v in character:GetDescendants() do
        if v.Name == "RootJoint" or v.Name == "Neck" then 
            continue 
        end

        if v:IsA("BasePart") then
            if v:HasTag("Ragdoll") then 
                v.CanCollide = not enabled
            end
        end

        if v:IsA("BasePart") then
            if v:HasTag("Ragdoll") then 
                v.CanCollide = not enabled
            end
        end

        if v:IsA("Motor6D") then 
            v.Enabled = enabled
        end

        if v:IsA("BallSocketConstraint") then 
            v.Enabled = not enabled 
        end
    end
end

local function setupHumamoid(humanoid: Humanoid, enabled: boolean?)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not enabled)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, not enabled)
    humanoid.PlatformStand = enabled
    humanoid.AutoRotate = not enabled
end

ragdollRE.OnClientEvent:Connect(function(humanoid: Humanoid)
    camera.CameraSubject = humanoid
end)

local clone
clientRagdollRE.OnClientEvent:Connect(function(character: Model, enabled: boolean)
    if character.Parent == nil and clone.Parent then
        character.Parent = clone.Parent
    end

    if enabled then
        character.Archivable = true
        clone = character:Clone()
        character.Archivable = false
    end

    local _player = Players:GetPlayerFromCharacter(character) :: Player
    local cloneHumanoid = clone:WaitForChild("Humanoid") :: Humanoid
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid

    if enabled then
        if _player == player then
            camera.CameraSubject = cloneHumanoid
        end
        setupHumamoid(cloneHumanoid, true)
        toggleMotor6D(clone, false)
        clone.Parent = character.Parent

        _player.CharacterAdded:Once(function()
            clone:Destroy()
        end)
        character.Parent = nil
    else
        if _player == player then
            camera.CameraSubject = humanoid
        end
        clone:Destroy()
    end
end)