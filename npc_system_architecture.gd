extends Node
class_name NPCSystem

# Core NPC System Architecture for handling arbitrary requests
# This system manages multiple NPCs, interprets requests, and generates responses

# ============================================================================
# CORE DATA STRUCTURES
# ============================================================================

class Personality:
	var warmth: float
	var assertiveness: float  
	var conscientiousness: float
	var curiosity: float
	var risk_tolerance: float
	var stability: float
	var values: Dictionary  # POWER, HONOR, KNOWLEDGE, COMMUNITY, etc.
	
	func _init(
		w: float = 0.0, a: float = 0.0, c: float = 0.0,
		cu: float = 0.0, r: float = 0.0, s: float = 0.0,
		v: Dictionary = {}
	):
		warmth = w
		assertiveness = a
		conscientiousness = c
		curiosity = cu
		risk_tolerance = r
		stability = s
		values = v if v else {"POWER": 0.5, "HONOR": 0.5}
	
	func clone() -> Personality:
		return Personality.new(
			warmth, assertiveness, conscientiousness,
			curiosity, risk_tolerance, stability,
			values.duplicate()
		)

class Relationship:
	var target_id: String
	var affection: float = 0.0
	var trust: float = 0.0
	var respect: float = 0.0
	var fear: float = 0.0
	var history: Array[String] = []  # Track key interactions
	
	func get_influence_multiplier() -> float:
		# Calculate how much this relationship influences decisions
		var mult = 1.0
		mult += affection * 0.3
		mult += trust * 0.4
		mult += respect * 0.4
		mult += fear * 0.2
		return max(0.1, mult)  # Never go below 0.1

class NPCContext:
	var location: String = ""
	var current_mood: float = 0.0  # -1 to 1
	var stress_level: float = 0.0  # 0 to 1
	var recent_events: Array[String] = []
	var active_goals: Array[String] = []
	var faction: String = ""
	var role: String = ""  # leader, merchant, scholar, etc.

class NPC:
	var id: String
	var name: String
	var personality: Personality
	var relationships: Dictionary = {}  # target_id -> Relationship
	var context: NPCContext
	var archetype: String = ""
	var memory: Array[Dictionary] = []  # Store past decisions/events
	
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
		if memory.size() > 20:  # Keep only recent memory
			memory.pop_front()

# ============================================================================
# REQUEST INTERPRETATION
# ============================================================================

class RequestContext:
	var request_type: String  # ASK, SUGGEST, DEMAND, INFORM, THREATEN, etc.
	var topic: String  # combat, trade, alliance, personal, information, etc.
	var urgency: float = 0.5
	var formality: float = 0.5
	var emotional_tone: float = 0.0  # -1 angry to 1 friendly
	var requester_id: String = "player"
	var witnesses: Array[String] = []  # NPCs present

class Request:
	var raw_text: String
	var context: RequestContext
	var parsed_intent: Dictionary  # action -> weight
	var response_options: Array[ResponseOption] = []
	
	func _init(text: String):
		raw_text = text
		context = RequestContext.new()
		parsed_intent = {}

class ResponseOption:
	var response_type: String  # AGREE, REFUSE, NEGOTIATE, DEFLECT, QUESTION, etc.
	var base_score: float = 0.5
	var personality_tags: Dictionary = {}  # is_aggressive, is_helpful, etc.
	var relationship_impact: Dictionary = {}  # target_id -> impact amount
	var response_template: String = ""

# ============================================================================
# REQUEST PARSER
# ============================================================================

class RequestParser:
	# Keywords for identifying request types
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
		
		# Determine request type
		request.context.request_type = _identify_type(lower_text)
		request.context.topic = _identify_topic(lower_text)
		request.context.urgency = _assess_urgency(lower_text)
		request.context.emotional_tone = _assess_tone(lower_text)
		
		# Parse intent
		request.parsed_intent = _extract_intent(lower_text, request.context)
		
		# Generate response options
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
		
		# Positive indicators
		var positive = ["please", "friend", "appreciate", "thank", "kind"]
		for word in positive:
			if text.contains(word):
				tone += 0.2
		
		# Negative indicators
		var negative = ["fool", "idiot", "stupid", "damn", "hell"]
		for word in negative:
			if text.contains(word):
				tone -= 0.3
		
		return clamp(tone, -1.0, 1.0)
	
	func _extract_intent(text: String, context: RequestContext) -> Dictionary:
		var intent = {}
		
		# Map request type and topic to likely intents
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
		
		# Always have basic options
		var agree = ResponseOption.new()
		agree.response_type = "AGREE"
		agree.base_score = 0.5
		agree.personality_tags = {"is_helpful": true, "is_cooperative": true}
		agree.response_template = "I'll {action}. {reason}"
		options.append(agree)
		
		var refuse = ResponseOption.new()
		refuse.response_type = "REFUSE"
		refuse.base_score = 0.5
		refuse.personality_tags = {"is_assertive": true, "is_cautious": true}
		refuse.response_template = "I cannot {action}. {reason}"
		options.append(refuse)
		
		var negotiate = ResponseOption.new()
		negotiate.response_type = "NEGOTIATE"
		negotiate.base_score = 0.5
		negotiate.personality_tags = {"is_strategic": true, "is_calculating": true}
		negotiate.response_template = "Perhaps, but {condition}. {offer}"
		options.append(negotiate)
		
		var deflect = ResponseOption.new()
		deflect.response_type = "DEFLECT"
		deflect.base_score = 0.4
		deflect.personality_tags = {"is_evasive": true, "is_cautious": true}
		deflect.response_template = "That's interesting, but {redirect}. {alternative}"
		options.append(deflect)
		
		# Context-specific options
		if request.context.request_type == "THREATEN":
			var challenge = ResponseOption.new()
			challenge.response_type = "CHALLENGE"
			challenge.base_score = 0.5
			challenge.personality_tags = {"is_aggressive": true, "is_brave": true}
			challenge.response_template = "You dare threaten me? {consequence}"
			options.append(challenge)
		
		return options

# ============================================================================
# RESPONSE GENERATOR
# ============================================================================

class ResponseGenerator:
	var personality_phrases = {
		"high_warmth": ["my friend", "of course", "I'd be happy to", "certainly"],
		"low_warmth": ["I suppose", "if necessary", "very well", "as required"],
		"high_assertiveness": ["I will", "absolutely", "without question", "immediately"],
		"low_assertiveness": ["perhaps", "I might", "possibly", "I'll consider"],
		"high_conscientiousness": ["precisely", "exactly", "according to protocol", "properly"],
		"low_conscientiousness": ["whatever", "I guess", "probably", "more or less"],
		"high_risk_tolerance": ["let's do this", "why not", "sounds exciting", "I'm in"],
		"low_risk_tolerance": ["too dangerous", "unwise", "risky", "I must be careful"]
	}
	
	var value_phrases = {
		"POWER": ["strengthen my position", "gain influence", "assert dominance"],
		"HONOR": ["maintain my integrity", "uphold my principles", "do what's right"],
		"KNOWLEDGE": ["learn more", "understand better", "gather information"],
		"COMMUNITY": ["help others", "support the group", "work together"],
		"WEALTH": ["profit from this", "increase earnings", "gain resources"],
		"FREEDOM": ["maintain independence", "avoid constraints", "stay free"]
	}
	
	func generate_response(
		npc: NPC,
		chosen_option: ResponseOption,
		request: Request
	) -> String:
		var template = chosen_option.response_template
		var response = template
		
		# Replace template variables
		response = _apply_personality_modifiers(response, npc.personality)
		response = _apply_value_modifiers(response, npc.personality.values)
		response = _apply_context_modifiers(response, npc.context, request.context)
		response = _apply_relationship_modifiers(
			response, 
			npc.get_relationship(request.context.requester_id)
		)
		
		# Add personality flavor
		response = _add_personality_flavor(response, npc.personality)
		
		# Add name if appropriate
		if npc.personality.warmth > 0.3 and randf() > 0.7:
			response = response + ", friend."
		elif npc.personality.assertiveness > 0.5 and randf() > 0.8:
			response = response + ". That is final."
		
		return response
	
	func _apply_personality_modifiers(template: String, personality: Personality) -> String:
		var result = template
		
		# Replace {action} based on personality
		if result.contains("{action}"):
			if personality.conscientiousness > 0.5:
				result = result.replace("{action}", "handle this properly")
			elif personality.risk_tolerance > 0.5:
				result = result.replace("{action}", "take on this challenge")
			else:
				result = result.replace("{action}", "do that")
		
		# Replace {reason} based on personality
		if result.contains("{reason}"):
			var reason = _generate_reason(personality)
			result = result.replace("{reason}", reason)
		
		return result
	
	func _generate_reason(personality: Personality) -> String:
		var reasons = []
		
		if personality.warmth > 0.5:
			reasons.append("I want to help")
		if personality.assertiveness > 0.5:
			reasons.append("It's necessary")
		if personality.conscientiousness > 0.5:
			reasons.append("It's the proper course")
		if personality.risk_tolerance < -0.3:
			reasons.append("It's too dangerous")
		
		if reasons.is_empty():
			return "I have my reasons"
		
		return reasons[randi() % reasons.size()]
	
	func _apply_value_modifiers(template: String, values: Dictionary) -> String:
		var result = template
		
		# Find highest value
		var highest_value = ""
		var highest_score = 0.0
		for value in values:
			if values[value] > highest_score:
				highest_score = values[value]
				highest_value = value
		
		# Apply value-based modifications
		if result.contains("{condition}"):
			var condition = _generate_condition(highest_value)
			result = result.replace("{condition}", condition)
		
		if result.contains("{offer}"):
			var offer = _generate_offer(highest_value)
			result = result.replace("{offer}", offer)
		
		return result
	
	func _generate_condition(value: String) -> String:
		match value:
			"POWER":
				return "I maintain control"
			"HONOR":
				return "it's done honorably"
			"WEALTH":
				return "I'm compensated fairly"
			"KNOWLEDGE":
				return "you share what you know"
			_:
				return "we agree on terms"
	
	func _generate_offer(value: String) -> String:
		match value:
			"POWER":
				return "I'll need something in return"
			"HONOR":
				return "Let's do this properly"
			"WEALTH":
				return "What's your offer?"
			"KNOWLEDGE":
				return "Tell me more first"
			_:
				return "What do you propose?"
	
	func _apply_context_modifiers(
		template: String,
		npc_context: NPCContext,
		request_context: RequestContext
	) -> String:
		var result = template
		
		# Stress affects responses
		if npc_context.stress_level > 0.7:
			result = "I... " + result  # Hesitation
		
		# Urgency affects responses
		if request_context.urgency > 0.8:
			result = result.replace("Perhaps", "Fine")
			result = result.replace("I'll consider", "I'll do it")
		
		# Add context-specific elements
		if result.contains("{redirect}"):
			var redirect = _generate_redirect(npc_context)
			result = result.replace("{redirect}", redirect)
		
		if result.contains("{alternative}"):
			var alternative = _generate_alternative(npc_context)
			result = result.replace("{alternative}", alternative)
		
		return result
	
	func _generate_redirect(context: NPCContext) -> String:
		if context.stress_level > 0.5:
			return "I have other concerns"
		elif not context.active_goals.is_empty():
			return "I'm focused on " + context.active_goals[0]
		else:
			return "there are other matters"
	
	func _generate_alternative(context: NPCContext) -> String:
		if context.role == "merchant":
			return "Perhaps a trade instead?"
		elif context.role == "scholar":
			return "Let me research this first"
		elif context.role == "warrior":
			return "We should prepare properly"
		else:
			return "We could try something else"
	
	func _apply_relationship_modifiers(template: String, relationship: Relationship) -> String:
		var result = template
		
		# High trust makes responses more direct
		if relationship.trust > 0.7:
			result = result.replace("Perhaps", "Yes")
			result = result.replace("I might", "I will")
		
		# Fear adds caution
		if relationship.fear > 0.5:
			result = "I... " + result.to_lower()
		
		# Affection adds warmth
		if relationship.affection > 0.6:
			if randf() > 0.7:
				result = "Of course, " + result.to_lower()
		
		# Replace consequence for threats
		if result.contains("{consequence}"):
			if relationship.fear > 0.3:
				result = result.replace("{consequence}", "Please, let's discuss this")
			else:
				result = result.replace("{consequence}", "You'll regret this")
		
		return result
	
	func _add_personality_flavor(response: String, personality: Personality) -> String:
		# Add personality-specific interjections
		if personality.warmth > 0.6 and randf() > 0.8:
			response = "Well, " + response.to_lower()
		elif personality.assertiveness > 0.6 and randf() > 0.8:
			response = "Listen. " + response
		elif personality.curiosity > 0.6 and randf() > 0.8:
			response = "Interesting... " + response.to_lower()
		
		return response

# ============================================================================
# DECISION SYSTEM
# ============================================================================

class DecisionEngine:
	func evaluate_response(
		npc: NPC,
		option: ResponseOption,
		request: Request
	) -> float:
		var score = option.base_score
		
		# Apply personality modifiers
		score *= _calculate_personality_modifier(npc.personality, option)
		
		# Apply value alignment
		score *= _calculate_value_modifier(npc.personality.values, option)
		
		# Apply relationship influence
		var relationship = npc.get_relationship(request.context.requester_id)
		score *= _calculate_relationship_modifier(relationship, request.context)
		
		# Apply context modifiers
		score *= _calculate_context_modifier(npc.context, request.context)
		
		# Small randomness
		score += randf_range(-0.1, 0.1)
		
		return score
	
	func _calculate_personality_modifier(
		personality: Personality, 
		option: ResponseOption
	) -> float:
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
		
		# Different response types align with different values
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
	
	func _calculate_relationship_modifier(
		relationship: Relationship,
		request_context: RequestContext
	) -> float:
		var modifier = relationship.get_influence_multiplier()
		
		# Negative tone reduces influence
		if request_context.emotional_tone < -0.3:
			modifier *= 0.7
		
		# Positive tone increases influence
		if request_context.emotional_tone > 0.3:
			modifier *= 1.2
		
		return max(0.1, modifier)
	
	func _calculate_context_modifier(
		npc_context: NPCContext,
		request_context: RequestContext
	) -> float:
		var modifier = 1.0
		
		# Stress makes NPCs more likely to refuse or deflect
		if npc_context.stress_level > 0.5:
			modifier *= 0.8
		
		# Urgency increases compliance (slightly)
		modifier += request_context.urgency * 0.1
		
		# Witnesses affect behavior
		if not request_context.witnesses.is_empty():
			modifier *= 1.1  # More likely to maintain reputation
		
		return max(0.1, modifier)

# ============================================================================
# MAIN NPC SYSTEM
# ============================================================================

var npcs: Dictionary = {}  # id -> NPC
var parser: RequestParser
var generator: ResponseGenerator
var decision_engine: DecisionEngine

func _ready():
	parser = RequestParser.new()
	generator = ResponseGenerator.new()
	decision_engine = DecisionEngine.new()
	
	# Initialize with sample NPCs
	_create_sample_npcs()

func _create_sample_npcs():
	# Create a variety of NPCs with different personalities
	var archetypes = {
		"warlord": Personality.new(
			-0.3, 0.8, 0.2, -0.1, 0.7, 0.3,
			{"POWER": 0.8, "HONOR": 0.4, "WEALTH": 0.3}
		),
		"scholar": Personality.new(
			0.3, -0.2, 0.8, 0.9, -0.2, 0.6,
			{"KNOWLEDGE": 0.9, "HONOR": 0.5, "POWER": 0.2}
		),
		"merchant": Personality.new(
			0.4, 0.2, 0.6, 0.3, 0.4, 0.5,
			{"WEALTH": 0.8, "COMMUNITY": 0.4, "KNOWLEDGE": 0.3}
		),
		"healer": Personality.new(
			0.8, -0.3, 0.7, 0.4, -0.4, 0.7,
			{"COMMUNITY": 0.9, "HONOR": 0.6, "KNOWLEDGE": 0.4}
		),
		"rogue": Personality.new(
			-0.1, 0.3, -0.4, 0.5, 0.8, 0.2,
			{"FREEDOM": 0.9, "WEALTH": 0.6, "POWER": 0.3}
		),
		"noble": Personality.new(
			0.2, 0.6, 0.7, 0.1, -0.3, 0.8,
			{"HONOR": 0.8, "POWER": 0.7, "TRADITION": 0.6}
		)
	}
	
	var names = [
		"Vorak", "Lyris", "Thane", "Mira", "Kass", "Lord Aldric",
		"Elena", "Grimm", "Sofia", "Marcus", "Zara", "Viktor"
	]
	
	var roles = [
		"warlord", "scholar", "merchant", "healer", "rogue", "noble",
		"merchant", "warlord", "scholar", "healer", "rogue", "noble"
	]
	
	for i in range(12):
		var npc_name = names[i]
		var role = roles[i]
		var personality = archetypes[role].clone()
		
		# Add some random variation
		personality.warmth += randf_range(-0.2, 0.2)
		personality.assertiveness += randf_range(-0.2, 0.2)
		personality.risk_tolerance += randf_range(-0.2, 0.2)
		
		var npc = NPC.new("npc_" + str(i), npc_name, personality)
		npc.archetype = role
		npc.context.role = role
		
		# Set initial relationships with player
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
	
	# Parse the request
	var request = parser.parse_request(request_text)
	
	# Evaluate all response options
	var best_option: ResponseOption = null
	var best_score = -INF
	
	for option in request.response_options:
		var score = decision_engine.evaluate_response(npc, option, request)
		if score > best_score:
			best_score = score
			best_option = option
	
	# Generate response
	if best_option:
		var response = generator.generate_response(npc, best_option, request)
		
		# Update NPC state
		_update_npc_after_response(npc, best_option, request)
		
		return "[" + npc.name + "]: " + response
	
	return "[" + npc.name + "]: I... don't understand."

func _update_npc_after_response(
	npc: NPC,
	chosen_option: ResponseOption,
	request: Request
):
	# Update relationship based on response
	var relationship = npc.get_relationship(request.context.requester_id)
	
	match chosen_option.response_type:
		"AGREE":
			relationship.affection += 0.05
			relationship.trust += 0.02
		"REFUSE":
			relationship.affection -= 0.03
		"CHALLENGE":
			relationship.respect += 0.05
			relationship.fear += 0.03
	
	# Record in memory
	npc.remember_event({
		"type": "interaction",
		"requester": request.context.requester_id,
		"request": request.raw_text,
		"response": chosen_option.response_type,
		"timestamp": Time.get_ticks_msec()
	})
	
	# Update stress based on request urgency
	npc.context.stress_level = min(
		1.0,
		npc.context.stress_level + request.context.urgency * 0.1
	)
	# Decay stress over time
	npc.context.stress_level *= 0.95

# ============================================================================
# PUBLIC INTERFACE
# ============================================================================

func send_request_to_npc(npc_name: String, text: String) -> String:
	# Find NPC by name
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
