extends Node
class_name CameraDirector

# Decides how the screen is shown in co-op.
#
#   SHARED: one full-screen view whose camera frames both players, pulling back as they spread out.
#   SPLIT:  two side-by-side views (P1 left, P2 right), each following one player.
#
# It splits once the players are more than SPLIT_DISTANCE apart, or are standing in different camera zones.
# It merges once they're back within MERGE_DISTANCE and have shared a zone (or no zone) for ZONE_MERGE_DELAY.
# The gaps between those numbers stop it flickering at the boundary.
# Both views look into the same world; the right-hand one only renders while split.

enum MODES { SHARED, SPLIT }

@export var left_view: SubViewportContainer;
@export var right_view: SubViewportContainer;
@export var left_camera: FollowCamera;
@export var right_camera: FollowCamera;
@export var divider: Control;

var mode: MODES = MODES.SHARED;
var _time_in_same_zone := 0.0;

#region BUILT IN ===================================================================================
func _ready() -> void:
  Global.camera_director = self;
  Global.camera = left_camera.camera;
  right_view.get_node("SubViewport").world_3d = left_view.get_node("SubViewport").world_3d;
  _set_mode(MODES.SHARED, true);
#/_ready

func _physics_process(delta: float) -> void:
  if Global.p1_char == null || Global.p2_char == null: return;
  if left_camera.targets.is_empty(): _set_mode(mode, true); # Players spawned since _ready.

  var spread := Global.p1_char.global_position.distance_to(Global.p2_char.global_position);
  var zones_differ := Global.p1_char.get_camera_zone() != Global.p2_char.get_camera_zone();
  _time_in_same_zone = 0.0 if zones_differ else _time_in_same_zone + delta;

  if mode == MODES.SHARED && (spread > CameraStats.SPLIT_DISTANCE || zones_differ):
    _set_mode(MODES.SPLIT);
  elif mode == MODES.SPLIT && spread < CameraStats.MERGE_DISTANCE && _time_in_same_zone >= CameraStats.ZONE_MERGE_DELAY:
    _set_mode(MODES.SHARED);
  #/if
#/_physics_process
#endregion =========================================================================================

#region PUBLIC =====================================================================================
# The camera a player's stick directions should be relative to.
func get_camera_for_player(player_id: int) -> Camera3D:
  return right_camera.camera if mode == MODES.SPLIT && player_id == 2 else left_camera.camera;
#/get_camera_for_player

func get_mode_name() -> String:
  return MODES.keys()[mode];
#/get_mode_name
#endregion =========================================================================================

#region PRIVATE ====================================================================================
func _set_mode(new_mode: MODES, force := false) -> void:
  if new_mode == mode && !force: return;
  mode = new_mode;

  var players: Array[PlayerCharacter] = [];
  if Global.p1_char != null: players.append(Global.p1_char);
  if Global.p2_char != null: players.append(Global.p2_char);

  match mode:
    MODES.SHARED:
      left_camera.targets = players;
      left_camera.controller_ids = [1, 2];
      _set_view_split(false);
    MODES.SPLIT:
      # The right camera starts exactly where the shared one is, then both ease toward their own player.
      right_camera.copy_from(left_camera);
      left_camera.targets = [Global.p1_char];
      left_camera.controller_ids = [1];
      right_camera.targets = [Global.p2_char];
      right_camera.controller_ids = [2];
      _set_view_split(true);
  #/match
#/_set_mode

func _set_view_split(is_split: bool) -> void:
  left_view.anchor_right = 0.5 if is_split else 1.0;
  left_view.offset_right = 0.0;
  right_view.visible = is_split;
  right_view.get_node("SubViewport").render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_split else SubViewport.UPDATE_DISABLED;
  right_camera.set_physics_process(is_split);
  divider.visible = is_split;
#/_set_view_split
#endregion =========================================================================================
