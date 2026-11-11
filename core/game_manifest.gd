class_name GameManifest
extends Resource
## One per game at games/<id>/manifest.tres. The hub lists games from these; no hub code per game.

@export var id: String = ""
@export var display_name: String = ""
@export var subtitle: String = ""
@export_file("*.tscn") var scene: String = ""
@export var min_save_version: int = 1
@export var enabled: bool = false
@export var unlock_cost: int = 0
@export var coming_label: String = "SOON"
@export var order: int = 0
@export var accent: Color = Color(0.3, 0.5, 1.0)
@export var accent_dark: Color = Color(0.08, 0.1, 0.25)
## Which vector icon the hub card draws (see hub/game_icon.gd).
@export var icon_kind: String = ""
