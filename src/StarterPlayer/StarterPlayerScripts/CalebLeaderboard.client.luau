-- CalebLeaderboard (client only)
-- "CALEB'S TOP FEEDERS" boards on Caleb's podium: one SurfaceGui per board
-- (the "Board" part in each Podium/Leaderboard<corner> model), same cartoony
-- look as the rest of the game. Rows "1  Justin   248,321 🍪", gold / silver
-- / bronze badges for the top 3, the local player's row highlighted, and the
-- shared total "12,345 / 1,000,000" at the bottom. "FINAL RESULTS" during
-- TrophyClaim (the server keeps the list until the reset).
--
-- Display only: reads the statue's replicated attributes (CalebTopFeeders,
-- CookiesEaten, CalebMaxCookies, CalebState). It never talks to the server.
-- These are cookies FED to Caleb (tracked by the server), not cookies made.
--
-- Each SurfaceGui is built once, lives in PlayerGui, and is adorned to its
-- Board part; when content streaming unloads and reloads a board, the same
-- gui is re-adorned to the new part.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CalebEvent = require(ReplicatedStorage.Shared.CalebEvent)
local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local statue = Workspace:WaitForChild("Map"):WaitForChild("Statue")

local ROWS = Config.CalebLeaderboardSize

-- Look (presentation only, same as StatueBar / FeedPromptUI)
local PANEL_COLOR = Color3.fromRGB(255, 214, 64)
local OUTLINE_COLOR = Color3.fromRGB(40, 28, 20)
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local ROW_COLOR = Color3.fromRGB(255, 244, 205)
local MY_ROW_COLOR = Color3.fromRGB(150, 230, 120)
local MY_ROW_STROKE = Color3.fromRGB(40, 150, 50)
local BADGE_COLOR = Color3.fromRGB(150, 96, 52)
local MEDAL_COLORS = { Color3.fromRGB(255, 190, 30), Color3.fromRGB(200, 208, 220), Color3.fromRGB(215, 135, 70) }
local FINAL_COLOR = Color3.fromRGB(235, 70, 70)
local FONT = Enum.Font.FredokaOne
local PIXELS_PER_STUD = 40
local MAX_DISTANCE = 250
local NAME_TEXT_SIZE = 22

type Feeder = { UserId: number?, Name: string, Cookies: number }
type BoardUI = { Gui: SurfaceGui, Subtitle: TextLabel, Empty: TextLabel, Total: TextLabel, Rows: { any } }

local boards: { [string]: BoardUI } = {}

-- "1250" -> "1,250"
local function formatNumber(amount: number): string
	local digits = tostring(math.floor(math.abs(amount)))
	local withCommas = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if withCommas:sub(1, 1) == "," then
		withCommas = withCommas:sub(2)
	end
	return withCommas
end

-- The server's list. Anything malformed counts as empty / is skipped.
local function readFeeders(): { Feeder }
	local raw = statue:GetAttribute(CalebEvent.Attr.TopFeeders)
	if typeof(raw) ~= "string" or raw == "" then
		return {}
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or typeof(data) ~= "table" then
		return {}
	end
	local list = {}
	for _, entry in ipairs(data) do
		if #list >= ROWS then
			break
		end
		local cookies = if typeof(entry) == "table" then entry.Cookies else nil
		if typeof(cookies) == "number" and cookies == cookies and cookies >= 0 and cookies < math.huge then
			local name = if typeof(entry.Name) == "string" then entry.Name:gsub("%c", " ") else "?"
			table.insert(list, { UserId = tonumber(entry.UserId), Name = name, Cookies = cookies })
		end
	end
	return list
end

local function stroke(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode, color: Color3?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or OUTLINE_COLOR
	s.Thickness = thickness
	s.ApplyStrokeMode = mode
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
	return s
end

local function corner(parent: GuiObject, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

-- Plain text only (RichText off) so player names can't inject markup.
local function label(parent: GuiObject, name: string, position: UDim2, size: UDim2, outlined: boolean): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = position
	l.Size = size
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.RichText = false
	l.Text = ""
	l.TextColor3 = if outlined then TEXT_COLOR else OUTLINE_COLOR
	l.TextScaled = true
	l.Parent = parent
	if outlined then
		stroke(l, 2.5, Enum.ApplyStrokeMode.Contextual)
	end
	return l
end

local function buildRow(list: Frame, index: number)
	local step = 1 / ROWS
	local row = Instance.new("Frame")
	row.Name = `Row{index}`
	row.Position = UDim2.fromScale(0, (index - 1) * step)
	row.Size = UDim2.fromScale(1, step * 0.86)
	row.BackgroundColor3 = ROW_COLOR
	row.Visible = false
	row.Parent = list
	corner(row, UDim.new(0.3, 0))
	local rowStroke = stroke(row, 2, Enum.ApplyStrokeMode.Border)

	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.Position = UDim2.fromScale(0.01, 0.08)
	badge.Size = UDim2.fromScale(0.07, 0.84)
	badge.BackgroundColor3 = BADGE_COLOR
	badge.Parent = row
	corner(badge, UDim.new(0.5, 0))
	stroke(badge, 2, Enum.ApplyStrokeMode.Border)
	local rank = label(badge, "Rank", UDim2.fromScale(0.1, 0.1), UDim2.fromScale(0.8, 0.8), true)
	rank.Text = tostring(index)

	-- Fixed text size + truncation: a long name gets "..." instead of
	-- overflowing or shrinking to nothing.
	local name = label(row, "PlayerName", UDim2.fromScale(0.11, 0.1), UDim2.fromScale(0.55, 0.8), false)
	name.TextScaled = false
	name.TextSize = NAME_TEXT_SIZE
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.ClipsDescendants = true

	local cookies = label(row, "Cookies", UDim2.fromScale(0.67, 0.12), UDim2.fromScale(0.31, 0.76), false)
	cookies.TextXAlignment = Enum.TextXAlignment.Right

	return { Frame = row, Stroke = rowStroke, Badge = badge, Name = name, Cookies = cookies }
end

local function buildBoard(boardName: string): BoardUI
	local gui = Instance.new("SurfaceGui")
	gui.Name = `CalebLeaderboard_{boardName}`
	gui.ResetOnSpawn = false
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.MaxDistance = MAX_DISTANCE
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -16, 1, -16)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.Parent = gui
	corner(panel, UDim.new(0.06, 0))
	stroke(panel, 5, Enum.ApplyStrokeMode.Border)

	label(panel, "Title", UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.92, 0.12), true).Text = "CALEB'S TOP FEEDERS"
	local subtitle = label(panel, "Subtitle", UDim2.fromScale(0.1, 0.145), UDim2.fromScale(0.8, 0.06), true)

	local list = Instance.new("Frame")
	list.Name = "List"
	list.Position = UDim2.fromScale(0.04, 0.22)
	list.Size = UDim2.fromScale(0.92, 0.65)
	list.BackgroundTransparency = 1
	list.Parent = panel

	local rows = {}
	for i = 1, ROWS do
		rows[i] = buildRow(list, i)
	end

	local empty = label(list, "Empty", UDim2.fromScale(0.05, 0.35), UDim2.fromScale(0.9, 0.15), true)
	empty.Text = "Be the first to feed Caleb!"

	local total = label(panel, "Total", UDim2.fromScale(0.08, 0.885), UDim2.fromScale(0.84, 0.08), true)

	gui.Parent = playerGui
	return { Gui = gui, Subtitle = subtitle, Empty = empty, Total = total, Rows = rows }
end

-- Refresh ---------------------------------------------------------------------

local function renderBoard(board: BoardUI, feeders: { Feeder }, totalText: string, final: boolean)
	board.Subtitle.Text = if final then "FINAL RESULTS" else "Cookies fed this round"
	board.Subtitle.TextColor3 = if final then FINAL_COLOR else TEXT_COLOR
	board.Empty.Visible = #feeders == 0
	board.Total.Text = totalText

	for i, row in board.Rows do
		local feeder = feeders[i]
		row.Frame.Visible = feeder ~= nil
		if feeder then
			local mine = feeder.UserId == player.UserId
			row.Frame.BackgroundColor3 = if mine then MY_ROW_COLOR else ROW_COLOR
			row.Stroke.Color = if mine then MY_ROW_STROKE else OUTLINE_COLOR
			row.Stroke.Thickness = if mine then 4 else 2
			row.Badge.BackgroundColor3 = MEDAL_COLORS[i] or BADGE_COLOR
			row.Name.Text = feeder.Name
			row.Cookies.Text = `{formatNumber(feeder.Cookies)} 🍪`
		end
	end
end

local function refresh()
	local feeders = readFeeders()
	local eaten = statue:GetAttribute(CalebEvent.Attr.CookiesEaten)
	local max = statue:GetAttribute(CalebEvent.Attr.MaxCookies)
	if typeof(eaten) ~= "number" then
		eaten = 0
	end
	if typeof(max) ~= "number" or max <= 0 then
		max = CalebEvent.MaxCookies()
	end
	local totalText = `🍪 {formatNumber(eaten)} / {formatNumber(max)}`
	local final = CalebEvent.GetState(statue) == CalebEvent.State.TrophyClaim
	for _, board in boards do
		renderBoard(board, feeders, totalText, final)
	end
end

-- Boards (and streaming) --------------------------------------------------------

local function watchBoard(item: Instance)
	local model = item.Parent
	if item.Name ~= "Board" or not item:IsA("BasePart") or not model or not model.Name:match("^Leaderboard") then
		return
	end
	local board = boards[model.Name]
	if not board then
		board = buildBoard(model.Name)
		boards[model.Name] = board
		refresh()
	end
	board.Gui.Adornee = item
end

statue.DescendantAdded:Connect(watchBoard)
for _, item in statue:GetDescendants() do
	watchBoard(item)
end

for _, attr in { CalebEvent.Attr.TopFeeders, CalebEvent.Attr.CookiesEaten, CalebEvent.Attr.MaxCookies, CalebEvent.Attr.State } do
	statue:GetAttributeChangedSignal(attr):Connect(refresh)
end
refresh()
