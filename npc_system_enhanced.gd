extends Node
class_name NPCSystemEnhanced

var debugging = true
# Enhanced NPC System with fixes for:
# 1. Response repetition
# 2. Meaningful relationship changes
# 3. Stress accumulation bug
# 4. Response variety

# ============================================================================
# CORE DATA STRUCTURES (same as before)
# ============================================================================
class Personality:
	var warmth: float
	var assertiveness: float
	var conscientiousness: float
	var curiosity: float
	var risk_tolerance: float
	var stability: float
	var values: Dictionary
	
	func _init(w: float = 0.0, a: float = 0.0, c: float = 0.0,
		cu: float = 0.0, r: float = 0.0, s: float = 0.0, v: Dictionary = {}):
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
	var recent_responses: Array[String] = []  # NEW: Track recent responses

class NPC:
	var id: String
	var name: String
	var personality: Personality
	var relationships: Dictionary = {}
	var context: NPCContext
	var archetype: String = ""
	var memory: Array[Dictionary] = []
	
	func _init(npc_id: String, npc_name: String, pers: Personality):
		id = npc_id
		name = npc_name
		personality = pers
		context = NPCContext.new()
	
	func get_relationship(target_id: String) -> Relationship:
		if not relationships.has(target_id):
			relationships[target_id] = Relationship.new()
			relationships[target_id].target_id = target_id
		return relationships[target_id]
	
	func remember_event(event: Dictionary):
		memory.append(event)
		if memory.size() > 20:
			memory.pop_front()
	
	# NEW: Track recent responses to avoid repetition
	func remember_response(response: String):
		context.recent_responses.append(response)
		if context.recent_responses.size() > 5:
			context.recent_responses.pop_front()
	
	# NEW: Check if response is too similar to recent ones
	func is_response_repetitive(response: String) -> bool:
		for recent in context.recent_responses:
			if _similarity_score(response, recent) > 0.85:  # Increased from 0.7
				return true
		return false
	
	func _similarity_score(s1: String, s2: String) -> float:
		# Simple word-based similarity
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

class Request:
	var raw_text: String
	var context: RequestContext
	var parsed_intent: Dictionary
	var response_options: Array[ResponseOption] = []
	
	func _init(text: String):
		raw_text = text
		context = RequestContext.new()
		parsed_intent = {}

class ResponseOption:
	var response_type: String
	var base_score: float = 0.5
	var personality_tags: Dictionary = {}
	var relationship_impact: Dictionary = {}
	var response_template: String = ""
	var template_variant: int = 0  # NEW: Track which variant

# ============================================================================
# REQUEST PARSER (mostly same)
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
	
	func _generate_response_options(request: Request) -> Array[ResponseOption]:
		var options: Array[ResponseOption] = []
		
		# AGREE options with variants
		for i in range(3):  # Generate 3 variants
			var agree = ResponseOption.new()
			agree.response_type = "AGREE"
			agree.base_score = 0.5
			agree.personality_tags = {"is_helpful": true, "is_cooperative": true}
			agree.template_variant = i
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
		options.append(deflect)
		
		# CHALLENGE option for threats
		if request.context.request_type == "THREATEN":
			var challenge = ResponseOption.new()
			challenge.response_type = "CHALLENGE"
			challenge.base_score = 0.5
			challenge.personality_tags = {"is_aggressive": true, "is_brave": true}
			challenge.response_template = "You dare threaten me? {consequence}"
			options.append(challenge)
		
		return options

# ============================================================================
# ENHANCED RESPONSE GENERATOR
# ============================================================================

class ResponseGenerator:
	var re : RegEx = RegEx.new()
	
	var enthusiasm_phrases = {
		"high": ["Absolutely", "Gladly", "With pleasure", "Certainly"],
		"medium": ["Sure", "Alright", "I can do that", "Very well"],
		"low": ["I suppose", "If necessary", "Fine", "As you wish"]
	}
	
	var dismissal_phrases = {
		"harsh": ["No", "Absolutely not", "Out of the question", "Never"],
		"polite": ["I'm afraid not", "I must decline", "Unfortunately no", "I cannot"]
	}
	
	var condition_questions = [
		"What can you offer me in return?",
		"What's in it for me?",
		"And what do I gain from this?",
		"Why should I agree to this?"
	]
	
	func generate_response(npc: NPC, chosen_option: ResponseOption, request: Request) -> String:
		var template = chosen_option.response_template
		var response = template
		re.compile("\\bi\\b") 
		
		# Replace template variables with personality-driven variations
		response = _apply_personality_modifiers(response, npc.personality, chosen_option.template_variant)
		response = _apply_value_modifiers(response, npc.personality.values, chosen_option.template_variant)
		response = _apply_context_modifiers(response, npc.context, request.context)
		response = _apply_relationship_modifiers(response, npc.get_relationship(request.context.requester_id))
		response = _add_personality_flavor(response, npc.personality)
		
		# Ensure response ends with punctuation before adding closings
		if not response.ends_with(".") and not response.ends_with("!") and not response.ends_with("?"):
			response = response + "."
		
		# Add closing punctuation variation
		if npc.personality.warmth > 0.3 and randf() > 0.7:
			response = response.trim_suffix(".") + ", friend."
		elif npc.personality.assertiveness > 0.5 and randf() > 0.8:
			response = response.trim_suffix(".") + ". That is final."
		
		response = re.sub(response, "I", true)
		return response
	
	func _apply_personality_modifiers(template: String, personality: Personality, variant: int) -> String:
		var result = template
		
		# {action} variations
		if result.contains("{action}"):
			var actions = []
			if personality.conscientiousness > 0.5:
				actions = ["handle this properly", "address this correctly", "deal with this responsibly"]
			elif personality.risk_tolerance > 0.5:
				actions = ["take on this challenge", "dive into this", "tackle this head-on"]
			else:
				actions = ["do that", "help with this", "assist you"]
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
		
		# {enthusiasm} based on warmth
		if result.contains("{enthusiasm}"):
			var level = "medium"
			if personality.warmth > 0.5:
				level = "high"
			elif personality.warmth < -0.3:
				level = "low"
			var phrases = enthusiasm_phrases[level]
			result = result.replace("{enthusiasm}", phrases[randi() % phrases.size()])
		
		# {dismissal} based on assertiveness
		if result.contains("{dismissal}"):
			var level = "polite"
			if personality.assertiveness > 0.5:
				level = "harsh"
			var phrases = dismissal_phrases[level]
			result = result.replace("{dismissal}", phrases[randi() % phrases.size()])
		
		# {reason} variations
		if result.contains("{reason}"):
			var reasons = _generate_reasons(personality)
			result = result.replace("{reason}", reasons[variant % reasons.size()])
		
		# {harsh_reason} for refusals
		if result.contains("{harsh_reason}"):
			var harsh_reasons = [
				"I have more important matters",
				"This doesn't concern me",
				"Find someone else",
				"That's not my problem"
			]
			result = result.replace("{harsh_reason}", harsh_reasons[randi() % harsh_reasons.size()])
		
		return result
	
	func _generate_reasons(personality: Personality) -> Array[String]:
		var reasons: Array[String] = []
		
		if personality.warmth > 0.5:
			reasons.append_array(["I want to help.", "I'm happy to assist.", "I care about this."])
		if personality.assertiveness > 0.5:
			reasons.append_array(["It's necessary.", "It must be done.", "There's no other way."])
		if personality.conscientiousness > 0.5:
			reasons.append_array(["It's the proper course.", "It's the right thing.", "Protocol demands it."])
		if personality.risk_tolerance < -0.3:
			reasons.append_array(["It's too dangerous.", "The risk is too high.", "I must be cautious."])
		
		if reasons.is_empty():
			reasons = ["I have my reasons.", "It's complicated.", "Trust me on this."]
		
		return reasons
	
	func _apply_value_modifiers(template: String, values: Dictionary, variant: int) -> String:
		var result = template
		
		var highest_value = ""
		var highest_score = 0.0
		for value in values:
			if values[value] > highest_score:
				highest_score = values[value]
				highest_value = value
		
		# {condition} variations by value
		if result.contains("{condition}"):
			var conditions = _generate_conditions(highest_value)
			result = result.replace("{condition}", conditions[variant % conditions.size()])
		
		# {condition_question} variations
		if result.contains("{condition_question}"):
			result = result.replace("{condition_question}", condition_questions[randi() % condition_questions.size()])
		
		# {offer} variations by value
		if result.contains("{offer}"):
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
	
	func _apply_context_modifiers(template: String, npc_context: NPCContext, request_context: RequestContext) -> String:
		var result = template
		
		# Stress hesitation
		if npc_context.stress_level > 0.7:
			result = "I... " + result
		
		# Urgency modifications
		if request_context.urgency > 0.8:
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
	
	func _apply_relationship_modifiers(template: String, relationship: Relationship) -> String:
		var result = template
		
		# High trust = more direct
		if relationship.trust > 0.7:
			result = result.replace("Perhaps", "Yes")
			result = result.replace("I might", "I will")
		
		# Fear = cautious
		if relationship.fear > 0.5:
			if not result.begins_with("I... "):
				result = "I... " + result.to_lower()
		
		# Affection = warmth
		if relationship.affection > 0.6 and randf() > 0.7:
			result = "Of course, " + result.to_lower()
		
		# Replace {consequence}
		if result.contains("{consequence}"):
			if relationship.fear > 0.3:
				result = result.replace("{consequence}", "Please, let's discuss this")
			else:
				result = result.replace("{consequence}", "You'll regret this")
		
		return result
	
	func _add_personality_flavor(response: String, personality: Personality) -> String:
		# Don't add flavor if already has flavor (avoid "Well, Well, ...")
		if response.begins_with("Well, ") or response.begins_with("Listen. ") or response.begins_with("Interesting... "):
			return response
		
		if personality.warmth > 0.6 and randf() > 0.8:
			response = "Well, " + _lowercase_first_char_safe(response)
		elif personality.assertiveness > 0.6 and randf() > 0.8:
			response = "Listen. " + response
		elif personality.curiosity > 0.6 and randf() > 0.8:
			response = "Interesting... " + _lowercase_first_char_safe(response)
		
		return response
	
	# Helper to lowercase first character but preserve "I" as "I"
	func _lowercase_first_char_safe(text: String) -> String:
		if text.is_empty():
			return text
		
		# Don't lowercase if starts with "I " (pronoun)
		if text.begins_with("I "):
			return text
		
		# Lowercase just the first character
		return text[0].to_lower() + text.substr(1)

# ============================================================================
# DECISION SYSTEM (Enhanced)
# ============================================================================

class DecisionEngine:
	func evaluate_response(npc: NPC, option: ResponseOption, request: Request) -> float:
		var score = option.base_score
		
		# Apply personality modifiers
		score *= _calculate_personality_modifier(npc.personality, option)
		
		# Apply value alignment
		score *= _calculate_value_modifier(npc.personality.values, option)
		
		# Apply relationship influence (NOW STRONGER)
		var relationship = npc.get_relationship(request.context.requester_id)
		score *= _calculate_relationship_modifier(relationship, request.context)
		
		# Apply context modifiers
		score *= _calculate_context_modifier(npc.context, request.context)
		
		# INCREASED randomness to break ties
		score += randf_range(-0.2, 0.2)
		
		# Penalize if response would be repetitive
		# We can't fully generate the response here, but we can penalize
		# by response type if it was used recently
		if npc.context.recent_responses.size() > 0:
			var last_response = npc.context.recent_responses[-1]
			if last_response.contains(option.response_type):
				score *= 0.7  # 30% penalty for same type
		
		return score
	
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

# ============================================================================
# MAIN NPC SYSTEM
# ============================================================================

var npcs: Dictionary = {}
var parser: RequestParser
var generator: ResponseGenerator
var decision_engine: DecisionEngine
var tick_count: int = 0  # NEW: Track ticks for stress decay

func _ready():
	parser = RequestParser.new()
	generator = ResponseGenerator.new()
	decision_engine = DecisionEngine.new()
	_create_sample_npcs()

func _create_sample_npcs():
	var archetypes = {
		"warlord": Personality.new(-0.3, 0.8, 0.2, -0.1, 0.7, 0.3,
			{"POWER": 0.8, "HONOR": 0.4, "WEALTH": 0.3}),
		"scholar": Personality.new(0.3, -0.2, 0.8, 0.9, -0.2, 0.6,
			{"KNOWLEDGE": 0.9, "HONOR": 0.5, "POWER": 0.2}),
		"merchant": Personality.new(0.4, 0.2, 0.6, 0.3, 0.4, 0.5,
			{"WEALTH": 0.8, "COMMUNITY": 0.4, "KNOWLEDGE": 0.3}),
		"healer": Personality.new(0.8, -0.3, 0.7, 0.4, -0.4, 0.7,
			{"COMMUNITY": 0.9, "HONOR": 0.6, "KNOWLEDGE": 0.4}),
		"rogue": Personality.new(-0.1, 0.3, -0.4, 0.5, 0.8, 0.2,
			{"FREEDOM": 0.9, "WEALTH": 0.6, "POWER": 0.3}),
		"noble": Personality.new(0.2, 0.6, 0.7, 0.1, -0.3, 0.8,
			{"HONOR": 0.8, "POWER": 0.7, "TRADITION": 0.6})
	}
	
	var names = ["Vorak", "Lyris", "Thane", "Mira", "Kass", "Lord Aldric",
		"Elena", "Grimm", "Sofia", "Marcus", "Zara", "Viktor"]
	var roles = ["warlord", "scholar", "merchant", "healer", "rogue", "noble",
		"merchant", "warlord", "scholar", "healer", "rogue", "noble"]
	
	for i in range(12):
		var npc_name = names[i]
		var role = roles[i]
		var personality = archetypes[role].clone()
		
		personality.warmth += randf_range(-0.2, 0.2)
		personality.assertiveness += randf_range(-0.2, 0.2)
		personality.risk_tolerance += randf_range(-0.2, 0.2)
		
		var npc = NPC.new("npc_" + str(i), npc_name, personality)
		npc.archetype = role
		npc.context.role = role
		
		var player_rel = npc.get_relationship("player")
		player_rel.trust = randf_range(0.2, 0.6)
		player_rel.respect = randf_range(0.3, 0.7)
		player_rel.affection = randf_range(-0.2, 0.4)
		player_rel.fear = randf_range(0.0, 0.3)
		
		npcs[npc.id] = npc

func process_request(npc_id: String, request_text: String) -> String:
	if not npcs.has(npc_id):
		return "Unknown NPC"
	
	var npc = npcs[npc_id]
	var request = parser.parse_request(request_text)
	
	# Evaluate options and pick best (with anti-repetition)
	var best_option: ResponseOption = null
	var best_score = -INF
	var attempts = 0
	var max_attempts = 2  # Reduced from 3
	
	while attempts < max_attempts:
		best_option = null
		best_score = -INF
		
		for option in request.response_options:
			var score = decision_engine.evaluate_response(npc, option, request)
			if score > best_score:
				best_score = score
				best_option = option
		
		if best_option:
			var response = generator.generate_response(npc, best_option, request)
			
			# Check if repetitive
			if not npc.is_response_repetitive(response):
				npc.remember_response(response)
				_update_npc_after_response(npc, best_option, request)
				return "[" + npc.name + "]: " + response
		
		# Penalize this option and try again
		if best_option:
			best_option.base_score *= 0.5
		attempts += 1
	
	# Fallback
	return "[" + npc.name + "]: I... I need to think about this."

func _update_npc_after_response(npc: NPC, chosen_option: ResponseOption, request: Request):
	var relationship = npc.get_relationship(request.context.requester_id)
	
	# INCREASED relationship changes
	if debugging:
		pass
	else:
		match chosen_option.response_type:
			"AGREE":
				relationship.affection += 0.10  # Was 0.05
				relationship.trust += 0.05      # Was 0.02
			"REFUSE":
				relationship.affection -= 0.08  # Was 0.03
			"CHALLENGE":
				relationship.respect += 0.10    # Was 0.05
				relationship.fear += 0.08       # Was 0.03
			"NEGOTIATE":
				relationship.respect += 0.03
	
	# Clamp relationships
	relationship.affection = clamp(relationship.affection, -1.0, 1.0)
	relationship.trust = clamp(relationship.trust, 0.0, 1.0)
	relationship.respect = clamp(relationship.respect, 0.0, 1.0)
	relationship.fear = clamp(relationship.fear, 0.0, 1.0)
	
	npc.remember_event({
		"type": "interaction",
		"requester": request.context.requester_id,
		"request": request.raw_text,
		"response": chosen_option.response_type,
		"timestamp": Time.get_ticks_msec()
	})
	
	# FIXED: Don't add and decay stress in same tick
	npc.context.stress_level += request.context.urgency * 0.1
	npc.context.stress_level = clamp(npc.context.stress_level, 0.0, 1.0)

func _process(delta: float):
	# Decay stress periodically, not every interaction
	tick_count += 1
	if tick_count % 60 == 0:  # Every ~1 second at 60fps
		for npc_id in npcs:
			var npc = npcs[npc_id]
			npc.context.stress_level *= 0.95
			npc.context.stress_level = max(0.0, npc.context.stress_level)

# Public interface
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
