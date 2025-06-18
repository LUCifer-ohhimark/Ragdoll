--!nocheck
local Players = game.Players
local ragdollRF = script.RagdollRF
local ragdoll = {
    __index = {
        className = "Ragdoll",
        isRagdoll = false
    }
}

export type Ragdoll = {
    isRagdoll: boolean,
    Character: Model,
    Humanoid: Humanoid,
    Template: Model
}

function ragdoll.__index:GetRagdollType()
    return self.isRagdoll
end

local function setupRagdoll(character: Model)
    local bodyParts = {
        character:FindFirstChild("Torso"),
        character:FindFirstChild("Head"),
        character:FindFirstChild("Left Leg"),
        character:FindFirstChild("Right Leg"),
        character:FindFirstChild("Left Arm"),
        character:FindFirstChild("Right Arm")
    }

    local partSize = Vector3.new(.5, .5, .5)
    for i, _ in bodyParts do
        local part = Instance.new("Part")
        part.Name = "RAGDOLL_COLLIDER"
        part.Size = partSize
        part.CanCollide = false
        part.CFrame = bodyParts[i].CFrame
        part.Transparency = 1
        part:AddTag("Ragdoll")

        local weld = Instance.new("WeldConstraint")
        weld.Name = "RAGDOLL_WELD"
        weld.Part0 = bodyParts[i]
        weld.Part1 = part

        weld.Parent = part
        part.Parent = bodyParts[i]
    end

    local jointData = {
        [character.Torso.Neck] = {CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0)},
        [character.Torso["Left Shoulder"]] = {CFrame.new(-1, 1, 0), CFrame.new(0.5, 1, 0)},
        [character.Torso["Right Shoulder"]] = {CFrame.new(1, 1, 0), CFrame.new(-0.5, 1, 0)},
        [character.Torso["Left Hip"]] = {CFrame.new(-1, -1, 0), CFrame.new(-0.5, 1, 0)},
        [character.Torso["Right Hip"]] = {CFrame.new(1, -1, 0), CFrame.new(0.5, 1, 0)}
    }

    for joint, value in jointData do
        local attachment0 = Instance.new("Attachment")
        attachment0.CFrame = value[1]
        attachment0.Name = "RAGDOLL_ATTACHMENT_"..string.upper(string.gsub(joint.Part0.Name, " ", "_"))

        local attachment1 = Instance.new("Attachment")
        attachment1.CFrame = value[2]
        attachment1.Name = "RAGDOLL_ATTACHMENT_"..string.upper(string.gsub(joint.Part1.Name, " ", "_"))

        local ragdollJoint = Instance.new("BallSocketConstraint")
        ragdollJoint.Name = "RAGDOLL_JOINT"
        ragdollJoint.Attachment0 = attachment0
        ragdollJoint.Attachment1 = attachment1

        ragdollJoint.LimitsEnabled = true
        ragdollJoint.TwistLimitsEnabled = true
        ragdollJoint.TwistLowerAngle = -45
        ragdollJoint.TwistUpperAngle = 45

        ragdollJoint.UpperAngle = joint.Part1 == character:FindFirstChild("")

        attachment0.Parent = joint.Part0
        attachment1.Parent = joint.Part1
        ragdollJoint.Parent = joint.Part1
    end
end

local function setMotor6D(character: Model, enabled: boolean)
    for _, v in character:GetDescendants() do
        if v.Name == "RootJoint" or v.Name == "Neck" or v.Name == "Handle" then 
            continue 
        end

        if v:IsA("BallSocketConstraint") then 
            v.Enabled = not enabled 
        end

        if v:IsA("BasePart") then
            if v:HasTag("Ragdoll") then 
                v.CanCollide = not enabled 
            end
        end

        if v:IsA("Motor6D") then 
            v.Enabled = enabled
        end
    end
end

--[=[
    Creates a Ragdoll as an object.
    character: Model -- Character for setting up a Ragdoll.
]=]
function ragdoll.new(character: Model) : {}
    local self = setmetatable({}:: Ragdoll, {__index = ragdoll})
    self.Character = character
    self.Humanoid = self.Character:FindFirstChild("Humanoid") :: Humanoid
    self.Humanoid.RequiresNeck = true
    self.Humanoid.BreakJointsOnDeath = false
    return self
end

function ragdoll:SetRagdoll(enabled: boolean)
    self.Template = script:FindFirstChild("RagdollTemplate"):Clone() :: Model
    local oldCharacter = self.Character
    local player = Players:GetPlayerFromCharacter(self.Character)

    for _, instance in pairs(oldCharacter:GetChildren()) do
        if instance:IsA("Humanoid") then
            return
        end
        instance = instance:Clone()
        instance.Parent = self.Template
    end

    self.Template.Name = tostring(player).."_RAGDOLL"
    setupRagdoll(self.Template)

    self.Template.PrimaryPart = oldCharacter.PrimaryPart
    self.Template:PivotTo(oldCharacter:GetPivot())

    if enabled then
        self.Character = self.Template
        oldCharacter:Destroy()
        self.Template.Parent = workspace
    else
        self.Template:Destroy()
    end

    setMotor6D(self.Character, not enabled)
    self.Humanoid = self.Character:FindFirstChild("Humanoid") :: Humanoid
    self.Humanoid.PlatformStand = enabled
    ragdollRF:InvokeClient(player, self.Humanoid)
    self.isRagdoll = enabled
end

return ragdoll