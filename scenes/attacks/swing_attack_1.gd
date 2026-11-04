extends Attack

## Relative amount of swing, with positive being counter clockwise
@export var swing_arc_degrees := 160.0;

func _on_attack_start() -> void:
  var tween := create_tween();
  var final_degrees = effect.rotation_degrees.y + swing_arc_degrees;
  tween.tween_property(effect, "rotation_degrees:y", final_degrees, lifetime);
#/_on_attack_start
