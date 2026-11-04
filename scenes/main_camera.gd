extends Node3D

var target: PlayerCharacter;

func _ready() -> void:
  if Global.p1_char != null:
    target = Global.p1_char;
#/_ready

func _process(delta: float) -> void:
  if !target && Global.p1_char != null:
    target = Global.p1_char;
  
  if target:
    var new_position: Vector3 = lerp(global_position, target.global_position, delta * 4);
    global_position = new_position;
#/_process
