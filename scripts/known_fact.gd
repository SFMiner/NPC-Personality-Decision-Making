class_name KnownFact
extends RefCounted

enum SourceType { WITNESSED, TOLD_TRUSTED, TOLD_STRANGER, RUMOR, INNATE }

var fact_id: int
var strength: float = 1.0  # 0.0 - 1.0
var source_type: SourceType = SourceType.INNATE
var source_id: String = ""  # Who told them
var generation: int = 0  # 0 = witnessed/innate, 1+ = hearsay
var known_version: int = 1  # Version when learned
var learned_at: float = 0.0
var last_accessed: float = 0.0
var reinforcement_count: int = 0

func calculate_effective_strength(current_time: float, decay_rate: float) -> float:
	var time_elapsed = current_time - last_accessed
	# Exponential decay based on time since last access
	var decay = exp(-decay_rate * max(0.0, time_elapsed))
	var base = strength * decay
	# Reinforcement provides a buffer against decay
	var reinforcement_bonus = min(0.3, reinforcement_count * 0.05)
	return clamp(base + reinforcement_bonus, 0.0, 1.0)
