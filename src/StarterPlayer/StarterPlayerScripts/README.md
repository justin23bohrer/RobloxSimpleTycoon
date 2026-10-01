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

Client code may handle input, visual effects, and presentation. It must never
be trusted for cash, ownership, purchases, drops, or collection.
