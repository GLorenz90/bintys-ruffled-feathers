extends Node3D
class_name Main

# The one scene that's always running. It owns input, the camera and the UI,
# and swaps levels in and out under the SubViewport's Scene node.
# Players live beside the level (not inside it), so they survive level changes.
#
# Binty (P1) is always there. Glinty (P2) drops in once a second device is assigned to them
# (plug in a second controller), or with F4 from the debug overlay for testing.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/players/player_character.tscn");
const P1_SPAWN_NAME := "P1Spawn";
const P2_SPAWN_NAME := "P2Spawn";
const DROP_IN_OFFSET := Vector3(1.5, 0.5, 0.0); # Where Glinty appears relative to Binty when joining mid-level.

@export var start_level: PackedScene;

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport;
@onready var right_viewport: SubViewport = $RightViewContainer/SubViewport;
@onready var level_parent: Node3D = $SubViewportContainer/SubViewport/Scene;

var _current_level_scene: PackedScene;

#region BUILT IN ===================================================================================
func _init() -> void:
  Global.main = self;
#/_init

func _ready() -> void:
  Global.ui_layer = $Hud/UiLayer;
  Settings.update_visual_settings();
  Signals.player_device_assigned.connect(_on_player_device_assigned);

  if start_level != null: load_level(start_level);
#/_ready
#endregion =========================================================================================

#region PUBLIC =====================================================================================
# Both views the world is drawn into (the right one is only shown in split screen).
func get_game_viewports() -> Array[SubViewport]:
  return [viewport, right_viewport];
#/get_game_viewports

func load_level(level_scene: PackedScene) -> void:
  if Global.current_level != null:
    level_parent.remove_child(Global.current_level);
    Global.current_level.queue_free();
  #/if

  var level: Node3D = level_scene.instantiate();
  level_parent.add_child(level);
  Global.current_level = level;
  _current_level_scene = level_scene;
  GameState.clear_checkpoint();

  _place_player(1);
  if Global.p2_char != null || Global.device_manager.is_player_assigned(2): _place_player(2);
#/load_level

func restart_level() -> void:
  load_level(_current_level_scene);
#/restart_level

# Where a player (re)spawns: beside the current checkpoint, or at the level's own spawn point.
func get_spawn_transform(player_id: int) -> Transform3D:
  if GameState.current_checkpoint != null: return GameState.current_checkpoint.get_spawn_transform(player_id);
  var marker: Node3D = Global.current_level.get_node_or_null(P1_SPAWN_NAME if player_id == 1 else P2_SPAWN_NAME);
  return marker.global_transform if marker != null else Transform3D.IDENTITY;
#/get_spawn_transform

# Glinty joins beside Binty. Does nothing if Glinty's already here.
func spawn_player_two() -> void:
  if Global.p2_char != null: return;
  var player := _create_player(2);
  if Global.p1_char != null:
    player.global_position = Global.p1_char.global_position + DROP_IN_OFFSET;
  else:
    player.global_transform = get_spawn_transform(2);
  #/if
#/spawn_player_two
#endregion =========================================================================================

#region PRIVATE ====================================================================================
# Spawns the player the first time; after that, revives them at their spawn point.
func _place_player(player_id: int) -> void:
  var player := Global.get_player(player_id);
  if player == null:
    player = _create_player(player_id);
    player.global_transform = get_spawn_transform(player_id);
  else:
    player.revive_at(get_spawn_transform(player_id));
  #/if
#/_place_player

func _create_player(player_id: int) -> PlayerCharacter:
  var player: PlayerCharacter = PLAYER_SCENE.instantiate();
  player.is_p1 = player_id == 1;
  player.char_type = Enums.CHARACTERS.BINTY if player_id == 1 else Enums.CHARACTERS.GLINTY;
  player.name = Enums.CHARACTERS.keys()[player.char_type].capitalize();
  level_parent.add_child(player);
  Signals.player_spawned.emit(player);
  return player;
#/_create_player

func _on_player_device_assigned(player_id: int, _device_type: int, _device_id: int) -> void:
  if player_id == 2 && Global.current_level != null: spawn_player_two();
#/_on_player_device_assigned
#endregion =========================================================================================
