-- DoubleJump (client only)
-- Rocket Caleb's power: while the server-written player attribute
-- "CanDoubleJump" is true (PowerService), the local player can jump once more
-- while in the air. Landing gives the extra jump back.
--
-- Character physics is client-owned in Roblox anyway, so this is a local
-- movement feature: it changes nothing the server trusts (cookies, plots,
-- purchases are all server-side).
--
-- Lives in StarterPlayerScripts (runs once per session) and re-hooks each
-- new character.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- JumpRequest fires repeatedly while the jump button is held, so the air jump
-- is only allowed this long after leaving the ground (holding jump does not
-- fire both jumps at once).
local MIN_AIR_SECONDS = 0.2

local humanoid: Humanoid? = nil
local airborneSince: number? = nil
local usedAirJump = false

local function onStateChanged(_old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
	if new == Enum.HumanoidStateType.Landed
		or new == Enum.HumanoidStateType.Running
		or new == Enum.HumanoidStateType.Swimming
		or new == Enum.HumanoidStateType.Climbing
	then
		airborneSince = nil
		usedAirJump = false
	elseif new == Enum.HumanoidStateType.Freefall or new == Enum.HumanoidStateType.Jumping then
		airborneSince = airborneSince or os.clock()
	end
end

local function onCharacterAdded(character: Model)
	local newHumanoid = character:WaitForChild("Humanoid", 10)
	if not newHumanoid or not newHumanoid:IsA("Humanoid") or player.Character ~= character then
		return
	end
	humanoid = newHumanoid
	airborneSince = nil
	usedAirJump = false
	newHumanoid.StateChanged:Connect(onStateChanged)
end

UserInputService.JumpRequest:Connect(function()
	local current = humanoid
	if not current or current.Health <= 0 or usedAirJump or not player:GetAttribute("CanDoubleJump") then
		return
	end
	if current:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end
	if not airborneSince or os.clock() - airborneSince < MIN_AIR_SECONDS then
		return
	end
	usedAirJump = true
	current:ChangeState(Enum.HumanoidStateType.Jumping)
end)

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
