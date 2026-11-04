extends Node
class_name InputManager

@onready var p1_device: Dictionary = Global.device_manager.get_player_device(1);
@onready var p2_device: Dictionary = Global.device_manager.get_player_device(2);

enum INPUTS {
  MOVE_UP_KEYBOARD,
  MOVE_DOWN_KEYBOARD,
  MOVE_LEFT_KEYBOARD,
  MOVE_RIGHT_KEYBOARD,
  JUMP_KEYBOARD,
  ROLL_KEYBOARD,
  ATTACK_KEYBOARD,
  INTERACT_KEYBOARD,
  USE_ITEM_KEYBOARD,
  NEXT_ITEM_KEYBOARD,
  PREV_ITEM_KEYBOARD,

  MOVE_UP_GAMEPAD,
  MOVE_DOWN_GAMEPAD,
  MOVE_LEFT_GAMEPAD,
  MOVE_RIGHT_GAMEPAD,
  JUMP_GAMEPAD,
  ROLL_GAMEPAD,
  ATTACK_GAMEPAD,
  INTERACT_GAMEPAD,
  USE_ITEM_GAMEPAD,
  NEXT_ITEM_GAMEPAD,
  PREV_ITEM_GAMEPAD
}

enum ACTIONS {
  MOVE,
  JUMP,
  ROLL,
  ATTACK,
  INTERACT,
  USE_ITEM,
  NEXT_ITEM,
  PREV_ITEM
}

var template_input_map: Dictionary[INPUTS, InputEvent] = {
  INPUTS.MOVE_UP_KEYBOARD: null,
  INPUTS.MOVE_DOWN_KEYBOARD: null,
  INPUTS.MOVE_LEFT_KEYBOARD: null,
  INPUTS.MOVE_RIGHT_KEYBOARD: null,
  INPUTS.JUMP_KEYBOARD: null,
  INPUTS.ROLL_KEYBOARD: null,
  INPUTS.ATTACK_KEYBOARD: null,
  INPUTS.INTERACT_KEYBOARD: null,
  INPUTS.USE_ITEM_KEYBOARD: null,
  INPUTS.NEXT_ITEM_KEYBOARD: null,
  INPUTS.PREV_ITEM_KEYBOARD: null,

  INPUTS.MOVE_UP_GAMEPAD: null,
  INPUTS.MOVE_DOWN_GAMEPAD: null,
  INPUTS.MOVE_LEFT_GAMEPAD: null,
  INPUTS.MOVE_RIGHT_GAMEPAD: null,
  INPUTS.JUMP_GAMEPAD: null,
  INPUTS.ROLL_GAMEPAD: null,
  INPUTS.ATTACK_GAMEPAD: null,
  INPUTS.INTERACT_GAMEPAD: null,
  INPUTS.USE_ITEM_GAMEPAD: null,
  INPUTS.NEXT_ITEM_GAMEPAD: null,
  INPUTS.PREV_ITEM_GAMEPAD: null
};

# Raw data used to calculate the current state
var template_action_states: Dictionary = {
  ACTIONS.MOVE: Vector2(0.0, 0.0),
  ACTIONS.JUMP: false,
  ACTIONS.ROLL: false,
  ACTIONS.ATTACK: false,
  ACTIONS.INTERACT: false,
  ACTIONS.USE_ITEM: false,
  ACTIONS.NEXT_ITEM: false,
  ACTIONS.PREV_ITEM: false
};

# Buffer that is used in actual scripts
var template_input_buffer: Dictionary = {
  Enums.INPUT_BUFFER.MOVE: Vector2(0.0, 0.0),

  Enums.INPUT_BUFFER.JUMP_PRESSED: false,
  Enums.INPUT_BUFFER.JUMP_HELD: false,
  Enums.INPUT_BUFFER.JUMP_HELD_TIME: 0.0,

  Enums.INPUT_BUFFER.ROLL_PRESSED: false,
  Enums.INPUT_BUFFER.ROLL_HELD: false,
  Enums.INPUT_BUFFER.ROLL_HELD_TIME: 0.0,

  Enums.INPUT_BUFFER.ATTACK_PRESSED: false,
  Enums.INPUT_BUFFER.ATTACK_HELD: false,
  Enums.INPUT_BUFFER.ATTACK_HELD_TIME: 0.0,

  Enums.INPUT_BUFFER.INTERACT_PRESSED: false,
  Enums.INPUT_BUFFER.INTERACT_HELD: false,
  Enums.INPUT_BUFFER.INTERACT_HELD_TIME: 0.0,

  Enums.INPUT_BUFFER.USE_ITEM_PRESSED: false,
  Enums.INPUT_BUFFER.USE_ITEM_HELD: false,
  Enums.INPUT_BUFFER.USE_ITEM_HELD_TIME: 0.0,

  Enums.INPUT_BUFFER.NEXT_ITEM_PRESSED: false,
  Enums.INPUT_BUFFER.NEXT_ITEM_HELD: false,
  Enums.INPUT_BUFFER.NEXT_ITEM_HELD_TIME: 0.0,

  Enums.INPUT_BUFFER.PREV_ITEM_PRESSED: false,
  Enums.INPUT_BUFFER.PREV_ITEM_HELD: false,
  Enums.INPUT_BUFFER.PREV_ITEM_HELD_TIME: 0.0
};

var p1_input_map := template_input_map.duplicate();
var p1_cur_action_state = template_action_states.duplicate();
var p1_prev_action_state = template_action_states.duplicate();
var p1_just_pressed_action_state = template_action_states.duplicate();

var p2_input_map = template_input_map.duplicate();
var p2_cur_action_state = template_action_states.duplicate();
var p2_prev_action_state = template_action_states.duplicate();
var p2_just_pressed_action_state = template_action_states.duplicate();

var p1_input_buffer := template_input_buffer.duplicate();
var p2_input_buffer := template_input_buffer.duplicate();

func _ready() -> void:
  Global.input_manager = self;
  setup_default_controls();
#/_ready

func _physics_process(delta) -> void:
  process_action_state(1);
  process_action_state(2);

  process_input_buffer(1, delta);
  process_input_buffer(2, delta);
#/_physics_process

func setup_default_controls() -> void:
  # Player 1 Keyboard
  set_key_action(1, INPUTS.MOVE_UP_KEYBOARD, KEY_W);
  set_key_action(1, INPUTS.MOVE_DOWN_KEYBOARD, KEY_S);
  set_key_action(1, INPUTS.MOVE_LEFT_KEYBOARD, KEY_A);
  set_key_action(1, INPUTS.MOVE_RIGHT_KEYBOARD, KEY_D);
  set_key_action(1, INPUTS.JUMP_KEYBOARD, KEY_SPACE);
  set_key_action(1, INPUTS.ROLL_KEYBOARD, KEY_CTRL);
  set_key_action(1, INPUTS.ATTACK_KEYBOARD, KEY_Q);
  set_key_action(1, INPUTS.INTERACT_KEYBOARD, KEY_E);
  set_key_action(1, INPUTS.USE_ITEM_KEYBOARD, KEY_F);
  set_key_action(1, INPUTS.NEXT_ITEM_KEYBOARD, KEY_C);
  set_key_action(1, INPUTS.PREV_ITEM_KEYBOARD, KEY_Z);

  # Player 1 Gamepad
  set_joypad_axis_action(1, INPUTS.MOVE_UP_GAMEPAD, JOY_AXIS_LEFT_Y, -1);
  set_joypad_axis_action(1, INPUTS.MOVE_DOWN_GAMEPAD, JOY_AXIS_LEFT_Y, 1);
  set_joypad_axis_action(1, INPUTS.MOVE_LEFT_GAMEPAD, JOY_AXIS_LEFT_X, -1);
  set_joypad_axis_action(1, INPUTS.MOVE_RIGHT_GAMEPAD, JOY_AXIS_LEFT_X, 1);
  set_joypad_button_action(1, INPUTS.JUMP_GAMEPAD, JOY_BUTTON_A);
  set_joypad_button_action(1, INPUTS.ROLL_GAMEPAD, JOY_BUTTON_B);
  set_joypad_button_action(1, INPUTS.ATTACK_GAMEPAD, JOY_BUTTON_X);
  set_joypad_button_action(1, INPUTS.INTERACT_GAMEPAD, JOY_BUTTON_A);
  set_joypad_button_action(1, INPUTS.USE_ITEM_GAMEPAD, JOY_BUTTON_Y);
  set_joypad_button_action(1, INPUTS.NEXT_ITEM_GAMEPAD, JOY_BUTTON_RIGHT_SHOULDER);
  set_joypad_button_action(1, INPUTS.PREV_ITEM_GAMEPAD, JOY_BUTTON_LEFT_SHOULDER);

  # Player 2 Keyboard
  set_key_action(2, INPUTS.MOVE_UP_KEYBOARD, KEY_W);
  set_key_action(2, INPUTS.MOVE_DOWN_KEYBOARD, KEY_S);
  set_key_action(2, INPUTS.MOVE_LEFT_KEYBOARD, KEY_A);
  set_key_action(2, INPUTS.MOVE_RIGHT_KEYBOARD, KEY_D);
  set_key_action(2, INPUTS.JUMP_KEYBOARD, KEY_SPACE);
  set_key_action(2, INPUTS.ROLL_KEYBOARD, KEY_SPACE);
  set_key_action(2, INPUTS.ATTACK_KEYBOARD, KEY_Q);
  set_key_action(2, INPUTS.INTERACT_KEYBOARD, KEY_E);
  set_key_action(2, INPUTS.USE_ITEM_KEYBOARD, KEY_F);
  set_key_action(2, INPUTS.NEXT_ITEM_KEYBOARD, KEY_C);
  set_key_action(2, INPUTS.PREV_ITEM_KEYBOARD, KEY_Z);

  # Player 2 Gamepad
  set_joypad_axis_action(2, INPUTS.MOVE_UP_GAMEPAD, JOY_AXIS_LEFT_Y, -1);
  set_joypad_axis_action(2, INPUTS.MOVE_DOWN_GAMEPAD, JOY_AXIS_LEFT_Y, 1);
  set_joypad_axis_action(2, INPUTS.MOVE_LEFT_GAMEPAD, JOY_AXIS_LEFT_X, -1);
  set_joypad_axis_action(2, INPUTS.MOVE_RIGHT_GAMEPAD, JOY_AXIS_LEFT_X, 1);
  set_joypad_button_action(2, INPUTS.JUMP_GAMEPAD, JOY_BUTTON_A);
  set_joypad_button_action(2, INPUTS.ROLL_GAMEPAD, JOY_BUTTON_B);
  set_joypad_button_action(2, INPUTS.ATTACK_GAMEPAD, JOY_BUTTON_X);
  set_joypad_button_action(2, INPUTS.INTERACT_GAMEPAD, JOY_BUTTON_A);
  set_joypad_button_action(2, INPUTS.USE_ITEM_GAMEPAD, JOY_BUTTON_Y);
  set_joypad_button_action(2, INPUTS.NEXT_ITEM_GAMEPAD, JOY_BUTTON_RIGHT_SHOULDER);
  set_joypad_button_action(2, INPUTS.PREV_ITEM_GAMEPAD, JOY_BUTTON_LEFT_SHOULDER);
#/setup_default_controls

func process_action_state(player: int) -> void:
  var player_cur_action_state = p1_cur_action_state if player == 1 else p2_cur_action_state;
  var player_prev_action_state = p1_prev_action_state if player == 1 else p2_prev_action_state;
  var player_just_pressed_action_state = p1_just_pressed_action_state if player == 1 else p2_just_pressed_action_state;

  player_prev_action_state = player_cur_action_state.duplicate();

  var movement_x = clampf(get_axis(player, INPUTS.MOVE_LEFT_KEYBOARD, INPUTS.MOVE_RIGHT_KEYBOARD) + get_axis(player, INPUTS.MOVE_LEFT_GAMEPAD, INPUTS.MOVE_RIGHT_GAMEPAD), -1.0, 1.0);
  var movement_y = clampf(get_axis(player, INPUTS.MOVE_UP_KEYBOARD, INPUTS.MOVE_DOWN_KEYBOARD) + get_axis(player, INPUTS.MOVE_UP_GAMEPAD, INPUTS.MOVE_DOWN_GAMEPAD), -1.0, 1.0);
  player_cur_action_state[ACTIONS.MOVE] = Vector2(movement_x, movement_y);

  var attack_pressed = is_action_pressed(player, INPUTS.ATTACK_KEYBOARD) || is_action_pressed(player, INPUTS.ATTACK_GAMEPAD);
  var jump_pressed = is_action_pressed(player, INPUTS.JUMP_KEYBOARD) || is_action_pressed(player, INPUTS.JUMP_GAMEPAD);
  var roll_pressed = is_action_pressed(player, INPUTS.ROLL_KEYBOARD) || is_action_pressed(player, INPUTS.ROLL_GAMEPAD);
  var interact_pressed = is_action_pressed(player, INPUTS.INTERACT_KEYBOARD) || is_action_pressed(player, INPUTS.INTERACT_GAMEPAD);
  var use_item_pressed = is_action_pressed(player, INPUTS.USE_ITEM_KEYBOARD) || is_action_pressed(player, INPUTS.USE_ITEM_GAMEPAD);
  var next_item_pressed = is_action_pressed(player, INPUTS.NEXT_ITEM_KEYBOARD) || is_action_pressed(player, INPUTS.NEXT_ITEM_GAMEPAD);
  var prev_item_pressed = is_action_pressed(player, INPUTS.PREV_ITEM_KEYBOARD) || is_action_pressed(player, INPUTS.PREV_ITEM_GAMEPAD);

  player_cur_action_state[ACTIONS.ATTACK] = attack_pressed;
  player_cur_action_state[ACTIONS.JUMP] = jump_pressed;
  player_cur_action_state[ACTIONS.ROLL] = roll_pressed;
  player_cur_action_state[ACTIONS.INTERACT] = interact_pressed;
  player_cur_action_state[ACTIONS.USE_ITEM] = use_item_pressed;
  player_cur_action_state[ACTIONS.NEXT_ITEM] = next_item_pressed;
  player_cur_action_state[ACTIONS.PREV_ITEM] = prev_item_pressed;

  player_just_pressed_action_state[ACTIONS.ATTACK] = attack_pressed && !player_prev_action_state[ACTIONS.ATTACK];
  player_just_pressed_action_state[ACTIONS.JUMP] = jump_pressed && !player_prev_action_state[ACTIONS.JUMP];
  player_just_pressed_action_state[ACTIONS.ROLL] = roll_pressed && !player_prev_action_state[ACTIONS.ROLL];
  player_just_pressed_action_state[ACTIONS.INTERACT] = interact_pressed && !player_prev_action_state[ACTIONS.INTERACT];
  player_just_pressed_action_state[ACTIONS.USE_ITEM] = use_item_pressed && !player_prev_action_state[ACTIONS.USE_ITEM];
  player_just_pressed_action_state[ACTIONS.NEXT_ITEM] = next_item_pressed && !player_prev_action_state[ACTIONS.NEXT_ITEM];
  player_just_pressed_action_state[ACTIONS.PREV_ITEM] = prev_item_pressed && !player_prev_action_state[ACTIONS.PREV_ITEM];
#/process_action_state

func process_input_buffer(player: int, delta: float) -> void:
  var prev_player_input_buffer = p1_input_buffer if player == 1 else p2_input_buffer;
  var player_cur_action_state = p1_cur_action_state if player == 1 else p2_cur_action_state;
  var player_just_pressed_action_state = p1_just_pressed_action_state if player == 1 else p2_just_pressed_action_state;

  var player_input_buffer = {
    Enums.INPUT_BUFFER.MOVE: player_cur_action_state[ACTIONS.MOVE],
    Enums.INPUT_BUFFER.JUMP_PRESSED: player_just_pressed_action_state[ACTIONS.JUMP],
    Enums.INPUT_BUFFER.JUMP_HELD: player_cur_action_state[ACTIONS.JUMP],
    Enums.INPUT_BUFFER.JUMP_HELD_TIME: (prev_player_input_buffer[Enums.INPUT_BUFFER.JUMP_HELD_TIME] + delta) if player_cur_action_state[ACTIONS.JUMP] else 0.0,
    Enums.INPUT_BUFFER.ROLL_PRESSED: player_just_pressed_action_state[ACTIONS.ROLL],
    Enums.INPUT_BUFFER.ROLL_HELD: player_cur_action_state[ACTIONS.ROLL],
    Enums.INPUT_BUFFER.ROLL_HELD_TIME: (prev_player_input_buffer[Enums.INPUT_BUFFER.ROLL_HELD_TIME] + delta) if player_cur_action_state[ACTIONS.ROLL] else 0.0,
    Enums.INPUT_BUFFER.ATTACK_PRESSED: player_just_pressed_action_state[ACTIONS.ATTACK],
    Enums.INPUT_BUFFER.ATTACK_HELD: player_cur_action_state[ACTIONS.ATTACK],
    Enums.INPUT_BUFFER.ATTACK_HELD_TIME: (prev_player_input_buffer[Enums.INPUT_BUFFER.ATTACK_HELD_TIME] + delta) if player_cur_action_state[ACTIONS.ATTACK] else 0.0,
    Enums.INPUT_BUFFER.INTERACT_PRESSED: player_just_pressed_action_state[ACTIONS.INTERACT],
    Enums.INPUT_BUFFER.INTERACT_HELD: player_cur_action_state[ACTIONS.INTERACT],
    Enums.INPUT_BUFFER.INTERACT_HELD_TIME: (prev_player_input_buffer[Enums.INPUT_BUFFER.INTERACT_HELD_TIME] + delta) if player_cur_action_state[ACTIONS.INTERACT] else 0.0,
    Enums.INPUT_BUFFER.USE_ITEM_PRESSED: player_just_pressed_action_state[ACTIONS.USE_ITEM],
    Enums.INPUT_BUFFER.USE_ITEM_HELD: player_cur_action_state[ACTIONS.USE_ITEM],
    Enums.INPUT_BUFFER.USE_ITEM_HELD_TIME: (prev_player_input_buffer[Enums.INPUT_BUFFER.USE_ITEM_HELD_TIME] + delta) if player_cur_action_state[ACTIONS.USE_ITEM] else 0.0,
    Enums.INPUT_BUFFER.NEXT_ITEM_PRESSED: player_just_pressed_action_state[ACTIONS.NEXT_ITEM],
    Enums.INPUT_BUFFER.NEXT_ITEM_HELD: player_cur_action_state[ACTIONS.NEXT_ITEM],
    Enums.INPUT_BUFFER.NEXT_ITEM_HELD_TIME: (prev_player_input_buffer[Enums.INPUT_BUFFER.NEXT_ITEM_HELD_TIME] + delta) if player_cur_action_state[ACTIONS.NEXT_ITEM] else 0.0,
    Enums.INPUT_BUFFER.PREV_ITEM_PRESSED: player_just_pressed_action_state[ACTIONS.PREV_ITEM],
    Enums.INPUT_BUFFER.PREV_ITEM_HELD: player_cur_action_state[ACTIONS.PREV_ITEM],
    Enums.INPUT_BUFFER.PREV_ITEM_HELD_TIME: (prev_player_input_buffer[Enums.INPUT_BUFFER.PREV_ITEM_HELD_TIME] + delta) if player_cur_action_state[ACTIONS.PREV_ITEM] else 0.0
  };

  if(player == 1):
    p1_input_buffer = player_input_buffer;
  else:
    p2_input_buffer = player_input_buffer;
#/process_input_buffer

#region INPUT UTILS
func set_key_action(player: int, action: INPUTS, keycode: Key) -> void:
  var player_input_map = p1_input_map if player == 1 else p2_input_map;
  var event := InputEventKey.new();
  event.keycode = keycode;

  player_input_map[action] = event;
#/set_key_action

func set_joypad_button_action(player: int, action: INPUTS, button: JoyButton) -> void:
  var player_input_map = p1_input_map if player == 1 else p2_input_map;
  var event := InputEventJoypadButton.new();
  event.button_index = button;
  event.device = p1_device.device_id if player == 1 else p2_device.device_id;

  player_input_map[action] = event;
#/set_joypad_button_action

func set_joypad_axis_action(player: int, action: INPUTS, axis: JoyAxis, axis_value: float) -> void:
  var player_input_map = p1_input_map if player == 1 else p2_input_map;
  var event := InputEventJoypadMotion.new();
  event.axis = axis;
  event.axis_value = axis_value;
  event.device = p1_device.device_id if player == 1 else p2_device.device_id;

  player_input_map[action] = event;
#/set_joypad_axis_action

func clear_action(player: int, action: INPUTS) -> void:
  var player_input_map = p1_input_map if player == 1 else p2_input_map;
  player_input_map[action] = null;
#/clear_action

func is_action_pressed(player: int, action: INPUTS) -> bool:
  var player_device = p1_device if player == 1 else p2_device;
  var player_input_map = p1_input_map if player == 1 else p2_input_map;

  if !player_input_map.has(action) || player_input_map[action] == null:
    return false;
  #/if

  var event = player_input_map[action];

  if event is InputEventKey && player_device.type == Enums.INPUT_SOURCES.KEYBOARD:
    return Input.is_key_pressed(event.keycode);
  elif event is InputEventJoypadButton && player_device.type == Enums.INPUT_SOURCES.CONTROLLER:
    return Input.is_joy_button_pressed(player_device.device_id, event.button_index);
  elif event is InputEventJoypadMotion && player_device.type == Enums.INPUT_SOURCES.CONTROLLER:
    var axis_val := Input.get_joy_axis(player_device.device_id, player_input_map[action].axis);
    return abs(axis_val) >= Settings.stick_deadzone;
  #/if

  return false;
#/is_action_pressed

func get_axis(player: int, negative_action: INPUTS, positive_action: INPUTS) -> float:
  var player_device = p1_device if player == 1 else p2_device;
  var player_input_map = p1_input_map if player == 1 else p2_input_map;

  if !player_input_map.has(negative_action) || !player_input_map.has(positive_action):
    return 0.0;
  #/if

  var neg_event = player_input_map[negative_action];
  var pos_event = player_input_map[positive_action];

  var neg_value = 0.0;
  var pos_value = 0.0;

  if neg_event is InputEventKey && player_device.type == Enums.INPUT_SOURCES.KEYBOARD:
    neg_value = -1.0 if Input.is_key_pressed(neg_event.keycode) else 0.0;
  elif neg_event is InputEventJoypadButton && player_device.type == Enums.INPUT_SOURCES.CONTROLLER:
    neg_value =  -1.0 if Input.is_joy_button_pressed(player_device.device_id, neg_event.button_index) else 0.0;
  elif neg_event is InputEventJoypadMotion && player_device.type == Enums.INPUT_SOURCES.CONTROLLER:
    var axis_val := Input.get_joy_axis(player_device.device_id, neg_event.axis);
    neg_value = axis_val if sign(axis_val) == sign(neg_event.axis_value) && abs(axis_val) >= Settings.stick_deadzone else 0.0;
  #/if

  if pos_event is InputEventKey && player_device.type == Enums.INPUT_SOURCES.KEYBOARD:
    pos_value = 1.0 if Input.is_key_pressed(pos_event.keycode) else 0.0;
  elif pos_event is InputEventJoypadButton && player_device.type == Enums.INPUT_SOURCES.CONTROLLER:
    pos_value =  1.0 if Input.is_joy_button_pressed(player_device.device_id, pos_event.button_index) else 0.0;
  elif pos_event is InputEventJoypadMotion && player_device.type == Enums.INPUT_SOURCES.CONTROLLER:
    var axis_val := Input.get_joy_axis(player_device.device_id, pos_event.axis);
    pos_value = axis_val if sign(axis_val) == sign(pos_event.axis_value) && abs(axis_val) >= Settings.stick_deadzone else 0.0;
  #/if
  return pos_value + neg_value;
#/get_axis
#endregion
