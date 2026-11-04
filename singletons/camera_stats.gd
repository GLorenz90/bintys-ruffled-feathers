extends Node

# Every number that decides how the camera behaves, in one place. Same idea as CharStats.
# Distances are metres, angles degrees, speeds per second.
# "Sharpness" values control smoothing: higher catches up faster (about 1/sharpness seconds to close most of a gap).

#region FOLLOW =================================================================
const DEFAULT_DISTANCE := 9.0;          # How far behind the player the camera sits.
const DEFAULT_PITCH := -22.0;           # Looking down at the player. Negative is down.
const FOCUS_HEIGHT := 1.4;              # The camera aims this far above the player's feet.
const FOLLOW_SHARPNESS := 10.0;         # Horizontal catch-up.
const VERTICAL_FOLLOW_SHARPNESS := 3.0; # Vertical catch-up is lazier, so jumps don't bob the view.
const DISTANCE_SHARPNESS := 4.0;        # How quickly distance changes (zones, co-op zoom) are eased in.
#endregion =====================================================================

#region AUTO TURN ==============================================================
# The camera drifts round behind you when you run sideways across the screen.
# Running straight toward or away from it doesn't turn it at all.
const AUTO_TURN_RATE := 0.1;            # Radians per second, per m/s of sideways speed.
#endregion =====================================================================

#region MANUAL CONTROL =========================================================
const STICK_YAW_SPEED := 160.0;         # Degrees per second at full right-stick (or arrow keys).
const STICK_PITCH_SPEED := 90.0;
const STICK_ACCELERATION := 700.0;      # Degrees per second squared: full yaw speed takes about 0.23 s, so taps are small nudges.
const STICK_DECELERATION := 900.0;      # How quickly the turn winds down after letting go of the stick.
const MOUSE_SENSITIVITY := 0.25;        # Degrees per pixel of mouse movement (hold the right mouse button).
const MIN_PITCH := -70.0;
const MAX_PITCH := 10.0;
const MANUAL_HOLD_TIME := 1.5;          # After you stop steering left / right, the camera waits this long before auto-turning again.
const PITCH_RETURN_DELAY := 0.2;        # After you stop pushing up / down, the camera waits this long, then eases back...
const PITCH_RETURN_SPEED := 45.0;       # ...at this average speed in degrees per second, along an S-curve (slow, faster, slow),
const MIN_PITCH_RETURN_TIME := 0.25;    # ...taking at least this long, to DEFAULT_PITCH (or a zone's pitch).
#endregion =====================================================================

#region COLLISION ==============================================================
const COLLISION_MARGIN := 0.2;          # Gap kept between the camera and a wall it's pushed in front of.
const COLLISION_RADIUS := 0.3;
#endregion =====================================================================

#region CO-OP ==================================================================
# Shared screen pulls back as the players spread out, then splits in two past SPLIT_DISTANCE.
# It merges back only once they're within MERGE_DISTANCE, so it doesn't flicker at the boundary.
const SHARED_DISTANCE_PER_METRE := 0.45; # Extra camera distance per metre between the players.
const MAX_SHARED_DISTANCE := 17.0;
const SPLIT_DISTANCE := 18.0;
const MERGE_DISTANCE := 13.0;
const SPLIT_DIVIDER_WIDTH := 6.0;        # Pixels.
# The screen also splits whenever the players are in different camera zones (e.g. one in a fixed zone, one not).
const ZONE_MERGE_DELAY := 0.5;           # Both must share a zone this long before merging, so walking along an edge doesn't flicker.
#endregion =====================================================================

#region ZONES ==================================================================
const ZONE_BLEND_SHARPNESS := 4.0;       # How quickly a camera zone's angle takes over, and lets go.
#endregion =====================================================================
