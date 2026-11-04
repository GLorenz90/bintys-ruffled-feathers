extends Node3D
class_name Main

# The one scene that's always running. It owns input, the camera and the UI,
# and swaps levels in and out under the SubViewport's Scene node.
# Players live beside the level (not inside it), so they survive level changes.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/players/player_character.tscn");
const P1_SPAWN_NAME := "P1Spawn";
const P2_SPAWN_NAME := "P2Spawn";

@export var start_level: PackedScene;

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport;
@onready var level_parent: Node3D = $SubViewportContainer/SubViewport/Scene;

#region BUILT IN ===================================================================================
func _init() -> void:
  Global.main = self;
#/_init

func _ready() -> void:
  Global.camera = $SubViewportContainer/SubViewport/CameraTarget/Camera;
  Global.ui_layer = $SubViewportContainer/SubViewport/UiLayer;
  Settings.update_visual_settings();

  if start_level != null: load_level(start_level);
#/_ready
#endregion =========================================================================================

#region PUBLIC =====================================================================================
func load_level(level_scene: PackedScene) -> void:
  if Global.current_level != null:
    level_parent.remove_child(Global.current_level);
    Global.current_level.queue_free();
  #/if

  var level: Node3D = level_scene.instantiate();
  level_parent.add_child(level);
  Global.current_level = level;

  _place_player(1, level.get_node_or_null(P1_SPAWN_NAME));
  _place_player(2, level.get_node_or_null(P2_SPAWN_NAME));
#/load_level
#endregion =========================================================================================

#region PRIVATE ====================================================================================
# Spawns the player the first time, then moves them to the level's spawn point (if it has one).
func _place_player(player_id: int, spawn: Node3D) -> void:
  var player := Global.get_player(player_id);
  if player == null:
    player = PLAYER_SCENE.instantiate();
    player.is_p1 = player_id == 1;
    player.char_type = Enums.CHARACTERS.BINTY if player_id == 1 else Enums.CHARACTERS.GLINTY;
    player.name = Enums.CHARACTERS.keys()[player.char_type].capitalize();
    level_parent.add_child(player);
  #/if

  if spawn != null:
    player.global_transform = spawn.global_transform;
    player.velocity = Vector3.ZERO;
  #/if
#/_place_player
#endregion =========================================================================================
