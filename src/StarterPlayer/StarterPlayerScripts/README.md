# StarterPlayerScripts

Syncs into Studio as `StarterPlayer.StarterPlayerScripts`. (Rojo ignores this README.)

Client code goes here as `Name.client.luau` (a LocalScript).

- `CashDisplay.client.luau` — bottom-center cookie counter (display only).
- `FeedPrompt.client.luau` + `FeedPromptUI.luau` (ModuleScript) — the
  "feed Caleb" pop-up on the statue's feed pads. Sends the amount to the
  server; the server decides and spends.

Client code may handle input, visual effects, and presentation. It must never
be trusted for cash, ownership, purchases, drops, or collection.
