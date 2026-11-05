extends Control
class_name Hud

# Top bar: each player's name and health pips on the outside edges, lives (or deaths) and silver in the middle.
# P2's side only shows once Glinty has joined. A ghost's pips are greyed out.

const PIP_SIZE := Vector2(22, 22);
const PIP_FULL_COLOR := Color(1.0, 0.35, 0.35);
const PIP_EMPTY_COLOR := Color(0.2, 0.2, 0.25, 0.8);
const PIP_GHOST_COLOR := Color(0.6, 0.7, 0.9, 0.5);

@onready var _p1_name: Label = $Bar/P1/Name;
@onready var _p1_pips: HBoxContainer = $Bar/P1/Pips;
@onready var _p2_side: Control = $Bar/P2;
@onready var _p2_name: Label = $Bar/P2/Name;
@onready var _p2_pips: HBoxContainer = $Bar/P2/Pips;
@onready var _lives: Label = $Bar/Center/Lives;
@onready var _silver: Label = $Bar/Center/Silver;

func _process(_delta: float) -> void:
  _update_player(Global.p1_char, _p1_name, _p1_pips);
  _p2_side.visible = Global.p2_char != null;
  if Global.p2_char != null: _update_player(Global.p2_char, _p2_name, _p2_pips);

  if GameState.death_counter_mode:
    _lives.text = "Deaths: %d" % GameState.death_count;
  else:
    _lives.text = "Lives x%d" % GameState.lives;
  #/if
  _silver.text = "Silver: %d" % GameState.money;
#/_process

func _update_player(player: PlayerCharacter, name_label: Label, pips: HBoxContainer) -> void:
  if player == null: return;
  name_label.text = player.name.to_upper() + (" (ghost)" if player.is_ghost() else "");

  var max_health := player.get_max_health();
  while pips.get_child_count() < max_health: pips.add_child(_make_pip());
  while pips.get_child_count() > max_health:
    var extra := pips.get_child(pips.get_child_count() - 1);
    pips.remove_child(extra);
    extra.queue_free();
  #/while

  for i in max_health:
    var pip: ColorRect = pips.get_child(i);
    if player.is_ghost():
      pip.color = PIP_GHOST_COLOR;
    else:
      pip.color = PIP_FULL_COLOR if i < player.get_health() else PIP_EMPTY_COLOR;
    #/if
  #/for
#/_update_player

func _make_pip() -> ColorRect:
  var pip := ColorRect.new();
  pip.custom_minimum_size = PIP_SIZE;
  return pip;
#/_make_pip
