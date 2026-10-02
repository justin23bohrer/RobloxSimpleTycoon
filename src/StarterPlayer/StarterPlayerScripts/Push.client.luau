-- Push (client only)
-- The defender's push (ARCHITECTURE.md "House Raid (contract)", Push):
--   * input: F (keyboard), ButtonX (gamepad), or the round PUSH button on
--     touch devices (PushButton). A press plays the shove locally
--     (PushAnimation) and the swing sound, and fires PushRequest (no args).
--     The cooldown is respected here too, but only for looks: the server
--     enforces Config.PushCooldown and finds the target itself.
--   * PushKnockback(velocity, stagger): the server says this client's
--     character was pushed. Characters are client-owned, so it is applied
--     here: the root gets the velocity; a stopped thief also staggers
--     (PlatformStand) for Config.PushStaggerSeconds.
--   * PushFX(pusherUserId, targetUserId?, stoppedThief): everyone sees the
--     pusher's shove (other players' pushes), and on a hit the burst, hit
--     sound and "POW!" / "STOPPED!" pop (PushEffects).
-- Lives in StarterPlayerScripts (runs once per session).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local HouseRaid = require(ReplicatedStorage.Shared.HouseRaid)
local PushAnimation = require(script.Parent:WaitForChild("PushAnimation"))
local PushButton = require(script.Parent:WaitForChild("PushButton"))
local PushEffects = require(script.Parent:WaitForChild("PushEffects"))

local player = Players.LocalPlayer
local pushRemote = HouseRaid.GetRemote(HouseRaid.Remote.Push)

-- A server velocity bigger than this is ignored (never fling ourselves).
local MAX_KNOCKBACK = (Config.PushKnockbackSpeed + Config.PushKnockbackUp) * 1.5

local lastPushAt = -math.huge
local buttonParts: PushButton.Parts? = nil

local function aliveCharacter(target: Player?): (Model?, Humanoid?, BasePart?)
	local character = target and target.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil, nil, nil
	end
	return character, humanoid, root
end

local function push()
	local now = os.clock()
	if now - lastPushAt < Config.PushCooldown then
		return
	end
	local character, _, root = aliveCharacter(player)
	if not character or not root then
		return
	end
	lastPushAt = now
	PushAnimation.Play(character)
	PushEffects.Swing(root.Position)
	if buttonParts then
		PushButton.StartCooldown(buttonParts, Config.PushCooldown)
	end
	pushRemote:FireServer()
end

ContextActionService:BindAction("Push", function(_name, state: Enum.UserInputState, _input)
	if state == Enum.UserInputState.Begin then
		push()
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonX)

if UserInputService.TouchEnabled then
	buttonParts = PushButton.Build(push)
end

-- Knockback ------------------------------------------------------------------

local staggerToken = 0

HouseRaid.GetRemote(HouseRaid.Remote.Knockback).OnClientEvent:Connect(function(velocity: any, stagger: any)
	if typeof(velocity) ~= "Vector3" or velocity.Magnitude > MAX_KNOCKBACK then
		return
	end
	local _, humanoid, root = aliveCharacter(player)
	if not humanoid or not root then
		return
	end
	if stagger == true then
		staggerToken += 1
		local token = staggerToken
		humanoid.PlatformStand = true
		task.delay(Config.PushStaggerSeconds, function()
			if staggerToken == token and humanoid.Parent then
				humanoid.PlatformStand = false
				root.AssemblyAngularVelocity = Vector3.zero
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end
	root.AssemblyLinearVelocity = velocity
end)

-- Feedback (every push, from the server) ---------------------------------------

HouseRaid.GetRemote(HouseRaid.Remote.PushFX).OnClientEvent:Connect(function(pusherId: any, targetId: any, thief: any)
	if typeof(pusherId) ~= "number" then
		return
	end
	-- Our own shove and swing already played on the press.
	if pusherId ~= player.UserId then
		local pusherCharacter, _, pusherRoot = aliveCharacter(Players:GetPlayerByUserId(pusherId))
		if pusherCharacter and pusherRoot then
			PushAnimation.Play(pusherCharacter)
			PushEffects.Swing(pusherRoot.Position)
		end
	end
	if typeof(targetId) == "number" then
		local target = Players:GetPlayerByUserId(targetId)
		local targetCharacter = target and target.Character
		if targetCharacter then
			PushEffects.Hit(targetCharacter, thief == true)
		end
	end
end)
