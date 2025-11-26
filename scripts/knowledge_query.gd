class_name KnowledgeQuery
extends RefCounted

enum QueryType { WHERE, WHO, WHAT, WHY, HOW, WHEN, GENERAL }

var raw_text: String
var query_type: QueryType = QueryType.GENERAL
var extracted_tags: Array[String] = []
var subject: String = ""

# --- INNER RESULT CLASS ---
class QueryResult:
	var success: bool = false
	var facts: Array[FactData] = []
	var known_facts: Array[KnownFact] = []
	var confidence: float = 0.0
	var has_contradictions: bool = false
	var partial_knowledge: bool = false
	var missing_prerequisites: Array[int] = []

# --- PARSING ---
static func parse(text: String) -> KnowledgeQuery:
	var query = KnowledgeQuery.new()
	query.raw_text = text
	query._parse()
	return query

func _parse() -> void:
	var lower = raw_text.to_lower()
	
	if lower.begins_with("where") or "location" in lower or "find" in lower:
		query_type = QueryType.WHERE
	elif lower.begins_with("who"):
		query_type = QueryType.WHO
	elif lower.begins_with("what"):
		query_type = QueryType.WHAT
	elif lower.begins_with("why"):
		query_type = QueryType.WHY
	elif lower.begins_with("how"):
		query_type = QueryType.HOW
	elif lower.begins_with("when"):
		query_type = QueryType.WHEN
	else:
		query_type = QueryType.GENERAL
	
	extracted_tags = _extract_tags(lower)
	subject = _extract_subject(lower)

func _extract_tags(text: String) -> Array[String]:
	var tags: Array[String] = []
	
	# Implicit tags based on query type
	match query_type:
		QueryType.WHERE: tags.append("location")
		QueryType.WHO: tags.append("person")
		QueryType.WHEN: tags.append("event")
	
	# Simple Keyword Matching (Expandable)
	var map = {
		"blacksmith": ["blacksmith", "trade"],
		"king": ["royalty", "politics", "king"],
		"queen": ["royalty", "politics", "queen"],
		"tavern": ["tavern", "social"],
		"war": ["war", "history"],
		"sword": ["weapon", "trade"],
		"market": ["trade", "location"]
	}
	
	for key in map:
		if key in text:
			for t in map[key]:
				if t not in tags: tags.append(t)
				
	return tags

func _extract_subject(text: String) -> String:
	# Naive subject extraction
	var words = text.split(" ")
	for i in range(words.size()):
		if words[i] in ["the", "a", "an"] and i + 1 < words.size():
			return words[i+1].strip_edges()
	return ""

# --- EXECUTOR CLASS ---
class QueryExecutor:
	var world: WorldKnowledge
	var min_strength_threshold: float = 0.2
	
	func _init(world_ref: WorldKnowledge):
		world = world_ref
	
	func execute(npc_knowledge: KnowledgeIndex, query: KnowledgeQuery) -> QueryResult:
		var result = QueryResult.new()
		
		# 1. Early Reject
		if not npc_knowledge.has_any_tag(query.extracted_tags):
			result.success = false
			# Check partial/forgotten
			for tag in query.extracted_tags:
				if tag in npc_knowledge.forgotten_tags:
					result.partial_knowledge = true
					break
			return result
			
		# 2. Candidate Lookup
		var candidate_ids = world.get_facts_by_tags(query.extracted_tags, false)
		if candidate_ids.is_empty():
			result.success = false
			return result
			
		# 3. Filter Knowledge
		var known_candidates: Array[Dictionary] = []
		var current_time = Time.get_unix_time_from_system()
		
		for fid in candidate_ids:
			if not npc_knowledge.known_facts.has(fid):
				continue
				
			var k_fact = npc_knowledge.known_facts[fid]
			var eff_strength = k_fact.calculate_effective_strength(current_time, npc_knowledge.forgetfulness_rate)
			
			if eff_strength < min_strength_threshold:
				continue
			
			var f_data = world.get_fact(fid)
			
			# Check Prereqs
			var missing = false
			for p_id in f_data.prerequisites:
				if not npc_knowledge.known_facts.has(p_id):
					result.missing_prerequisites.append(p_id)
					missing = true
			if missing: continue
			
			# Check Skills
			var skill_issue = false
			for s_name in f_data.skill_requirements:
				var req = f_data.skill_requirements[s_name]
				var level = npc_knowledge.skills.get(s_name, 0.0)
				if level < req:
					skill_issue = true
					break
			if skill_issue and f_data.granularity == FactData.Granularity.EXPERT:
				continue
				
			known_candidates.append({
				"fact": f_data,
				"known": k_fact,
				"strength": eff_strength
			})
			
		if known_candidates.is_empty():
			result.success = false
			return result
			
		# 4. Misinformation & Sorting
		# Sort by strength descending
		known_candidates.sort_custom(func(a, b): return a.strength > b.strength)
		
		result.success = true
		result.confidence = known_candidates[0].strength
		
		# Apply misinfo
		for cand in known_candidates:
			var fid = cand.fact.fact_id
			if npc_knowledge.misinformation.has(fid):
				var mis = npc_knowledge.misinformation[fid]
				# Clone fact data for response to avoid modifying global state
				var distorted_fact = FactData.new() # Shallow copy wrapper
				distorted_fact.data = mis.distorted_data
				distorted_fact.tags = cand.fact.tags
				result.facts.append(distorted_fact)
			else:
				result.facts.append(cand.fact)
			result.known_facts.append(cand.known)
			
		return result
