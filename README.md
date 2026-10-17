# Cargo Teleportation

Capital ships waste minutes queueing for a pier just to hand over cargo to a station you own, and some of your stations have no pier that fits them at all. This extension adds four research projects that extend the teleportation line to freight: your own ships and stations in the same zone exchange cargo where they are, without docking.

## Features

- **Cargo Teleportation - Range I** research, available after **Teleportation - Range II**: a ware exchange between two of your ships happens without docking, parking or dropping containers once they are in the same zone and within 5 km of each other.
- **Cargo Teleportation - Range II** and **Range III**: the same up to 15 km and 30 km.
- **Cargo Teleportation - Stations** research, available after **Cargo Teleportation - Range II**: every trade between your own ship and your own station happens without docking as soon as the ship is in the station's zone, at any distance. Your existing traders and miners use it on their own, with no new orders.
- **No drones needed for the transfer**: the cargo arrives in a few seconds; between two large ships it takes about half a minute.
- **Extension Options**: switch it off, or change the ship-to-ship range of each step from 1 to 50 km.

## Limitations

- Only trades in which both sides are yours. Trades with other factions dock as usual.
- Both sides must be in the same zone: a cube 100 km wide in which the game places stations and ships. Ships fly into the partner's zone first; for a ware exchange they then close in to the researched range.
- When a large ship takes part, it or its partner still needs at least one cargo drone, as the game requires for any capital ship trade.
- A ware exchange between two ships that cannot complete this way fails with "Unable to trade with trade partner"; two large ships park as usual instead.
- The ship you are piloting yourself is left out.

## Requirements

- **X4: Foundations**: Version **8.00** or higher, Windows version.
- **Mod Support APIs**: Version **1.95** or higher by [SirNukes](https://next.nexusmods.com/profile/sirnukes?gameId=2659).
  - Available on Steam: [SirNukes Mod Support APIs](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274)
  - Available on Nexus Mods: [Mod Support APIs](https://www.nexusmods.com/x4foundations/mods/503)
- **Options Helper**: Version **1.10** or higher by [Chem O`Dun](https://next.nexusmods.com/profile/ChemODun/mods?gameId=2659).
  - Available on Steam: [Options Helper](https://steamcommunity.com/sharedfiles/filedetails/?id=3715253556)
  - Available on Nexus Mods: [Options Helper](https://www.nexusmods.com/x4foundations/mods/2155)
- **Print Extension List**: Version **1.00** or higher by [Chem O`Dun](https://next.nexusmods.com/profile/ChemODun/mods?gameId=2659).
  - Available on Steam: [Print Extension List](https://steamcommunity.com/sharedfiles/filedetails/?id=3770927339)
  - Available on Nexus Mods: [Print Extension List](https://www.nexusmods.com/x4foundations/mods/2191)

## Installation

You can download the latest version via Steam client - [Cargo Teleportation](https://steamcommunity.com/sharedfiles/filedetails/?id=)
Or you can do it via the Nexus Mods - [Cargo Teleportation](https://www.nexusmods.com/x4foundations/mods/)

## Save state

**No** (removing the extension does not break saves).

## Usage

Research **Teleportation - Range II** at your headquarters, then **Cargo Teleportation - Range I**. From then on a ware exchange between two of your ships uses it on its own: one ship holds its position, the other comes into range and the cargo changes hands. After **Range II**, research **Cargo Teleportation - Stations**: every trade order between your own ship and your own station then uses it too: the ship flies into the station's zone and the cargo changes hands there. When something prevents it, the ship docks or parks as usual.

## Credits

- Author: Chem O`Dun, on [Nexus Mods](https://next.nexusmods.com/profile/ChemODun/mods?gameId=2659) and [Steam Workshop](https://steamcommunity.com/id/chemodun/myworkshopfiles/?appid=392160)
- *"X4: Foundations"* is a trademark of [Egosoft](https://www.egosoft.com).

## Acknowledgements

- [EGOSOFT](https://www.egosoft.com) - for the X series.
- [SirNukes](https://next.nexusmods.com/profile/sirnukes?gameId=2659) - for the Mod Support APIs that power the UI hooks.

## Changelog

### [1.00] - 2026-??-??

- **Added**
  - Initial public version
