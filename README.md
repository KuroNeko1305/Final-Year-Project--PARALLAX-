# Project Structure

This document outlines the complete structure of the Godot game project, focusing on scenes, scripts, and assets.

---

## 📊 Project Statistics

- **Total Scripts**: ~50+ GDScript files
- **Total Scenes**: ~30+ scene files
- **Total Assets**: 
  - Images/Sprites: 100+ PNG/JPG files
  - Audio Files: 40+ WAV/MP3 files
  - Fonts: 5 TTF files

---

## 🎯 Key Features

1. **Multiplayer Support**: Network handler and multiplayer spawners
2. **Voice & Text Chat**: Integrated communication system
3. **Multi-Chapter Structure**: Chapter 1, Chapter 2, with puzzles
4. **Gem Collection System**: Global gem management
5. **Parallax Backgrounds**: Multiple biome backgrounds
6. **Interactive Objects**: Crates, rocks, ladders, platforms, traps
7. **Audio System**: Separate managers for music and sound effects
8. **Menu System**: Main menu, pause menu, settings with persistence

---

## 🔄 Scene Flow

```
Main Menu → Introduction Map → Chapter 1 → Puzzle 1 → Puzzle 2 → Chapter 2 → Game Over
                ↑                                                                  ↓
                └──────────────────────────────────────────────────────────────────┘
```

## 📁 Directory Overview


```
Final-Year-Project--PARALLAX-/
├── autoload/                                    # Singleton scripts (autoloaded)
│   ├── audio_manager.gd
│   ├── chat_manager.gd
│   ├── gem_manager.gd
│   ├── global_introduction.gd
│   ├── network_handler.gd
│   ├── sound_manager.gd
│   └── voice_manager.gd
│
├── assets/                                      # Game assets (images, audio, etc.)
│   ├── chapter1/
│   │   ├── puzzle1/                            # Puzzle 1 assets (backgrounds, sprites)
│   │   │   ├── background1.png
│   │   │   ├── background2.png
│   │   │   ├── background3.png
│   │   │   ├── background4a.png
│   │   │   ├── background4b.png
│   │   │   ├── crate.png
│   │   │   ├── mainlev_build.png
│   │   │   ├── props1.png
│   │   │   ├── props2.png
│   │   │   ├── rock.png
│   │   │   └── water.png
│   │   └── puzzle2/                            # Puzzle 2 assets
│   │       ├── Background.png
│   │       ├── Bat.png
│   │       ├── Coin.png
│   │       ├── Crystals.png
│   │       ├── door.png
│   │       ├── spikes.png
│   │       ├── Tiles.png
│   │       ├── Vine_1.png
│   │       └── Water.png
│   │
│   ├── chapter2/                               # Chapter 2 season-themed assets
│   │   ├── autumn_background.png
│   │   ├── door.png
│   │   ├── snow.png
│   │   ├── spike_winter.png
│   │   ├── tileset_fall_v2.png
│   │   ├── tree-autumn.png
│   │   ├── tree_winter.png
│   │   ├── winter_autumn_tile.png
│   │   └── winter_background.png
│   │
│   ├── introduction/
│   │   └── assets/
│   │       ├── Demo/                           # Character sprite sheets
│   │       │   ├── Esh Climb.png
│   │       │   ├── Esh Dash.png
│   │       │   ├── Esh Fall.png
│   │       │   ├── Esh Hold.png
│   │       │   ├── Esh Idle.png
│   │       │   ├── Esh Jump.png
│   │       │   ├── Esh Pull.png
│   │       │   ├── Esh Push.png
│   │       │   ├── Esh Run.png
│   │       │   ├── Esh Swim.png
│   │       │   └── Esh Wall Slide.png
│   │       │
│   │       ├── Pixel Woods Asset Pack/
│   │       │   ├── Backgrounds/
│   │       │   │   ├── cave/                   # Cave background layers
│   │       │   │   │   ├── 1.png
│   │       │   │   │   ├── 2.png
│   │       │   │   │   ├── 4.png
│   │       │   │   │   ├── 5.png
│   │       │   │   │   ├── 7.png
│   │       │   │   │   └── 9.png
│   │       │   │   ├── light/                  # Lighting effects
│   │       │   │   │   ├── 3fx.png
│   │       │   │   │   ├── 6fx.png
│   │       │   │   │   ├── 8fx.png
│   │       │   │   │   ├── Lights 1.png
│   │       │   │   │   └── Lights 2.png
│   │       │   │   ├── mountain/               # Mountain parallax layers
│   │       │   │   │   ├── clouds_front_fc.png
│   │       │   │   │   ├── clouds_front_t_fc.png
│   │       │   │   │   ├── clouds_mid_fc.png
│   │       │   │   │   ├── clouds_mid_t_fc.png
│   │       │   │   │   ├── far_mountains_fc.png
│   │       │   │   │   └── grassy_mountains_fc.png
│   │       │   │   ├── sky/                    # Sky backgrounds
│   │       │   │   │   ├── Background_1.png
│   │       │   │   │   └── Background_2.png
│   │       │   │   ├── tree/                   # Tree layers
│   │       │   │   │   ├── Textures&trees.png
│   │       │   │   │   ├── Tlayer1.png
│   │       │   │   │   ├── Tlayer2.png
│   │       │   │   │   └── Tlayer3.png
│   │       │   │   └── waterfall/              # Waterfall animation frames
│   │       │   │       ├── W1001.png
│   │       │   │       ├── W1002.png
│   │       │   │       ├── W1003.png
│   │       │   │       ├── W1004.png
│   │       │   │       ├── W1005.png
│   │       │   │       ├── W1006.png
│   │       │   │       ├── W1007.png
│   │       │   │       └── W1008.png
│   │       │   └── Tileset/
│   │       │       └── Pixel_Woods_Tileset.png
│   │       │
│   │       ├── chain.png
│   │       ├── knight.png
│   │       ├── mic-off.png
│   │       ├── mic.png
│   │       ├── rope-ladder.png
│   │       ├── vines_no_bg (1).png
│   │       └── x.png
│   │
│   ├── musics/                                 # Background music tracks
│   │   ├── introduction_map.wav
│   │   ├── menu.wav
│   │   ├── puzzle1.mp3
│   │   └── puzzle2.mp3
│   │
│   └── sounds/                                 # Sound effects library
│       ├── Blops/
│       │   ├── Retro Blop 07.wav
│       │   ├── Retro Blop 18.wav
│       │   ├── Retro Blop 22.wav
│       │   ├── Retro Blop StereoUP 04.wav
│       │   └── Retro Blop StereoUP 09.wav
│       ├── Bounce Jump/
│       │   ├── Retro Jump 01.wav
│       │   ├── Retro Jump Classic 08.wav
│       │   ├── Retro Jump Simple A 01.wav
│       │   ├── Retro Jump Simple B 05.wav
│       │   ├── Retro Jump Simple C2 02.wav
│       │   ├── Retro Jump StereoUP Simple 01.wav
│       │   └── Retro Jump StereoUP Simple 05.wav
│       ├── Coins/
│       │   ├── hurt.wav
│       │   ├── industrial_door_close.wav
│       │   ├── Retro Event Wrong Simple 07.wav
│       │   ├── Retro PickUp Coin StereoUP 04.wav
│       │   └── wood_small_gather.wav
│       ├── Doors/
│       │   ├── door_knock.wav
│       │   └── door_open.wav
│       ├── Explosion/
│       │   ├── Retro Explosion Long 02.wav
│       │   ├── Retro Explosion Short 01.wav
│       │   ├── Retro Explosion Short 15.wav
│       │   └── Retro Explosion Swoshes 04.wav
│       ├── FootStep/
│       │   ├── Retro FootStep 03.wav
│       │   ├── Retro FootStep Grass 01.wav
│       │   ├── Retro FootStep Gravel 01.wav
│       │   ├── Retro FootStep Krushed Landing 01.wav
│       │   ├── Retro FootStep Metal 01.wav
│       │   └── Retro FootStep Mud 01.wav
│       ├── Pops/
│       │   ├── pop_1.wav
│       │   ├── pop_2.wav
│       │   └── pop_3.wav
│       ├── Stones/
│       │   ├── stone_push_long.wav
│       │   ├── stone_push_medium.wav
│       │   └── stone_push_short.wav
│       ├── Swoosh/
│       │   ├── Retro Swooosh 02.wav
│       │   ├── Retro Swooosh 07.wav
│       │   └── Retro Swooosh 16.wav
│       └── UI/
│           ├── UI Close.wav
│           └── UI Open.wav
│
├── menus/                                      # Menu system
│   ├── assets/
│   │   ├── fonts/
│   │   │   ├── PixelOperator8-Bold.ttf
│   │   │   └── PixelOperator8.ttf
│   │   ├── menu_background.jpg
│   │   ├── Spritesheet_UI_Flat_Animated.png
│   │   └── Spritesheet_UI_Flat.png
│   │
│   ├── Fonts/
│   │   ├── Pixeled.ttf
│   │   ├── PixelOperator8-Bold.ttf
│   │   ├── PixelOperator8.ttf
│   │   └── pixel.ttf
│   │
│   ├── scenes/                                # Menu scene files
│   │   ├── chat_box.tscn
│   │   ├── main_menu.tscn
│   │   ├── pause_menu.tscn
│   │   └── setting_menu.tscn
│   │
│   └── scripts/                               # Menu logic scripts
│       ├── chat_box.gd
│       ├── main_menu.gd
│       ├── menu_navigator.gd
│       ├── pause_menu.gd
│       ├── setting_menu.gd
│       ├── settings_load.gd
│       └── shader/
│           └── pause_menu.gdshader
│
├── scenes/                                     # Game scenes (.tscn files)
│   ├── backgrounds/                           # Parallax background scenes
│   │   ├── cave_background.tscn
│   │   ├── forest_background.tscn
│   │   ├── mountain_background.tscn
│   │   ├── puzzle1_background.tscn
│   │   └── sky_background.tscn
│   │
│   ├── controls/                              # UI and control scenes
│   │   ├── chatbox.tscn
│   │   ├── dialog.tscn
│   │   ├── voice_chat.tscn
│   │   └── voice_manager.tscn
│   │
│   ├── items/                                 # Interactive object scenes
│   │   ├── blue_gem.tscn
│   │   ├── crate.tscn
│   │   ├── drop_platform.tscn
│   │   ├── gem_demo_scene.tscn
│   │   ├── help_board.tscn
│   │   ├── ladder.tscn
│   │   ├── platfoms.tscn
│   │   ├── red_gem.tscn
│   │   ├── rock.tscn
│   │   ├── scene_change_area.tscn
│   │   ├── transition_door.tscn
│   │   ├── trap.tscn
│   │   ├── tree_on_rock.tscn
│   │   ├── water.tscn
│   │   └── wood_log.tscn
│   │
│   ├── maps/                                  # Level/map scenes
│   │   ├── chapter1.tscn
│   │   ├── chapter_2.tscn
│   │   ├── game_over.tscn
│   │   ├── introduction_map.tscn
│   │   ├── puzze2_map.tscn
│   │   ├── puzzle1_map_back.tscn
│   │   └── puzzle1_map.tscn
│   │
│   └── players/                               # Player character scenes
│       ├── player_0.tscn
│       └── player_1.tscn
│
└── scripts/                                    # Game logic scripts (.gd files)
    ├── backgrounds/                           # Background behavior scripts
    │   ├── background.gd
    │   ├── cave_biome.gd
    │   ├── forest_biome.gd
    │   ├── mountain_biome.gd
    │   ├── puzzle_biome.gd
    │   └── sky_biome.gd
    │
    ├── controls/                              # UI and control logic
    │   ├── chatbox.gd
    │   ├── dialog.gd
    │   ├── multiplayer_spawner.gd
    │   ├── next_scene_multiplayer_spawner.gd
    │   └── voice_chat.gd
    │
    ├── items/                                 # Interactive object logic
    │   ├── base_gem.gd
    │   ├── blue_gem.gd
    │   ├── crate.gd
    │   ├── drop_platform.gd
    │   ├── gem_test_debug.gd
    │   ├── help_board.gd
    │   ├── ladder.gd
    │   ├── red_gem.gd
    │   ├── rock.gd
    │   ├── scene_change_area.gd
    │   ├── transition_door.gd
    │   ├── trap.gd
    │   ├── tree_on_rock.gd
    │   └── wood_log.gd
    │
    ├── maps/                                  # Map/level logic
    │   ├── chapter_2_map.gd
    │   ├── game_over.gd
    │   └── map.gd
    │
    └── players/                               # Player controller scripts
        ├── player_0.gd
        ├── player_1.gd
        └── player.gd
```

---

## 🔧 Autoload (Singleton Scripts)

Global scripts that are automatically loaded when the game starts:

```
autoload/
├── audio_manager.gd          # Manages background music
├── chat_manager.gd           # Handles chat functionality
├── gem_manager.gd            # Manages gem collection system
├── global_introduction.gd    # Global state for introduction
├── network_handler.gd        # Network/multiplayer handler
├── sound_manager.gd          # Manages sound effects
└── voice_manager.gd          # Handles voice chat functionality
```

---

## 🎨 Assets

### Chapter 1 Assets

#### Puzzle 1
```
assets/chapter1/puzzle1/
├── background1.png
├── background2.png
├── background3.png
├── background4a.png
├── background4b.png
├── crate.png
├── mainlev_build.png
├── props1.png
├── props2.png
├── rock.png
└── water.png
```

#### Puzzle 2
```
assets/chapter1/puzzle2/
├── Background.png
├── Bat.png
├── Coin.png
├── Crystals.png
├── door.png
├── spikes.png
├── Tiles.png
├── Vine_1.png
└── Water.png
```

### Chapter 2 Assets
```
assets/chapter2/
├── autumn_background.png
├── door.png
├── snow.png
├── spike_winter.png
├── tileset_fall_v2.png
├── tree-autumn.png
├── tree_winter.png
├── winter_autumn_tile.png
└── winter_background.png
```

### Introduction Assets

#### Character Sprites (Demo)
```
assets/introduction/assets/Demo/
├── Esh Climb.png
├── Esh Dash.png
├── Esh Fall.png
├── Esh Hold.png
├── Esh Idle.png
├── Esh Jump.png
├── Esh Pull.png
├── Esh Push.png
├── Esh Run.png
├── Esh Swim.png
└── Esh Wall Slide.png
```

#### Pixel Woods Asset Pack

**Backgrounds - Cave**
```
assets/introduction/assets/Pixel Woods Asset Pack/Backgrounds/cave/
├── 1.png
├── 2.png
├── 4.png
├── 5.png
├── 7.png
└── 9.png
```

**Backgrounds - Light**
```
assets/introduction/assets/Pixel Woods Asset Pack/Backgrounds/light/
├── 3fx.png
├── 6fx.png
├── 8fx.png
├── Lights 1.png
└── Lights 2.png
```

**Backgrounds - Mountain**
```
assets/introduction/assets/Pixel Woods Asset Pack/Backgrounds/mountain/
├── clouds_front_fc.png
├── clouds_front_t_fc.png
├── clouds_mid_fc.png
├── clouds_mid_t_fc.png
├── far_mountains_fc.png
└── grassy_mountains_fc.png
```

**Backgrounds - Sky**
```
assets/introduction/assets/Pixel Woods Asset Pack/Backgrounds/sky/
├── Background_1.png
└── Background_2.png
```

**Backgrounds - Tree**
```
assets/introduction/assets/Pixel Woods Asset Pack/Backgrounds/tree/
├── Textures&trees.png
├── Tlayer1.png
├── Tlayer2.png
└── Tlayer3.png
```

**Backgrounds - Waterfall**
```
assets/introduction/assets/Pixel Woods Asset Pack/Backgrounds/waterfall/
├── W1001.png
├── W1002.png
├── W1003.png
├── W1004.png
├── W1005.png
├── W1006.png
├── W1007.png
└── W1008.png
```

**Tileset**
```
assets/introduction/assets/Pixel Woods Asset Pack/Tileset/
└── Pixel_Woods_Tileset.png
```

#### Other Introduction Assets
```
assets/introduction/assets/
├── chain.png
├── knight.png
├── mic-off.png
├── mic.png
├── rope-ladder.png
├── vines_no_bg (1).png
└── x.png
```

### Music
```
assets/musics/
├── introduction_map.wav
├── menu.wav
├── puzzle1.mp3
└── puzzle2.mp3
```

### Sound Effects

#### Blops
```
assets/sounds/Blops/
├── Retro Blop 07.wav
├── Retro Blop 18.wav
├── Retro Blop 22.wav
├── Retro Blop StereoUP 04.wav
└── Retro Blop StereoUP 09.wav
```

#### Bounce Jump
```
assets/sounds/Bounce Jump/
├── Retro Jump 01.wav
├── Retro Jump Classic 08.wav
├── Retro Jump Simple A 01.wav
├── Retro Jump Simple B 05.wav
├── Retro Jump Simple C2 02.wav
├── Retro Jump StereoUP Simple 01.wav
└── Retro Jump StereoUP Simple 05.wav
```

#### Coins
```
assets/sounds/Coins/
├── hurt.wav
├── industrial_door_close.wav
├── Retro Event Wrong Simple 07.wav
├── Retro PickUp Coin StereoUP 04.wav
└── wood_small_gather.wav
```

#### Doors
```
assets/sounds/Doors/
├── door_knock.wav
└── door_open.wav
```

#### Explosion
```
assets/sounds/Explosion/
├── Retro Explosion Long 02.wav
├── Retro Explosion Short 01.wav
├── Retro Explosion Short 15.wav
└── Retro Explosion Swoshes 04.wav
```

#### FootStep
```
assets/sounds/FootStep/
├── Retro FootStep 03.wav
├── Retro FootStep Grass 01.wav
├── Retro FootStep Gravel 01.wav
├── Retro FootStep Krushed Landing 01.wav
├── Retro FootStep Metal 01.wav
└── Retro FootStep Mud 01.wav
```

#### Pops
```
assets/sounds/Pops/
├── pop_1.wav
├── pop_2.wav
└── pop_3.wav
```

#### Stones
```
assets/sounds/Stones/
├── stone_push_long.wav
├── stone_push_medium.wav
└── stone_push_short.wav
```

#### Swoosh
```
assets/sounds/Swoosh/
├── Retro Swooosh 02.wav
├── Retro Swooosh 07.wav
└── Retro Swooosh 16.wav
```

#### UI
```
assets/sounds/UI/
├── UI Close.wav
└── UI Open.wav
```

---

## 🎮 Menus

### Menu Assets
```
menus/assets/
├── fonts/
│   ├── PixelOperator8-Bold.ttf
│   └── PixelOperator8.ttf
├── menu_background.jpg
├── Spritesheet_UI_Flat_Animated.png
└── Spritesheet_UI_Flat.png
```

### Menu Fonts
```
menus/Fonts/
├── Pixeled.ttf
├── PixelOperator8-Bold.ttf
├── PixelOperator8.ttf
└── pixel.ttf
```

### Menu Scenes
```
menus/scenes/
├── chat_box.tscn         # Chat interface scene
├── main_menu.tscn        # Main menu scene
├── pause_menu.tscn       # Pause menu scene
└── setting_menu.tscn     # Settings menu scene
```

### Menu Scripts
```
menus/scripts/
├── chat_box.gd           # Chat box logic
├── main_menu.gd          # Main menu logic
├── menu_navigator.gd     # Menu navigation handler
├── pause_menu.gd         # Pause menu logic
├── setting_menu.gd       # Settings menu logic
├── settings_load.gd      # Settings persistence
└── shader/
    └── pause_menu.gdshader   # Pause menu shader effect
```

---

## 🎬 Scenes

### Background Scenes
```
scenes/backgrounds/
├── cave_background.tscn      # Cave biome background
├── forest_background.tscn    # Forest biome background
├── mountain_background.tscn  # Mountain biome background
├── puzzle1_background.tscn   # Puzzle 1 background
└── sky_background.tscn       # Sky biome background
```

### Control Scenes
```
scenes/controls/
├── chatbox.tscn         # In-game chat box
├── dialog.tscn          # Dialog system
├── voice_chat.tscn      # Voice chat UI
└── voice_manager.tscn   # Voice manager instance
```

### Item Scenes
```
scenes/items/
├── blue_gem.tscn             # Blue gem collectible
├── crate.tscn                # Movable crate
├── drop_platform.tscn        # Dropping platform
├── gem_demo_scene.tscn       # Gem testing scene
├── help_board.tscn           # Help/tutorial board
├── ladder.tscn               # Climbable ladder
├── platfoms.tscn             # Platform variations
├── red_gem.tscn              # Red gem collectible
├── rock.tscn                 # Rock obstacle
├── scene_change_area.tscn    # Scene transition area
├── transition_door.tscn      # Door for scene transitions
├── trap.tscn                 # Trap/hazard
├── tree_on_rock.tscn         # Tree decoration
├── water.tscn                # Water obstacle
└── wood_log.tscn             # Wood log platform
```

### Map Scenes
```
scenes/maps/
├── chapter1.tscn             # Chapter 1 main map
├── chapter_2.tscn            # Chapter 2 main map
├── game_over.tscn            # Game over screen
├── introduction_map.tscn     # Introduction/tutorial map
├── puzze2_map.tscn           # Puzzle 2 map
├── puzzle1_map_back.tscn     # Puzzle 1 background layer
└── puzzle1_map.tscn          # Puzzle 1 main map
```

### Player Scenes
```
scenes/players/
├── player_0.tscn    # Player 1 (first player)
└── player_1.tscn    # Player 2 (second player)
```

---

## 📜 Scripts

### Background Scripts
```
scripts/backgrounds/
├── background.gd          # Base background class
├── cave_biome.gd          # Cave background logic
├── forest_biome.gd        # Forest background logic
├── mountain_biome.gd      # Mountain background logic
├── puzzle_biome.gd        # Puzzle background logic
└── sky_biome.gd           # Sky background logic
```

### Control Scripts
```
scripts/controls/
├── chatbox.gd                            # Chat box functionality
├── dialog.gd                             # Dialog system logic
├── multiplayer_spawner.gd                # Multiplayer spawn management
├── next_scene_multiplayer_spawner.gd     # Scene transition spawner
└── voice_chat.gd                         # Voice chat implementation
```

### Item Scripts
```
scripts/items/
├── base_gem.gd              # Base gem class
├── blue_gem.gd              # Blue gem logic
├── crate.gd                 # Crate physics/interaction
├── drop_platform.gd         # Dropping platform logic
├── gem_test_debug.gd        # Gem testing/debugging
├── help_board.gd            # Help board display logic
├── ladder.gd                # Ladder climbing logic
├── red_gem.gd               # Red gem logic
├── rock.gd                  # Rock interaction
├── scene_change_area.gd     # Scene change trigger
├── transition_door.gd       # Door transition logic
├── trap.gd                  # Trap/hazard logic
├── tree_on_rock.gd          # Tree decoration script
└── wood_log.gd              # Wood log platform logic
```

### Map Scripts
```
scripts/maps/
├── chapter_2_map.gd    # Chapter 2 map logic
├── game_over.gd        # Game over screen logic
└── map.gd              # Base map class
```

### Player Scripts
```
scripts/players/
├── player_0.gd    # Player 1 controller
├── player_1.gd    # Player 2 controller
└── player.gd      # Base player class
```

---

**Note**: This structure excludes Godot-specific configuration files (.import, .uid, .tres, .gdextension files) and focuses on game content.

*Last Updated: November 15, 2025*
