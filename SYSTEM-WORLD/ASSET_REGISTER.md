# SYSTEM WORLD — 3D Asset Register

## Purpose
Central inventory of existing 3D systems, scenes,
maps, NPC systems and procedural environments.
Do not recreate existing work without checking this file.

## Official Runtime Project
SYSTEM-WORLD/

Main scene:
- MainScene.tscn

Core integration:
- scripts/main.gd
- scripts/world_manager.gd
- scripts/world_map_manager.gd
- scripts/world_map_ui.gd
- scripts/world_map_ui_bootstrap.gd

## Maps
- world_map_manager.gd
- world_map_ui.gd
- world_map_ui_bootstrap.gd
- modern_world_discovery_manager.gd
- world_interaction_manager.gd

Map UI bootstrap is registered in project.godot.
Map manager and discovery systems are created by main.gd.

## NPC and Society
- ai_npc_society_manager.gd
- npc_player_interaction_manager.gd
- fantasy_settlement_manager.gd
- NPC life, work, travel, relationships and family data
- Resident and settlement registration

NPC visual models must be checked separately
from NPC simulation and interaction logic.

## Procedural Environments
- forest_manager.gd
- mountain_manager.gd
- waterways_manager.gd
- marine_environment_manager.gd
- marine_life_manager.gd
- wildlife_manager.gd
- fantasy_world_manager.gd
- historical_world_manager.gd
- greed_island_manager.gd

## Separate 3D Preview Project
SYSTEM-WORLD-3D/

Scenes:
- main.tscn
- command_center.tscn
- premium_command_center.tscn
- miyar_character.tscn
- adam_character.tscn
- fantasy_world.tscn
- historical_world.tscn
- portal_test.tscn

Scripts:
- 31 GDScript files in scripts/

## Existing Visual References
- assets/1000220666-1.png
- assets/ui/file_0000000053f081f4ab5d3e27245ce7a9.png

## Verification Notes
- Procedural geometry exists in GDScript.
- No standalone GLB, GLTF, FBX, OBJ or BLEND
  model files were found in the current repository tree.
- This does not mean procedural 3D geometry is absent.
- Miyar and Adam scenes have model attachment points.
- Do not delete, rename or merge either project.
- Preserve all existing work and continue from it.

## Pending Visual Audit
- Inspect generated map geometry in Godot.
- Inspect NPC visual appearance and animations.
- Confirm all scene references and runtime links.
- Separate finished assets from prototypes.
