# StarterGui

Syncs into Studio as `StarterGui`. (Rojo ignores this README.)

Empty for now. Cookies (the currency; "cash" in code) are shown by the built-in player list (`leaderstats`) and
by the cookie panel, which is built by
`StarterPlayerScripts/CashDisplay.client.luau`.

UI here is presentation only. It may read replicated values (like
`leaderstats.Cookies`) but must never decide cash, ownership, or purchases.
