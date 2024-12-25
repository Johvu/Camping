**Requirements**
* [Renewed-Lib](https://github.com/Renewed-Scripts/Renewed-Lib)
* [ox_lib](https://github.com/overextended/ox_lib)
* [ox_target](https://github.com/overextended/ox_target)
* [ox_inventory](https://github.com/overextended/ox_inventory)
* [weathersync](https://github.com/kibook/weathersync) (Optional)
* [esx_basicneed](https://github.com/esx-framework/esx_basicneeds) (Optional)

**INSTALL**

if you want to use heatzone
- you need to place this in esx_basicneed>client>main.lua at 'esx_status:loaded' event handle
```
TriggerEvent('esx_status:registerStatus', 'cold', 0, '#FFFFFF', function(status)
            return false
        end, function(status)
            status.add(100)
        end)
```


**Feature**

**TENT**
- Sleep in tent: it will set your animation to sleep inside the tent for 1 minute
- Open Tent Storage: will open Tent Stash with 10 slots and 10 kg. weight
- Pickup Tent: delete your tent and add item back to your inventory
**WARNING**
If your have item in tent and then you pickup tent all the item inside tent storage will be delete


**CAMPFIRE**

- Use Campfire: Open Context menu with 2 option
- Fual Level: cap at 300 sec (5 minute) use for cooking
- Add Fuel: will open submenu to select what you want to add
  - Paper = 15 sec
  - Wood = 30 sec
  - Coal = 60 sec
- Cooking: will open submenu to select what recipe you want to cook
  - Grill Meat = Cook time: 60 seconds. Recipe: Meat x1
  - Meat Soup = Cook time: 120 seconds. Recipe: Meat x1, Water x1, Bowl x1
  - Grill Potato = Cook time: 30 seconds. Recipe: Potato x1
