extends Node

#region CONSTANTS ==============================================================
const MAX_VELOCITY := 50.0;
const MAX_COYOTE_TIME := 0.15;
const MAX_INPUT_BUFFER_TIME := 0.2;

const BASE_WALK_SPEED := 6;
const BASE_ROLL_SPEED := 18.0;
const BASE_JUMP_TIME := 0.08;
const BASE_JUMP_VELOCITY := 15.0;
const BASE_HURT_VELOCITY := 18.0;
const BASE_MAX_HEALTH := 6;

const HURT_TIME := .75;
const INVULN_TIME := 2.0;
const HURT_KNOCKBACK_SPEED := 8.0;
const ROLL_TIME := 0.3;

# duration -1 means cannot be interrupted, and lasts forever. INF means it can always be interrupted
var ACTION_RULES = {
  # Neutral States
  Enums.CHAR_STATES.INIT:       { flag = null, move = 0.0, ground_only = false,  turn = false, attack = false, roll = false, jump = false, interrupt_after = -1.0,            state_duration = INF },
  Enums.CHAR_STATES.FREE:       { flag = null, move = 1.0, ground_only = true,   turn = true,  attack = true,  roll = true,  jump = true,  interrupt_after = 0.0,             state_duration = INF },
  Enums.CHAR_STATES.MIDAIR:     { flag = null, move = 1.0, ground_only = false,  turn = true,  attack = true,  roll = false, jump = false, interrupt_after = 0.0,             state_duration = INF },

  # Movements
  Enums.CHAR_STATES.JUMPING:    { flag = "jump", move = 1.0, ground_only = true,   turn = true,  attack = true,  roll = false, jump = false, interrupt_after = 0.0,           state_duration = INF },
  Enums.CHAR_STATES.ROLLING:    { flag = "roll", move = 0.0, ground_only = true,   turn = false, attack = true,  roll = false, jump = true,  interrupt_after = 0.0,           state_duration = ROLL_TIME },

  # Attacks
  Enums.CHAR_STATES.SWORD_1:    { flag = "attack", move = 0.3, ground_only = false,  turn = false, attack = true,  roll = true,  jump = true,  interrupt_after = 0.1,         state_duration = 0.2 },
  Enums.CHAR_STATES.SWORD_2:    { flag = "attack", move = 0.3, ground_only = false,  turn = false, attack = false, roll = true,  jump = true,  interrupt_after = 0.2,         state_duration = 0.3 },

  # Abilities

  # Special states with their own rules to enter and exit
  Enums.CHAR_STATES.INTERACT:   { flag = null, move = 0.0, ground_only = true,   turn = false, attack = false, roll = false, jump = false, interrupt_after = -1.0,          state_duration = -1.0 },
  Enums.CHAR_STATES.HURT:       { flag = null, move = 0.0, ground_only = false,  turn = false, attack = false, roll = false, jump = false, interrupt_after = -1.0,          state_duration = HURT_TIME },
}
#endregion

#region ADJUSTABLES ============================================================
# These should always start at 0 on new game.
var ADJUST_WALK_SPEED := 0.0;
var ADJUST_ROLL_SPEED := 0.0;
var ADJUST_JUMP_TIME := 0.0;
var ADJUST_JUMP_VELOCITY := 0.0;
var ADJUST_MAX_HEALTH := 0;

var WALK_SPEED: float:
  get: return BASE_WALK_SPEED + ADJUST_WALK_SPEED;
var ROLL_SPEED: float:
  get: return BASE_ROLL_SPEED + ADJUST_ROLL_SPEED;
var JUMP_TIME: float:
  get: return BASE_JUMP_TIME + ADJUST_JUMP_TIME;
var JUMP_VELOCITY: float:
  get: return BASE_JUMP_VELOCITY + ADJUST_JUMP_VELOCITY;
var MAX_HEALTH: int:
  get: return BASE_MAX_HEALTH + ADJUST_MAX_HEALTH;
#endregion

#region PLAYER STATS =========================================================
var P1_CURRENT_HEALTH := MAX_HEALTH:
  set(value):
    P1_CURRENT_HEALTH = clampi(value, 0, MAX_HEALTH);
var P2_CURRENT_HEALTH := MAX_HEALTH:
  set(value):
    P2_CURRENT_HEALTH = clampi(value, 0, MAX_HEALTH);

var CURRENT_MONEY := 0;
#endregion
