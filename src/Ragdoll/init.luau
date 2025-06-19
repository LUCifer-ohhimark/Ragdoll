--!nocheck
local Players = game.Players
local ragdollRE = script.RagdollRE
local ragdoll = {}
local _ragdoll = {__index = ragdoll}
export type Ragdoll = {
    isRagdoll: boolean,
    Character: Model,
    Humanoid: Humanoid,
    Template: Model,
    ToggleRagdoll: (character: Model?, enabled: boolean?) -> (),
    toggleRagdollCharacter: (character: Model?, enabled: boolean?) -> (),
    MakeRagdollClone: (character: Model?, playerAttach: boolean?) -> ()
}

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

    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart

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

        ragdollJoint.UpperAngle = joint.Part1 == character:FindFirstChild("Head") and 45 or 90

        attachment0.Parent = rootPart
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
    local self = {} :: Ragdoll
    setmetatable(self, {__index = _ragdoll})
    self.Character = character
    self.Humanoid = self.Character:FindFirstChildOfClass("Humanoid") :: Humanoid
    self.Humanoid.RequiresNeck = true
    self.Humanoid.BreakJointsOnDeath = false

    self.isRagdoll = false :: boolean

    setupRagdoll(self.Character)
    return self
end

local function setupHumamoid(humanoid: Humanoid, enabled: boolean?)
    humanoid.PlatformStand = enabled
    humanoid.AutoRotate = not enabled
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not enabled)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, not enabled)
end

--[=[
    Toggles Ragdoll for Character.
    character: Model? -- Character for toggling Ragdoll.
    enabled: Model? -- self-explainatory.
]=]
function _ragdoll:ToggleRagdoll(character: Model?, enabled: boolean?)
    if character then
        self.Character = character
    end
    self.Humanoid = self.Character:FindFirstChildOfClass("Humanoid") :: Humanoid
    setupHumamoid(self.Humanoid, enabled)
    setMotor6D(character, not enabled)
end

--[=[
    Toggles Ragdoll for Character. Deprecated naming for ToggleRagdoll() method.
    character: Model? -- Character for toggling Ragdoll.
    enabled: Model? -- self-explainatory.
]=]
function _ragdoll:toggleRagdollCharacter(character: Model?, enabled: boolean?)
    self:ToggleRagdoll(character, enabled)
end


--[=[
    Clones your character and ragdolles it.
    character: Model? -- Character for Ragdoll Clone.
    playerAttach: boolean? -- Whether will player be attached to this Clone.
]=]
function _ragdoll:MakeRagdollClone(character: Model?, playerAttach: boolean?) : ()
    if character then
        self.Character = character
    end
    local oldCharacter = self.Character
    local player = Players:GetPlayerFromCharacter(self.Character)

    self.Character.Archivable = true
    self._Character = oldCharacter:Clone()
    self.Character.Archivable = false

    self._Character.PrimaryPart = oldCharacter.PrimaryPart
    self._Character:PivotTo(oldCharacter:GetPivot())

    self._Character.Name = oldCharacter.Name

    if playerAttach then
        player.Character = self._Character
        oldCharacter:Destroy()
    end

    self._Character:FindFirstChild("Health"):Destroy()

    self._Character.Parent = workspace
    self._Humanoid = self._Character:FindFirstChildOfClass("Humanoid") :: Humanoid
    setupHumamoid(self._Humanoid, true)
    setMotor6D(self._Character, false)
    local rootPart = self._Character:FindFirstChild("HumanoidRootPart") :: BasePart
    local owner = playerAttach and player or nil
    rootPart:SetNetworkOwner(owner)

    if playerAttach then
        ragdollRE:FireClient(player, self._Humanoid)
    end
    self.isRagdoll = true
end

function _ragdoll:GetRagdollType()
    return self.isRagdoll
end

return ragdoll