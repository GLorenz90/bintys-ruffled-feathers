extends CanvasLayer
class_name PauseMenu

# Escape (keyboard) or Start (any controller) pauses. Holds the options, starting with the
# Death Counter switch. Navigate with the arrow keys / d-pad, confirm with Enter / A.

@export var death_screen: DeathScreen;

@onready var _resume_button: Button = $Panel/Content/Resume;
@onready var _death_counter_toggle: CheckButton = $Panel/Content/DeathCounter;
@onready var _quit_button: Button = $Panel/Content/Quit;

func _ready() -> void:
  process_mode = Node.PROCESS_MODE_ALWAYS;
  visible = false;
  _resume_button.pressed.connect(close);
  _death_counter_toggle.toggled.connect(GameState.set_death_counter_mode);
  _quit_button.pressed.connect(func(): get_tree().quit());
#/_ready

func _input(event: InputEvent) -> void:
  var pressed_pause: bool = (event is InputEventKey && event.pressed && !event.echo && event.keycode == KEY_ESCAPE) \
    || (event is InputEventJoypadButton && event.pressed && event.button_index == JOY_BUTTON_START);
  if !pressed_pause: return;
  get_viewport().set_input_as_handled();
  if visible:
    close();
  elif death_screen == null || !death_screen.is_showing():
    open();
  #/if
#/_input

func open() -> void:
  _death_counter_toggle.set_pressed_no_signal(GameState.death_counter_mode);
  visible = true;
  get_tree().paused = true;
  _resume_button.grab_focus();
#/open

func close() -> void:
  visible = false;
  get_tree().paused = false;
#/close
