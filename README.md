Archive submission from Curseforge

# Boss Health Bars *(WotLK Classic 3.4.3)*

<img width="435" height="210" alt="image" src="https://github.com/user-attachments/assets/35a5e548-7f9f-4074-8972-d6d351bc623b" />
<img width="430" height="120" alt="image" src="https://github.com/user-attachments/assets/bd8a7371-1c86-4ddf-9567-153d90269752" />

Provides health bars for bosses and additional enemies during WotLK Classic raids, inspired by the old [Deus Vox Encounters](https://www.curseforge.com/wow/addons/deus-vox-encounters) health display.

This is helpful for coordinating the kill of multiple enemies (such as Mimiron Phase 3), to see the health of enemies other groups of players are fighting (such as the Blood Beasts, Bone Spikes, or Empowered Adherents), or to simply have a single place to view the last known health of any relevant units.

Units are tracked via any available data source that the Lua API provides, such as your current target, your focus target, any raid member's current target, nameplates etc. Any units that lose tracking will show their last known health value.

The bars are visual and not interactive, dynamically populating and updating clickable bars in combat is not possible due to Blizzard's API protections.

Includes support for:

* Icecrown Citadel
* Trial of the Crusader (excluding Faction Champions)
* Ulduar
* Naxxramas
* The Obsidian Sanctum
* Eye of Eternity
