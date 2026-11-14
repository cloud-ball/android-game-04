class_name CoursePreset
extends RefCounted
## Per-course conditions (pure): green speed and firmness, fairway roll, altitude, wind range.
## Research: docs/research/Fairway Flick courses and maps.md (course line-up table) and the
## ball physics notes (Stimpmeter conversion, section 5).

## Stimpmeter exit speed (m/s) and feet -> metres.
const STIMP_V0 := 1.83
const FT := 0.3048

var stimp := 10.0  # feet
var firm_greens := false
var firm_fairways := false
## Air density relative to sea level (1.0); the alpine bonus course uses ~0.86 (~1,500 m).
var air_factor := 1.0
var wind_min := 0.0  # m/s at 10 m
var wind_max := 3.0
var prevailing_deg := 0.0  # wind comes FROM this heading (0 = from straight ahead)
var wind_jitter_deg := 45.0


## Rolling deceleration on the green: a = v0^2 / (2 * Stimp).
func green_decel() -> float:
	return STIMP_V0 * STIMP_V0 / (2.0 * stimp * FT)


## Steepest grade (rise / run) a stopped ball can rest on, for the baker and validators: the
## rolling slope pull (5/7) g sin(theta) must stay below GolfSurfaces.STATIC_FACTOR x the roll
## decel. sin ~ tan at these slopes (< 0.1% error below 10%).
func max_rest_grade(g := 9.81) -> float:
	return GolfSurfaces.STATIC_FACTOR * green_decel() / (5.0 / 7.0 * g)
