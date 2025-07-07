--!nocheck
local Players = game.Players
local ragdollCloneRE = script.RagdollCloneRE
local ragdoll = {}

local lastChar: Model

local isRagdoll: boolean = false
export type Ragdoll = {
    ToggleRagdoll: (character: Model?, enabled: boolean?) -> (),
    toggleRagdollCharacter: (character: Model?, enabled: boolean?) -> (),
	MakeRagdollClone: (character: Model?, playerAttach: boolean?) -> (),
	GetRagdollState: () -> ()
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

    for i, _ in bodyParts do
        local part = Instance.new("Part")
        part.Name = "RAGDOLL_COLLIDER"
        part.Size = bodyParts[i].Size / 2
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

local function setupHumamoid(humanoid: Humanoid, enabled: boolean?)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not enabled)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, not enabled)
    humanoid.PlatformStand = enabled
    humanoid.AutoRotate = not enabled
end

local function toggleMotor6D(character: Model?, enabled: boolean?)
    for _, instance in character:GetDescendants() do
        if instance.Name == "RootJoint" or instance.Name == "Neck" then
            continue
        end

        if instance:IsA("BasePart") then
            if instance:HasTag("Ragdoll") then
                instance.CanCollide = not enabled
            end
        end

        if instance:IsA("Motor6D") then
            instance.Enabled = enabled
        end

        if instance:IsA("BallSocketConstraint") then
            instance.Enabled = not enabled
        end
    end
end

local function fireRagdoll(character: Model, enabled: boolean)
    toggleMotor6D(character, not enabled)
    setupHumamoid(character:WaitForChild("Humanoid"), enabled)
end

--[=[
    Creates a Ragdoll as an object.
    character: Model -- Character for setting up a Ragdoll.
]=]
function ragdoll.new(character: Model) : {}
    local self = {} :: Ragdoll
    lastChar = character
    local humanoid = lastChar:FindFirstChildOfClass("Humanoid") :: Humanoid
    humanoid.RequiresNeck = true
    humanoid.BreakJointsOnDeath = false

    isRagdoll = false

    setupRagdoll(lastChar)
    return self
end

local modelCFrame: CFrame
--[=[
    Toggles Ragdoll for Character.
    character: Model? -- Character for toggling Ragdoll.
    enabled: boolean? -- self-explainatory.
]=]
function ragdoll:ToggleRagdoll(character: Model?, enabled: boolean?)
    if character then
        self.Character = character
    end

    if enabled then
        modelCFrame = character:GetPivot()
    end

    local player = Players:GetPlayerFromCharacter(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart

    if enabled then
        if player then
            rootPart:SetNetworkOwner(player)
        else
            rootPart:SetNetworkOwner(nil)
        end
    end

    fireRagdoll(character, enabled)
    
	isRagdoll = enabled

    if not enabled then
        local characterPivot = character:GetPivot()
        local characterPos = characterPivot.Position

        local position = CFrame.new(characterPos.X, characterPos.Y, characterPos.Z)
        character:PivotTo(position * modelCFrame.Rotation)
    end
end

--[=[
    Toggles Ragdoll for Character. Deprecated naming for ToggleRagdoll() method.
    character: Model? -- Character for toggling Ragdoll.
    enabled: boolean? -- self-explainatory.
]=]
function ragdoll:toggleRagdollCharacter(character: Model?, enabled: boolean?)
    ragdoll:ToggleRagdoll(character, enabled)
end


--[=[
    Clones your character and ragdolles it.
    character: Model? -- Character for Ragdoll Clone.
    playerAttach: boolean? -- Whether will player be attached to this Clone.
]=]
function ragdoll:MakeRagdollClone(character: Model?, playerAttach: boolean?, timeout: number?) : ()
    if character then
        lastChar = character
    end
    local oldCharacter = lastChar
    local player = Players:GetPlayerFromCharacter(lastChar)

    lastChar.Archivable = true
    local _character = oldCharacter:Clone()
    lastChar.Archivable = false

    _character.PrimaryPart = oldCharacter.PrimaryPart
    _character:PivotTo(oldCharacter:GetPivot())

    _character.Name = oldCharacter.Name.."_RAGDOLL"

    if playerAttach then
        oldCharacter:Destroy()
    end

    _character:FindFirstChild("Health"):Destroy()

    _character.Parent = workspace
    local _humanoid = _character:FindFirstChildOfClass("Humanoid") :: Humanoid
    fireRagdoll(_character, true)
    local rootPart = _character:FindFirstChild("HumanoidRootPart") :: BasePart
    local owner
    if not player then
        owner = nil 
    else
        owner = playerAttach and player or nil
    end
    rootPart:SetNetworkOwner(owner)

    if playerAttach then
        ragdollCloneRE:FireClient(player, _humanoid)
    end
    
    if timeout then
        task.delay(timeout, function()
            _character:Destroy()
        end)
    end
end

function ragdoll:GetRagdollState()
    return isRagdoll
end

return ragdoll