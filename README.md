# Campfire Cooking Script

A versatile camping and campfire cooking script for FiveM that allows players to set up tents, spawn campfires, and engage in a cooking mini-game with an evolving skill system and recipe discovery mechanics. This script integrates with multiple frameworks and resources to provide a rich roleplaying experience.

## Preview

[details="Cooking Menu"]
![image|690x388](upload://xGu083RgOGBfq15r4HIkOlGqz3n.jpeg)
[/details]


## Features

- **Tent and Campfire Placement:**  
  Players can place tents (which double as storage) and campfires in the game world.
  
- **Fuel Management System:**  
  The campfire fuel system uses various fuel types (e.g., garbage, firewood, coal) with dynamic fuel consumption affected by weather conditions.
  
- **Cooking Mini-Game:**  
  Engage in cooking using a UI that shows recipes, progress bars, and ingredient validations. Cooking skill progression can lead to benefits like faster cook times and ingredient reductions.
  
- **Recipe Discovery:**  
  Hidden recipes can be discovered based on ingredient matching and player cooking skills.
  
- **Framework Compatibility:**  
  Supports ESX, QBCore, and standalone mode, enabling flexible integration.
  
- **Inventory Integration:**  
  Leverages [ox_inventory](https://github.com/overextended/ox_inventory) for seamless item management.
  
- **Contextual Interactions:**  
  Uses [ox_target](https://github.com/overextended/ox_target) and [Renewed-Lib](https://github.com/Renewed-Scripts/Renewed-Lib) for intuitive in-game object interactions.
  
- **Optional Weather Integration:**  
  If enabled, integrates with [GES-Temperature](https://github.com) (optional) to create dynamic heat zones around campfires.

## Requirements

- [Renewed-Lib](https://github.com/Renewed-Scripts/Renewed-Lib)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [GES-Temperature](https://github.com/DevAlexandre0/GES-Temperature) (Optional)

## Installation

1. **Download the Resource:**  
   Place the resource folder (containing the server.lua, client.lua, script.js, index.html, and styles.css files) in your FiveM resources directory.

2. **Configure Your Server:**  
   Ensure that the required dependencies ([Renewed-Lib](https://github.com/Renewed-Scripts/Renewed-Lib), [ox_lib](https://github.com/overextended/ox_lib), [ox_target](https://github.com/overextended/ox_target), [ox_inventory](https://github.com/overextended/ox_inventory), and optionally [GES-Temperature](https://github.com)) are installed and running.

3. **Add to Server Configuration:**  
   Add the resource to your `server.cfg` file:
   ```
   ensure camping
   ```

## Configuration

Customize the script by editing the configuration file (usually `config.lua`). Settings include:
- **Framework Mode:**  
  Set the mode to `esx`, `qb-core`, or `standalone`.
- **Fuel Settings:**  
  Define default fuel levels, maximum fuel, and fuel consumption rates.
- **Cooking and Recipe Settings:**  
  Adjust cooking times, XP gains, and recipe discovery chances.
- **Item and Model Settings:**  
  Specify the item names and models for tents, campfires, and fuel types.
- **Cooldowns and Interactions:**  
  Configure cooldown timers and interaction settings for tent and campfire actions.

## Usage

- **Placing Tents and Campfires:**  
  Use the designated items (e.g., a tent or campfire item) from your inventory to place these objects in the world. Tents provide storage access and shelter, while campfires serve as the hub for the cooking mini-game.

- **Fueling the Campfire:**  
  Approach a campfire and use the fuel UI to add fuel. The script checks your inventory for the correct fuel type and quantity before updating the fuel level.

- **Cooking:**  
  Once a campfire is fueled, interact with it to open the cooking menu. Select a recipe, and if you have the necessary ingredients, initiate the cooking process. Progress is tracked via an in-game progress bar, and successful cooking may increase your cooking skill and discover new recipes.

- **Interactions:**  
  In-game notifications, animations, and contextual menus (via [ox_target](https://github.com/overextended/ox_target) and [Renewed-Lib](https://github.com/Renewed-Scripts/Renewed-Lib)) provide a smooth and engaging user experience.

## Troubleshooting

- **UI Not Reopening:**  
  If you receive a message like "UI is already open, not opening again" when trying to reopen the cooking menu, ensure that the close events are firing correctly and that any state flags (e.g., `FuelSystem.isUIOpen`) are reset properly when exiting the menu.

- **Fuel Amount Issues:**  
  Verify that the correct fuel type and quantity are available in your inventory. Check the configuration for fuel type limits and ensure that `availableAmount` (from the inventory) is correctly populated.

## Credits

- **Developers:**  
  Developed by [DevAlexandre&GESUS].
  
- **Special Thanks:**  
  - [Renewed-Lib](https://github.com/Renewed-Scripts/Renewed-Lib)
  - [ox_lib](https://github.com/overextended/ox_lib)
  - [ox_target](https://github.com/overextended/ox_target)
  - [ox_inventory](https://github.com/overextended/ox_inventory)
  - [GES-Temperature](https://github.com) (Optional)
---
