# Remotes

This folder syncs into Studio as `ReplicatedStorage.Remotes`. (Rojo ignores this
README; it is documentation only.)

Remotes here:

- `FeedStatue.model.json` (RemoteFunction): the feed pop-up asks the server
  to feed the statue an amount of cookies. Handled by `StatueService`.

- `CookiePartyCollect` (RemoteEvent, client → server), `CookiePartySpawn`,
  `CookiePartyCollected`, `CookiePartyFinale` (RemoteEvents, server →
  clients): the Cookie Party's collectable cookies. Handled by
  `CookiePartyService`; see ARCHITECTURE.md "Cookie Party (contract)".

- `CantAfford.model.json` (RemoteEvent, server → one client, no arguments):
  the player touched a buy button they can't afford; `CantAffordSound.client`
  plays `Config.TycoonSounds.CantAfford`. Fired (rate-limited) by the server
  helper `TycoonSounds`.

Everything else needs no remote:

- Buying and collecting happen when a character touches a part. The server
  receives `Touched` directly, so no client message is needed.
- Cookies (the currency) are shown with `leaderstats`, which Roblox replicates automatically.

Only add a remote when the client truly must tell the server something the
server cannot observe itself (for example, clicking a UI button). When you do:

1. Add it as a `RemoteEvent` model file here, e.g. `RequestSomething.model.json`:
   `{ "className": "RemoteEvent" }`
2. Handle it in the owning server service.
3. Treat every argument as untrusted: check types, check the player owns what
   they are acting on, and check prices/amounts using server values only.
4. Document it in `ARCHITECTURE.md` (Remotes section).

See `ARCHITECTURE.md` for when to use a remote vs. a server-side function call.
