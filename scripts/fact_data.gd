class_name FactData
extends RefCounted

# Granularity levels
enum Granularity { SUMMARY, GENERAL, DETAILED, EXPERT }
# Fact Types
enum FactType { STATIC, DYNAMIC, EVENT, RUMOR, SECRET }

var fact_id: int
var type: FactType = FactType.STATIC
var granularity: Granularity = Granularity.GENERAL
var data: Dictionary = {}  # E.g., {"subject": "", "predicate": "", "object": ""}
var tags: Array[String] = []
var prerequisites: Array[int] = []  # IDs of facts that must be known first
var leads_to: Array[int] = []  # IDs this unlocks
var skill_requirements: Dictionary = {}  # {"skill_name": min_level (0.0-1.0)}
var happened_at: float = -1.0  # Timestamp
var last_updated: float = 0.0
var version: int = 1
var covers_facts: Array[int] = []  # For summary facts
var response_templates: Array[String] = []  # Specific phrasings for this fact
