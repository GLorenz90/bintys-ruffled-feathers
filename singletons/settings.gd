extends Node

# Player-facing options, saved to user://settings.cfg.

#region CONSTANTS ==============================================================
const SETTINGS_FILE_PATH := "user://settings.cfg";

const DEFAULT_MASTER_VOLUME := 50.0;
const DEFAULT_MUSIC_VOLUME := 50.0;
const DEFAULT_EFFECTS_VOLUME := 50.0;
const DEFAULT_ANTIALIASING := Viewport.MSAA_4X;
const DEFAULT_STICK_DEADZONE := 0.25;

const ANTIALIASING_OPTIONS := [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X];
#endregion =====================================================================

#region SETTINGS ===============================================================
var master_volume := DEFAULT_MASTER_VOLUME;
var music_volume := DEFAULT_MUSIC_VOLUME;
var effects_volume := DEFAULT_EFFECTS_VOLUME;
var antialiasing: Viewport.MSAA = DEFAULT_ANTIALIASING;
var stick_deadzone := DEFAULT_STICK_DEADZONE;
#endregion =====================================================================

var _config := ConfigFile.new();

func _init() -> void:
  load_settings_file();
#/_init

#region FUNCTIONS ==============================================================
func save_settings_file() -> void:
  _config.set_value("audio", "master_volume", master_volume);
  _config.set_value("audio", "music_volume", music_volume);
  _config.set_value("audio", "effects_volume", effects_volume);
  _config.set_value("visual", "antialiasing", antialiasing);
  _config.set_value("input", "stick_deadzone", stick_deadzone);
  _config.save(SETTINGS_FILE_PATH);

  apply_all();
#/save_settings_file

func load_settings_file() -> void:
  if _config.load(SETTINGS_FILE_PATH) == OK:
    master_volume = _config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME);
    music_volume = _config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME);
    effects_volume = _config.get_value("audio", "effects_volume", DEFAULT_EFFECTS_VOLUME);
    antialiasing = _config.get_value("visual", "antialiasing", DEFAULT_ANTIALIASING);
    stick_deadzone = _config.get_value("input", "stick_deadzone", DEFAULT_STICK_DEADZONE);
  #/if

  update_audio_buses();
#/load_settings_file

func reset_to_default() -> void:
  master_volume = DEFAULT_MASTER_VOLUME;
  music_volume = DEFAULT_MUSIC_VOLUME;
  effects_volume = DEFAULT_EFFECTS_VOLUME;
  antialiasing = DEFAULT_ANTIALIASING;
  stick_deadzone = DEFAULT_STICK_DEADZONE;

  apply_all();
#/reset_to_default

func apply_all() -> void:
  update_audio_buses();
  update_visual_settings();
#/apply_all

# Music and Effects are scaled by Master, so turning Master down turns everything down.
func update_audio_buses() -> void:
  var master_ratio := master_volume / 100.0;
  _set_bus_volume("Master", master_ratio);
  _set_bus_volume("Music", (music_volume / 100.0) * master_ratio);
  _set_bus_volume("Effects", (effects_volume / 100.0) * master_ratio);
#/update_audio_buses

func update_visual_settings() -> void:
  # Main isn't around until the game scene loads; Main calls this itself once it's ready.
  if Global.main == null: return;
  for game_viewport in Global.main.get_game_viewports(): game_viewport.msaa_3d = antialiasing;
#/update_visual_settings

func _set_bus_volume(bus_name: String, ratio: float) -> void:
  var bus_index := AudioServer.get_bus_index(bus_name);
  if bus_index == -1: return;
  AudioServer.set_bus_volume_db(bus_index, linear_to_db(ratio));
#/_set_bus_volume
#endregion =====================================================================
