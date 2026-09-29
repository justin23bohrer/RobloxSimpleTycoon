# SimpleTycoon Agent Instructions

## Scope

This repository is a Roblox game managed with Rojo. The source of truth is the Lua and project configuration in this repository, not the binary place file.

## Rules

- Keep important gameplay server-authoritative.
- Treat all client input and remote requests as untrusted.
- Validate ownership, currency, purchases, and collection on the server.
- Do not add monetization, pets, rebirths, or unrelated features until the MVP is playable and tested.
- Do not edit `*.rbxl` directly unless explicitly requested.
- Keep changes small and testable.

## Project Commands

```bash
rojo serve
rojo build default.project.json --output /tmp/simple-tycoon.rbxlx
```

Use Roblox Studio Play mode to test behavior after syncing with Rojo.
