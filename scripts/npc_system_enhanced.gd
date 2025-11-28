extends Node
class_name NPCSystemEnhanced

var debugging : bool= false
# KNOWLEDGE SYSTEM INTEGRATION
var world_knowledge: WorldKnowledge

# ============================================================================
# CORE DATA STRUCTURES (Retained & Updated)
# ============================================================================
class Personality:
	var warmth: float
	var assertiveness: float
	var conscientiousness: float
	var curiosity: float
	var risk_tolerance: float
	var stability: float
	var values: Dictionary
	var debugging : bool = true
	
	func _init(w: float = 0.0, a: float = 0.0, c: float = 0.0,
		cu: float = 0.0, r: float = 0.0, s: float = 0.0, v: Dictionary = {}, debug = true):
		debugging = debug
		warmth = w
		assertiveness = a
		conscientiousness = c
		curiosity = cu
		risk_tolerance = r
		stability = s
		values = v if v else {"POWER": 0.5, "HONOR": 0.5}
	
	func clone() -> Personality:
		return Personality.new(warmth, assertiveness, conscientiousness,
			curiosity, risk_tolerance, stability, values.duplicate())

class Relationship:
	var target_id: String
	var affection: float = 0.0
	var trust: float = 0.0
	var respect: float = 0.0
	var fear: float = 0.0
	var history: Array[String] = []

	func get_influence_multiplier() -> float:
		var mult = 1.0
		mult += affection * 0.5  # INCREASED from 0.3
		mult += trust * 0.6      # INCREASED from 0.4
		mult += respect * 0.5    # INCREASED from 0.4
		mult += fear * 0.3       # INCREASED from 0.2
		return max(0.1, mult)

class NPCContext:
	var location: String = ""
	var current_mood: float = 0.0
	var stress_level: float = 0.0
	var recent_events: Array[String] = []
	var active_goals: Array[String] = []
	var faction: String = ""
	var role: String = ""
	var recent_responses: Array[String] = []
	var wealth: int = 100
	var health: float = 1.0
	var hunger: float = 0.2
	var energy: float = 0.8

class NPC:
	var id: String
	var name: String
	var personality: Personality
	var relationships: Dictionary = {}
	var context: NPCContext
	var archetype: String = ""
	var memory: Array[Dictionary] = []
	var baseline_drives: Array[Drive] = []
	var dynamic_drives: Array[Drive] = []
	var debugging : bool= true

	# NEW: KNOWLEDGE SYSTEM INTEGRATION
	var knowledge: KnowledgeIndex
	
	func _init(npc_id: String, npc_name: String, pers: Personality, debug : bool = false):
		id = npc_id
		name = npc_name
		personality = pers
		context = NPCContext.new()
		knowledge = KnowledgeIndex.new()
		knowledge.owner_id = npc_id
	
	func get_relationship(target_id: String) -> Relationship:
		if not relationships.has(target_id):
			relationships[target_id] = Relationship.new()
			relationships[target_id].target_id = target_id
		return relationships[target_id]
	
	func remember_event(event: Dictionary):
		memory.append(event)
		if memory.size() > 20:
			memory.pop_front()
	
	func remember_response(response: String):
		context.recent_responses.append(response)
		if context.recent_responses.size() > 5:
			context.recent_responses.pop_front()
	
	func is_response_repetitive(response: String) -> bool:
		for recent in context.recent_responses:
			if _similarity_score(response, recent) > 0.85:
				return true
		return false
	
	func _similarity_score(s1: String, s2: String) -> float:
		var words1 = s1.split(" ")
		var words2 = s2.split(" ")
		var common = 0
		for word in words1:
			if word in words2:
				common += 1
		return float(common) / max(words1.size(), words2.size())

class RequestContext:
	var request_type: String
	var topic: String
	var urgency: float = 0.5
	var formality: float = 0.5
	var emotional_tone: float = 0.0
	var requester_id: String = "player"
	var witnesses: Array[String] = []
	var debugging : bool = true

class Request:
	var raw_text: String
	var context: RequestContext
	var parsed_intent: Dictionary
	var response_options: Array[ResponseOption] = []
	var debugging : bool = true

	
	func _init(text: String, debug : bool = false):
		raw_text = text
		context = RequestContext.new()
		parsed_intent = {}

class ResponseOption:
	var response_type: String
	var base_score: float = 0.5
	var personality_tags: Dictionary = {}
	var relationship_impact: Dictionary = {}
	var response_template: String = ""
	var template_variant: int = 0
	var action_tags: Dictionary = {}
	var knowledge_result: KnowledgeQuery.QueryResult = null  # NEW: Store query result


class Drive:
	var drive_type: String  # "SEEK_WEALTH", "PROTECT_character", "SELF_PRESERVATION", etc.
	var weight: float  # 0.0 to 1.0 (can go higher in extreme situations)
	var target_id: String = ""  # For personal drives like "PROTECT_Mira"
	var urgency: float = 0.5  # How pressing is this drive right now?
	var last_satisfied: int = 0  # Timestamp for future decay/urgency systems
	var debugging : bool= true

	
	func _init(type: String = "", w: float = 0.5, target: String = "", urg: float = 0.5, debug : bool = false):
		drive_type = type
		weight = w
		target_id = target
		urgency = urg
		last_satisfied = Time.get_ticks_msec()

class ArchetypeTemplate:
	var name: String
	var description: String
	var warmth: float
	var assertiveness: float
	var conscientiousness: float
	var curiosity: float
	var risk_tolerance: float
	var stability: float
	var values: Dictionary
	var baseline_drives: Dictionary = {}
	var wealth_range: Vector2i
	var health: float = 1.0
	var hunger: float = 0.2
	var energy: float = 0.8
	var personality_variance: float = 0.15
	var drive_variance: float = 0.15
	var wealth_variance: float = 0.2
	var debugging : bool= true

	
	func _init(archetype_name: String = "", debug : bool = false):
		name = archetype_name

class ArchetypeLibrary:
	var templates: Dictionary = {}
	var debugging : bool = true

	
	func _init():
		_define_archetypes()
	
	func _define_archetypes():
		# MERCHANT
		var merchant = ArchetypeTemplate.new("merchant")
		merchant.description = "Profit-focused trader"
		merchant.warmth = 0.4
		merchant.assertiveness = 0.2
		merchant.conscientiousness = 0.6
		merchant.curiosity = 0.3
		merchant.risk_tolerance = 0.4
		merchant.stability = 0.5
		merchant.values = {"WEALTH": 0.8, "COMMUNITY": 0.4, "KNOWLEDGE": 0.3}
		merchant.baseline_drives = {
			"SELF_PRESERVATION": 0.6,
			"SEEK_WEALTH": 0.9,
			"SEEK_GIFTS": 0.7,
			"AVOID_PAIN": 0.7
		}
		merchant.wealth_range = Vector2i(300, 700)
		templates["merchant"] = merchant
		
		# WARLORD
		var warlord = ArchetypeTemplate.new("warlord")
		warlord.description = "Battle-hardened leader"
		warlord.warmth = -0.3
		warlord.assertiveness = 0.8
		warlord.conscientiousness = 0.2
		warlord.curiosity = -0.1
		warlord.risk_tolerance = 0.7
		warlord.stability = 0.3
		warlord.values = {"POWER": 0.8, "HONOR": 0.4, "WEALTH": 0.3}
		warlord.baseline_drives = {
			"SELF_PRESERVATION": 0.4,
			"SEEK_STATUS": 0.9,
			"SEEK_WEALTH": 0.5,
			"AVOID_PAIN": 0.3
		}
		warlord.wealth_range = Vector2i(200, 500)
		templates["warlord"] = warlord
		
		# HEALER
		var healer = ArchetypeTemplate.new("healer")
		healer.description = "Compassionate caregiver"
		healer.warmth = 0.8
		healer.assertiveness = -0.3
		healer.conscientiousness = 0.7
		healer.curiosity = 0.4
		healer.risk_tolerance = -0.4
		healer.stability = 0.7
		healer.values = {"COMMUNITY": 0.9, "HONOR": 0.6, "KNOWLEDGE": 0.4}
		healer.baseline_drives = {
			"SELF_PRESERVATION": 0.9,
			"AVOID_PAIN": 0.9,
			"SEEK_WEALTH": 0.3,
			"SEEK_GIFTS": 0.4
		}
		healer.wealth_range = Vector2i(100, 300)
		templates["healer"] = healer
		
		# SCHOLAR
		var scholar = ArchetypeTemplate.new("scholar")
		scholar.description = "Knowledge seeker"
		scholar.warmth = 0.3
		scholar.assertiveness = -0.2
		scholar.conscientiousness = 0.8
		scholar.curiosity = 0.9
		scholar.risk_tolerance = -0.2
		scholar.stability = 0.6
		scholar.values = {"KNOWLEDGE": 0.9, "HONOR": 0.5, "POWER": 0.2}
		scholar.baseline_drives = {
			"SELF_PRESERVATION": 0.7,
			"SEEK_KNOWLEDGE": 0.9,
			"SEEK_WEALTH": 0.4,
			"AVOID_PAIN": 0.6
		}
		scholar.wealth_range = Vector2i(150, 400)
		templates["scholar"] = scholar
		
		# ROGUE
		var rogue = ArchetypeTemplate.new("rogue")
		rogue.description = "Independent opportunist"
		rogue.warmth = -0.1
		rogue.assertiveness = 0.3
		rogue.conscientiousness = -0.4
		rogue.curiosity = 0.5
		rogue.risk_tolerance = 0.8
		rogue.stability = 0.2
		rogue.values = {"FREEDOM": 0.9, "WEALTH": 0.6, "POWER": 0.3}
		rogue.baseline_drives = {
			"SELF_PRESERVATION": 0.5,
			"SEEK_WEALTH": 0.8,
			"SEEK_STATUS": 0.4,
			"AVOID_PAIN": 0.5
		}
		rogue.wealth_range = Vector2i(50, 250)
		templates["rogue"] = rogue
		
		# NOBLE
		var noble = ArchetypeTemplate.new("noble")
		noble.description = "High-born authority"
		noble.warmth = 0.2
		noble.assertiveness = 0.6
		noble.conscientiousness = 0.7
		noble.curiosity = 0.1
		noble.risk_tolerance = -0.3
		noble.stability = 0.8
		noble.values = {"HONOR": 0.8, "POWER": 0.7, "TRADITION": 0.6}
		noble.baseline_drives = {
			"SELF_PRESERVATION": 0.7,
			"SEEK_STATUS": 0.9,
			"SEEK_WEALTH": 0.6,
			"SEEK_GIFTS": 0.8
		}
		noble.wealth_range = Vector2i(800, 1500)
		templates["noble"] = noble
	
	func get_template(archetype: String) -> ArchetypeTemplate:
		if templates.has(archetype):
			return templates[archetype]
		push_error("Unknown archetype: " + archetype)
		return templates["merchant"]  # Safe fallback

class RoleModifier:
	var role_name: String
	var health_override: float = -1.0
	var wealth_override: Vector2i = Vector2i(-1, -1)
	var stress_override: float = -1.0
	var hunger_override: float = -1.0
	var energy_override: float = -1.0
	var drive_modifiers: Dictionary = {}
	func _init(name: String = ""): role_name = name

class RoleLibrary:
	var modifiers: Dictionary = {}
	func _init(): pass # Implement full roles if needed
	func get_modifier(role: String) -> RoleModifier: return modifiers.get(role, null)

# ============================================================================
# REQUEST PARSER
# ============================================================================

class RequestParser:
	var type_keywords = {
		"ASK": ["could you", "would you", "can you", "please", "may I"],
		"DEMAND": ["you must", "you will", "I order", "do it", "now"],
		"SUGGEST": ["how about", "what if", "maybe", "perhaps", "consider"],
		"THREATEN": ["or else", "if you don't", "consequences", "regret"],
		"INFORM": ["I heard", "did you know", "news", "rumor", "fact"],
		"NEGOTIATE": ["deal", "trade", "exchange", "offer", "bargain"]
	}
	
	var topic_keywords = {
		"combat": ["fight", "battle", "attack", "defend", "war", "soldier"],
		"trade": ["buy", "sell", "merchant", "gold", "goods", "price"],
		"alliance": ["ally", "together", "join", "unite", "partner", "team"],
		"personal": ["you", "your", "feel", "think", "family", "friend"],
		"information": ["know", "tell", "explain", "where", "who", "what"],
		"help": ["help", "assist", "aid", "support", "rescue", "save"]
	}
	var debugging : bool = true

	func _init(debug : bool = true):
		debugging = debug
		
	func parse_request(text: String) -> Request:
		var request = Request.new(text)
		var lower_text = text.to_lower()
		
		request.context.request_type = _identify_type(lower_text)
		request.context.topic = _identify_topic(lower_text)
		request.context.urgency = _assess_urgency(lower_text)
		request.context.emotional_tone = _assess_tone(lower_text)
		request.parsed_intent = _extract_intent(lower_text, request.context)
		request.response_options = _generate_response_options(request)
		
		return request
	
	func _identify_type(text: String) -> String:
		var best_match = "ASK"
		var best_score = 0
		for type in type_keywords:
			var score = 0
			for keyword in type_keywords[type]:
				if text.contains(keyword):
					score += 1
			if score > best_score:
				best_score = score
				best_match = type
		return best_match
	
	func _identify_topic(text: String) -> String:
		var best_match = "general"
		var best_score = 0
		for topic in topic_keywords:
			var score = 0
			for keyword in topic_keywords[topic]:
				if text.contains(keyword):
					score += 1
			if score > best_score:
				best_score = score
				best_match = topic
		return best_match
	
	func _assess_urgency(text: String) -> float:
		var urgency = 0.5
		if text.contains("!"):
			urgency += 0.2
		if text.contains("urgent") or text.contains("immediately"):
			urgency += 0.3
		if text.contains("now") or text.contains("quick"):
			urgency += 0.2
		return min(1.0, urgency)
	
	func _assess_tone(text: String) -> float:
		var tone = 0.0
		var positive = ["please", "friend", "appreciate", "thank", "kind"]
		for word in positive:
			if text.contains(word):
				tone += 0.2
		var negative = ["fool", "idiot", "stupid", "damn", "hell"]
		for word in negative:
			if text.contains(word):
				tone -= 0.3
		return clamp(tone, -1.0, 1.0)
	
	func _extract_intent(text: String, context: RequestContext) -> Dictionary:
		var intent = {}
		match context.request_type:
			"ASK":
				intent["comply"] = 0.6
				intent["negotiate"] = 0.3
				intent["refuse"] = 0.1
			"DEMAND":
				intent["comply"] = 0.3
				intent["refuse"] = 0.5
				intent["challenge"] = 0.2
			"NEGOTIATE":
				intent["negotiate"] = 0.6
				intent["accept"] = 0.2
				intent["counter"] = 0.2
			_:
				intent["acknowledge"] = 0.5
				intent["question"] = 0.5
		return intent
	func _infer_action_tags(request: Request) -> Dictionary:
		var tags = {}
		var lower_text = request.raw_text.to_lower()
		
		# Combat/Risk detection
		if request.context.topic == "combat" or _contains_any(lower_text, ["fight", "battle", "attack", "combat"]):
			tags["risky"] = 0.6 + request.context.urgency * 0.3
			tags["combat"] = true
			tags["helps"] = request.context.requester_id
			
			if _contains_any(lower_text, ["dangerous", "deadly", "lethal", "die", "death"]):
				tags["lethal"] = true
				tags["risky"] = 0.9
		
		# Money detection
		if _contains_any(lower_text, ["gold", "coins", "pay", "reward", "treasure", "money"]):
			# Try to extract amount
			var amount = _extract_number(lower_text)
			if amount > 0:
				tags["money_reward"] = amount
			else:
				tags["money_reward"] = 50  # Default
		
		if _contains_any(lower_text, ["lend", "borrow", "loan", "cost"]):
			var amount = _extract_number(lower_text)
			if amount > 0:
				tags["money_cost"] = amount
			else:
				tags["money_cost"] = 50
		
		# Gift detection
		if _contains_any(lower_text, ["gift", "present", "offering"]):
			tags["gift_received"] = true
			tags["money_reward"] = 30  # Gifts have monetary value
		
		# Protection/Help detection
		if _contains_any(lower_text, ["help", "protect", "save", "rescue", "assist"]):
			tags["helps"] = request.context.requester_id
			
			# Check if protecting someone else
			if _contains_any(lower_text, ["protect", "save"]):
				var protected = _extract_protected_entity(lower_text)
				if protected:
					tags["helps"] = protected  # Override to the actual target
		
		# Harm detection
		if _contains_any(lower_text, ["kill", "murder", "harm", "hurt", "assassinate", "attack"]):
			var target = _extract_target_entity(lower_text)
			if target:
				tags["harms"] = target
		
		# Status/Prestige detection
		if _contains_any(lower_text, ["glory", "honor", "fame", "reputation", "prestige"]):
			tags["prestige"] = 0.7
		
		# Knowledge detection
		if _contains_any(lower_text, ["teach", "learn", "know", "information", "secret"]):
			tags["knowledge_gain"] = true
		
		return tags
	

	func _contains_any(text: String, keywords: Array) -> bool:
		for keyword in keywords:
			if keyword in text:
				return true
		return false

	func _extract_number(text: String) -> int:
		var regex = RegEx.new()
		regex.compile("\\b(\\d+)\\b")
		var result = regex.search(text)
		if result:
			return result.get_string().to_int()
		return 0

	func _extract_protected_entity(text: String) -> String:
		# Simple pattern matching for now
		if "princess" in text:
			return "princess"
		if "prince" in text:
			return "prince"
		if "child" in text or "children" in text:
			return "children"
		if "king" in text:
			return "king"
		if "queen" in text:
			return "queen"
		# Could expand with more sophisticated parsing
		return ""

	func _extract_target_entity(text: String) -> String:
		# Similar to _extract_protected_entity
		return _extract_protected_entity(text)

	
	func _generate_response_options(request: Request) -> Array[ResponseOption]:
		var options: Array[ResponseOption] = []
		
		# NEW: Infer action tags from request
		var inferred_tags = _infer_action_tags(request)
		
		# AGREE options with variants
		for i in range(3):
			var agree = ResponseOption.new()
			agree.response_type = "AGREE"
			agree.base_score = 0.5
			agree.personality_tags = {"is_helpful": true, "is_cooperative": true}
			agree.template_variant = i
			agree.action_tags = inferred_tags.duplicate()  # NEW: Add tags
			match i:
				0: agree.response_template = "I'll {action}. {reason}"
				1: agree.response_template = "{enthusiasm}, I can {action}. {reason}"
				2: agree.response_template = "Of course. {action_detail}"
			options.append(agree)
		
		# REFUSE options with variants
		for i in range(3):
			var refuse = ResponseOption.new()
			refuse.response_type = "REFUSE"
			refuse.base_score = 0.5
			refuse.personality_tags = {"is_assertive": true, "is_cautious": true}
			refuse.template_variant = i
			# NEW: Refusing removes most action consequences
			refuse.action_tags = {"safe": true}  # Refusing is usually safer
			match i:
				0: refuse.response_template = "I cannot {action}. {reason}"
				1: refuse.response_template = "{dismissal}. {reason}"
				2: refuse.response_template = "No. {harsh_reason}"
			options.append(refuse)
		
		# NEGOTIATE options with variants
		for i in range(3):
			var negotiate = ResponseOption.new()
			negotiate.response_type = "NEGOTIATE"
			negotiate.base_score = 0.5
			negotiate.personality_tags = {"is_strategic": true, "is_calculating": true}
			negotiate.template_variant = i
			# NEW: Negotiation reduces risk but maintains other tags
			negotiate.action_tags = inferred_tags.duplicate()
			if negotiate.action_tags.has("risky"):
				negotiate.action_tags["risky"] *= 0.5  # Negotiation reduces risk
			match i:
				0: negotiate.response_template = "Perhaps, but {condition}. {offer}"
				1: negotiate.response_template = "I might consider it if {condition}. {offer}"
				2: negotiate.response_template = "{condition_question} Then we can discuss terms."
			options.append(negotiate)
		
		# DEFLECT option
		var deflect = ResponseOption.new()
		deflect.response_type = "DEFLECT"
		deflect.base_score = 0.4
		deflect.personality_tags = {"is_evasive": true, "is_cautious": true}
		deflect.response_template = "That's interesting, but {redirect}. {alternative}"
		deflect.action_tags = {"safe": true}  # NEW: Deflecting is safe
		options.append(deflect)
		
		# CHALLENGE option for threats
		if request.context.request_type == "THREATEN":
			var challenge = ResponseOption.new()
			challenge.response_type = "CHALLENGE"
			challenge.base_score = 0.5
			challenge.personality_tags = {"is_aggressive": true, "is_brave": true}
			challenge.response_template = "You dare threaten me? {consequence}"
			challenge.action_tags = {"risky": 0.5, "prestige": 0.6}  # NEW: Standing up has risks but gains respect
			options.append(challenge)

		assert(options.size() >= 9, "Not enough response options generated!")
		

		return options
	

# ============================================================================
# RESPONSE GENERATOR (Logic for standard dialogue)
# ============================================================================
class ResponseGenerator:
	# Response type constants
	const AGREE = "AGREE"
	const AGREE_CONDITIONAL = "AGREE_CONDITIONAL"
	const REFUSE = "REFUSE"
	const REFUSE_SOFT = "REFUSE_SOFT"
	const REFUSE_HEDGED = "REFUSE_HEDGED"
	const NEGOTIATE = "NEGOTIATE"
	const DEFLECT = "DEFLECT"
	const CHALLENGE = "CHALLENGE"
	
	# Tag constants for phrase compatibility
	const TAG_POSITIVE = ["AGREE", "AGREE_CONDITIONAL", "NEGOTIATE"]  # Acceptance/cooperation
	const TAG_NEGATIVE = ["REFUSE", "REFUSE_SOFT", "REFUSE_HEDGED", "DEFLECT"]  # Rejection
	const TAG_AGGRESSIVE = ["CHALLENGE", "REFUSE"]  # Confrontational
	const TAG_COOPERATIVE = ["AGREE", "NEGOTIATE"]  # Working together
	const TAG_UNCERTAIN = ["NEGOTIATE", "DEFLECT", "REFUSE_HEDGED"]  # Hesitant/conditional
	const TAG_ALL = ["AGREE", "AGREE_CONDITIONAL", "REFUSE", "REFUSE_SOFT", "REFUSE_HEDGED", "NEGOTIATE", "DEFLECT", "CHALLENGE"]
	
	# Grammar compatibility constants
	const DEFINITIVE_CORES = [
		"Out of the question",
		"Never",
		"Absolutely not",
		"Certainly",
		"Of course"
	]
	
	const INCOMPATIBLE_WITH_HESITATION = [
		"Out of the question",
		"Never",
		"That is final",
		"End of discussion",
		"Absolutely",
		"Certainly"
	]
	
	# Phrase pools with compatibility tags
	var enthusiasm_phrases = {
		"high": {
			"phrases": ["Absolutely", "Gladly", "With pleasure", "Certainly"],
			"compatible_with": TAG_POSITIVE
		},
		"medium": {
			"phrases": ["Sure", "Alright", "I can do that", "Very well"],
			"compatible_with": TAG_POSITIVE
		},
		"low": {
			"phrases": ["I suppose", "If necessary", "Fine", "As you wish"],
			"compatible_with": TAG_POSITIVE + TAG_UNCERTAIN
		}
	}
	
	var dismissal_phrases = {
		"harsh": {
			"phrases": ["No", "Absolutely not", "Out of the question", "Never"],
			"compatible_with": TAG_NEGATIVE
		},
		"polite": {
			"phrases": ["I'm afraid not", "I must decline", "Unfortunately no", "I cannot"],
			"compatible_with": TAG_NEGATIVE
		}
	}
	
	var condition_questions = {
		"phrases": [
			"What can you offer me in return?",
			"What's in it for me?",
			"And what do I gain from this?",
			"Why should I agree to this?"
		],
		"compatible_with": ["NEGOTIATE"]
	}
	
	# Risk-tolerance phrases with tags
	var risk_phrases = {
		"high_risk_enthusiasm": {
			"phrases": ["gladly", "eagerly", "enthusiastically", "with excitement"],
			"compatible_with": TAG_POSITIVE,
			"usage": "adverb_modifier"  # How to apply: modifies verbs
		},
		"high_risk_acceptance": {
			"phrases": ["Let's do it!", "Sounds exciting!", "I'm in!", "Why not?", "Absolutely!"],
			"compatible_with": TAG_POSITIVE,
			"usage": "standalone"  # Replaces entire response
		},
		"high_risk_prefix_positive": {
			"phrases": ["I'd love to", "I'd be thrilled to", "I'm eager to"],
			"compatible_with": TAG_POSITIVE,
			"usage": "verb_prefix"  # Prefix before main verb
		},
		"high_risk_prefix_negative": {
			"phrases": ["I'd love to, but", "I'd be happy to, but", "I wish I could, but"],
			"compatible_with": TAG_NEGATIVE,
			"usage": "refusal_softener"  # Makes refusals less harsh
		},
		"low_risk_hedging": {
			"phrases": ["carefully", "cautiously", "with great care", "if it's safe"],
			"compatible_with": TAG_POSITIVE + TAG_UNCERTAIN,
			"usage": "adverb_modifier"
		},
		"low_risk_acceptance": {
			"phrases": ["If we're careful...", "Cautiously, yes", "We must be safe", "Proceed slowly"],
			"compatible_with": TAG_POSITIVE + TAG_UNCERTAIN,
			"usage": "standalone"
		},
		"low_risk_refusal_reason": {
			"phrases": ["That's too dangerous", "Too risky for my taste", "I must be cautious", "It's too uncertain"],
			"compatible_with": TAG_NEGATIVE,
			"usage": "reason"  # Used in {reason} slot
		},
		"bold_refusal_reason": {
			"phrases": ["Not worth my time", "Doesn't interest me", "I have better things to do", "Too mundane"],
			"compatible_with": TAG_NEGATIVE,
			"usage": "reason"
		}
	}
	
	# Conscientiousness phrases with tags
	var conscientiousness_phrases = {
		"high_precision": {
			"phrases": ["correctly", "properly", "precisely", "according to protocol", "by the book", "as it should be done", "with proper procedure"],
			"compatible_with": TAG_POSITIVE + TAG_UNCERTAIN,
			"usage": "adverb_modifier"
		},
		"low_casual": {
			"phrases": ["more or less", "I guess", "probably", "good enough", "doesn't matter much", "whatever works"],
			"compatible_with": TAG_ALL,
			"usage": "adverb_modifier"
		}
	}
	
	# Warmth phrases with tags
	var warmth_phrases = {
		"high_warmth_suffix": {
			"phrases": [", friend", ", my friend"],
			"compatible_with": TAG_ALL,  # Can be used with any response
			"usage": "sentence_suffix"
		},
		"high_warmth_prefix": {
			"phrases": ["Well,", "You see,"],
			"compatible_with": TAG_ALL,
			"usage": "sentence_prefix"
		},
		"soft_refusal_intro": {
			"phrases": ["I'm so sorry, but", "I'm afraid", "Unfortunately", "I wish I could help, but"],
			"compatible_with": TAG_NEGATIVE,
			"usage": "refusal_softener"
		}
	}
	
	# Assertiveness phrases with tags
	var assertiveness_phrases = {
		"high_assertive_prefix": {
			"phrases": ["Listen.", "Now listen.", "Understand this."],
			"compatible_with": TAG_ALL,
			"usage": "sentence_prefix"
		},
		"high_assertive_suffix": {
			"phrases": [" That is final.", " End of discussion.", " No more debate."],
			"compatible_with": TAG_NEGATIVE + ["CHALLENGE"],
			"usage": "sentence_suffix"
		}
	}
	
	# Prefix phrases with tags (for _add_personality_flavor)
	var personality_prefixes = {
		"hesitation": {
			"phrases": ["I… "],
			"compatible_with": TAG_ALL,
			"incompatible_with_cores": INCOMPATIBLE_WITH_HESITATION,
			"conditions": {"max_assertiveness": -0.4, "max_stability": -0.3, "random_threshold": 0.92}
		},
		"curiosity": {
			"phrases": ["Interesting… "],
			"compatible_with": TAG_ALL,
			"incompatible_with_cores": INCOMPATIBLE_WITH_HESITATION,
			"conditions": {"min_curiosity": 0.7, "random_threshold": 0.85}
		},
		"assertiveness": {
			"phrases": ["Listen. "],
			"compatible_with": TAG_ALL,
			"conditions": {"min_assertiveness": 0.7, "random_threshold": 0.8}
		},
		"warmth": {
			"phrases": ["Well, "],
			"compatible_with": TAG_ALL,
			"conditions": {"min_warmth": 0.5, "random_threshold": 0.85}
		}
	}
	var debugging : bool = true

	func _init(debug : bool = false):
		debugging = debug

	func _add_personality_flavor(response: String, personality: Personality, response_type: String, debug : bool = false) -> String:
		# Don't add flavor if already has flavor
		if response.begins_with("Well, ") or response.begins_with("Listen. ") or response.begins_with("Interesting… "):
			return response
		
		# Check each prefix type
		for prefix_type in personality_prefixes:
			var prefix_data = personality_prefixes[prefix_type]
			
			# Check if compatible with response type
			if not _is_compatible(response_type, prefix_data.compatible_with):
				continue
			
			# Check if response core is incompatible
			if prefix_data.has("incompatible_with_cores"):
				if _has_incompatible_core(response, prefix_data.incompatible_with_cores):
					continue
			
			# Check personality conditions
			var conditions_met = true
			var conditions = prefix_data.conditions
			
			if conditions.has("max_assertiveness") and personality.assertiveness >= conditions.max_assertiveness:
				conditions_met = false
			if conditions.has("max_stability") and personality.stability >= conditions.max_stability:
				conditions_met = false
			if conditions.has("min_assertiveness") and personality.assertiveness <= conditions.min_assertiveness:
				conditions_met = false
			if conditions.has("min_curiosity") and personality.curiosity <= conditions.min_curiosity:
				conditions_met = false
			if conditions.has("min_warmth") and personality.warmth <= conditions.min_warmth:
				conditions_met = false
			
			# Check random threshold
			if conditions.has("random_threshold") and randf() <= conditions.random_threshold:
				conditions_met = false
			
			# Apply prefix if all conditions met
			if conditions_met:
				var phrase = prefix_data.phrases[0]
				if prefix_type == "warmth" or prefix_type == "curiosity":
					response = phrase + _lowercase_first_char_safe(response)
				else:
					response = phrase + response
				break  # Only apply one prefix
		
		return response

	# Main generation function
	func generate_response(npc: NPC, chosen_option: ResponseOption, request: Request) -> String:
		var response = chosen_option.response_template
		var response_type = chosen_option.response_type  # IMPORTANT: Declare this at the top
		
		# Handle knowledge responses first (returns early, bypasses rest)
		if response_type in ["SHARE_KNOWLEDGE", "SHARE_CAUTIOUS"]:
			return _format_knowledge_response(npc, chosen_option)
		
		# NEW: Handle ADMIT_IGNORANCE (complete response, skip modifiers)
		if response_type == "ADMIT_IGNORANCE":
			response = _select_knowledge_template("ADMIT_IGNORANCE", "", npc.personality)
			# Note: response_type is still in scope for _add_personality_flavor below
		
		# NEW: Handle DENY_KNOWLEDGE (complete response, skip modifiers)
		elif response_type == "DENY_KNOWLEDGE":
			response = _select_knowledge_template("DENY_KNOWLEDGE", "", npc.personality)
		
		# NEW: Handle ADMIT_FORGOTTEN (complete response, skip modifiers)
		elif response_type == "ADMIT_FORGOTTEN":
			response = _select_knowledge_template("ADMIT_FORGOTTEN", "", npc.personality)
		
		# For all OTHER response types, apply normal modifiers
		else:
			# Apply modifiers in order (existing logic for AGREE, REFUSE, NEGOTIATE, etc.)
			response = _apply_personality_modifiers(response, npc.personality, chosen_option.template_variant, response_type)
			response = _apply_value_modifiers(response, npc.personality.values, chosen_option.template_variant, response_type)
			response = _apply_context_modifiers(response, npc, request.context, response_type)
			response = _apply_relationship_modifiers(response, npc.get_relationship(request.context.requester_id), npc.personality, response_type)
		
		# Add personality flavor to ALL responses (response_type is in scope throughout)
		response = _add_personality_flavor(response, npc.personality, response_type)
		
		# Ensure proper punctuation
		if not response.ends_with(".") and not response.ends_with("!") and not response.ends_with("?"):
			response = response + "."
		
		# Add closings (existing logic)
		if npc.personality.warmth > 0.3 and randf() > 0.7:
			response = response.trim_suffix(".") + ", friend."
		
		# Add assertive ending
		response = _add_assertive_ending(response, npc.personality, response_type)
		
		# Format with NPC name
		return "[%s]: %s" % [npc.name, response]

	
	
	# Helper function to check if response_type is compatible with tag list
	func _is_compatible(response_type: String, tag_list: Array) -> bool:
		return response_type in tag_list
	
	# Helper function to check if response starts with incompatible core
	func _has_incompatible_core(response: String, incompatible_list: Array) -> bool:
		for phrase in incompatible_list:
			if response.begins_with(phrase):
				return true
		return false
	
	# MODIFIED: Now accepts response_type for tag checking
	func _apply_personality_modifiers(template: String, personality: Personality, variant: int, response_type: String) -> String:
		var result = template
		
		# {action} variations (tag-aware based on response_type)
		if result.contains("{action}"):
			var actions = []
			
			# High conscientiousness: only for positive/cooperative responses
			if personality.conscientiousness > 0.5 and _is_compatible(response_type, TAG_POSITIVE):
				actions = ["handle this properly", "address this correctly", "deal with this responsibly"]
			
			# High risk-tolerance: only for positive responses
			elif personality.risk_tolerance > 0.5 and _is_compatible(response_type, TAG_POSITIVE):
				actions = ["take on this challenge", "dive into this", "tackle this head-on"]
			
			# Generic actions work for all types
			else:
				if _is_compatible(response_type, TAG_POSITIVE):
					actions = ["do that", "help with this", "assist you"]
				else:
					actions = ["get involved", "help", "assist"]
			
			result = result.replace("{action}", actions[variant % actions.size()])
		
		# {action_detail} variations
		if result.contains("{action_detail}"):
			var details = [
				"I'll handle it right away.",
				"Leave it to me.",
				"I'll take care of it.",
				"Consider it done."
			]
			result = result.replace("{action_detail}", details[variant % details.size()])
		
		# {enthusiasm} based on warmth (tag-aware)
		if result.contains("{enthusiasm}"):
			var level = "medium"
			if personality.warmth > 0.5:
				level = "high"
			elif personality.warmth < -0.3:
				level = "low"
			
			var pool = enthusiasm_phrases[level]
			if _is_compatible(response_type, pool.compatible_with):
				var phrases = pool.phrases
				result = result.replace("{enthusiasm}", phrases[randi() % phrases.size()])
			else:
				# Fallback to neutral
				result = result.replace("{enthusiasm}", "")
		
		# {dismissal} based on assertiveness (only for negative responses)
		if result.contains("{dismissal}"):
			if _is_compatible(response_type, TAG_NEGATIVE):
				var level = "polite"
				if personality.assertiveness > 0.5:
					level = "harsh"
				var pool = dismissal_phrases[level]
				var phrases = pool.phrases
				result = result.replace("{dismissal}", phrases[randi() % phrases.size()])
		
		# {reason} variations (context-aware)
		if result.contains("{reason}"):
			var reasons = _generate_reasons(personality, response_type)
			result = result.replace("{reason}", reasons[variant % reasons.size()])
		
		# {harsh_reason} for refusals only
		if result.contains("{harsh_reason}"):
			if _is_compatible(response_type, TAG_NEGATIVE):
				var harsh_reasons = [
					"I have more important matters",
					"This doesn't concern me",
					"Find someone else",
					"That's not my problem"
				]
				result = result.replace("{harsh_reason}", harsh_reasons[randi() % harsh_reasons.size()])
		
		# Risk-Tolerance vocabulary modifications (TAG-AWARE)
		if personality.risk_tolerance > 0.6:
			if _is_compatible(response_type, TAG_POSITIVE):
				# High risk + positive = enthusiasm
				if result.contains("I'll ") and not result.contains("I'll gladly"):
					result = result.replace("I'll ", "I'll gladly ")
				if result.contains("I can ") and not result.contains("I'd love to"):
					result = result.replace("I can ", "I'd love to ")
				result = result.replace("perhaps", "absolutely")
				
				# Add enthusiasm to acceptances
				if result.begins_with("Of course"):
					result = result.replace("Of course", "Absolutely")
			
			elif _is_compatible(response_type, TAG_NEGATIVE):
				# High risk + negative = soften with "I'd love to, but"
				if result.begins_with("I cannot") or result.begins_with("I can't"):
					result = "I'd love to, but " + result.to_lower()
				elif result.begins_with("I must decline"):
					result = "I'd love to help, but I must decline"
				elif result.begins_with("Unfortunately"):
					result = "I'd love to assist, but unfortunately " + result.substr(15).to_lower()
		
		elif personality.risk_tolerance < -0.4:
			if _is_compatible(response_type, TAG_POSITIVE + TAG_UNCERTAIN):
				# Low risk = cautious language for positive/uncertain responses
				if result.contains("I'll ") and not result.contains("carefully"):
					result = result.replace("I'll ", "I'll carefully ")
				elif result.contains("I can "):
					result = result.replace("I can ", "I can try to ")
				
				# Add safety qualifiers
				if not result.contains("careful") and not result.contains("cautious"):
					if randf() > 0.7:
						result = result.replace(". ", ", if it's safe. ")
		
		# Conscientiousness vocabulary (TAG-AWARE, with variety)
		if personality.conscientiousness > 0.6:
			if _is_compatible(response_type, TAG_POSITIVE):
				# High conscientiousness + positive = precise language
				var pool = conscientiousness_phrases["high_precision"]
				var phrases = pool.phrases
				var chosen = phrases[randi() % phrases.size()]
				
				# Only apply 30% of the time to avoid overuse
				if randf() > 0.7:
					if result.contains("I'll take care"):
						result = result.replace("take care", "handle this " + chosen)
					elif result.contains("I can do"):
						result = result.replace("I can do", "I can execute this " + chosen)
		
		elif personality.conscientiousness < -0.3:
			# Low conscientiousness = casual language (works with all types)
			if randf() > 0.75:
				var pool = conscientiousness_phrases["low_casual"]
				var phrases = pool.phrases
				var chosen = phrases[randi() % phrases.size()]
				result = result.replace("I'll ", "I'll " + chosen + " ")
		
		return result
	
	func _generate_reasons(personality: Personality, response_type: String) -> Array[String]:
		var reasons: Array[String] = []
		
		# Positive responses get positive reasons
		if _is_compatible(response_type, TAG_POSITIVE):
			if personality.warmth > 0.5:
				reasons.append_array(["I want to help.", "I'm happy to assist.", "I care about this."])
			if personality.assertiveness > 0.5:
				reasons.append_array(["It's necessary.", "It must be done.", "There's no other way."])
			if personality.conscientiousness > 0.5:
				reasons.append_array(["It's the proper course.", "It's the right thing.", "Protocol demands it."])
		
		# Negative responses get negative reasons
		elif _is_compatible(response_type, TAG_NEGATIVE):
			if personality.risk_tolerance < -0.3:
				reasons.append_array(["It's too dangerous.", "The risk is too high.", "I must be cautious."])
			if personality.assertiveness > 0.5:
				reasons.append_array(["I have more important matters.", "This doesn't concern me.", "I'm not interested."])
			if personality.warmth < -0.3:
				reasons.append_array(["That's not my problem.", "Find someone else.", "I have better things to do."])
		
		# Fallback
		if reasons.is_empty():
			if _is_compatible(response_type, TAG_POSITIVE):
				reasons = ["I have my reasons.", "It's complicated.", "Trust me on this."]
			else:
				reasons = ["I have my reasons.", "It's complicated.", "Not interested."]
		
		return reasons
	
	# MODIFIED: Now accepts response_type
	func _apply_value_modifiers(template: String, values: Dictionary, variant: int, response_type: String) -> String:
		var result = template
		
		var highest_value = ""
		var highest_score = 0.0
		for value in values:
			if values[value] > highest_score:
				highest_score = values[value]
				highest_value = value
		
		# {condition} variations by value (only for negotiate/uncertain)
		if result.contains("{condition}"):
			if _is_compatible(response_type, TAG_UNCERTAIN):
				var conditions = _generate_conditions(highest_value)
				result = result.replace("{condition}", conditions[variant % conditions.size()])
		
		# {condition_question} variations (only for negotiate)
		if result.contains("{condition_question}"):
			if response_type == "NEGOTIATE":
				result = result.replace("{condition_question}", condition_questions.phrases[randi() % condition_questions.phrases.size()])
		
		# {offer} variations by value (only for negotiate)
		if result.contains("{offer}"):
			if response_type == "NEGOTIATE":
				var offers = _generate_offers(highest_value)
				result = result.replace("{offer}", offers[variant % offers.size()])
		
		return result
	
	func _generate_conditions(value: String) -> Array[String]:
		match value:
			"POWER":
				return ["I maintain control", "I keep authority", "I stay in charge", "my position is secure"]
			"HONOR":
				return ["it's done honorably", "we maintain integrity", "it's done properly", "honor is preserved"]
			"WEALTH":
				return ["I'm compensated fairly", "the price is right", "I profit from this", "there's gold involved"]
			"KNOWLEDGE":
				return ["you share what you know", "I learn something", "you tell me everything", "information flows both ways"]
			_:
				return ["we agree on terms", "it's mutually beneficial", "we both gain", "it's fair to both"]
	
	func _generate_offers(value: String) -> Array[String]:
		match value:
			"POWER":
				return ["I'll need something in return.", "You'll owe me.", "This comes at a cost.", "I expect compensation."]
			"HONOR":
				return ["Let's do this properly.", "We maintain honor.", "It must be done right.", "With integrity."]
			"WEALTH":
				return ["What's your offer?", "Name your price.", "How much?", "What can you pay?"]
			"KNOWLEDGE":
				return ["Tell me more first.", "Explain everything.", "I need all the details.", "What do you know?"]
			_:
				return ["What do you propose?", "What are your terms?", "What's the arrangement?", "Let's discuss."]
	
	# MODIFIED: Now accepts response_type
	func _apply_context_modifiers(template: String, npc: NPC, request_context: RequestContext, response_type: String) -> String:
		var result = template
		var personality = npc.personality
		var npc_context: NPCContext = npc.context
		var assertiveness = personality.assertiveness
		var stress_level = npc_context.stress_level
		
		# Stress hesitation (only if not definitive and assertiveness allows)
		if (stress_level > 0.7 and randf() > 0.9 and assertiveness < 0.7) or (assertiveness < 0.4 and randf() > 0.85):
			if not _has_incompatible_core(result, INCOMPATIBLE_WITH_HESITATION):
				result = "I… " + result
		
		# Urgency modifications (only for positive/uncertain responses)
		if request_context.urgency > 0.8 and _is_compatible(response_type, TAG_POSITIVE + TAG_UNCERTAIN):
			result = result.replace("Perhaps", "Fine")
			result = result.replace("I'll consider", "I'll do it")
			result = result.replace("I might", "I will")
		
		# Context-specific elements
		if result.contains("{redirect}"):
			result = result.replace("{redirect}", _generate_redirect(npc_context))
		if result.contains("{alternative}"):
			result = result.replace("{alternative}", _generate_alternative(npc_context))
		
		return result
	
	func _generate_redirect(context: NPCContext) -> String:
		if context.stress_level > 0.5:
			return "I have other concerns"
		elif not context.active_goals.is_empty():
			return "I'm focused on " + context.active_goals[0]
		else:
			return "there are other matters"
	
	func _generate_alternative(context: NPCContext) -> String:
		match context.role:
			"merchant":
				return "Perhaps a trade instead?"
			"scholar":
				return "Let me research this first"
			"warlord", "warrior":
				return "We should prepare properly"
			_:
				return "We could try something else"
	
	# MODIFIED: Now accepts personality and response_type
	func _apply_relationship_modifiers(template: String, relationship: Relationship, personality: Personality, response_type: String) -> String:
		var result = template
		
		# High trust = more direct (only for positive responses)
		if relationship.trust > 0.7 and _is_compatible(response_type, TAG_POSITIVE):
			result = result.replace("Perhaps", "Yes")
			result = result.replace("I might", "I will")
		
		# Fear = cautious (but NOT if high assertiveness)
		if relationship.fear > 0.5 and personality.assertiveness < 0.70:
			if not _has_incompatible_core(result, INCOMPATIBLE_WITH_HESITATION):
				if not result.begins_with("I… "):
					result = "I… " + result.to_lower()
		
		# Affection = warmth (works with all types)
		if relationship.affection > 0.6 and randf() > 0.7:
			if not result.begins_with("Of course, "):
				result = "Of course, " + result.to_lower()
		
		# Replace {consequence} (only for challenge/aggressive responses)
		if result.contains("{consequence}"):
			if _is_compatible(response_type, TAG_AGGRESSIVE):
				if relationship.fear > 0.3:
					result = result.replace("{consequence}", "Please, let's discuss this")
				else:
					result = result.replace("{consequence}", "You'll regret this")
		
		return result
	
	
	# MODIFIED: Now accepts response_type
	func _add_assertive_ending(response: String, personality: Personality, response_type: String) -> String:
		# Only high assertiveness (>0.7) can add "That is final"
		# And only for negative/aggressive responses
		if personality.assertiveness > 0.7 and randf() > 0.7:
			if _is_compatible(response_type, TAG_NEGATIVE + ["CHALLENGE"]):
				if _is_negative_response(response):
					response += " That is final."
		
		return response
	
	func _is_negative_response(response: String) -> bool:
		var negative_indicators = ["No.", "Never.", "Out of the question", "I cannot", "I must decline"]
		for indicator in negative_indicators:
			if response.contains(indicator):
				return true
		return false
	
	func apply_personality_constraints(options: Array[ResponseOption], personality: Personality) -> Array[ResponseOption]:
		var filtered: Array[ResponseOption] = []
		
		var harsh_rejections = [
			"No. Find someone else",
			"No. This doesn't concern me",
			"No. That's not my problem",
			"Out of the question",
			"Never."
		]
		
		var absolute_language = [
			"Never",
			"Absolutely not",
			"Out of the question",
			"That is final",
			"End of discussion"
		]
		
		for option in options:
			var is_harsh = false
			var is_absolute = false
			
			for harsh in harsh_rejections:
				if option.response_template.contains(harsh):
					is_harsh = true
					break
			
			for absolute in absolute_language:
				if option.response_template.contains(absolute):
					is_absolute = true
					break
			
			# High warmth (>0.7) characters CANNOT use harsh rejections
			if personality.warmth > 0.7 and is_harsh:
				continue
			
			# Low assertiveness (<-0.2) should AVOID absolute language
			if personality.assertiveness < -0.2 and is_absolute:
				continue
			
			filtered.append(option)
		
		return filtered
	
	func create_soft_refusal() -> ResponseOption:
		var option = ResponseOption.new()
		option.response_type = "REFUSE_SOFT"
		option.base_score = 0.6
		option.personality_tags = {"is_polite": true, "is_apologetic": true}
		
		var templates = [
			"I'm so sorry, but I cannot {action}. I wish I could help",
			"I'm afraid I can't {action}, friend. I truly wish I could",
			"Unfortunately, I must decline. I apologize",
			"I wish I could help, but I cannot {action}. Forgive me"
		]
		option.response_template = templates[randi() % templates.size()]
		
		return option
	
	func create_hedged_refusal() -> ResponseOption:
		var option = ResponseOption.new()
		option.response_type = "REFUSE_HEDGED"
		option.base_score = 0.6
		option.personality_tags = {"is_uncertain": true, "is_cautious": true}
		
		var templates = [
			"I don't think I can {action}. Perhaps someone else",
			"I'm not sure about this. Maybe {alternative}",
			"I probably shouldn't {action}. I have my reasons",
			"I'd rather not {action}, if that's alright"
		]
		option.response_template = templates[randi() % templates.size()]
		
		return option
	
	func select_fallback_text(npc: NPC) -> String:
		if npc.personality.assertiveness > 0.5:
			return "I need to consider my position strategically"
		elif npc.context.role == "scholar":
			return "I need to research this matter further"
		elif npc.context.role == "rogue":
			return "I need to weigh the risks before deciding"
		elif npc.context.role == "noble":
			return "I must consult my advisors first"
		elif npc.personality.warmth > 0.5:
			return "I need a moment to think about this, friend"
		else:
			return "I need time to consider this carefully"
	
	func _lowercase_first_char_safe(text: String) -> String:
		if text.is_empty():
			return text
		if text.begins_with("I "):
			return text
		return text[0].to_lower() + text.substr(1)

	func _format_knowledge_response(npc: NPC, option: ResponseOption) -> String:
		# Safety check: ensure we have valid knowledge result
		if not option.knowledge_result or not option.knowledge_result.success:
			return "[" + npc.name + "]: I don't know anything about that."
		
		var k_result = option.knowledge_result
		
		# Safety check: ensure we have facts
		if k_result.facts.is_empty():
			return "[" + npc.name + "]: I don't know anything about that."
		
		var fact = k_result.facts[0].data
		
		# NEW: Safety check - verify fact data has required fields
		if not fact.has("subject") or not fact.has("predicate") or not fact.has("object"):
			push_warning("Malformed fact data: %s" % str(fact))
			return "[" + npc.name + "]: I can't quite recall the details."
		
		# NEW: Validate that the fact is actually relevant
		# (This prevents using tavern facts for blacksmith queries)
		if not _is_fact_relevant_to_response(fact, option.response_type):
			push_warning("Irrelevant fact selected for response: %s" % str(fact))
			return "[" + npc.name + "]: Hmm, I'm not sure about that."
		
		# Get confidence level
		var confidence_level = "high"
		if k_result.confidence < 0.3:
			confidence_level = "low"
		elif k_result.confidence < 0.6:
			confidence_level = "medium"
		
		# Select template based on type and personality
		var template = _select_knowledge_template(
			option.response_type,
			confidence_level,
			npc.personality
		)
		
		print("Template returned: '%s'" % template)
		
		# Fill template with fact data
		var response = template \
			.replace("{subject}", fact.get("subject", "it")) \
			.replace("{predicate}", fact.get("predicate", "is")) \
			.replace("{object}", fact.get("object", "unknown"))
#		print("Fact data: subject='%s', predicate='%s', object='%s'" % [fact.subject, fact.predicate, fact.object])
		
		# Apply personality flavor
		response = _add_personality_flavor(response, npc.personality, option.response_type)

		if response.length() > 0:
			response = response[0].to_upper() + response.substr(1)
		
		return "[" + npc.name + "]: " + response

	# NEW HELPER FUNCTION: Validate fact relevance
	func _is_fact_relevant_to_response(fact_data: Dictionary, response_type: String) -> bool:
		# For knowledge sharing responses, verify the fact has meaningful content
		if response_type in ["SHARE_KNOWLEDGE", "SHARE_CAUTIOUS"]:
			var subject = str(fact_data.get("subject", ""))
			var predicate = str(fact_data.get("predicate", ""))
			var obj = str(fact_data.get("object", ""))
			
			# Check for empty or placeholder values
			if subject.is_empty() or obj.is_empty():
				return false
			
			if subject == "unknown" or obj == "unknown":
				return false
			
			# Fact should have actual content
			if subject.length() < 3 or obj.length() < 3:
				return false
			
			return true
		
		# Other response types are always valid
		return true

	# OPTIONAL: Enhanced version that checks query-fact alignment
	# Add this if you want even stricter validation
	func _fact_matches_query_intent(fact_data: Dictionary, query_tags: Array[String]) -> bool:
		# This would require passing query_tags through to the response generator
		# For now, the tag matching in QueryExecutor handles this
		# But you could add additional checks here if needed
		return true
		
		
	func _select_knowledge_template(response_type: String, confidence: String, personality: Personality) -> String:
		var knowledge_templates = {
			"SHARE_KNOWLEDGE": {
				"high": [
					"{subject} {predicate} {object}.",
					"I can tell you that {subject} {predicate} {object}.",
					"{object}. Everyone knows that."
				],
				"medium": [
					"I believe {subject} {predicate} {object}.",
					"If I recall correctly, {subject} {predicate} {object}.",
					"From what I understand, {subject} {predicate} {object}."
				],
				"low": [
					"I think {subject} might be {object}... but I'm not certain.",
					"If memory serves, {subject} {predicate} {object}... though don't quote me."
				]
			},
			"SHARE_CAUTIOUS": {
				"high": [
					"Well... {subject} {predicate} {object}.",
					"I suppose I can tell you: {subject} {predicate} {object}."
				],
				"medium": [
					"I've heard that {subject} {predicate} {object}.",
					"Some say {subject} {predicate} {object}."
				],
				"low": [
					"I've heard rumors that {subject} might be {object}.",
					"There are whispers about {subject}... something about {object}."
				]
			}
		}
		
		# NEW: ADMIT_IGNORANCE templates - organized by personality style
		var ignorance_templates = {
			# Direct, honest (default)
			"direct": [
				"I don't know.",
				"I have no idea.",
				"I'm afraid I don't know anything about that.",
				"That's outside my knowledge.",
				"I don't have that information.",
				"I can't help you with that."
			],
			# Warm, apologetic (high warmth)
			"apologetic": [
				"I wish I could help, but I don't know.",
				"I'm so sorry, I don't have that information.",
				"Unfortunately, I can't help you with that.",
				"I'd love to help, but I simply don't know.",
				"Forgive me, I don't know anything about that.",
				"I'm sorry, that's not something I know about."
			],
			# Deflecting/suggesting alternatives (low assertiveness)
			"deflecting": [
				"I don't know. Perhaps someone else might.",
				"That's not something I know about. Try asking elsewhere.",
				"I'm not the right person to ask about that.",
				"I don't know, but maybe someone at the tavern would.",
				"I haven't heard about that. You might ask around.",
				"That's beyond me, I'm afraid. Try the merchants."
			],
			# Uncertain/hedged (low assertiveness + low warmth)
			"uncertain": [
				"I... I don't think I know that.",
				"I'm not sure. I don't really know.",
				"I probably don't know enough to say.",
				"I don't believe I know anything about that.",
				"I'm uncertain... I don't know.",
				"I don't know, really."
			],
			# Curious/intrigued (high curiosity)
			"curious": [
				"Interesting question... but I don't know.",
				"I wish I knew! That's fascinating, but I don't have the answer.",
				"Now that's a question. Sadly, I don't know.",
				"Curious... I don't know, but I'd like to find out.",
				"I've wondered about that myself. I don't know.",
				"That's intriguing, but I'm afraid I don't know."
			],
			# Dismissive/curt (low warmth, high assertiveness)
			"dismissive": [
				"No idea.",
				"Don't know.",
				"Can't help you.",
				"Not my area.",
				"I don't know that.",
				"No."
			]
		}
		
		# NEW: DENY_KNOWLEDGE templates - for when NPC won't share OR doesn't know
		var deny_templates = {
			# Secretive (knows but won't tell)
			"secretive": [
				"I prefer not to say.",
				"That's not something I discuss.",
				"I'd rather keep that to myself.",
				"Some things are better left unsaid.",
				"I have my reasons for not sharing.",
				"That information isn't for sharing."
			],
			# Protective (protecting someone/something)
			"protective": [
				"I can't tell you that.",
				"That's not for me to say.",
				"I'm not at liberty to discuss that.",
				"I've been asked not to share that.",
				"That's private information.",
				"Some knowledge is dangerous to share."
			],
			# Evasive (doesn't know but won't admit it)
			"evasive": [
				"I don't know anything about that.",
				"Can't help you there.",
				"That's not my concern.",
				"I stay out of such matters.",
				"I make it a point not to know.",
				"Best not to ask me about that."
			],
			# Dismissive (doesn't care)
			"dismissive": [
				"Don't know, don't care.",
				"Not my problem.",
				"Why would I know that?",
				"Ask someone else.",
				"I have better things to worry about.",
				"That's irrelevant to me."
			]
		}
		
		# NEW: ADMIT_FORGOTTEN templates
		var forgotten_templates = {
			"nostalgic": [
				"I feel like I knew something about that once...",
				"That sounds familiar, but I can't quite remember.",
				"I used to know, but it escapes me now.",
				"It's on the tip of my tongue... but I can't recall.",
				"I'm sure I knew this once. How frustrating.",
				"The memory is there, but too hazy to grasp."
			],
			"frustrated": [
				"Damn it, I knew this once...",
				"I can't remember. This is annoying.",
				"I've forgotten. How irritating.",
				"It's slipped my mind entirely.",
				"I should know this, but I don't.",
				"My memory fails me on this."
			],
			"honest": [
				"I think I used to know, but I've forgotten.",
				"I may have known once, but not anymore.",
				"My memory of that has faded.",
				"I've lost that knowledge, I'm afraid.",
				"That information has slipped away from me.",
				"I no longer remember that."
			]
		}
		
		# =========================================================================
		# SELECTION LOGIC
		# =========================================================================
		
		# Handle ADMIT_IGNORANCE - Select style based on personality
		if response_type == "ADMIT_IGNORANCE":
			var style = "direct"  # Default
			
			# High warmth → apologetic
			if personality.warmth > 0.5:
				style = "apologetic"
			# Low assertiveness → deflecting or uncertain
			elif personality.assertiveness < -0.2:
				if personality.warmth < -0.2:
					style = "uncertain"
				else:
					style = "deflecting"
			# High curiosity → curious
			elif personality.curiosity > 0.6:
				style = "curious"
			# Low warmth + high assertiveness → dismissive
			elif personality.warmth < -0.3 and personality.assertiveness > 0.4:
				style = "dismissive"
			
			var templates = ignorance_templates[style]
			return templates[randi() % templates.size()]
		
		# Handle DENY_KNOWLEDGE - Select style based on personality
		if response_type == "DENY_KNOWLEDGE":
			var style = "evasive"  # Default
			
			# High conscientiousness → protective
			if personality.conscientiousness > 0.6:
				style = "protective"
			# Low risk tolerance → secretive
			elif personality.risk_tolerance < -0.3:
				style = "secretive"
			# Low warmth + high assertiveness → dismissive
			elif personality.warmth < -0.3 and personality.assertiveness > 0.4:
				style = "dismissive"
			
			var templates = deny_templates[style]
			return templates[randi() % templates.size()]
		
		# Handle ADMIT_FORGOTTEN - Select style based on personality
		if response_type == "ADMIT_FORGOTTEN":
			var style = "honest"  # Default
			
			# High assertiveness → frustrated
			if personality.assertiveness > 0.5:
				style = "frustrated"
			# High warmth or curiosity → nostalgic
			elif personality.warmth > 0.4 or personality.curiosity > 0.5:
				style = "nostalgic"
			
			var templates = forgotten_templates[style]
			return templates[randi() % templates.size()]
		
		# Handle SHARE_KNOWLEDGE and SHARE_CAUTIOUS (existing logic)
		var type_templates = knowledge_templates.get(response_type, knowledge_templates["SHARE_KNOWLEDGE"])
		var confidence_templates = type_templates.get(confidence, type_templates.get("medium", []))
		
		if confidence_templates.is_empty():
			return "{subject} {predicate} {object}."
		
		# Calculate weights for each template based on personality
		var weights: Array[float] = []
		for i in range(confidence_templates.size()):
			var weight = _calculate_template_weight(i, confidence_templates.size(), personality, confidence)
			weights.append(weight)
		
		# Weighted random selection
		var index = _weighted_random_select(weights)
		return confidence_templates[index]
	func _calculate_template_weight(index: int, total: int, personality: Personality, confidence: String) -> float:
		var weight = 0.2
		
		if index == 0:
			weight += max(0.0, personality.assertiveness) * 0.5
			weight += max(0.0, personality.conscientiousness) * 0.2
		
		if index > 0 and index < total - 1:
			weight += max(0.0, personality.warmth) * 0.6
			weight += max(0.0, personality.curiosity) * 0.2
		
		if index == total - 1:
			weight += max(0.0, -personality.assertiveness) * 0.3
			if confidence == "high":
				weight += 0.3
				weight += max(0.0, personality.assertiveness) * 0.2
		
		return max(0.1, weight)


	func _weighted_random_select(weights: Array[float]) -> int:
		var total = 0.0
		for w in weights:
			total += w
		
		if total <= 0:
			return randi() % weights.size()
		
		var roll = randf() * total
		var cumulative = 0.0
		for i in range(weights.size()):
			cumulative += weights[i]
			if roll < cumulative:
				return i
		
		return weights.size() - 1


# ============================================================================
# DECISION SYSTEM
# ============================================================================
class DecisionEngine:
	var debugging : bool = true
			
	func _init(debug : bool = false):
		debugging = debug
	
	func evaluate_response(npc: NPC, option: ResponseOption, request: Request, system: NPCSystemEnhanced) -> float:
		var score = option.base_score
		
		# Apply personality modifiers (existing)
		score *= _calculate_personality_modifier(npc.personality, option)
		
		# Apply value alignment (existing)
		score *= _calculate_value_modifier(npc.personality.values, option)
		
		# Apply relationship influence (existing)
		var relationship = npc.get_relationship(request.context.requester_id)
		score *= _calculate_relationship_modifier(relationship, request.context)
		
		# Apply context modifiers (existing)
		score *= _calculate_context_modifier(npc.context, request.context)
		
		# NEW: Apply drive modifiers (additive)
		score += _calculate_drive_modifier(npc, option, system)
		
		# INCREASED randomness to break ties (existing)
		score += randf_range(-0.2, 0.2)
		
		# Penalize if response would be repetitive (existing)
		if npc.context.recent_responses.size() > 0:
			var last_response = npc.context.recent_responses[-1]
			if last_response.contains(option.response_type):
				score *= 0.7  # 30% penalty for same type
		
		return score

	
	
	func _generate_fallback(npc: NPC) -> String:
		# Select fallback text based on personality and role
		var fallback_text = ""
		
		# Assertive characters are decisive
		if npc.personality.assertiveness > 0.5:
			fallback_text = "I need to consider my position strategically"
		
		# Scholars prioritize research
		elif npc.context.role == "scholar":
			fallback_text = "I need to research this matter further"
		
		# Rogues weigh risks
		elif npc.context.role == "rogue":
			fallback_text = "I need to weigh the risks before deciding"
		
		# Nobles consult others
		elif npc.context.role == "noble":
			fallback_text = "I must consult my advisors first"
		
		# Warm characters are apologetic
		elif npc.personality.warmth > 0.5:
			fallback_text = "I need a moment to think about this, friend"
		
		# Default
		else:
			fallback_text = "I need time to consider this carefully"
		
		return "[" + npc.name + "]: " + fallback_text + "."
		
		
	func _calculate_personality_modifier(personality: Personality, option: ResponseOption) -> float:
		var modifier = 1.0
		for tag in option.personality_tags:
			match tag:
				"is_helpful":
					if option.personality_tags[tag]:
						modifier += personality.warmth * 0.3
				"is_aggressive":
					if option.personality_tags[tag]:
						modifier += personality.assertiveness * 0.3
				"is_cautious":
					if option.personality_tags[tag]:
						modifier += (1.0 - personality.risk_tolerance) * 0.3
				"is_strategic":
					if option.personality_tags[tag]:
						modifier += personality.conscientiousness * 0.2
				"is_evasive":
					if option.personality_tags[tag]:
						modifier += (1.0 - personality.assertiveness) * 0.2

		# NEW: Risk-Tolerance affects acceptance/refusal likelihood
		if option.response_type in ["AGREE", "AGREE_CONDITIONAL"]:
			# High risk-tolerance = more likely to accept
			modifier += personality.risk_tolerance * 0.5
		elif option.response_type in ["REFUSE", "REFUSE_SOFT", "REFUSE_HEDGED", "DEFLECT"]:
			# Low risk-tolerance = more likely to refuse
			modifier += (1.0 - personality.risk_tolerance) * 0.4

		# Adjust conditional responses based on risk
		if option.response_type == "AGREE_CONDITIONAL":
			# Low risk wants MORE conditions (harder to accept unconditionally)
			if personality.risk_tolerance < 0.0:
				modifier += 0.3

		return max(0.1, modifier)
	
	func _calculate_value_modifier(values: Dictionary, option: ResponseOption) -> float:
		var modifier = 1.0
		match option.response_type:
			"AGREE":
				modifier += values.get("COMMUNITY", 0.0) * 0.2
			"REFUSE":
				modifier += values.get("FREEDOM", 0.0) * 0.2
			"NEGOTIATE":
				modifier += values.get("POWER", 0.0) * 0.3
			"CHALLENGE":
				modifier += values.get("HONOR", 0.0) * 0.3
		return max(0.1, modifier)
	
	func _calculate_relationship_modifier(relationship: Relationship, request_context: RequestContext) -> float:
		var modifier = relationship.get_influence_multiplier()
		if request_context.emotional_tone < -0.3:
			modifier *= 0.7
		if request_context.emotional_tone > 0.3:
			modifier *= 1.2
		return max(0.1, modifier)
	
	func _calculate_context_modifier(npc_context: NPCContext, request_context: RequestContext) -> float:
		var modifier = 1.0
		if npc_context.stress_level > 0.5:
			modifier *= 0.8
		modifier += request_context.urgency * 0.1
		if not request_context.witnesses.is_empty():
			modifier *= 1.1
		return max(0.1, modifier)

	func _calculate_drive_modifier(npc, option, system):
		var total_score = 0.0
		var action_tags = option.action_tags
		
		# Collect all drive influences
		var drive_influences: Array[Dictionary] = []
		
		# Evaluate baseline drives
		for drive in npc.baseline_drives:
			var influence = _evaluate_drive_against_action(drive, action_tags, npc, system)
			if influence.score != 0.0:
				drive_influences.append(influence)
		
		# Evaluate dynamic drives
		for drive in npc.dynamic_drives:
			var influence = _evaluate_drive_against_action(drive, action_tags, npc, system)
			if influence.score != 0.0:
				drive_influences.append(influence)
		
		# Check for conflicts in THIS specific action
		var resolved_score = _resolve_drive_conflicts(drive_influences, action_tags)
		
		return resolved_score
		
	func _evaluate_drive_against_action(drive, action_tags: Dictionary, npc, system) -> Dictionary:
		var effective_weight = system.get_effective_drive_weight(npc, drive)
		var score = 0.0
		var reasoning = ""
		
		match drive.drive_type:
			"SELF_PRESERVATION":
				if action_tags.has("risky"):
					score = -effective_weight * action_tags["risky"]
					reasoning = "avoid_risk"
				if action_tags.has("lethal"):
					score = -effective_weight * 3.0
					reasoning = "avoid_death"
				if action_tags.has("safe"):
					score = effective_weight * 0.3
					reasoning = "prefer_safety"
			
			"SEEK_WEALTH":
				if action_tags.has("money_reward"):
					var reward_value = action_tags["money_reward"]
					# Normalize reward (100 gold = 1.0 score point)
					score = effective_weight * (reward_value / 100.0)
					reasoning = "gain_wealth"
				if action_tags.has("money_cost"):
					var cost = action_tags["money_cost"]
					score = -effective_weight * (cost / 100.0)
					reasoning = "spend_wealth"
			
			"SEEK_GIFTS":
				if action_tags.has("gift_received"):
					score = effective_weight * 0.6
					reasoning = "receive_gift"
			
			"SEEK_STATUS":
				if action_tags.has("prestige"):
					score = effective_weight * action_tags["prestige"]
					reasoning = "gain_status"
			
			"SEEK_KNOWLEDGE":
				if action_tags.has("knowledge_gain"):
					score = effective_weight * 0.8
					reasoning = "gain_knowledge"
			
			"AVOID_PAIN":
				if action_tags.has("painful"):
					score = -effective_weight * action_tags["painful"]
					reasoning = "avoid_pain"
				if action_tags.has("risky"):
					score -= effective_weight * action_tags["risky"] * 0.3
					reasoning = "avoid_pain"
			
			"PROTECT_X":
				if action_tags.has("helps") and action_tags["helps"] == drive.target_id:
					score = effective_weight * 2.0
					reasoning = "protect_target"
				if action_tags.has("harms") and action_tags["harms"] == drive.target_id:
					score = -effective_weight * 3.0
					reasoning = "harm_target"
			
			"AVOID_X":
				if action_tags.has("involves") and action_tags["involves"] == drive.target_id:
					score = -effective_weight * 1.5
					reasoning = "avoid_target"
		
		return {
			"drive_type": drive.drive_type,
			"target": drive.target_id,
			"score": score,
			"reasoning": reasoning
		}

	func _resolve_drive_conflicts(influences, action_tags) -> float:
		var final_score = 0.0
		
		# Check for direct conflicts (same target, opposite intent)
		# Example: PROTECT_princess + action harms princess + SEEK_WEALTH + action gives money
		var protection_score = 0.0
		var harm_score = 0.0
		
		for influence in influences:
			if influence.reasoning == "protect_target":
				protection_score += influence.score
			elif influence.reasoning == "harm_target":
				harm_score += influence.score
		
		# If both exist, they conflict
		if protection_score != 0.0 and harm_score != 0.0:
			# The stronger drive wins, but is reduced by the weaker
			var net_protection = protection_score + harm_score  # harm_score is negative
			final_score += net_protection
			
			# Remove these from further consideration
			var filtered: Array[Dictionary] = []
			for inf in influences:
				if inf.reasoning not in ["protect_target", "harm_target"]:
					filtered.append(inf)
			influences = filtered
		else:
			# No conflict, add protection/harm scores
			final_score += protection_score + harm_score
		
		# Add all other non-conflicting drives
		for influence in influences:
			if influence.reasoning not in ["protect_target", "harm_target"]:
				final_score += influence.score
		
		return final_score
		
# ============================================================================
# MAIN SYSTEM
# ============================================================================

var npcs: Dictionary = {}
var parser: RequestParser
var generator: ResponseGenerator
var decision_engine: DecisionEngine
var archetype_library: ArchetypeLibrary
var role_library: RoleLibrary
var knowledge_seeder: KnowledgeHelpers.Seeder
var knowledge_decay: KnowledgeHelpers.DecaySystem
var tick_count: int = 0

func _ready():
	world_knowledge = WorldDB
	# In a real setup, you might add_child(world_knowledge) if it needs to process frames, 
	# but here it's acting as a database.
	world_knowledge._ready() # Initialize default facts
	
	parser = RequestParser.new()
	generator = ResponseGenerator.new()
	decision_engine = DecisionEngine.new()
	archetype_library = ArchetypeLibrary.new()
	role_library = RoleLibrary.new()
	
	knowledge_seeder = KnowledgeHelpers.Seeder.new(world_knowledge)
	knowledge_decay = KnowledgeHelpers.DecaySystem.new(world_knowledge)
	
	_create_sample_npcs()

func _create_sample_npcs():
	var configs = [
		{"id": "npc_0", "name": "Vorak", "archetype": "warlord"},
		{"id": "npc_1", "name": "Lyris", "archetype": "scholar"},
		{"id": "npc_2", "name": "Thane", "archetype": "merchant"},
		{"id": "npc_3", "name": "Mira", "archetype": "healer"},
		{"id": "npc_4", "name": "Kass", "archetype": "rogue"},
		{"id": "npc_5", "name": "Lord Aldric", "archetype": "noble"},
		{"id": "npc_6", "name": "Elena", "archetype": "merchant"},
		{"id": "npc_7", "name": "Grimm", "archetype": "warlord"},
		{"id": "npc_8", "name": "Sofia", "archetype": "scholar"},
		{"id": "npc_9", "name": "Marcus", "archetype": "healer"},
		{"id": "npc_10", "name": "Zara", "archetype": "rogue"},
		{"id": "npc_11", "name": "Viktor", "archetype": "noble"},
	]
	for config in configs:
		var npc = create_npc_from_template(config.id, config.name, config.archetype)
		npcs[npc.id] = npc

func create_npc_from_template(npc_id, npc_name, archetype, contextual_role = ""):
	var template = archetype_library.get_template(archetype)
	var personality = Personality.new(
		template.warmth + randf_range(-0.1, 0.1),
		template.assertiveness + randf_range(-0.1, 0.1),
		template.conscientiousness + randf_range(-0.1, 0.1),
		template.curiosity + randf_range(-0.1, 0.1),
		template.risk_tolerance + randf_range(-0.1, 0.1),
		template.stability + randf_range(-0.1, 0.1),
		template.values.duplicate()
	)
	
	var npc = NPC.new(npc_id, npc_name, personality)
	npc.archetype = archetype
	npc.context.role = contextual_role if contextual_role else archetype
	
	# Seed Knowledge
	knowledge_seeder.seed_npc(npc.knowledge, archetype)
	
	return npc

func process_request(npc_id: String, request_text: String) -> String:
	if not npcs.has(npc_id):
		return "Unknown NPC"
	
	var npc = npcs[npc_id]
	
	# 1. PARSE REQUEST
	var request = parser.parse_request(request_text)
	
	# 2. CHECK IF THIS IS A KNOWLEDGE QUERY AND ADD KNOWLEDGE OPTIONS
	var k_query = KnowledgeQuery.parse(request_text)
	if debugging: print("DEBUG: Query='%s', Type=%s" % [request_text, KnowledgeQuery.QueryType.keys()[k_query.query_type]])

	if k_query.query_type != KnowledgeQuery.QueryType.GENERAL:
		# This is a knowledge query - add knowledge-based response options
		var k_executor = KnowledgeQuery.QueryExecutor.new(world_knowledge)
		var k_result = k_executor.execute(npc.knowledge, k_query)
		if debugging: print("DEBUG: Knowledge success=%s, confidence=%.2f" % [k_result.success, k_result.confidence])

		var k_options = _create_knowledge_options(k_result)
		if debugging: print("DEBUG: Created %d knowledge options" % k_options.size())
		request.response_options.append_array(k_options)
		
		# Add knowledge response options to the existing options
		request.response_options.append_array(_create_knowledge_options(k_result))
	
	# 3. ADD PERSONALITY-SPECIFIC OPTIONS
	if npc.personality.warmth > 0.7:
		request.response_options.append(generator.create_soft_refusal())
	
	if npc.personality.assertiveness < -0.2:
		request.response_options.append(generator.create_hedged_refusal())
	
	# 4. APPLY PERSONALITY CONSTRAINTS
	request.response_options = generator.apply_personality_constraints(
		request.response_options, npc.personality
	)
	
	# 5. EVALUATE ALL OPTIONS AND PICK BEST (with anti-repetition)
	var best_option: ResponseOption = null
	var best_score = -INF
	var attempts = 0
	var max_attempts = _get_max_attempts(npc)
	
	while attempts < max_attempts:
		best_option = null
		best_score = -INF
		
		# Score all options
		for option in request.response_options:
			var score = decision_engine.evaluate_response(npc, option, request, self)
			if score > best_score:
				best_score = score
				best_option = option
		
		if best_option:
			var response = generator.generate_response(npc, best_option, request)
			
			# Check if repetitive
			if not npc.is_response_repetitive(response):
				npc.remember_response(response)
				_update_npc_after_response(npc, best_option, request)
				return response
			if best_option.response_type in ["SHARE_KNOWLEDGE", "SHARE_CAUTIOUS", "DENY_KNOWLEDGE"]:
# Factual queries should give consistent answers
				npc.remember_response(response)
				_update_npc_after_response(npc, best_option, request)
				return response
		
		
		# Penalize this option and try again
		if best_option:
			best_option.base_score *= 0.5
		attempts += 1
	
	# 6. FALLBACK (only as last resort)
	return decision_engine._generate_fallback(npc)

func _create_knowledge_options(k_result: KnowledgeQuery.QueryResult) -> Array[ResponseOption]:
	var options: Array[ResponseOption] = []
	
	if k_result.success:
		# NPC HAS KNOWLEDGE
		# SHARE_KNOWLEDGE - High confidence answer
		var share = ResponseOption.new()
		share.response_type = "SHARE_KNOWLEDGE"
		share.base_score = 0.8 + (k_result.confidence * 0.2)  # Changed from 0.3 to 0.2
		share.personality_tags = {"is_helpful": true, "is_knowledgeable": true}
		share.action_tags = {"knowledge_sharing": true}
		share.knowledge_result = k_result
		share.response_template = "{knowledge_response}"
		options.append(share)
		
		# SHARE_CAUTIOUSLY - For secretive/careful characters
		var cautious = ResponseOption.new()
		cautious.response_type = "SHARE_CAUTIOUS"
		cautious.base_score = 0.7  # Increased from 0.5
		cautious.personality_tags = {"is_cautious": true, "is_secretive": true}
		cautious.action_tags = {"knowledge_sharing": true}
		cautious.knowledge_result = k_result
		cautious.response_template = "{knowledge_response_cautious}"
		options.append(cautious)
		
		# DENY_KNOWLEDGE - "I know but won't tell" (for secretive NPCs)
		var deny_has_knowledge = ResponseOption.new()
		deny_has_knowledge.response_type = "DENY_KNOWLEDGE"
		deny_has_knowledge.base_score = 0.25  # Very low - only for very secretive
		deny_has_knowledge.personality_tags = {"is_secretive": true, "is_protective": true}
		deny_has_knowledge.response_template = "{deny_knowledge_response}"
		options.append(deny_has_knowledge)
	
	elif k_result.partial_knowledge:
		# NPC USED TO KNOW BUT FORGOT
		# ADMIT_FORGOTTEN - Honest about forgetting
		var forgotten = ResponseOption.new()
		forgotten.response_type = "ADMIT_FORGOTTEN"
		forgotten.base_score = 0.6  # Increased from 0.45
		forgotten.personality_tags = {"is_honest": true}
		forgotten.response_template = "{forgotten_response}"
		options.append(forgotten)
		
		# ADMIT_IGNORANCE - Alternative (claim full ignorance)
		var admit_partial = ResponseOption.new()
		admit_partial.response_type = "ADMIT_IGNORANCE"
		admit_partial.base_score = 0.5
		admit_partial.personality_tags = {"is_honest": true}
		admit_partial.response_template = "{ignorance_response}"
		options.append(admit_partial)
		
		# DENY_KNOWLEDGE - Evasive
		var deny_partial = ResponseOption.new()
		deny_partial.response_type = "DENY_KNOWLEDGE"
		deny_partial.base_score = 0.4
		deny_partial.personality_tags = {"is_secretive": true}
		deny_partial.response_template = "{deny_knowledge_response}"
		options.append(deny_partial)
	
	else:
		# *** THIS IS THE CRITICAL NEW CODE ***
		# NPC DOESN'T KNOW AT ALL
		
		# ADMIT_IGNORANCE - Honest "I don't know"
		var admit = ResponseOption.new()
		admit.response_type = "ADMIT_IGNORANCE"
		admit.base_score = 0.85  # HIGH - should strongly win
		admit.personality_tags = {"is_honest": true, "is_helpful": true}
		admit.response_template = "{ignorance_response}"
		options.append(admit)
		
		# DENY_KNOWLEDGE - Evasive/dismissive "I don't know"
		var deny = ResponseOption.new()
		deny.response_type = "DENY_KNOWLEDGE"
		deny.base_score = 0.4  # Lower than ADMIT_IGNORANCE
		deny.personality_tags = {"is_secretive": true, "is_dismissive": true}
		deny.response_template = "{deny_knowledge_response}"
		options.append(deny)
	
	return options
	
func _get_max_attempts(npc: NPC) -> int:
	# Decisive roles try more times before giving up
	if npc.context.role in ["warlord", "noble"]:
		return 5
	elif npc.personality.assertiveness > 0.7:
		return 4
	# Thoughtful roles give up sooner
	elif npc.context.role in ["scholar", "rogue"]:
		return 2
	elif npc.personality.conscientiousness > 0.7:
		return 2
	else:
		return 3

func _process(delta: float):
	tick_count += 1
	if tick_count % 60 == 0:
		var time = Time.get_unix_time_from_system()
		for npc_id in npcs:
			var npc = npcs[npc_id]
			# Decay stress
			npc.context.stress_level = max(0.0, npc.context.stress_level * 0.95)
			# Decay Knowledge
			knowledge_decay.process_decay(npc.knowledge, time)

func _update_npc_after_response(npc: NPC, option: ResponseOption, request: Request) -> void:
	# Update relationship based on response
	var rel = npc.get_relationship(request.context.requester_id)
	
	if option.response_type in ["AGREE", "SHARE_KNOWLEDGE"]:
		rel.trust += 0.05
		rel.affection += 0.03
	elif option.response_type in ["REFUSE", "DENY_KNOWLEDGE"]:
		rel.trust -= 0.02
		rel.affection -= 0.01
	elif option.response_type == "NEGOTIATE":
		rel.respect += 0.02
	
	# Update stress based on action tags
	if option.action_tags.get("risky", 0.0) > 0.5:
		npc.context.stress_level += 0.1
	
	# Clamp values
	rel.trust = clamp(rel.trust, -1.0, 1.0)
	rel.affection = clamp(rel.affection, -1.0, 1.0)
	rel.respect = clamp(rel.respect, -1.0, 1.0)
	npc.context.stress_level = clamp(npc.context.stress_level, 0.0, 1.0)

func _generate_knowledge_options(
	npc: NPC, 
	query: KnowledgeQuery, 
	query_result: KnowledgeQuery.QueryResult) -> Array[ResponseOption]:
	var options: Array[ResponseOption] = []
	
	if query_result.success:
		# SHARE_KNOWLEDGE - High confidence
		var share = ResponseOption.new()
		share.response_type = "SHARE_KNOWLEDGE"
		share.base_score = 0.6 + (query_result.confidence * 0.2)
		share.personality_tags = {"is_helpful": true, "is_knowledgeable": true}
		share.action_tags = {"knowledge_sharing": true}
		share.knowledge_data = query_result  # Store for later formatting
		options.append(share)
		
		# SHARE_CAUTIOUSLY - Medium confidence or secretive NPCs
		var cautious = ResponseOption.new()
		cautious.response_type = "SHARE_CAUTIOUS"
		cautious.base_score = 0.5
		cautious.personality_tags = {"is_cautious": true, "is_secretive": true}
		cautious.action_tags = {"knowledge_sharing": true}
		cautious.knowledge_data = query_result
		options.append(cautious)
	
	elif query_result.partial_knowledge:
		# ADMIT_FORGOTTEN
		var forgotten = ResponseOption.new()
		forgotten.response_type = "ADMIT_FORGOTTEN"
		forgotten.base_score = 0.4
		forgotten.personality_tags = {"is_honest": true}
		forgotten.response_template = "That sounds familiar, but I can't quite remember..."
		options.append(forgotten)
	
	# Always include DENY_KNOWLEDGE as an option
	var deny = ResponseOption.new()
	deny.response_type = "DENY_KNOWLEDGE"
	deny.base_score = 0.3
	deny.personality_tags = {"is_secretive": true, "is_protective": true}
	deny.response_template = "I don't know anything about that"
	options.append(deny)
	
	return options

func send_request_to_npc(npc_name: String, text: String) -> String:
	for id in npcs:
		if npcs[id].name == npc_name:
			return process_request(id, text)
	return "I don't know anyone named " + npc_name

func get_npc_list() -> Array[String]:
	var names: Array[String] = []
	for id in npcs:
		names.append(npcs[id].name)
	return names

func get_npc_info(npc_name: String) -> Dictionary:
	for id in npcs:
		if npcs[id].name == npc_name:
			var npc = npcs[id]
			return {
				"name": npc.name,
				"role": npc.context.role,
				"personality": {
					"warmth": npc.personality.warmth,
					"assertiveness": npc.personality.assertiveness,
					"risk_tolerance": npc.personality.risk_tolerance
				},
				"relationship": {
					"trust": npc.get_relationship("player").trust,
					"respect": npc.get_relationship("player").respect,
					"affection": npc.get_relationship("player").affection
				}
			}
	return {}
