# Development Roadmap

## Phase 1 - Prototyping
- Implement core gameplay functionality
  - [x] Movement
  - [x] Camera Control
  - [x] Basic Inventory Functions
  - [x] Player HUD and Inventory UI
  - [x] Basic Combat mechanics (melee, ranged attack)
  - [x] Core Components for gameplay
    - [x] Health Component
    - [x] Inventory Component
    - [x] Combat Component
    - [x] Weapon Manager Component
    - [x] Interaction Component
    - [x] Loot Component

- Set up core game structure
  - [ ] Main (startup logic, global references, scene transitions)
  - [ ] Save Manager (loads/saves world and player data)
  - [ ] State Manager (Handle changing game states between MENU, PAUSE, GAME, etc.)
  - [ ] Audio Manager (Handles audio buses, music, etc.)
  - [ ] Input Manager (Handles non-gameplay inputs like screenshot, F11, Escape, etc.)
  - [ ] Main Menu
  - [ ] Pause Menu
  - [x] Game (Gameplay container)
  - [ ] World Director (handles gridmap, chunk streaming, weather, time of day, etc.)

## Phase 2 - Prototyping
- Expand on core gameplay functionality
  - Add more movement options
    - vaulting
    - sprinting
    - crouching
  - Extend inventory UI functionality
    - context menu
    - drop items
    - use items
  - Extend HUD functionality
    - Hotkeys to use quickslot items
    - Highlight active weapon slot
    - Track Vitals
    - Show current ammo, durability, etc. for weapons
  - Extend Camera Control and Combat systems
    - Two-phase camera-ray approach for aiming
    - Abstraction of combat mechanics to allow for different weapon types (shotguns, projectiles, etc.)
 - Implement core structure data/control flow
  - Launch game into start menu
  - Load game world
  - Save/Load world and player state
  - Gridmap world logic

## Phase 3 - Vertical Slice
- Implement basic enemy AI
  - Idle
  - Alert/Searching
  - Chase
  - Attack
- Single world chunk
- First art pass
  - Player character model
  - Player character animations
  - Enemy models
  - Enemy model animation
  - World objects
  - UI and HUD
- Basic audio

## Phase 4 - High Level processes
- World
  - Prefabs, tilesets
  - Procedural chunks (only for initial building)
  - Chunk streaming
  - Weather changes
  - Time of Day changes
- Game State
  - Load/Save multiple profiles
  - Load/Save container inventories per profile
- Loot Tables
- Friendly NPCs
- Safe Areas (Bunkers)
  - Building
  - Crafting
  - Recycling
- Quest logic
- Player skills
