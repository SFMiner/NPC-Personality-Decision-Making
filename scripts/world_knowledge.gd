class_name WorldKnowledge
extends Node

# This script can serve as an Autoload or be instantiated by NPCSystem

var facts: Dictionary = {}  # fact_id (int) -> FactData
var id_to_string: Dictionary = {}  # fact_id (int) -> readable key (String)
var string_to_id: Dictionary = {}  # key (String) -> fact_id (int)
var categories: Dictionary = {}  # category (String) -> Array[int]
var tags_index: Dictionary = {}  # tag (String) -> Array[int]
var next_fact_id: int = 1

signal fact_added(fact_id: int)
signal fact_updated(fact_id: int, old_version: int, new_version: int)
signal fact_removed(fact_id: int)

func _ready() -> void:
	# In a real project, we would load from JSON here.
	# For this implementation, we generate default data to ensure it runs immediately.
	_generate_default_facts()

func register_fact(fact: FactData, string_key: String) -> int:
	facts[fact.fact_id] = fact
	id_to_string[fact.fact_id] = string_key
	string_to_id[string_key] = fact.fact_id
	
	# Index by tags
	for tag in fact.tags:
		if not tags_index.has(tag):
			tags_index[tag] = []
		var list = tags_index[tag] as Array
		list.append(fact.fact_id)
	
	# Index by category (assume first tag is category if available)
	if fact.tags.size() > 0:
		var category = fact.tags[0]
		if not categories.has(category):
			categories[category] = []
		var cat_list = categories[category] as Array
		cat_list.append(fact.fact_id)
	
	fact_added.emit(fact.fact_id)
	return fact.fact_id

func get_fact(fact_id: int) -> FactData:
	return facts.get(fact_id, null)

func get_fact_by_key(key: String) -> FactData:
	var fact_id = string_to_id.get(key, -1)
	if fact_id >= 0:
		return facts.get(fact_id, null)
	return null

func get_facts_by_tag(tag: String) -> Array[int]:
	# explicit cast for safety
	var result: Array[int] = []
	if tags_index.has(tag):
		result.assign(tags_index[tag])
	return result

func get_facts_by_tags(tags: Array[String], match_all: bool = false) -> Array[int]:
	if tags.is_empty():
		return []
	
	var result_ids: Array[int] = []
	
	if match_all:
		# Intersection
		var first = true
		var potential_set = {}
		
		for tag in tags:
			var tag_facts = get_facts_by_tag(tag)
			if first:
				for fid in tag_facts:
					potential_set[fid] = true
				first = false
			else:
				var new_set = {}
				for fid in tag_facts:
					if potential_set.has(fid):
						new_set[fid] = true
				potential_set = new_set
			
			if potential_set.is_empty():
				break
		
		result_ids.assign(potential_set.keys())
	else:
		# Union
		var potential_set = {}
		for tag in tags:
			var tag_facts = get_facts_by_tag(tag)
			for fid in tag_facts:
				potential_set[fid] = true
		result_ids.assign(potential_set.keys())
		
	return result_ids

func update_dynamic_fact(fact_id: int, new_data: Dictionary) -> void:
	if not facts.has(fact_id):
		return
	
	var fact = facts[fact_id]
	var old_version = fact.version
	fact.version += 1
	fact.data = new_data
	fact.last_updated = Time.get_unix_time_from_system()
	
	fact_updated.emit(fact_id, old_version, fact.version)

func _generate_default_facts():
	# Helper to create facts quickly
	var create = func(key, type, gran, data, tags, prereqs = [], skills = {}):
		var f = FactData.new()
		f.fact_id = next_fact_id
		next_fact_id += 1
		f.type = type
		f.granularity = gran
		f.data = data
		f.tags.assign(tags)
		f.prerequisites.assign(prereqs)
		f.skill_requirements = skills
		register_fact(f, key)
		return f.fact_id

	# --- LOCATIONS ---
	var blacksmith_loc = create.call("blacksmith_loc", FactData.FactType.STATIC, FactData.Granularity.GENERAL, 
		{"subject": "the blacksmith", "predicate": "is located in", "object": "the Market District"}, 
		["location", "blacksmith", "trade", "city"])
	
	var tavern_loc = create.call("tavern_loc", FactData.FactType.STATIC, FactData.Granularity.GENERAL,
		{"subject": "The Rusty Sword tavern", "predicate": "is near", "object": "the city gates"},
		["location", "tavern", "social", "city"])

	# --- PEOPLE ---
	var king_identity = create.call("king_identity", FactData.FactType.DYNAMIC, FactData.Granularity.GENERAL,
		{"subject": "the King", "predicate": "is named", "object": "Aldric III"},
		["politics", "royalty", "person"])

	var king_secret = create.call("king_secret", FactData.FactType.SECRET, FactData.Granularity.EXPERT,
		{"subject": "King Aldric", "predicate": "is secretly", "object": "ill"},
		["politics", "secret", "rumor"], [], {"politics": 0.7})

	# --- LORE ---
	var ancient_war = create.call("ancient_war", FactData.FactType.STATIC, FactData.Granularity.SUMMARY,
		{"subject": "The Great War", "predicate": "happened", "object": "100 years ago"},
		["history", "war", "lore"])
