# Combining small helper classes for file efficiency
class_name KnowledgeHelpers
extends RefCounted

class Seeder:
	var world: WorldKnowledge
	
	func _init(w: WorldKnowledge):
		world = w
	
	func seed_npc(knowledge: KnowledgeIndex, archetype: String):
		# Default skills based on archetype
		match archetype:
			# Warlords should know about blacksmiths (military supplies)
			"warlord": 
				knowledge.skills = {"warfare": 0.8, "politics": 0.5}
				_seed_tags(knowledge, ["location", "blacksmith", "trade", "politics", "royalty"])
			"merchant":
				knowledge.skills = {"trade": 0.7, "geography": 0.5}
				_seed_tags(knowledge, ["trade", "city"])
			"scholar":
				knowledge.skills = {"history": 0.8, "politics": 0.4}
				_seed_tags(knowledge, ["history", "politics", "lore"])
			"rogue":
				knowledge.skills = {"underworld": 0.7, "trade": 0.3}
				_seed_tags(knowledge, ["social", "tavern"])
			"noble":
				knowledge.skills = {"politics": 0.8, "history": 0.5}
				_seed_tags(knowledge, ["politics", "royalty"])
			_:
				knowledge.skills = {"common_sense": 0.5}
				_seed_tags(knowledge, ["social"])
				
	func _seed_tags(knowledge: KnowledgeIndex, tags: Array[String]):
		var candidates = world.get_facts_by_tags(tags, false)
		for fid in candidates:
			if randf() > 0.4: # 60% chance to know relevant facts
				var k = KnownFact.new()
				k.fact_id = fid
				k.strength = randf_range(0.5, 0.9)
				k.source_type = KnownFact.SourceType.INNATE
				k.learned_at = Time.get_unix_time_from_system()
				k.last_accessed = k.learned_at
				knowledge.learn_fact(fid, k, world)

class DecaySystem:
	var world: WorldKnowledge
	var decay_threshold: float = 0.15
	
	func _init(w: WorldKnowledge):
		world = w
		
	func process_decay(npc_knowledge: KnowledgeIndex, current_time: float):
		var to_forget: Array[int] = []
		
		for fid in npc_knowledge.known_facts:
			var k = npc_knowledge.known_facts[fid]
			var eff = k.calculate_effective_strength(current_time, npc_knowledge.forgetfulness_rate)
			if eff < decay_threshold:
				to_forget.append(fid)
				
		for fid in to_forget:
			npc_knowledge.forget_fact(fid, world)

class ResponseTemplates:
	static func get_template(confidence: float, query_type: int) -> String:
		if confidence > 0.7:
			match query_type:
				KnowledgeQuery.QueryType.WHERE: return "{subject} is located {object}."
				KnowledgeQuery.QueryType.WHO: return "{subject} is {object}."
				_: return "I know that {subject} {predicate} {object}."
		elif confidence > 0.4:
			return "I believe {subject} {predicate} {object}."
		else:
			return "I vaguely recall that {subject} {predicate} {object}, but I'm not sure."
