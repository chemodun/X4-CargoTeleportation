# Cargo Teleportation

Capital ships waste minutes queueing for a pier just to hand over cargo to a station you own, and some of your stations have no pier that fits them at all. This extension adds five research projects that extend the teleportation line to freight: your own ships and stations near each other exchange cargo where they are, without docking, and your ships restock from your own supply ships the same way.

## Features

- **Cargo Teleportation - Range I** research, available after **Teleportation - Range II**: a ware exchange between two of your ships happens without docking, parking or dropping containers once they are within 5 km of each other.
- **Cargo Teleportation - Range II** and **Range III**: the same up to 15 km and 30 km.
- **Cargo Teleportation - Stations** research, available after **Cargo Teleportation - Range II**: every trade between your own ship and your own station happens without docking as soon as the ship is near enough to the station. Your existing traders and miners use it on their own, with no new orders.
- **Cargo Teleportation - Restock** research, available after **Cargo Teleportation - Range II**: when one of your ships restocks missiles, drones or deployables from your own supply ship, it gets the **Restock by Cargo Teleportation** order instead of docking or parking: it moves within radar range of the supply ship, waits while the supply ship builds the items from its cargo, and receives them by teleportation. The wait is a few seconds plus a fifteenth of the normal build time, at most two minutes for an XL ship and one minute for any other.
- **No drones needed for the transfer**: the cargo arrives in a few seconds; between two large ships it takes about half a minute.
- **Extension Options**: switch ship-to-ship trades, ship-to-station trades and restocks on or off one by one. All three are on by default and each still needs its research; switched off, the feature behaves as if it were not researched. Another option lets a supply ship that lacks the resources for a restock get the **Get Supplies** order at once (this one works with or without the research).

## Limitations

- Only trades in which both sides are yours. Trades with other factions dock as usual.
- Both sides must be near enough to each other for the game to count them in one area, which it calls a zone. Ships fly close to the partner first; for a ware exchange they then close in to the researched range.
- When a large ship takes part, it or its partner still needs at least one cargo drone, as the game requires for any capital ship trade.
- A ware exchange between two ships that cannot complete this way fails with "Unable to trade with trade partner"; two large ships park as usual instead.
- The ship you are piloting yourself is left out.
- A restock by teleportation needs your own supply ship that already holds all the resources for the items; otherwise the game's usual restock runs. As in the base game, your ships restock only from supply ships in the same sector.

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

Research **Teleportation - Range II** at your headquarters, then **Cargo Teleportation - Range I**. From then on a ware exchange between two of your ships uses it on its own: one ship holds its position, the other comes into range and the cargo changes hands. After **Range II**, research **Cargo Teleportation - Stations**: every trade order between your own ship and your own station then uses it too: the ship flies near enough to the station and the cargo changes hands there. Research **Cargo Teleportation - Restock** after **Range II** as well, and your ships that restock from your own supply ship stay in open space: the supply ship builds the missiles, drones and deployables and teleports them over. When something prevents it, the ship docks or parks as usual.

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
