extends CharacterBody3D
class_name Character;

#region PRIVATE VARS =============================================================
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity");
@export var debug := false;
@export var _max_health := 1;
@export var _cur_health := 1:
  set(value):
    _cur_health = clampi(value, 0, _max_health);
@export var _invulnerable = false;
@export var _dodging = false;
#endregion

#region PUBLIC VARS =============================================================
@export var has_gravity:bool = true;
#endregion

#region BUILT IN ===================================================================================
func _ready() -> void:
  if(debug):
    print("gravity: " + str(_gravity));
  pass
#/_ready

func _physics_process(_delta: float) -> void:
  if _cur_health <= 0:
    _die();
  #/if
#/_physics_process
#endregion =========================================================================================

#region PRIVATE ====================================================================================
func _spawn_attack(attack_scene: PackedScene, duration: float) -> Attack:
  var attack: Attack = attack_scene.instantiate();
  attack.lifetime = duration;
  attack.attacker = self;
  add_sibling(attack);
  return attack;
#/spawn_attack

func _handle_damage(from_location := Vector3.FORWARD) -> void:
  print(from_location);
  pass
#/_damage_recoil()

func _die():
  #override me
  queue_free();
#/_die
#endregion =========================================================================================

#region PUBLIC =====================================================================================
func hit(value: int, from_location := Vector3.FORWARD) -> void:
  if( !_dodging):
    damage(value, from_location);
  #/if
#/hit

func damage(value: int, from_location := Vector3.FORWARD) -> void:
  if($InvulnTimer.is_stopped() && !_invulnerable):
    _cur_health -= value;
    _handle_damage(from_location);
    $InvulnTimer.start();
  #/if
#/damage

func heal(value: int) -> void:
  if($HealTimer.is_stopped()):
    _cur_health += value;
    $HealTimer.start();
  #/if
#/damage
#endregion =========================================================================================
