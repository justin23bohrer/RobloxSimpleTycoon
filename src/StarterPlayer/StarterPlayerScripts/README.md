# StarterPlayerScripts

Syncs into Studio as `StarterPlayer.StarterPlayerScripts`. (Rojo ignores this README.)

Client code goes here as `Name.client.luau` (a LocalScript).

- `CashDisplay.client.luau` — bottom-center cookie counter (display only).
- `FeedPrompt.client.luau` + `FeedPromptUI.luau` (ModuleScript) — the
  "feed Caleb" pop-up on the statue's feed pads. Sends the amount to the
  server; the server decides and spends.
- `StatueBar.client.luau` — progress bar above Caleb's head ("Caleb: N /
  1,000,000 🍪"), reusing `FeedPromptUI.ProgressBar`. Display only.
- `CookieRain.client.luau` + `CookieRainLook.luau` (ModuleScript) — cookie
  rain during Caleb's Celebration. Client-only visuals, pooled; no rewards.
  Ramps up with the Cookie Party phases.
- `CookiePartyCookies.client.luau` + `CookiePartyLook` / `CookiePartyMotion` /
  `CookiePartyFeedback` / `CookiePartyNumbers` / `CookiePartyHUD`
  (ModuleScripts) — the Cookie Party's collectable cookies: draws what the
  server spawns, asks the server to collect (it decides), and plays the
  collect feedback + party earnings counter.
- `CalebEventUI.client.luau` + `CalebEventUIBuild.luau` / `CalebEventFX.luau`
  and the Cookie Party's `CookiePartyUIBuild.luau` / `CookiePartyFX.luau` /
  `CookiePartyCountdown.luau` / `CookiePartyFinale.luau` (ModuleScripts) —
  event messages, party countdown, callouts, lighting, finale explosion.
  Display only.
- `CalebAudio.client.luau` + `CookiePartyAudio.luau` (ModuleScript) — Caleb
  Full Event sound effects and the party music / countdown ticks / finale
  boom, driven only by the statue's / player's attributes
  (`Config.CalebSounds`, `Config.CookiePartySounds`).
- `TrophyPrompt.client.luau` — hides the podium "Claim Caleb Trophy" prompt
  for players who can't claim, and shows the claim result message. The
  server decides every claim.

Client code may handle input, visual effects, and presentation. It must never
be trusted for cash, ownership, purchases, drops, or collection.
