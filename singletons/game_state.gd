extends Node

# The values that change while you play: lives, deaths, money, the last checkpoint.
# CharStats holds the tuning numbers; this holds where this playthrough is right now.
# Anything that changes here announces it through Signals so the HUD can update.

#region LIVES AND DEATHS =======================================================
var lives := CharStats.STARTING_LIVES;
var death_count := 0;                    # Every time a player dies, in either mode.
var death_counter_mode := false;         # On: lives don't matter, deaths are counted instead. Toggle in the pause menu.
var has_seen_last_life_offer := false;   # Death only offers the Death Counter the first time you run out.
#endregion =====================================================================

#region PROGRESS ===============================================================
var money := 0;
var current_checkpoint: Checkpoint = null; # null = the level's own spawn points.
#endregion =====================================================================

#region FUNCTIONS ==============================================================
func add_money(amount: int) -> void:
  money += amount;
  Signals.money_changed.emit(money);
#/add_money

func add_life() -> void:
  lives = mini(lives + 1, CharStats.MAX_LIVES);
  Signals.lives_changed.emit(lives);
#/add_life

# Returns true if that was the last life.
func lose_life() -> bool:
  lives = maxi(lives - 1, 0);
  Signals.lives_changed.emit(lives);
  return lives == 0;
#/lose_life

func reset_lives() -> void:
  lives = CharStats.STARTING_LIVES;
  Signals.lives_changed.emit(lives);
#/reset_lives

func count_death() -> void:
  death_count += 1;
  Signals.death_count_changed.emit(death_count);
#/count_death

# Turning it back off with no lives left gives you a fresh set, so you aren't one hit from game over.
func set_death_counter_mode(enabled: bool) -> void:
  death_counter_mode = enabled;
  if !enabled && lives == 0: reset_lives();
  Signals.death_counter_mode_changed.emit(enabled);
#/set_death_counter_mode

func set_checkpoint(checkpoint: Checkpoint) -> void:
  if current_checkpoint == checkpoint: return;
  if current_checkpoint != null: current_checkpoint.set_active(false);
  current_checkpoint = checkpoint;
  checkpoint.set_active(true);
#/set_checkpoint

# A new level starts from its own spawn points.
func clear_checkpoint() -> void:
  current_checkpoint = null;
#/clear_checkpoint
#endregion =====================================================================
