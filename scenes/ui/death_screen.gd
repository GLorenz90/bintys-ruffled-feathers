extends CanvasLayer
class_name DeathScreen

# Placeholder "meeting Death" scenes. The real scenes (and Death's real lines) come in M9;
# until then this is a panel with a line of text. The game is paused while it's up.

enum LINES { ORDINARY, LAST_LIFE, GAME_OVER }
enum CHOICES { KEEP_LIVES, DEATH_COUNTER }

signal choice_made(choice: CHOICES);

# Placeholder lines, to be written properly in M9.
const LINE_TEXT := {
  LINES.ORDINARY: "\"Back so soon?\"",
  LINES.LAST_LIFE: "\"That's it, kid.\"",
  LINES.GAME_OVER: "\"Out of lives. From the top.\"",
};
const LAST_LIFE_EXPLANATION := "You're out of lives. Keep them and start the level over,\nor let Death just count how many times you die from now on.";

@onready var _line: Label = $Panel/Content/Line;
@onready var _explanation: Label = $Panel/Content/Explanation;
@onready var _choices: Control = $Panel/Content/Choices;
@onready var _keep_lives_button: Button = $Panel/Content/Choices/KeepLives;
@onready var _death_counter_button: Button = $Panel/Content/Choices/DeathCounter;

func _ready() -> void:
  process_mode = Node.PROCESS_MODE_ALWAYS;
  visible = false;
  _keep_lives_button.pressed.connect(func(): choice_made.emit(CHOICES.KEEP_LIVES));
  _death_counter_button.pressed.connect(func(): choice_made.emit(CHOICES.DEATH_COUNTER));
#/_ready

func is_showing() -> bool:
  return visible;
#/is_showing

# Shows a line for DEATH_SCREEN_TIME, then hides. Await it.
func show_death(line: LINES) -> void:
  _open(line, false);
  await get_tree().create_timer(CharStats.DEATH_SCREEN_TIME, true, false, true).timeout;
  _close();
#/show_death

# The first time the last life is lost. Await it to get the player's choice.
func show_last_life_offer() -> CHOICES:
  _open(LINES.LAST_LIFE, true);
  _death_counter_button.grab_focus();
  var choice: CHOICES = await choice_made;
  _close();
  return choice;
#/show_last_life_offer

func _open(line: LINES, with_choices: bool) -> void:
  _line.text = LINE_TEXT[line];
  _explanation.text = LAST_LIFE_EXPLANATION;
  _explanation.visible = with_choices;
  _choices.visible = with_choices;
  visible = true;
  get_tree().paused = true;
#/_open

func _close() -> void:
  visible = false;
  get_tree().paused = false;
#/_close
