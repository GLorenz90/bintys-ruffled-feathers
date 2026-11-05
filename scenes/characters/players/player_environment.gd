extends RefCounted
class_name PlayerEnvironment

# Everything a player needs to know about the world around them, kept out of player_character.gd:
#   - ledges in front of them (raycasts)
#   - pushable blocks in front of them (raycast)
#   - ladders / ropes and water volumes they're touching (those report in themselves)
#   - the air meter for diving
# Each player owns one, as player.env. All numbers live in CharStats.

const TERRAIN_MASK := 1;

var player: PlayerCharacter;

var air := CharStats.AIR_MAX;
var time_since_ledge_drop := INF;   # For LEDGE_REGRAB_DELAY.
var time_since_climb_exit := INF;   # For CLIMB_REGRAB_DELAY.
var time_pushing_into_block := 0.0; # For PUSH_GRAB_TIME.

# What the player has hold of, set just before switching into the state that uses it.
var grabbed_ledge := {};             # From find_ledge(), for LedgeHang / LedgeClimb.
var grabbed_climbable: Climbable;    # For Climb.
var grabbed_block := {};             # From find_pushable(), for Push.

var _climbables: Array[Climbable] = [];
var _water_volumes: Array[WaterVolume] = [];

func _init(owner_player: PlayerCharacter) -> void:
  player = owner_player;
#/_init

func update(delta: float) -> void:
  time_since_ledge_drop += delta;
  time_since_climb_exit += delta;
#/update

#region LEDGES =====================================================================================
# Looks for a ledge to grab in front of a point (the player's feet by default), facing a direction.
# Returns {} if there isn't one, otherwise:
#   "top"     the point on top of the ledge, right at its edge
#   "normal"  the wall's outward direction (pointing back at the player), flat
#   "wall"    where we touched the wall
func find_ledge(feet := Vector3.INF, forward := Vector3.ZERO) -> Dictionary:
  if feet == Vector3.INF: feet = player.global_position;
  if forward == Vector3.ZERO: forward = player.get_facing_direction();

  # 1. A wall in front of us at chest height.
  var chest := feet + Vector3.UP * CharStats.LEDGE_WALL_CHECK_HEIGHT;
  var wall := _ray(chest, chest + forward * CharStats.LEDGE_REACH);
  if wall.is_empty() || absf(wall.normal.y) > 0.3: return {};
  var normal := Vector3(wall.normal.x, 0.0, wall.normal.z).normalized();

  # 2. A flat top to that wall, within reach of our hands. The ray starts in open air above the wall,
  #    so a wall too tall to grab gives no hit (rays ignore shapes they start inside).
  var inside_edge: Vector3 = wall.position - normal * 0.2;
  var reach_top := Vector3(inside_edge.x, feet.y + CharStats.LEDGE_MAX_HEIGHT, inside_edge.z);
  var reach_bottom := Vector3(inside_edge.x, feet.y + CharStats.LEDGE_MIN_HEIGHT, inside_edge.z);
  var top := _ray(reach_top, reach_bottom);
  if top.is_empty() || top.normal.y < 0.7: return {};

  # 3. Room to stand up on top.
  var stand: Vector3 = top.position + Vector3.UP * 0.1;
  if !_ray(stand, stand + Vector3.UP * CharStats.LEDGE_CLEARANCE).is_empty(): return {};

  return {"top": Vector3(wall.position.x, top.position.y, wall.position.z), "normal": normal, "wall": wall.position};
#/find_ledge

func can_grab_ledge() -> bool:
  return time_since_ledge_drop >= CharStats.LEDGE_REGRAB_DELAY && player.velocity.y <= CharStats.LEDGE_MAX_GRAB_RISE;
#/can_grab_ledge

# Where the player's feet go while hanging from a ledge.
func get_hang_position(ledge: Dictionary) -> Vector3:
  var radius: float = player.SHAPE_NORMAL.radius;
  var out: Vector3 = ledge.top + ledge.normal * (radius + 0.05);
  return Vector3(out.x, ledge.top.y - CharStats.LEDGE_HANG_HEIGHT, out.z);
#/get_hang_position
#endregion =========================================================================================

#region PUSHABLE BLOCKS ============================================================================
# A pushable block right in front of us, and the face we're touching. Returns {} if there isn't one.
#   "block"   the PushBlock
#   "normal"  the face's outward direction (pointing at us), snapped to the block's own axes
func find_pushable() -> Dictionary:
  var from := player.global_position + Vector3.UP * 0.5;
  var hit := _ray(from, from + player.get_facing_direction() * CharStats.PUSH_REACH);
  if hit.is_empty() || !(hit.collider is PushBlock): return {};
  var block: PushBlock = hit.collider;
  return {"block": block, "normal": block.snap_to_face_normal(hit.normal)};
#/find_pushable
#endregion =========================================================================================

#region CLIMBABLES =================================================================================
func enter_climbable(climbable: Climbable) -> void:
  if !_climbables.has(climbable): _climbables.append(climbable);
#/enter_climbable

func exit_climbable(climbable: Climbable) -> void:
  _climbables.erase(climbable);
#/exit_climbable

# The ladder or rope we're touching, if we're allowed to grab it right now.
func get_grabbable_climbable() -> Climbable:
  if _climbables.is_empty() || time_since_climb_exit < CharStats.CLIMB_REGRAB_DELAY: return null;
  return _climbables.back();
#/get_grabbable_climbable
#endregion =========================================================================================

#region WATER ======================================================================================
func enter_water(water: WaterVolume) -> void:
  if !_water_volumes.has(water): _water_volumes.append(water);
#/enter_water

func exit_water(water: WaterVolume) -> void:
  _water_volumes.erase(water);
#/exit_water

func is_in_water() -> bool:
  return !_water_volumes.is_empty();
#/is_in_water

# Height of the water surface we're in, or -INF if we're not in water.
func get_water_surface() -> float:
  var surface := -INF;
  for water in _water_volumes: surface = maxf(surface, water.get_surface_height());
  return surface;
#/get_water_surface

# How far our feet are under the surface (negative means above it).
func get_depth() -> float:
  return get_water_surface() - player.global_position.y;
#/get_depth

func use_air(delta: float) -> void:
  air = maxf(air - delta, 0.0);
#/use_air

func refill_air(delta: float) -> void:
  air = minf(air + CharStats.AIR_REFILL_RATE * delta, CharStats.AIR_MAX);
#/refill_air
#endregion =========================================================================================

func _ray(from: Vector3, to: Vector3) -> Dictionary:
  var query := PhysicsRayQueryParameters3D.create(from, to, TERRAIN_MASK, [player.get_rid()]);
  return player.get_world_3d().direct_space_state.intersect_ray(query);
#/_ray
