extends RefCounted
class_name PlayerState

# One thing a player can be doing. Exactly one state runs at a time.
#
#   enter()          runs once when the player switches into this state
#   physics_update() runs every physics frame while it's active
#   exit()           runs once when the player switches out
#
# Each state's physics_update starts with its transitions ("what can I do from here?"),
# then does its movement. The player calls move_and_slide() afterwards, so states only set velocity.

var player: PlayerCharacter;
var time_in_state := 0.0;

func _init(owner_player: PlayerCharacter) -> void:
  player = owner_player;
#/_init

func enter(_previous: Enums.PLAYER_STATES) -> void:
  pass;
#/enter

func exit(_next: Enums.PLAYER_STATES) -> void:
  pass;
#/exit

func physics_update(_delta: float) -> void:
  pass;
#/physics_update
