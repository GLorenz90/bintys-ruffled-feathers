extends Control
class_name Hud

# Top bar: each player's name and health pips on the outside edges, lives (or deaths) and silver in the middle.
# P2's side only shows once Glinty has joined. A ghost's pips are greyed out.

const PIP_SIZE := Vector2(22, 22);
const PIP_FULL_COLOR := Color(1.0, 0.35, 0.35);
const PIP_EMPTY_COLOR := Color(0.2, 0.2, 0.25, 0.8);
const PIP_GHOST_COLOR := Color(0.6, 0.7, 0.9, 0.5);
const AIR_BAR_SIZE := Vector2(150, 8);
const AIR_BAR_COLOR := Color(0.4, 0.8, 1.0);

@onready var _p1_name: Label = $Bar/P1/Name;
@onready var _p1_pips: HBoxContainer = $Bar/P1/Pips;
@onready var _p2_side: Control = $Bar/P2;
@onready var _p2_name: Label = $Bar/P2/Name;
@onready var _p2_pips: HBoxContainer = $Bar/P2/Pips;
@onready var _lives: Label = $Bar/Center/Lives;
@onready var _silver: Label = $Bar/Center/Silver;
@onready var _p1_air: ProgressBar = _make_air_bar($Bar/P1);
@onready var _p2_air: ProgressBar = _make_air_bar($Bar/P2);

func _process(_delta: float) -> void:
  _update_player(Global.p1_char, _p1_name, _p1_pips, _p1_air);
  _p2_side.visible = Global.p2_char != null;
  if Global.p2_char != null: _update_player(Global.p2_char, _p2_name, _p2_pips, _p2_air);

  if GameState.death_counter_mode:
    _lives.text = "Deaths: %d" % GameState.death_count;
  else:
    _lives.text = "Lives x%d" % GameState.lives;
  #/if
  _silver.text = "Silver: %d" % GameState.money;
#/_process

func _update_player(player: PlayerCharacter, name_label: Label, pips: HBoxContainer, air_bar: ProgressBar) -> void:
  if player == null: return;
  air_bar.visible = player.env != null && player.env.air < CharStats.AIR_MAX;
  if air_bar.visible: air_bar.value = player.env.air / CharStats.AIR_MAX;
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

# A thin bar under the health pips, shown only while some air has been used.
func _make_air_bar(side: Control) -> ProgressBar:
  var bar := ProgressBar.new();
  bar.custom_minimum_size = AIR_BAR_SIZE;
  bar.max_value = 1.0;
  bar.show_percentage = false;
  bar.size_flags_horizontal = Control.SIZE_SHRINK_END if side.name == "P2" else Control.SIZE_SHRINK_BEGIN;
  var fill := StyleBoxFlat.new();
  fill.bg_color = AIR_BAR_COLOR;
  bar.add_theme_stylebox_override("fill", fill);
  bar.visible = false;
  side.add_child(bar);
  return bar;
#/_make_air_bar

func _make_pip() -> ColorRect:
  var pip := ColorRect.new();
  pip.custom_minimum_size = PIP_SIZE;
  return pip;
#/_make_pip
