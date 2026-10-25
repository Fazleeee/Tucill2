# Neon Breach: Tactical Arena (Tugas Kecil 2 - Clan Programming)

Game 2D Top-Down Tactical Arena Shooter yang dibuat menggunakan **Godot Engine 4.7.2**.

## Kontrol Permainan
- **W, A, S, D / Arrow Keys**: Bergerak
- **Mouse**: Mengarahkan bidikan laser (*Raycasting*)
- **Klik Kiri Mouse**: Menembak
- **Space / Shift**: *Dash* menghindar
- **ESC**: *Pause Menu* (Resume, Save Progress, Main Menu)

## Implementasi Object-Oriented Programming (OOP - `class_name`)
1. `CharacterEntity` (`scripts/classes/character_entity.gd`) — Base class untuk karakter (HP, movement speed, animasi sprite, sistem damage, heal, dan sinyal kematian).
2. `PlayerController` (`scripts/classes/player_controller.gd`) — Mewarisi (`extends`) `CharacterEntity`, menangani input pemain, kemampuan *dash*, serta sistem tembakan berbasis *RayCast2D*.
3. `EnemyAgent` (`scripts/classes/enemy_agent.gd`) — Mewarisi (`extends`) `CharacterEntity`, mengimplementasikan AI musuh dengan *Pathfinding* (`AStarGrid2D`) dan deteksi garis pandang (*RayCast2D*).
4. `CollectibleItem` (`scripts/classes/collectible_item.gd`) — Class item *pickup* untuk memulihkan HP pemain dan menambah skor.
5. `DungeonMap` (`scripts/classes/dungeon_map.gd`) — Class pengelola arena *TileMapLayer*, *collision* tembok, serta graf *pathfinding*.
6. `AudioController` (`scripts/classes/audio_controller.gd`) — Class pengelola *Background Music* (BGM) dan *Sound Effects* (SFX) beserta pengaturan volume.
7. `SaveSystem` (`scripts/classes/save_system.gd`) — Class untuk menyimpan dan memuat data permainan ke penyimpanan lokal (`user://save_data.json`).

## Modular Concepts yang Diimplementasikan (6 Konsep)
1. **Save & Load**: Menyimpan dan memuat *High Score*, *Best Wave*, *Total Kills*, serta pengaturan volume BGM & SFX secara otomatis maupun manual ke file JSON (`user://save_data.json`).
2. **Tilemaps**: Menggunakan `TileMapLayer` dan `TileSet` dengan *physics layer collision* pada dinding dan pilar pelindung arena.
3. **Raycasting**: Menggunakan `RayCast2D` untuk laser bidikan/tembakan pemain secara *real-time* serta pengecekan *Line-of-Sight* (pandangan langsung) musuh terhadap pemain.
4. **Pathfinding**: Menggunakan `AStarGrid2D` pada `DungeonMap` sehingga musuh (`EnemyAgent`) dapat mencari jalur terpendek menghindari rintangan dinding menuju posisi pemain.
5. **UI/UX**: Antarmuka lengkap meliputi *Main Menu* (pengaturan volume, statistik tersimpan, reset data), *HUD* (HP Bar, Dash Cooldown Bar, Wave, Hostiles, Score), *Pause Menu*, serta *Game Over Modal*.
6. **Animation(s) & Audio System**: Menggunakan `AnimatedSprite2D` (`idle`, `walk`, `hit`, `pulse`) ditambah animasi `Tween`, serta sistem pemutar BGM dan SFX multi-channel.
