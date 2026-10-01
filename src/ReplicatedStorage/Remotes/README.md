# Remotes

This folder syncs into Studio as `ReplicatedStorage.Remotes`. (Rojo ignores this
README; it is documentation only.)

It is intentionally empty. The current MVP needs **no** remotes:

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
