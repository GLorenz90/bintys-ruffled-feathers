extends Node
class_name DeviceManager

# Decides which device each player is using.
# Controllers are handed out in the order they're connected: the first goes to P1, the second to P2.
# With no controller, P1 falls back to the keyboard. (InputManager also lets P1 use the keyboard at any time.)

var UNASSIGNED_DEVICE := {"type": Enums.INPUT_SOURCES.UNASSIGNED, "device_id": -1};

# Player ids are 1 and 2 (not array indexes) so they line up with p1 / p2 everywhere else.
var player_devices := {
  1: UNASSIGNED_DEVICE.duplicate(),
  2: UNASSIGNED_DEVICE.duplicate()
};

#region BUILT-IN ===================================================================================
func _ready() -> void:
  Global.device_manager = self;
  Input.joy_connection_changed.connect(_on_joy_connection_changed);
  _assign_connected_controllers();
#/_ready
#endregion =========================================================================================

#region PUBLIC =====================================================================================
func get_player_device(player_id: int) -> Dictionary:
  return player_devices.get(player_id, UNASSIGNED_DEVICE);
#/get_player_device

func is_player_assigned(player_id: int) -> bool:
  return get_player_device(player_id).type != Enums.INPUT_SOURCES.UNASSIGNED;
#/is_player_assigned

func get_device_label(player_id: int) -> String:
  var device := get_player_device(player_id);
  match device.type:
    Enums.INPUT_SOURCES.CONTROLLER: return "Controller %d" % device.device_id;
    Enums.INPUT_SOURCES.KEYBOARD: return "Keyboard";
    _: return "None";
  #/match
#/get_device_label

# Hands the device that produced this event to a player, unless another player already owns it.
# Not used yet: this is for a future "press a button to join" screen.
func detect_and_assign_device(event: InputEvent, player_id: int) -> bool:
  var device_info := _get_device_info(event);
  if device_info.type == Enums.INPUT_SOURCES.UNASSIGNED: return false;

  var owner_id := _find_owner(device_info.type, device_info.device_id);
  if owner_id != 0: return owner_id == player_id;

  _set_player_device(player_id, device_info.type, device_info.device_id);
  return true;
#/detect_and_assign_device

func unassign_player(player_id: int) -> void:
  if !player_devices.has(player_id): return;
  player_devices[player_id] = UNASSIGNED_DEVICE.duplicate();
  print("Player %d unassigned" % player_id);
#/unassign_player
#endregion =========================================================================================

#region PRIVATE ====================================================================================
func _assign_connected_controllers() -> void:
  var joypads := Input.get_connected_joypads();
  for player_id in player_devices:
    var index: int = player_id - 1;
    if index < joypads.size():
      _set_player_device(player_id, Enums.INPUT_SOURCES.CONTROLLER, joypads[index]);
    elif player_id == 1:
      _set_player_device(player_id, Enums.INPUT_SOURCES.KEYBOARD, -1);
    #/if
  #/for
#/_assign_connected_controllers

func _set_player_device(player_id: int, type: Enums.INPUT_SOURCES, device_id: int) -> void:
  player_devices[player_id] = {"type": type, "device_id": device_id};
  Signals.player_device_assigned.emit(player_id, type, device_id);
  print("Player %d assigned: %s" % [player_id, get_device_label(player_id)]);
#/_set_player_device

# Returns the player id using this device, or 0 if nobody is.
func _find_owner(type: Enums.INPUT_SOURCES, device_id: int) -> int:
  for player_id in player_devices:
    var device: Dictionary = player_devices[player_id];
    if device.type == type && device.device_id == device_id: return player_id;
  #/for
  return 0;
#/_find_owner

func _get_device_info(event: InputEvent) -> Dictionary:
  if event is InputEventKey || event is InputEventMouseButton || event is InputEventMouseMotion:
    return {"type": Enums.INPUT_SOURCES.KEYBOARD, "device_id": -1};
  elif event is InputEventJoypadButton || event is InputEventJoypadMotion:
    return {"type": Enums.INPUT_SOURCES.CONTROLLER, "device_id": event.device};
  #/if
  return UNASSIGNED_DEVICE.duplicate();
#/_get_device_info

# A newly connected controller goes to the first player without one.
# P1 on the keyboard counts as "without one", so plugging in a pad upgrades P1 from keyboard to controller.
func _give_controller_to_open_player(device_id: int) -> void:
  for player_id in player_devices:
    var device: Dictionary = player_devices[player_id];
    if device.type != Enums.INPUT_SOURCES.CONTROLLER:
      _set_player_device(player_id, Enums.INPUT_SOURCES.CONTROLLER, device_id);
      return;
    #/if
  #/for
#/_give_controller_to_open_player
#endregion =========================================================================================

#region SIGNALS ====================================================================================
func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
  print("Controller %d %s" % [device_id, "connected" if connected else "disconnected"]);
  if connected:
    if _find_owner(Enums.INPUT_SOURCES.CONTROLLER, device_id) == 0: _give_controller_to_open_player(device_id);
    return;
  #/if

  var owner_id := _find_owner(Enums.INPUT_SOURCES.CONTROLLER, device_id);
  if owner_id == 1:
    _set_player_device(1, Enums.INPUT_SOURCES.KEYBOARD, -1);
  elif owner_id != 0:
    unassign_player(owner_id);
  #/if
#/_on_joy_connection_changed
#endregion =========================================================================================
