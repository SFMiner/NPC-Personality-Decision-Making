class_name MisinfoEntry
extends RefCounted

enum MisinfoType { 
	WRONG_VALUE,      # "The king's name is Robert" (actually James)
	PARTIAL,          # Missing key details
	INVERTED,         # Opposite of truth
	CONFLATED,        # Mixed with another fact
	FABRICATED        # Completely made up
}

var type: MisinfoType = MisinfoType.WRONG_VALUE
var target_fact_id: int
var distortion_level: float = 0.5  # 0.0 = slight, 1.0 = completely wrong
var distorted_data: Dictionary = {}  # What the NPC believes instead
var source_id: String = ""
