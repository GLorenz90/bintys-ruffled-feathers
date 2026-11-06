extends Control

func _process(_delta: float) -> void:
  $MarginContainer/HBoxContainer/Health/Value.text = str(CharStats.P1_CURRENT_HEALTH);
  $MarginContainer/HBoxContainer/Silver/Value.text = str(CharStats.CURRENT_MONEY);
#/_process
