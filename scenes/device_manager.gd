extends Node
class_name DeviceManager

# Track which devices are already assigned
var assigned_devices := [];

# Player device assignments, We use 1 and 2, not 0 and 1 as an array because of the player id later, and how we set it in input manager
var player_devices := {
  1: {"type": Enums.INPUT_SOURCES.CONTROLLER, "device_id": 0},
  2: {"type": Enums.INPUT_SOURCES.CONTROLLER, "device_id": 0}
}

#region BUILT-IN ===================================================================================
func _ready() -> void:
  Global.device_manager = self;
  Input.joy_connection_changed.connect(_on_joy_connection_changed);

  print("p1_device: T:" + Enums.INPUT_SOURCES.keys()[player_devices[1].type] + " IDX:" + str(player_devices[1].device_id));
  print("p2_device: T:" + Enums.INPUT_SOURCES.keys()[player_devices[2].type] + " IDX:" + str(player_devices[2].device_id));
# end _ready

#region FUNCTIONS ==================================================================================
func detect_and_assign_device(event: InputEvent, player_id: int) -> bool:
  var device_info := get_device_info(event);

  if device_info.type == Enums.INPUT_SOURCES.UNASSIGNED:
    return false;

  # Check if this device is already assigned to another player
  var device_signature := "%s_%d" % [device_info.type, device_info.device_id];
  if device_signature in assigned_devices:
    # Find which player has this device
    for pid in player_devices:
      if player_devices[pid].type == device_info.type and \
         player_devices[pid].device_id == device_info.device_id:
        # Only return true if it matches the requesting player
        return pid == player_id;
    return false;

  # Assign the device to the player
  player_devices[player_id] = device_info;
  assigned_devices.append(device_signature);
  Signals.player_device_assigned.emit(player_id, device_info.type, device_info.device_id);

  print("Player %d assigned: %s (ID: %d)" % [player_id, str(device_info.type), device_info.device_id]);
  return true;
# end detect_and_assign_device

func unassign_player(player_id: int) -> void:
  if not player_devices.has(player_id):
    return;

  var device = player_devices[player_id];
  if device.type != Enums.INPUT_SOURCES.UNASSIGNED:
    var device_signature := "%s_%d" % [str(device.type), device.device_id];
    assigned_devices.erase(device_signature);

  player_devices[player_id] = {"type": Enums.INPUT_SOURCES.UNASSIGNED, "device_id": -1};
  print("Player " + str(player_id) + " unassigned");
# end unassign_player

func get_device_info(event: InputEvent) -> Dictionary:
  var info := {"type": Enums.INPUT_SOURCES.UNASSIGNED, "device_id": -1};

  if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
    info.type = Enums.INPUT_SOURCES.KEYBOARD;
    info.device_id = -1;  # Keyboard is always device -1

  elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
    info.type = Enums.INPUT_SOURCES.CONTROLLER;
    info.device_id = event.device;

  return info;
# end get_device_info

func get_player_device(player_id: int) -> Dictionary:
  return player_devices.get(player_id, {"type": Enums.INPUT_SOURCES.UNASSIGNED, "device_id": -1});
# end get_player_device

func is_player_assigned(player_id: int) -> bool:
  return player_devices.get(player_id, {}).get("type", Enums.INPUT_SOURCES.UNASSIGNED) != Enums.INPUT_SOURCES.UNASSIGNED;
# end is_player_assigned
#endregion

#region SIGNALS ====================================================================================
func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
  print("Connection Changed- ID:" + str(device_id) + " - Connected:" + str(connected));
  if not connected:
    # Unassign any player using this controller
    for player_id in player_devices:
      var device = player_devices[player_id];
      if device.type == Enums.INPUT_SOURCES.CONTROLLER and device.device_id == device_id:
        unassign_player(player_id);
      # end if
    # end for
  # end if
# end _on_joy_connection_changed
#endregion
