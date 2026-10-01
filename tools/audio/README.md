# tools/audio — Caleb Full Event sound effects

Original sound effects, **synthesized from scratch** by `generate_sfx.py`
(plain Python 3 standard library: `wave`, `math`, `struct`, `random`). No
samples, recordings, or third-party audio, so there are no copyright or
licensing questions. Not synced by Rojo. Music is not here: the user picks a
track later.

| File | `Config.CalebSounds` key | When it plays (`CalebAudio.client`) |
| ---- | ------------------------ | ----------------------------------- |
| `out/caleb_full.wav` | `Full` | Caleb reaches the goal (state → `Full`) |
| `out/celebration_start.wav` | `CelebrationStart` | Celebration starts |
| `out/cookie_rain.wav` | `CookieRain` | loops quietly for the whole Celebration (3 s, seamless loop) |
| `out/caleb_grow.wav` | `Grow` | Caleb is fed (in `Normal`, rate-limited) |
| `out/trophy_claim.wav` | `TrophyClaim` | you claim your trophy |
| `out/event_end.wav` | `EventEnd` | Celebration ends |

All files: 16-bit WAV, 44.1 kHz, mono, normalized to about −1 dBFS (no
clipping), each under 300 KB. They are committed, so you only need to
re-generate after changing the script.

## Generate

```bash
python3 tools/audio/generate_sfx.py
```

Writes the six files to `tools/audio/out/`. The output is deterministic
(fixed random seeds), so re-running without changes gives identical files.

## Upload to Roblox and use them

1. Open the place in Roblox Studio (signed in as the account or group that
   owns the game).
2. **View → Asset Manager**, then the **Bulk Import** button (or
   **Creator Hub → Creations → Development Items → Audio → Upload Asset**
   in a browser). Pick the six WAVs from `tools/audio/out/`. Give them clear
   names (e.g. `Caleb Full`, `Caleb Cookie Rain`).
3. Wait for moderation to approve them (usually a few minutes; they show as
   pending until then and play silently before approval).
4. Copy each asset id: in Asset Manager, right-click the audio →
   **Copy Asset ID** (on Creator Hub: the number in the asset's URL).
5. Paste each one into `src/ReplicatedStorage/Shared/Config.luau`, in
   `CalebSounds`, as `"rbxassetid://<id>"` (a bare number also works):

   ```lua
   CalebSounds = table.freeze({
   	Full = "rbxassetid://1111111111",
   	CelebrationStart = "rbxassetid://2222222222",
   	Grow = "rbxassetid://3333333333",
   	CookieRain = "rbxassetid://4444444444",
   	TrophyClaim = "rbxassetid://5555555555",
   	EventEnd = "rbxassetid://6666666666",
   }),
   ```

6. Edit the file in the repo (not only in Studio), commit, and let Rojo sync.
   Volumes are in `Config.CalebSoundVolumes`.

If the audio is uploaded by a different account than the one that owns the
game, it may not play in the published game (Roblox audio permissions). Upload
from the game's owner (or its group), or grant the experience access in the
asset's permissions on Creator Hub.

An empty id means that sound is skipped (in Studio, Output prints one info
line listing the skipped sounds).
