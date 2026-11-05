extends Node

# Every number that decides how Binty, Glinty and the enemies feel lives here, grouped by move.
# Values that change during play (current lives, money, deaths) live in GameState instead.
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

#region ATTACK =================================================================
# The ground and air combo: three blunt swings. Each entry is one swing, in order.
#   damage       health it takes off
#   knockback    how hard it shoves the target away (m/s)
#   time         how long the swing lasts
#   chain_after  how far into the swing the next press is accepted (or a jump / roll can cancel it)
#   hit_stop     how long the game freezes on a hit, for impact. The finisher hits hardest.
const ATTACK_COMBO := [
  {"damage": 1, "knockback": 5.0, "time": 0.25, "chain_after": 0.12, "hit_stop": 0.05},
  {"damage": 1, "knockback": 6.0, "time": 0.25, "chain_after": 0.12, "hit_stop": 0.05},
  {"damage": 2, "knockback": 12.0, "time": 0.4, "chain_after": 0.3, "hit_stop": 0.11},
];
const ATTACK_MOVE_MULTIPLIER := 0.3;    # Fraction of run speed while swinging.
const HIT_STOP_TIME_SCALE := 0.05;      # Game speed during hit stop (0 = full freeze).
#endregion =====================================================================

#region GETTING HURT ===========================================================
const HURT_TIME := 0.35;                # Control is lost for this long after a hit.
const HURT_KNOCKBACK := 9.0;            # Pushed away from whatever hit you (m/s)...
const HURT_KNOCKUP := 6.0;              # ...and popped up a little.
const INVULNERABLE_TIME := 1.5;         # Can't be hurt again for this long. The body blinks.
const INVULNERABLE_BLINK_RATE := 12.0;  # Blinks per second.
#endregion =====================================================================

#region GHOST ==================================================================
# In co-op, whoever dies first floats as a ghost until their partner reaches a checkpoint.
const GHOST_SPEED := 9.0;
const GHOST_ACCELERATION := 25.0;
const GHOST_HOVER_HEIGHT := 1.5;        # Floats this high above the partner's feet.
const GHOST_VERTICAL_SHARPNESS := 3.0;  # How quickly it drifts to that height.
const GHOST_LEASH_DISTANCE := 8.0;      # Gets pulled back toward the partner past this (keeps the screen shared).
const GHOST_LEASH_PULL := 6.0;          # Pull speed per metre past the leash.
const BOO_RADIUS := 5.0;                # Attack button as a ghost: enemies this close get confused...
const BOO_CONFUSE_TIME := 2.5;          # ...for this long.
const BOO_COOLDOWN := 4.0;
#endregion =====================================================================

#region LIVES ==================================================================
const STARTING_LIVES := 3;
const MAX_LIVES := 99;
const DEATH_SCREEN_TIME := 1.5;         # How long the placeholder Death scene shows on an ordinary death.
const DEATH_COUNTER_BONUS_MONEY := 25;  # Placeholder: what a hidden 1-up gives in Death Counter mode.
#endregion =====================================================================

#region ENEMY: GRUNT ===========================================================
const GRUNT_MAX_HEALTH := 4;
const GRUNT_SPEED := 4.0;
const GRUNT_ACCELERATION := 20.0;
const GRUNT_TURN_SPEED := 8.0;
const GRUNT_SIGHT_RANGE := 10.0;        # Starts chasing a player this close...
const GRUNT_LOSE_RANGE := 16.0;         # ...and gives up past this.
const GRUNT_CONTACT_DAMAGE := 1;
const GRUNT_STUN_TIME := 0.5;           # Stops chasing this long after being hit.
const GRUNT_KNOCKBACK_FRICTION := 25.0; # How quickly knockback slides to a stop.
const GRUNT_SILVER_DROP := 3;           # Small silver dropped on defeat.
#endregion =====================================================================

#region ENEMY: TRAINING DUMMY ==================================================
const DUMMY_HEAL_DELAY := 2.0;          # Heals back to full this long after the last hit. Never dies.
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
