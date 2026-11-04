extends Node

# Global event bus. Systems emit and listen here instead of holding references to each other.

signal end_interaction();
signal player_device_assigned(player_id: int, device_type: int, device_id: int);
