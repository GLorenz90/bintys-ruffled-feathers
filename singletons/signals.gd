extends Node

# Global event bus. Systems emit and listen here instead of holding references to each other.

#region INPUT ==================================================================
signal player_device_assigned(player_id: int, device_type: int, device_id: int);
#endregion =====================================================================

#region PLAYERS ================================================================
signal end_interaction();
signal player_health_changed(player: PlayerCharacter, health: int);
signal player_died(player: PlayerCharacter);
signal player_revived(player: PlayerCharacter);
signal player_spawned(player: PlayerCharacter);
#endregion =====================================================================

#region GAME STATE =============================================================
signal lives_changed(lives: int);
signal death_count_changed(death_count: int);
signal death_counter_mode_changed(enabled: bool);
signal money_changed(money: int);
signal checkpoint_reached(checkpoint: Checkpoint, player: PlayerCharacter);
#endregion =====================================================================
