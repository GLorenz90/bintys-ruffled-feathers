extends CharacterBody3D
class_name Character;

# Anything that moves and can be hurt: players and enemies.
#
# Getting hit:  hit(amount, from_position, knockback)
#   - ignored while dodging (rolling) or invulnerable
#   - takes the health off and starts the invulnerability timer (InvulnTimer)
#   - then calls _on_hurt(...), or _on_health_depleted() once health reaches 0
# Subclasses override those two to react: knockback, flashing, death.

#region VARS =======================================================================================
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity");
@export var debug := false;
@export var _max_health := 1;
@export var _cur_health := 1:
  set(value):
    _cur_health = clampi(value, 0, _max_health);
@export var _invulnerable := false;   # Set by things like cutscenes and interactions.
@export var _dodging := false;        # Set while rolling: hits pass straight through.
@export var has_gravity := true;
#endregion =========================================================================================

#region PUBLIC =====================================================================================
func hit(amount: int, from_position: Vector3, knockback := 0.0) -> bool:
  if !can_be_hit(): return false;

  _cur_health -= amount;
  $InvulnTimer.start();
  if _cur_health <= 0:
    _on_health_depleted();
  else:
    _on_hurt(amount, from_position, knockback);
  #/if
  return true;
#/hit

func can_be_hit() -> bool:
  return !_dodging && !_invulnerable && $InvulnTimer.is_stopped() && _cur_health > 0;
#/can_be_hit

func heal(amount: int) -> void:
  _cur_health += amount;
  _on_healed();
#/heal

func get_health() -> int:
  return _cur_health;
#/get_health

func get_max_health() -> int:
  return _max_health;
#/get_max_health

# Direction to push something away from a point, flat on the ground. Falls back to "backwards" if they overlap.
func get_knockback_direction(from_position: Vector3) -> Vector3:
  var away := global_position - from_position;
  away.y = 0.0;
  return away.normalized() if away.length() > 0.01 else global_basis.z;
#/get_knockback_direction
#endregion =========================================================================================

#region OVERRIDE IN SUBCLASSES =====================================================================
func _on_hurt(_amount: int, _from_position: Vector3, _knockback: float) -> void:
  pass;
#/_on_hurt

func _on_health_depleted() -> void:
  queue_free();
#/_on_health_depleted

func _on_healed() -> void:
  pass;
#/_on_healed
#endregion =========================================================================================

#region PRIVATE ====================================================================================
func _spawn_attack(attack_scene: PackedScene, duration: float) -> Attack:
  var attack: Attack = attack_scene.instantiate();
  attack.lifetime = duration;
  attack.attacker = self;
  add_sibling(attack);
  return attack;
#/_spawn_attack
#endregion =========================================================================================
