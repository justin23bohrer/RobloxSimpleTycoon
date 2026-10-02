# tools/audio — Caleb Full Event + Cookie Party audio

Original sound effects, **synthesized from scratch** by `generate_sfx.py`
(plain Python 3 standard library: `wave`, `math`, `struct`, `random`). No
samples, recordings, or third-party audio, so there are no copyright or
licensing questions. Not synced by Rojo. The Cookie Party music loop is
synthesized here too (simple chiptune).

| File | `Config.CalebSounds` key | When it plays (`CalebAudio.client`) |
| ---- | ------------------------ | ----------------------------------- |
| `out/caleb_full.wav` | `Full` | Caleb reaches the goal (state → `Full`) |
| `out/celebration_start.wav` | `CelebrationStart` | Celebration starts |
| `out/cookie_rain.wav` | `CookieRain` | loops quietly for the whole Celebration (3 s, seamless loop) |
| `out/caleb_grow.wav` | `Grow` | Caleb is fed (in `Normal`, rate-limited) |
| `out/trophy_claim.wav` | `TrophyClaim` | you claim your trophy |
| `out/event_end.wav` | `EventEnd` | Celebration ends (1.6 s after the finale boom if `FinaleBoom` is set) |

Cookie Party sounds go in `Config.CookiePartySounds` (volumes in
`Config.CookiePartySoundVolumes`):

| File | `Config.CookiePartySounds` key | When it plays (who plays it) |
| ---- | ------------------------------ | ---------------------------- |
| `out/party_music.wav` | `Music` | loops for the whole party; 120 BPM (`Config.CookiePartyMusicBPM`), 4 bars = 8 s, seamless loop; sped up per phase with `Config.CookiePartyMusicSpeed` (`CalebAudio.client` / `CookiePartyAudio`) |
| `out/countdown_tick.wav` | `CountdownTick` | each number of the 10…1 countdown, pitch rising (`CookiePartyAudio`) |
| `out/finale_boom.wav` | `FinaleBoom` | the finale explosion, Celebration → TrophyClaim (`CookiePartyAudio`) |
| `out/collect_pop.wav` | `Collect` | you collect a Normal / Chocolate party cookie (party cookies client) |
| `out/collect_golden.wav` | `CollectGolden` | you collect a Golden cookie (party cookies client) |
| `out/collect_giant.wav` | `CollectGiant` | you collect a Giant cookie (party cookies client) |
| `out/caleb_laugh.wav` | `CalebLaugh` | Caleb laughs during the party (Caleb party client) |
| `out/caleb_spit.wav` | `CalebSpit` | Caleb throws / spits a cookie (Caleb party client) |

All files: 16-bit WAV, 44.1 kHz, mono, normalized to about −1 dBFS (no
clipping); every effect is under 300 KB, the 8 s music loop is about 700 KB. They are committed, so you only need to
re-generate after changing the script.

## Generate

```bash
python3 tools/audio/generate_sfx.py
```

Writes the fourteen files to `tools/audio/out/`. The output is deterministic
(fixed random seeds), so re-running without changes gives identical files.

## Upload to Roblox and use them

1. Open the place in Roblox Studio (signed in as the account or group that
   owns the game).
2. **View → Asset Manager**, then the **Bulk Import** button (or
   **Creator Hub → Creations → Development Items → Audio → Upload Asset**
   in a browser). Pick the WAVs from `tools/audio/out/`. Give them clear
   names (e.g. `Caleb Full`, `Caleb Cookie Rain`).
3. Wait for moderation to approve them (usually a few minutes; they show as
   pending until then and play silently before approval).
4. Copy each asset id: in Asset Manager, right-click the audio →
   **Copy Asset ID** (on Creator Hub: the number in the asset's URL).
5. Paste each one into `src/ReplicatedStorage/Shared/Config.luau`, in
   `CalebSounds` or `CookiePartySounds` (tables above), as
   `"rbxassetid://<id>"` (a bare number also works):

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
   Volumes are in `Config.CalebSoundVolumes` / `Config.CookiePartySoundVolumes`.

If the audio is uploaded by a different account than the one that owns the
game, it may not play in the published game (Roblox audio permissions). Upload
from the game's owner (or its group), or grant the experience access in the
asset's permissions on Creator Hub.

An empty id means that sound is skipped (in Studio, Output prints one info
line listing the skipped sounds).
