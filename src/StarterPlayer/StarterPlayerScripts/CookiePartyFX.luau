-- CookiePartyFX (client only, ModuleScript)
-- The Cookie Party's screen show, driven by CalebEventUI.client.luau. While
-- the party (CalebState "Celebration") is on, one Heartbeat connection reads
-- CookieParty.TimeLeft (from the server's CalebStateEndsAt, so every client
-- agrees) and:
--   * pulses the "COOKIE PARTY!" banner on the beat, shifts its color per
--     phase and shakes it a little in Frenzy / Countdown;
--   * slams a short callout when Hype ("MORE COOKIES!") and Frenzy ("GOLDEN
--     COOKIE FRENZY!") begin (only when seen live, not on join);
--   * ramps the party lighting (CalebEventFX.UpdateParty) with the
--     intensity, plus a soft pulse every 2 beats (never > ~1.2 per second);
--   * drops small UI confetti bursts, more often in later phases;
--   * shows the 10..1 countdown: each number once (ceil of seconds left),
--     drawn by CookiePartyCountdown. (The tick sound is CalebAudio's.)
-- Stop() undoes everything. ShowReward plays the finale's "YOU COLLECTED"
-- total + party bonus (CookiePartyTotal).
-- Looks only: never changes game state, never talks to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local CookieParty = require(ReplicatedStorage.Shared.CookieParty)
local CalebEventFX = require(script.Parent:WaitForChild("CalebEventFX"))
local CookiePartyCountdown = require(script.Parent:WaitForChild("CookiePartyCountdown"))
local CookiePartyTotal = require(script.Parent:WaitForChild("CookiePartyTotal"))

local CookiePartyFX = {}

-- Look (presentation only)
local BANNER_COLORS = {
	Start = Color3.fromRGB(255, 90, 160), -- the banner's own pink
	Hype = Color3.fromRGB(255, 120, 70),
	Frenzy = Color3.fromRGB(240, 170, 20),
	Countdown = Color3.fromRGB(235, 60, 60),
}
local BANNER_SHAKE = { Start = 0, Hype = 0, Frenzy = 2, Countdown = 4 } -- pixels
local BANNER_HOME = UDim2.new(0.5, 0, 0, 70) -- CalebEventUIBuild's TOP_OFFSET

local ui = nil -- CalebEventUIBuild parts
local statue: Instance? = nil
local connection: RBXScriptConnection? = nil
local phase: string? = nil
local lastNumber: number? = nil
local bannerReadyAt = 0
local nextConfettiAt = 0

local function tween(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local t = TweenService:Create(instance, info, goal)
	t:Play()
	return t
end

local function step()
	if not statue then
		return
	end
	local left = CookieParty.TimeLeft(statue)
	local p = CookieParty.GetPhase(left)
	if p ~= phase then
		phase = p
		tween(ui.PartyBanner, TweenInfo.new(0.6), { BackgroundColor3 = BANNER_COLORS[p] })
		CookiePartyCountdown.ShowCallout(p)
		CalebEventFX.Confetti(ui, Config.CookiePartyConfettiPieces * 2)
	end

	-- Beat pulse from the server-synced clock: 1 on the pulse, easing to 0.
	local elapsed = Config.CalebCelebrationSeconds - left
	local pulsesPerSecond = Config.CookiePartyMusicBPM / 120 * (Config.CookiePartyMusicSpeed[p] or 1)
	local beat = (1 - (elapsed * pulsesPerSecond) % 1) ^ 2
	local strength = Config.CookiePartyPulse[p] or 0
	CalebEventFX.UpdateParty(CookieParty.Intensity(left), beat * strength)

	if os.clock() >= bannerReadyAt then
		ui.PartyScale.Scale = 1 + beat * (0.03 + 0.07 * strength)
		ui.PartyBanner.Rotation = math.sin(elapsed * pulsesPerSecond * math.pi) * 2 * strength
		local shake = BANNER_SHAKE[p] or 0
		ui.PartyBanner.Position = BANNER_HOME + UDim2.fromOffset(math.random(-shake, shake), math.random(-shake, shake))
	end

	local now = os.clock()
	if now >= nextConfettiAt then
		nextConfettiAt = now + (Config.CookiePartyConfettiEvery[p] or 8)
		CalebEventFX.Confetti(ui, Config.CookiePartyConfettiPieces)
	end

	local n = math.ceil(left)
	if left > 0 and n <= Config.CookiePartyPhases.Countdown and n ~= lastNumber then
		lastNumber = n
		CookiePartyCountdown.ShowNumber(n)
	end
end

-- Call once with the built UI (CalebEventUIBuild + CookiePartyUIBuild).
function CookiePartyFX.Init(uiParts, partyParts)
	ui = uiParts
	CookiePartyCountdown.Init(partyParts)
	CookiePartyTotal.Init(uiParts)
end

-- The party is on (also when joining mid-party: no callout for the phase
-- we land in; the countdown shows the current number).
function CookiePartyFX.Start(theStatue: Instance)
	CookiePartyFX.Stop()
	CookiePartyTotal.Hide()
	statue = theStatue
	phase = CookieParty.GetPhase(CookieParty.TimeLeft(theStatue))
	lastNumber = nil
	bannerReadyAt = os.clock() + 0.4 -- after CalebEventUI's pop-in
	nextConfettiAt = os.clock() + (Config.CookiePartyConfettiEvery[phase] or 8)
	ui.PartyBanner.BackgroundColor3 = BANNER_COLORS[phase]
	connection = RunService.Heartbeat:Connect(step)
end

-- The party is over (or never was): undo every change.
function CookiePartyFX.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	statue = nil
	phase = nil
	CookiePartyCountdown.Hide()
	ui.PartyScale.Scale = 1
	ui.PartyBanner.Rotation = 0
	ui.PartyBanner.Position = BANNER_HOME
	ui.PartyBanner.BackgroundColor3 = BANNER_COLORS.Start
end

-- The finale: "YOU COLLECTED" total + party bonus (CookiePartyFinale
-- remote; display only).
function CookiePartyFX.ShowReward(reward: any)
	CookiePartyTotal.Show(reward)
end

return CookiePartyFX
