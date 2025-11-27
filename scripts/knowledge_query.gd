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
		
		# 1. Early Reject - NPC doesn't have ANY relevant tags
		if not npc_knowledge.has_any_tag(query.extracted_tags):
			result.success = false
			# Check if forgotten
			for tag in query.extracted_tags:
				if tag in npc_knowledge.forgotten_tags:
					result.partial_knowledge = true
					break
			return result
		
		# 2. Candidate Lookup - find all facts matching ANY tag
		var candidate_ids = world.get_facts_by_tags(query.extracted_tags, false)
		if candidate_ids.is_empty():
			result.success = false
			return result
		
		# 3. Filter candidates NPC actually knows AND score by tag match quality
		var known_candidates: Array = []
		
		for fact_id in candidate_ids:
			if not npc_knowledge.known_facts.has(fact_id):
				continue
			
			var known_fact = npc_knowledge.known_facts[fact_id]
			var fact_data = world.get_fact(fact_id)
			
			if not fact_data:
				continue
			
			# Check prerequisites
			var has_prereqs = true
			for prereq_id in fact_data.prerequisites:
				if not npc_knowledge.known_facts.has(prereq_id):
					has_prereqs = false
					result.missing_prerequisites.append(prereq_id)
					break
			
			if not has_prereqs:
				continue
			
			# NEW: Calculate tag match quality score
			var match_score = _calculate_tag_match_score(fact_data.tags, query.extracted_tags)
			
			# NEW: Require minimum match quality (at least 2 matching tags OR 1 exact important tag)
			if match_score < 1.0:
				continue
			
			# Apply strength threshold
			var effective_strength = known_fact.calculate_effective_strength(
				Time.get_unix_time_from_system(),
				npc_knowledge.forgetfulness_rate
			)
			
			if effective_strength < min_strength_threshold:
				result.partial_knowledge = true
				continue
			
			# Store with match score for sorting
			known_candidates.append({
				"fact_id": fact_id,
				"fact_data": fact_data,
				"known_fact": known_fact,
				"strength": effective_strength,
				"match_score": match_score  # NEW: Store match quality
			})
		
		# 4. Sort by MATCH QUALITY first, then strength
		known_candidates.sort_custom(func(a, b): 
			if abs(a.match_score - b.match_score) > 0.1:
				return a.match_score > b.match_score  # Better match wins
			return a.strength > b.strength  # Tie-breaker: stronger memory
		)
		
		# 5. Return results
		if known_candidates.is_empty():
			result.success = false
			if result.missing_prerequisites.size() > 0:
				result.partial_knowledge = true
			return result
		
		result.success = true
		result.confidence = known_candidates[0].strength
		
		for candidate in known_candidates:
			result.facts.append(candidate.fact_data)
			result.known_facts.append(candidate.known_fact)
		
		# 6. Check for contradictions
		result.has_contradictions = _detect_contradictions(known_candidates)
		
		return result

	# NEW HELPER FUNCTION: Calculate how well fact tags match query tags
	func _calculate_tag_match_score(fact_tags: Array[String], query_tags: Array[String]) -> float:
		var score = 0.0
		var important_matches = 0
		var common_matches = 0
		
		# Define important tags that should be exact matches
		var important_tag_types = ["blacksmith", "tavern", "king", "queen", "healer", 
								   "merchant", "guild", "temple", "castle"]
		
		for query_tag in query_tags:
			if query_tag in fact_tags:
				# Check if this is an important/specific tag
				if query_tag in important_tag_types:
					important_matches += 1
					score += 2.0  # Important tags worth more
				else:
					common_matches += 1
					score += 0.5  # Generic tags (location, person) worth less
		
		# Scoring rules:
		# - 1+ important match = good (score >= 2.0)
		# - 2+ common matches = acceptable (score >= 1.0)
		# - 1 common match only = weak (score = 0.5, filtered out)
		
		return score

	# Keep the existing _detect_contradictions function as-is
	func _detect_contradictions(candidates: Array) -> bool:
		for i in range(candidates.size()):
			for j in range(i + 1, candidates.size()):
				var data_a = candidates[i].fact_data.data
				var data_b = candidates[j].fact_data.data
				
				if data_a.get("subject") == data_b.get("subject"):
					if data_a.get("object") != data_b.get("object"):
						return true
		return false
