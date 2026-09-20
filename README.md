# rsg-samples

Animal sample collector for RedM (best version) with leaderboard, certificate, and milestone rewards.

## Features

- Sedate wild animals and hold a prompt to collect their sample
- 60+ animal species across 6 categories (Predator, Bird, Reptile, Ungulate, Small Game, Exotic)
- Legendary animal variants with a gold ★ badge and boosted rewards
- Featured Animal of the day with a cash multiplier (changeable live)
- First Discovery bonus for the first player to sample an animal server-wide
- Milestone rewards at 5 / 10 / 25 / 50 samples
- NUI collector menu (My Samples, Leaderboard, Global Stats tabs)
- Field Research Certificate overlay with completion stats
- ox_target leaderboard zone + optional map blip
- ox_lib notify integration

## Requirements

- RSG Core (`rsg-core`)
- ox_lib
- ox_target
- oxmysql
- onesync

## Installation

1. Place `rsg-samples` in your `resources/[standalone]` folder
2. Add `ensure rsg-samples` to your `server.cfg`
3. Import `install/rsg-samples.sql` into your database (creates the `player_samples` table):
   - via HeidiSQL / phpMyAdmin, or
   - run: `mysql -u root -p < install/rsg-samples.sql`
4. Do not start the resource until the SQL has been imported — it will error on its first DB query otherwise
5. Restart the server or `ensure rsg-samples`

### Where to place the leaderboard

Edit `Config.LeaderboardLocation` in `config.lua` to set the ox_target interaction point (default: Valentine). Note: the SQL ships with an auto-increment seed of `47` — this is harmless and simply continues numbering from that point.

## Setup SQL

```sql
CREATE TABLE IF NOT EXISTS `player_samples` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `sample_id` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_citizenid_sampleid` (`citizenid`,`sample_id`),
  KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
```

## Commands

| Command | Description |
|---------|-------------|
| `/samplesmenu` | Open the full collector menu |
| `/samplecert` | Open just the certificate overlay |
| `/setfeatured bear` | Set the featured animal (admin) |
| `/setfeatured` | Clear the featured animal (admin) |

The `/setfeatured` command is gated by ace. Add to your `server.cfg`:

```
add_ace group.admin rsg-samples.admin allow
```

## File Structure

```
rsg-samples/
├── config.lua                  # All configuration
├── client/
│   ├── main.lua                # NUI handlers, notify, inventory bridge
│   ├── tagging.lua             # Sedation detection, prompts, sampling threads
│   ├── target.lua              # ox_target leaderboard zone + map blip
│   └── taglistener.js          # AI tag event listener (revive data feed)
├── server/
│   ├── main.lua                # Animal map, rewards, leaderboard, commands
│   └── tagging.lua             # Sample event handler
├── locales/
│   ├── en.json                 # All translatable strings (ox_lib locale)
│   ├── de.json, el.json, es.json, fr.json, ja.json,
│   └── nl.json, pl.json, pt-br.json, ro.json
├── html/
│   ├── samples.html            # NUI collector menu + certificate
│   ├── samples.js              # NUI JavaScript
│   └── samples.css             # NUI styles
├── install/
│   └── rsg-samples.sql         # Database schema
└── fxmanifest.lua
```

## Configuration Summary

| Setting | Default | Description |
|---------|---------|-------------|
| `Config.DebugClient` | `false` | Print client-side debug logs to F8 |
| `Config.DebugServer` | `false` | Print server-side debug logs |
| `Config.StoreSampleData` | `true` | Set `false` to disable all DB writes (testing) |
| `Config.SampleHoldTime` | `4000` | Hold time (ms) for the sampling prompt |
| `Config.AnimalCleanupTime` | `90000` | ms before a sedated animal recovers |
| `Config.LeaderboardLocation` | Valentine | ox_target sphere coords / radius |
| `Config.ShowBlip` | `true` | Show map blip at the leaderboard location |
| `Config.BlipSprite` | `0` | RDR3 blip sprite hash (0 = default) |
| `Config.BlipColor` | `2` | Blip color |
| `Config.BlipScale` | `0.8` | Blip scale |
| `Config.BlipLabel` | `'Samples Leaderboard'` | Blip label |
| `Config.MilestoneRewards` | 4 tiers | Bonus cash at 5/10/25/50 samples |
| `Config.FirstDiscoveryBonus` | `500` | Bonus for first-ever sample of an animal |
| `Config.LegendaryAnimals` | 5 hashes | Gold ★ legendary badge mapping |
| `Config.FeaturedAnimal` | `''` | Featured animal name (empty = none) |
| `Config.FeaturedMultiplier` | `2` | Reward multiplier for the featured animal |

## How It Works

### Required Equipment

You need a **.22 Rifle** loaded with **Tranquilizer Bullets** to sedate animals. The tranquilizer bullet sets the game's sedation flag (ped flag 580), which is what the script detects — without them the sampling prompt will never appear.

1. Equip the .22 Rifle with Tranquilizer Bullets and shoot any wild (non-player) animal — the script detects it via the 580 ped flag and network-registers it
2. A **Take Sample** hold prompt appears on the animal (hold for `Config.SampleHoldTime` ms)
3. On completion the sample is sent to the server, which:
   - checks the `player_samples` table for duplicates,
   - awards first discovery + milestone bonuses,
   - grants the cash reward (multiplied if the animal is featured)
4. Open `/samplesmenu` to view your collection, the server-wide leaderboard, and global stats
5. View `/samplecert` to claim a printable Field Research Certificate

## Locales

All strings live in `locales/*.json` and are loaded through ox_lib's locale module. Out of the box this resource ships with:

| Code    | Language              |
|---------|------------------------|
| `en`    | English (default/fallback) |
| `de`    | German |
| `el`    | Greek |
| `es`    | Spanish |
| `fr`    | French |
| `ja`    | Japanese |
| `nl`    | Dutch |
| `pl`    | Polish |
| `pt-br` | Portuguese (Brazil) |
| `ro`    | Romanian |

**Switching language:** add this to your `server.cfg` (English is used if unset or if the file for that code is missing):

```
setr ox:locale "de"
```

**Adding another language:** copy `locales/en.json` to `locales/<code>.json` (e.g. `locales/it.json`) and translate the values — keep every `%s` placeholder in the same order, since those get filled in with things like animal names and dollar amounts at runtime. No code changes required; ox_lib picks the file up automatically once `ox:locale` is set to match.

**Editing existing text:** just edit the value for a key in the matching `locales/<code>.json` file — the key names (left side) must stay the same since the code looks strings up by key.