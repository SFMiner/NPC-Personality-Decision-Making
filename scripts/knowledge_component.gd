class_name KnowledgeIndex
extends RefCounted

var owner_id: String
var known_facts: Dictionary = {}  # fact_id (int) -> KnownFact
var misinformation: Dictionary = {}  # fact_id (int) -> MisinfoEntry
var knowledge_tags: Array[String] = []  # Optimization for fast rejection
var forgotten_tags: Array[String] = []  # Tags of facts recently forgotten (for partial memory response)
var fact_index_by_tag: Dictionary = {}  # tag (String) -> Array[int] (fact_ids)
var skills: Dictionary = {}  # skill_name (String) -> level (float 0.0-1.0)
var forgetfulness_rate: float = 0.1

func has_tag(tag: String) -> bool:
	return tag in knowledge_tags

func has_any_tag(tags: Array[String]) -> bool:
	for tag in tags:
		if tag in knowledge_tags:
			return true
	return false

func get_facts_by_tag(tag: String) -> Array[int]:
	# Returns Array of ints (fact_ids), casting explicitly for safety
	var result: Array[int] = []
	if fact_index_by_tag.has(tag):
		result.assign(fact_index_by_tag[tag])
	return result

func learn_fact(fact_id: int, known_fact: KnownFact, world: Node) -> void:
	known_facts[fact_id] = known_fact
	
	# Update tag indices using the WorldKnowledge singleton/reference
	# Note: world parameter should be type WorldKnowledge, typed as Node to avoid circular ref errors during parsing if needed
	var fact_data = world.get_fact(fact_id)
	if fact_data:
		for tag in fact_data.tags:
			if tag not in knowledge_tags:
				knowledge_tags.append(tag)
			if not fact_index_by_tag.has(tag):
				fact_index_by_tag[tag] = []
			
			var list = fact_index_by_tag[tag] as Array
			if fact_id not in list:
				list.append(fact_id)

func forget_fact(fact_id: int, world: Node) -> void:
	if not known_facts.has(fact_id):
		return
	
	known_facts.erase(fact_id)
	
	# Update tag indices
	var fact_data = world.get_fact(fact_id)
	if fact_data:
		for tag in fact_data.tags:
			if fact_index_by_tag.has(tag):
				var list = fact_index_by_tag[tag] as Array
				list.erase(fact_id)
				if list.is_empty():
					knowledge_tags.erase(tag)
					fact_index_by_tag.erase(tag)
					if tag not in forgotten_tags:
						forgotten_tags.append(tag)
						if forgotten_tags.size() > 20:
							forgotten_tags.pop_front()
