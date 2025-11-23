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

		assert(options.size() >= 9, "Not enough response options generated!")
	
		return options

# ============================================================================
# ENHANCED RESPONSE GENERATOR
# ============================================================================

class ResponseGenerator:

	# NEW: Grammar compatibility constants
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

	const STRONG_ENDINGS = [
		"That is final.",
		"End of discussion.",
		"No more debate."
	]

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

	# NEW: Risk-tolerance phrases
	var personality_phrases = {
		"high_risk_accept": ["Let's do it!", "Sounds exciting!", "I'm in!", "Why not?", "Absolutely!"],
		"high_risk_enthusiasm": ["gladly", "eagerly", "enthusiastically", "with excitement"],
		"low_risk_accept": ["If we're careful…", "Cautiously, yes", "We must be safe", "Proceed slowly"],
		"low_risk_hedging": ["carefully", "cautiously", "with great care", "if it's safe"]
	}
	
	func generate_response(npc: NPC, chosen_option: ResponseOption, request: Request) -> String:
		var template = chosen_option.response_template
		var response = template
		var hesitation_ok = true
		# Replace template variables with personality-driven variations
		response = _apply_personality_modifiers(response, npc.personality, chosen_option.template_variant, hesitation_ok)
		response = _apply_value_modifiers(response, npc.personality.values, chosen_option.template_variant)
		response = _apply_context_modifiers(response, npc, request.context, hesitation_ok)
		response = _apply_relationship_modifiers(response, 	
			npc.get_relationship(request.context.requester_id),
			hesitation_ok)
		response = _add_personality_flavor(response, npc.personality)

		# Ensure response ends with punctuation before adding closings
		if not response.ends_with(".") and not response.ends_with("!") and not response.ends_with("?"):
			response = response + "."
 
		# Add closing punctuation variation
		if npc.personality.warmth > 0.3 and randf() > 0.7:
			response = response.trim_suffix(".") + ", friend."
		# NEW: Use assertive ending function to check compatibility
		response = _add_assertive_ending(response, npc.personality)

		# NEW: High risk-tolerance adds excitement to acceptances
		if npc.personality.risk_tolerance > 0.6:
			if chosen_option.response_type in ["AGREE", "AGREE_CONDITIONAL"]:
				# Add excitement - replace period with exclamation
				if response.ends_with(".") and randf() > 0.6:
					response = response.trim_suffix(".") + "!"

		var re = RegEx.new()
		re.compile("\\bi\\b")
		response = re.sub(response, "I", true)
		return response
	
	func _apply_personality_modifiers(template: String, personality: Personality, variant: int, hesitation_ok : bool) -> String:
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
		if personality.assertiveness > 0.5:
			hesitation_ok = false
			
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

		# NEW: Risk-Tolerance affects vocabulary
		if personality.risk_tolerance > 0.6:
			# High risk = enthusiastic, bold language
			if result.contains("I'll ") and not result.contains("I'll gladly"):
				result = result.replace("I'll ", "I'll gladly ")
			result = result.replace("perhaps", "absolutely")
			result = result.replace("I can", "I'd love to")

			# Add enthusiasm markers
			if result.begins_with("Of course"):
				result = result.replace("Of course", "Absolutely")

		elif personality.risk_tolerance < -0.4:
			# Low risk = cautious, hedging language
			if result.contains("I'll ") and not result.contains("carefully"):
				result = result.replace("I'll ", "I'll carefully ")
			elif result.contains("I can"):
				result = result.replace("I can", "I can try to")

			# Add safety qualifiers
			if not result.contains("careful") and not result.contains("cautious"):
				if randf() > 0.7:
					result = result.replace(". ", ", if it's safe. ")

		# NEW: Conscientiousness affects how they describe actions
		if personality.conscientiousness > 0.6:
			# High conscientiousness = precise language
			# But ROTATE through different words, don't always use "properly"
			var phrases = [
				"correctly", "properly", "precisely",
				"according to protocol", "by the book",
				"as it should be done", "with proper procedure"
			]
			var chosen = phrases[randi() % phrases.size()]

			# Only apply 30% of the time to avoid overuse
			if randf() > 0.7:
				if result.contains("I'll take care"):
					result = result.replace("take care", "handle this " + chosen)
				elif result.contains("I can do"):
					result = result.replace("I can do", "I can execute this " + chosen)

		elif personality.conscientiousness < -0.3:
			# Low conscientiousness = casual language
			if randf() > 0.75:
				var phrases = [
					"more or less", "I guess", "probably",
					"good enough", "doesn't matter much", "whatever works"
				]
				var chosen = phrases[randi() % phrases.size()]
				result = result.replace("I'll ", "I'll " + chosen + " ")

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
	
	func _apply_context_modifiers(template: String, npc, request_context: RequestContext, hesitation_ok : bool) -> String:
		var result = template
		var personality = npc.personality
		var npc_context : NPCContext = npc.context
		var assertiveness = npc.personality.assertiveness
		var stress_level = npc_context.stress_level
		# Stress hesitation
		if (stress_level > 0.7 and randf() > 0.9) or (assertiveness < 0.4 and randf() > 0.85):
			result = "I… " + result
		elif assertiveness > 0.7:
			hesitation_ok = true
			
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
	
	func _apply_relationship_modifiers(template: String, relationship: Relationship, hesitation_ok : bool) -> String:
		var result = template
		
		# High trust = more direct
		if relationship.trust > 0.7:
			result = result.replace("Perhaps", "Yes")
			result = result.replace("I might", "I will")
		
		# Fear = cautious
		if hesitation_ok:
			if relationship.fear > 0.5:
				if not result.begins_with("I… "):
					result = "I… " + result.to_lower()
		
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
		# Don't add flavor if already has flavor (avoid "Well, Well, …")
		if response.begins_with("Well, ") or response.begins_with("Listen. ") or response.begins_with("Interesting… "):
			return response

		# NEW: Check if response is incompatible with hesitation/uncertainty prefixes
		var is_incompatible_with_hesitation = _starts_with_any(response, INCOMPATIBLE_WITH_HESITATION)

		# Only add hesitation if response is NOT definitive/absolute
		if not is_incompatible_with_hesitation:
			# FIXED: Only trigger hesitation for VERY low assertiveness AND low stability (8% chance instead of 50%)
			if personality.assertiveness < -0.4 and personality.stability < -0.3 and randf() > 0.92:
				response = "I… " + response
			# Similarly, reduce "Interesting…" prefix frequency
			elif personality.curiosity > 0.7 and randf() > 0.85:
				# But NOT if response already starts definitively
				if not _starts_with_definitive(response):
					response = "Interesting… " + _lowercase_first_char_safe(response)

		# Assertive prefixes are OK with any content (they're strong markers)
		if personality.assertiveness > 0.7 and randf() > 0.8:
			response = "Listen. " + response
		elif personality.warmth > 0.5 and randf() > 0.85:
			response = "Well, " + _lowercase_first_char_safe(response)

		return response

	# NEW: Helper function to check if response starts with definitive statements
	func _starts_with_definitive(response: String) -> bool:
		var definitive_starts = [
			"Out of the question",
			"Never",
			"Absolutely",
			"Certainly",
			"Of course",
			"No."
		]
		for start in definitive_starts:
			if response.begins_with(start):
				return true
		return false

	# NEW: Helper to check if response starts with any item in array
	func _starts_with_any(text: String, prefixes: Array) -> bool:
		for prefix in prefixes:
			if text.begins_with(prefix):
				return true
		return false

	# NEW: Add assertive endings to strong refusals only
	func _add_assertive_ending(response: String, personality: Personality) -> String:
		# Only high assertiveness (>0.7) can add "That is final"
		if personality.assertiveness > 0.7 and randf() > 0.7:
			if _is_negative_response(response):
				response += " That is final."

		return response

	# NEW: Check if response is a negative/refusal statement
	func _is_negative_response(response: String) -> bool:
		var negative_indicators = ["No.", "Never.", "Out of the question", "I cannot", "I must decline"]
		for indicator in negative_indicators:
			if response.contains(indicator):
				return true
		return false

	# NEW: Apply personality-based constraints to filter options
	func apply_personality_constraints(options: Array[ResponseOption], personality: Personality) -> Array[ResponseOption]:
		var filtered: Array[ResponseOption] = []

		var harsh_rejections = [
			"No. Find someone else",
			"No. This doesn't concern me",
			"No. That's not my problem",
			"Out of the question",
			"Never."
		]

		# NEW: Define absolute language markers
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
				continue  # Skip this option

			# NEW: Low assertiveness constraint
			# Characters with assertiveness < -0.2 should AVOID absolute language
			if personality.assertiveness < -0.2 and is_absolute:
				continue  # Skip this option

			filtered.append(option)

		return filtered

	# NEW: Create soft refusal option for high-warmth characters
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

	# NEW: Create hedged refusal option for low-assertiveness characters
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

	# NEW: Select refusal reason based on risk tolerance
	func select_refusal_reason(personality: Personality) -> String:
		if personality.risk_tolerance < -0.3:
			# Low risk = safety concerns
			var cautious_reasons = [
				"That's too dangerous",
				"Too risky for my taste",
				"I must be cautious",
				"It's too uncertain"
			]
			return cautious_reasons[randi() % cautious_reasons.size()]
		elif personality.risk_tolerance > 0.6:
			# High risk = boredom/disinterest
			var bold_reasons = [
				"Not worth my time",
				"Doesn't interest me",
				"I have better things to do",
				"Too mundane"
			]
			return bold_reasons[randi() % bold_reasons.size()]
		else:
			# Neutral = practical concerns
			return "I have more important matters"

	# NEW: Select personality-specific fallback text
	func select_fallback_text(npc: NPC) -> String:
		# Assertive characters are decisive
		if npc.personality.assertiveness > 0.5:
			return "I need to consider my position strategically"

		# Scholars prioritize research
		elif npc.context.role == "scholar":
			return "I need to research this matter further"

		# Rogues weigh risks
		elif npc.context.role == "rogue":
			return "I need to weigh the risks before deciding"

		# Nobles consult others
		elif npc.context.role == "noble":
			return "I must consult my advisors first"

		# Warm characters are apologetic
		elif npc.personality.warmth > 0.5:
			return "I need a moment to think about this, friend"

		# Default
		else:
			return "I need time to consider this carefully"

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
	var decision_engine = DecisionEngine.new()
	var npc = npcs[npc_id]
	var request = parser.parse_request(request_text)

	# NEW: Add soft refusal option for high-warmth characters
	if npc.personality.warmth > 0.7:
		request.response_options.append(generator.create_soft_refusal())

	# NEW: Add hedged refusal option for low-assertiveness characters
	if npc.personality.assertiveness < -0.2:
		request.response_options.append(generator.create_hedged_refusal())

	# NEW: Apply personality constraints to filter harsh options
	request.response_options = generator.apply_personality_constraints(request.response_options, npc.personality)

	# Evaluate options and pick best (with anti-repetition)
	var best_option: ResponseOption = null
	var best_score = -INF
	var attempts = 0
	
	var max_attempts = _get_max_attempts(npc)
	
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

	# NEW: Check fallback threshold before triggering fallback
#	if best_score >= fallback_threshold and best_option:
		# Score is good enough - use it even if repetitive
#		var response = generator.generate_response(npc, best_option, request)
#		npc.remember_response(response)
#		_update_npc_after_response(npc, best_option, request)
#		return "[" + npc.name + "]: " + response

	# NEW: Personality-specific fallback
	var fallback_text = generator.select_fallback_text(npc)
	return decision_engine._generate_fallback(npc)

func _get_max_attempts(npc: NPC) -> int:
	# Decisive roles try more times before giving up (lower fallback rate)
	if npc.context.role in ["warlord", "noble"]:
		return 5  # Try harder to find a non-repetitive response
	elif npc.personality.assertiveness > 0.7:
		return 4  # Assertive characters keep trying
	
	# Thoughtful roles give up sooner (higher fallback rate is OK)
	elif npc.context.role in ["scholar", "rogue"]:
		return 2  # Current default
	elif npc.personality.conscientiousness > 0.7:
		return 2  # Deliberate characters may need to think
	
	# Default
	else:
		return 3

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
