extends RigidBody3D
class_name Pickup;

@export var money_value := 0;
@export var health_value := 0;

func _on_pickup_range_body_entered(_body: Node3D) -> void:
  CharStats.CURRENT_MONEY += money_value;
  CharStats.P1_CURRENT_HEALTH += health_value;
  CharStats.P2_CURRENT_HEALTH += health_value;
  #TODO: Glitter effect
  queue_free();
#/_on_pickup_range_body_entered
