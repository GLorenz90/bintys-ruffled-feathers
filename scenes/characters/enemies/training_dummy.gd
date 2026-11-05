extends Character
class_name TrainingDummy

# Something to hit in the gym. It wobbles and flashes when struck, counts the damage, and never dies:
# reaching zero just tops it back up. The label above it shows the last hit and the running total.

const BODY_COLOR := Color(0.8, 0.65, 0.45);
const WOBBLE_DEGREES := 25.0;
const WOBBLE_TIME := 0.35;
const MAX_HEALTH := 1000;

var _total_damage := 0;
var _time_since_hit := INF;
var _flash: EnemyBodyFlash;

@onready var _label: Label3D = $Label;

func _ready() -> void:
  _max_health = MAX_HEALTH;
  _cur_health = MAX_HEALTH;
  $InvulnTimer.wait_time = 0.05;
  _flash = EnemyBodyFlash.new($Model/Body, BODY_COLOR);
  _update_label(0);
#/_ready

func _physics_process(delta: float) -> void:
  _time_since_hit += delta;
  if _time_since_hit >= CharStats.DUMMY_HEAL_DELAY && _cur_health < _max_health:
    _cur_health = _max_health;
    _total_damage = 0;
    _update_label(0);
  #/if
  if !is_on_floor(): velocity.y -= _gravity * delta;
  move_and_slide();
#/_physics_process

func _on_hurt(amount: int, from_position: Vector3, knockback: float) -> void:
  _time_since_hit = 0.0;
  _total_damage += amount;
  _update_label(amount);
  _flash.flash(self);
  _wobble(from_position, knockback);
#/_on_hurt

func _on_health_depleted() -> void:
  _cur_health = _max_health;
#/_on_health_depleted

# Tips away from the hit (harder hits tip further) and springs back.
func _wobble(from_position: Vector3, knockback: float) -> void:
  var away := get_knockback_direction(from_position);
  var axis := Vector3.UP.cross(away).normalized();
  var angle := deg_to_rad(WOBBLE_DEGREES) * clampf(knockback / 10.0, 0.3, 1.5);
  var model: Node3D = $Model;
  model.transform.basis = Basis.IDENTITY;
  var tween := create_tween();
  tween.tween_property(model, "transform:basis", Basis(axis, angle), WOBBLE_TIME * 0.25);
  tween.tween_property(model, "transform:basis", Basis.IDENTITY, WOBBLE_TIME * 0.75).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT);
#/_wobble

func _update_label(last_hit: int) -> void:
  _label.text = "Total: %d" % _total_damage if last_hit == 0 else "Hit: %d\nTotal: %d" % [last_hit, _total_damage];
#/_update_label
