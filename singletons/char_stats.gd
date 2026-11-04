extends Node

# Every number that decides how Binty and Glinty feel lives here, grouped by move.
# Speeds are metres per second, accelerations metres per second squared, times in seconds.
# Gravity itself is the project setting physics/3d/default_gravity (40).
#
# BASE_ values are the defaults. ADJUST_ values are added on top by power-ups and always start at 0 on a new game.
# Read the combined value through the matching getter (RUN_SPEED, JUMP_VELOCITY, ...), never BASE_ directly.

#region INPUT ==================================================================
const INPUT_BUFFER_TIME := 0.15;        # A press this early still counts (e.g. jump just before landing).
const COYOTE_TIME := 0.12;              # You can still jump this long after running off a ledge.
#endregion =====================================================================

#region RUN ====================================================================
const BASE_RUN_SPEED := 8.0;            # Top speed at full stick.
const RUN_ACCELERATION := 60.0;         # Reaches top speed in about 0.13 s.
const RUN_DECELERATION := 50.0;         # Stops in about 0.16 s after letting go.
const TURNAROUND_DECELERATION := 90.0;  # Braking when the stick points against your movement (the skid).
const TURN_SPEED := 14.0;               # How quickly the body swings round to face where you're going.
#endregion =====================================================================

#region JUMP AND AIR ===========================================================
const BASE_JUMP_VELOCITY := 15.0;       # Upward speed at take-off. Full hold reaches about 2.8 m.
const JUMP_CUT_MULTIPLIER := 0.5;       # Letting go of jump early multiplies upward speed by this (short hops).
const FALL_GRAVITY_MULTIPLIER := 1.6;   # Falling is heavier than rising, so jumps don't feel floaty.
const MAX_FALL_SPEED := 40.0;
const AIR_ACCELERATION := 30.0;         # Steering in the air is weaker than on the ground.
const AIR_DECELERATION := 8.0;
#endregion =====================================================================

#region WING FLAP ==============================================================
const BASE_FLAP_TIME := 1.0;            # Longest a single flap can last. One flap per time in the air.
const FLAP_BOOST := 3.0;                # Small upward pop when the flap starts.
const FLAP_FALL_SPEED := 2.0;           # Slow, steady descent while flapping.
const FLAP_SETTLE_RATE := 25.0;         # How fast vertical speed eases toward FLAP_FALL_SPEED.
const FLAP_MIN_HEIGHT := 1.0;           # Closer to the ground than this, a jump press is saved for landing instead of flapping.
#endregion =====================================================================

#region ROLL ===================================================================
const BASE_ROLL_SPEED := 18.0;
const ROLL_TIME := 0.3;
#endregion =====================================================================

#region ATTACK (placeholder until M3) ==========================================
const ATTACK_TIME := 0.25;              # How long one swing lasts.
const ATTACK_CHAIN_AFTER := 0.12;       # The next swing can start this far into the current one.
const ATTACK_MOVE_MULTIPLIER := 0.3;    # Fraction of run speed while swinging.
#endregion =====================================================================

#region HEALTH =================================================================
const BASE_MAX_HEALTH := 6;
#endregion =====================================================================

#region ADJUSTABLES ============================================================
var ADJUST_RUN_SPEED := 0.0;
var ADJUST_JUMP_VELOCITY := 0.0;
var ADJUST_FLAP_TIME := 0.0;
var ADJUST_ROLL_SPEED := 0.0;
var ADJUST_MAX_HEALTH := 0;

var RUN_SPEED: float:
  get: return BASE_RUN_SPEED + ADJUST_RUN_SPEED;
var JUMP_VELOCITY: float:
  get: return BASE_JUMP_VELOCITY + ADJUST_JUMP_VELOCITY;
var FLAP_TIME: float:
  get: return BASE_FLAP_TIME + ADJUST_FLAP_TIME;
var ROLL_SPEED: float:
  get: return BASE_ROLL_SPEED + ADJUST_ROLL_SPEED;
var MAX_HEALTH: int:
  get: return BASE_MAX_HEALTH + ADJUST_MAX_HEALTH;
#endregion =====================================================================

#region PLAYER STATS ===========================================================
var P1_CURRENT_HEALTH := MAX_HEALTH:
  set(value):
    P1_CURRENT_HEALTH = clampi(value, 0, MAX_HEALTH);
var P2_CURRENT_HEALTH := MAX_HEALTH:
  set(value):
    P2_CURRENT_HEALTH = clampi(value, 0, MAX_HEALTH);

var CURRENT_MONEY := 0;
#endregion =====================================================================
