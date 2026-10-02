-- CookiePartyMotion (client only, ModuleScript)
-- How a collectable Cookie Party cookie moves each frame, for
-- CookiePartyCookies.client: the fall from the sky (or the arc out of Caleb's
-- mouth when FromCaleb) that touches down exactly at LandAt, the landing
-- bounce, the idle bob + spin, the blink before ExpiresAt, the lean toward
-- the player while a collect waits for the server, the "mine!" pop (grow,
-- then shrink into the player), and the expired fade.
--
-- Presentation only: it moves and fades the cookie's look (CookiePartyLook)
-- and decides nothing. All times are Workspace:GetServerTimeNow() values.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Look = require(script.Parent:WaitForChild("CookiePartyLook"))
local Feedback = require(script.Parent:WaitForChild("CookiePartyFeedback"))

local Motion = {}

-- Looks only; not gameplay tuning.
local SKY_HEIGHT = 70 -- sky cookies start this far above their landing spot
local FALL_WOBBLE = 3 -- sideways sway (studs) high up, none at touchdown
local FALL_TUMBLE = 1.2 -- extra tilt (radians) while flying
local AIR_SPIN = 3 -- spins this many times faster while flying
local TILT = math.rad(65) -- cookies stand tilted like coins so they read from afar
local THROW_ARC = 0.35 -- arc height per stud Caleb throws
local MIN_ARC = 12
local BOUNCE_SECONDS = 0.4
local BLINK_SECONDS = 1.5
local SUCK_SECONDS = 0.15
local POP_GROW_SECONDS = 0.08
local POP_SECONDS = 0.35
local FADE_SECONDS = 0.3

export type Live = {
	Id: number,
	Type: string, -- the server's type (Config.CookiePartyTypes key)
	Cookie: Look.Cookie,
	Ground: Vector3, -- landing spot (from the server)
	Rest: Vector3, -- cookie center when landed
	From: Vector3?, -- throw start (Caleb's mouth); nil = from the sky
	Arc: number,
	StartAt: number,
	LandAt: number,
	ExpiresAt: number,
	Phase: number,
	Angle: number,
	Pos: Vector3, -- where it was drawn last frame
	Landed: boolean,
	Asked: boolean, -- collect fired (only ever once)
	AskedAt: number?, -- waiting for the server since
	Ending: string?, -- "Pop" (mine) or "Fade" (expired)
	EndAt: number,
}

local lastMouth: Vector3? = nil

-- Caleb's mouth (center of the Mouth* parts), else his head, else the last
-- known spot, else the statue's top (parts may be streamed out).
function Motion.MouthPosition(statue: Instance): Vector3
	local sum, count = Vector3.zero, 0
	for _, child in statue:GetChildren() do
		if child:IsA("BasePart") and child.Name:match("^Mouth%d") then
			sum += child.Position
			count += 1
		end
	end
	local head = statue:FindFirstChild("Head")
	if count > 0 then
		lastMouth = sum / count
	elseif head and head:IsA("BasePart") then
		lastMouth = head.Position - Vector3.new(0, head.Size.Y * 0.3, 0)
	end
	if lastMouth then
		return lastMouth
	end
	local frame, size = (statue :: any):GetBoundingBox()
	return frame.Position + Vector3.new(0, size.Y / 2, 0)
end

-- A new cookie from a server Spawn record (already checked), drawn with
-- cookie. from = Caleb's mouth for a throw, nil for the sky.
function Motion.New(s: any, cookie: Look.Cookie, from: Vector3?, now: number): Live
	local rest = s.Position + Vector3.new(0, cookie.Hover, 0)
	return {
		Id = s.Id,
		Type = if typeof(s.Type) == "string" then s.Type else "Normal",
		Cookie = cookie,
		Ground = s.Position,
		Rest = rest,
		From = from,
		Arc = if from then math.max(MIN_ARC, (rest - from).Magnitude * THROW_ARC) else 0,
		StartAt = s.LandAt - Config.CookiePartyFallSeconds,
		LandAt = s.LandAt,
		ExpiresAt = s.ExpiresAt,
		Phase = math.random() * 2 * math.pi,
		Angle = math.random() * 2 * math.pi,
		Pos = rest,
		Landed = now >= s.LandAt, -- joined late: already on the ground, no bounce
		Asked = false,
		EndAt = 0,
	}
end

-- Starts the pop (collected by the local player) or the fade (expired).
function Motion.End(c: Live, ending: string, now: number)
	c.Ending, c.EndAt = ending, now
end

-- Where the cookie is this frame: (cookie frame, beacon frame) or nil when
-- it is finished (then it goes back to the pool).
function Motion.Step(c: Live, now: number, dt: number, rootPos: Vector3?): (CFrame?, CFrame?)
	local cookie = c.Cookie
	local style = cookie.Style
	local ground = CFrame.new(c.Ground)
	if c.Ending == "Pop" then
		local since = now - c.EndAt
		if since >= POP_SECONDS then
			return nil, nil
		end
		local scale = if since < POP_GROW_SECONDS
			then 1 + 0.6 * since / POP_GROW_SECONDS
			else 1.6 - 1.45 * (since - POP_GROW_SECONDS) / (POP_SECONDS - POP_GROW_SECONDS)
		Look.SetScale(cookie, scale)
		Look.SetAlpha(cookie, 0, 1)
		local k = since / POP_SECONDS
		local pos = if rootPos then c.Pos:Lerp(rootPos, k * k) else c.Pos
		c.Angle += dt * style.Spin * 6
		return CFrame.new(pos) * CFrame.Angles(0, c.Angle, 0) * CFrame.Angles(TILT, 0, 0), nil
	elseif c.Ending == "Fade" then
		local k = (now - c.EndAt) / FADE_SECONDS
		if k >= 1 then
			return nil, nil
		end
		Look.SetAlpha(cookie, k, math.max(k, cookie.GroundAlpha))
		return CFrame.new(c.Pos - Vector3.new(0, k, 0)) * CFrame.Angles(0, c.Angle, 0) * CFrame.Angles(TILT, 0, 0), ground
	elseif now >= c.ExpiresAt then
		Motion.End(c, "Fade", now) -- the server's "expired" may come a moment later
		return CFrame.new(c.Pos) * CFrame.Angles(0, c.Angle, 0) * CFrame.Angles(TILT, 0, 0), ground
	end

	local pos, tilt
	if now < c.LandAt then
		local k = math.clamp((now - c.StartAt) / (c.LandAt - c.StartAt), 0, 1)
		if c.From then
			pos = (c.From :: Vector3):Lerp(c.Rest, k) + Vector3.new(0, c.Arc * 4 * k * (1 - k), 0)
		else
			local wobble = (1 - k) * FALL_WOBBLE
			local t = now + c.Phase
			pos = c.Rest + Vector3.new(math.sin(t * 2) * wobble, SKY_HEIGHT * (1 - k * k), math.cos(t * 1.7) * wobble)
		end
		tilt = TILT + math.sin(now * 7 + c.Phase) * FALL_TUMBLE * (1 - k)
		c.Angle += dt * style.Spin * AIR_SPIN
		Look.SetAlpha(cookie, 0, 0.6 + 0.4 * (1 - k)) -- the beacon fades in: "it lands here"
	else
		if not c.Landed then
			c.Landed = true
			Feedback.Land(cookie.Type, c.Ground)
		end
		local since = now - c.LandAt
		local y
		if since < BOUNCE_SECONDS then
			local u = since / BOUNCE_SECONDS
			y = math.sin(u * math.pi) * style.Bounce * (1 - u * 0.4)
		elseif style.Hop then
			y = math.abs(math.sin((since - BOUNCE_SECONDS) * 4)) * style.Bob
		else
			y = (0.5 - 0.5 * math.cos((since - BOUNCE_SECONDS) * 3)) * style.Bob
		end
		pos = c.Rest + Vector3.new(0, y, 0)
		tilt = TILT
		c.Angle += dt * style.Spin
		local left = c.ExpiresAt - now
		local blink = left < BLINK_SECONDS and math.floor(left * 8) % 2 == 0
		Look.SetAlpha(cookie, if blink then 0.7 else 0, if blink then 0.7 else 0)
	end

	if c.AskedAt then -- waiting for the server: lean toward the player
		local waited = now - c.AskedAt
		if waited > Config.CookiePartyClientCollectTimeout then
			c.AskedAt = nil -- not confirmed: back to normal (never asked again)
		elseif rootPos then
			pos = pos:Lerp(rootPos, 0.5 * math.min(1, waited / SUCK_SECONDS))
		end
	end
	c.Pos = pos
	return CFrame.new(pos) * CFrame.Angles(0, c.Angle, 0) * CFrame.Angles(tilt, 0, 0), ground
end

return Motion
