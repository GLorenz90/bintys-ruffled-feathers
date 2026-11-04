extends Node3D
class_name Attack

#region PUBLIC VARS ================================================================================
@export var damage := 1;
## Seconds before the attack removes itself. <= 0 means it lives until end_attack() is called.
@export var lifetime := 0.25;
## True: tracks the attacker every physics frame. False: stays where it was spawned.
@export var follow_attacker := true;
## Offset in the attacker's local space (-Z is forward, since characters use look_at).
@export var spawn_offset := Vector3.ZERO;

var attacker: Character;
#endregion =========================================================================================

#region PRIVATE VARS ===============================================================================
var _hit_bodies: Array[Node3D] = [];
var _time_alive := 0.0;

@onready var area: Area3D = $Area;
@onready var effect: Node3D = $Effect;
#endregion =========================================================================================

#region BUILT IN ===================================================================================
func _ready() -> void:
  area.body_entered.connect(_on_body_entered);
  _snap_to_attacker();
  _on_attack_start();
#/_ready

func _physics_process(delta: float) -> void:
  if follow_attacker:
    _snap_to_attacker();
  #/if

  _time_alive += delta;
  if lifetime > 0.0 && _time_alive >= lifetime:
    end_attack();
  #/if
#/_physics_process
#endregion =========================================================================================

#region PRIVATE ====================================================================================
func _snap_to_attacker() -> void:
  if !is_instance_valid(attacker):
    return;
  #/if
  global_transform = attacker.global_transform.translated_local(spawn_offset);
#/_snap_to_attacker

func _on_body_entered(body: Node3D) -> void:
  if body == attacker || body in _hit_bodies:
    return;
  #/if
  _hit_bodies.append(body);
  _on_hit(body);
#/_on_body_entered
#endregion =========================================================================================

#region VIRTUAL (override in subclasses) ===========================================================
func _on_attack_start() -> void:
  pass;
#/_on_attack_start

func _on_hit(body: Node3D) -> void:
  if body.has_method("damage"):
    body.damage(damage, global_position);
  #/if
#/_on_hit

func _on_attack_end() -> void:
  pass;
#/_on_attack_end
#endregion =========================================================================================

#region PUBLIC =====================================================================================
func end_attack() -> void:
  _on_attack_end();
  queue_free();
#/end_attack
#endregion =========================================================================================
