extends Node
class_name DeathManager

# Decides what happens when a player dies. The rules (design doc, section 6):
#
#   Partner still alive (co-op)   -> become a ghost. No life lost. Revived when the partner touches a checkpoint.
#   Nobody left alive             -> everyone is down:
#       Death Counter mode        -> Death's scene, then everyone respawns at the checkpoint. Deaths are counted.
#       Lives left                -> lose a life, Death's scene, respawn at the checkpoint.
#       Last life, first time     -> Death: "That's it, kid." Choose: keep lives (start the level over)
#                                    or switch to the Death Counter (carry on from the checkpoint).
#       Last life, after that     -> game over: the level starts over with full lives.
#
# Every death, ghost or not, adds to GameState.death_count.

@export var death_screen: DeathScreen;

var _handling_wipe := false;

func _ready() -> void:
  Signals.player_died.connect(_on_player_died);
  Signals.checkpoint_reached.connect(_on_checkpoint_reached);
#/_ready

#region SIGNALS ====================================================================================
func _on_player_died(player: PlayerCharacter) -> void:
  GameState.count_death();
  var partner := player.get_partner();
  if partner != null && partner.is_alive():
    player.become_ghost();
    return;
  #/if
  _handle_wipe.call_deferred();
#/_on_player_died

func _on_checkpoint_reached(checkpoint: Checkpoint, player: PlayerCharacter) -> void:
  var partner := player.get_partner();
  if partner != null && partner.is_ghost():
    partner.revive_at(checkpoint.get_spawn_transform(partner.get_player_id()));
  #/if
#/_on_checkpoint_reached
#endregion =========================================================================================

#region PRIVATE ====================================================================================
func _handle_wipe() -> void:
  if _handling_wipe: return;
  _handling_wipe = true;

  if GameState.death_counter_mode:
    await death_screen.show_death(DeathScreen.LINES.ORDINARY);
    _respawn_everyone();
  elif !GameState.lose_life():
    await death_screen.show_death(DeathScreen.LINES.ORDINARY);
    _respawn_everyone();
  elif !GameState.has_seen_last_life_offer:
    GameState.has_seen_last_life_offer = true;
    var choice: DeathScreen.CHOICES = await death_screen.show_last_life_offer();
    if choice == DeathScreen.CHOICES.DEATH_COUNTER:
      GameState.set_death_counter_mode(true);
      _respawn_everyone();
    else:
      _game_over();
    #/if
  else:
    await death_screen.show_death(DeathScreen.LINES.GAME_OVER);
    _game_over();
  #/if

  _handling_wipe = false;
#/_handle_wipe

func _respawn_everyone() -> void:
  for player in [Global.p1_char, Global.p2_char]:
    if player != null: player.revive_at(Global.main.get_spawn_transform(player.get_player_id()));
  #/for
#/_respawn_everyone

func _game_over() -> void:
  GameState.reset_lives();
  GameState.clear_checkpoint();
  Global.main.restart_level();
#/_game_over
#endregion =========================================================================================
