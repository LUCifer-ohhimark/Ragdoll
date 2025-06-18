local ragdoll = {}

local function createPart(parent, name: string, cframe:CFrame, size: number, transparency: number)
    local part = Instance.new("Part")
    part.Parent = parent
    part.Name = name
    part.CFrame = cframe
    part.Size = size
    part.Transparency = transparency
    part.CanCollide = false
    return part
end

local function createWeldConstraint(parent, part0: BasePart, part1: BasePart)
    local weld = Instance.new("WeldConstraint")
    weld.Parent = parent
    weld.Part0 = part0
    weld.Part1 = part1

    return weld
end

local function createAttachment(parent, name: string, cframe: CFrame)
    local attachment = Instance.new("Attachment")
    attachment.Parent = parent
    attachment.Name = name
    attachment.CFrame = cframe
    return attachment
end

local function createRagdollJoint(parent, name: string, attachment0: Attachment, attachment1: Attachment)
    local joint = Instance.new("BallSocketConstraint")
    joint.Parent = parent
    joint.Name = name
    joint.Attachment0 = attachment0
    joint.Attachment1 = attachment1
    return joint
end

local function buildRagdollColliders(character: Model)
    local partSize = Vector3.new(0.5, 0.5, 0.5)

    local bodyParts = {
        character.Torso,
        character.Head,
        character["Left Arm"],
        character["Right Arm"],
        character["Left Leg"],
        character["Right Leg"]
    }

    for i, _ in bodyParts do
        local part = createPart(bodyParts[i], "RAGDOLL_COLLIDER", bodyParts[i].CFrame, partSize, 1)
        part:AddTag("Ragdoll")
        part.CanCollide = false
        createWeldConstraint(part, part, bodyParts[i])
    end
end

local function buildRagdollJoints(character: Model)
    local jointData = {
        [character.Torso.Neck] = {CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0)},
        [character.Torso["Left Shoulder"]] = {CFrame.new(-1, 1, 0), CFrame.new(0.5, 1, 0)},
        [character.Torso["Right Shoulder"]] = {CFrame.new(1, 1, 0), CFrame.new(-0.5, 1, 0)},
        [character.Torso["Left Hip"]] = {CFrame.new(-1, -1, 0), CFrame.new(-0.5, 1, 0)},
        [character.Torso["Right Hip"]] = {CFrame.new(1, -1, 0), CFrame.new(0.5, 1, 0)}
    }

    for i, v in jointData do
        local attachment0 = createAttachment(i.Part0, "RAGDOLL_ATTACHMENT_"..string.upper(string.gsub(i.Name, " ", "_")), v[1])
        local attachment1 = createAttachment(i.Part1, "RAGDOLL_ATTACHMENT_"..string.upper(string.gsub(i.Part1.Name, " ", "_")), v[2])
        local joint = createRagdollJoint(i.Part1, "RAGDOLL_JOINT", attachment0, attachment1)
        joint.LimitsEnabled = true
        joint.TwistLimitsEnabled = true
        joint.TwistLowerAngle = -45
        joint.TwistUpperAngle = 45
        if i.Part1 == character.Head then
            joint.UpperAngle = 45
        else
            joint.UpperAngle = 90
        end
    end
end

local function toggleMotor6D(character: Model, enabled: boolean)
    for _, v in character:GetDescendants() do
		if v.Name == "RootJoint" or v.Name == "Neck" or v.Name == "Handle" then continue end
        if v:IsA("BallSocketConstraint") then v.Enabled = not enabled end
        if v:IsA("BasePart") then
			if v:HasTag("Ragdoll") then v.CanCollide = not enabled end
		end
        if v:IsA("Motor6D") then v.Enabled = enabled end
    end
end

function ragdoll:init(character: Model)
    local humanoid = character.Humanoid
    humanoid.BreakJointsOnDeath = false
    humanoid.RequiresNeck = true

    buildRagdollColliders(character)
    buildRagdollJoints(character)
end

function ragdoll:toggleRagdollCharacter(character: Model, enabled: boolean)
    local humanoid = character.Humanoid
    humanoid.PlatformStand = enabled
    humanoid.AutoRotate = not enabled
	toggleMotor6D(character, not enabled)
end

return ragdoll