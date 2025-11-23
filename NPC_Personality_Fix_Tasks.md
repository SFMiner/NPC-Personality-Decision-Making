# NPC Personality System - Fix Task List for Haiku 4.5

**Project**: NPC Personality Response System  
**Main File**: `/mnt/project/npc_system_enhanced.gd`  
**Current Issues**: Grammar bugs (77% "I..." prefix), personality violations, fallback overuse (10.3%), weak trait expression

---

## PHASE 1: Critical Grammar and String Handling Fixes

**Goal**: Fix the "I..." stutter bug affecting 77% of responses and eliminate lowercase "i" artifacts

### Task 1.1: Fix Lowercase "i" Bug

**Dependencies**: None  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be OFF for this task."

**Implementation**:

1. Locate the `ResponseGenerator.generate_response()` function (around line 400-500)
2. Add final cleanup step AFTER all string assembly is complete:

```gdscript
func generate_response(
	npc: NPC,
	chosen_option: ResponseOption,
	request: Request
) -> String:
	var response = chosen_option.response_template
	
	# ... existing assembly logic ...
	response = _apply_personality_modifiers(response, npc.personality)
	response = _apply_value_modifiers(response, npc.personality.values)
	response = _apply_context_modifiers(response, npc.context, request.context)
	response = _apply_relationship_modifiers(response, npc.get_relationship(request.context.requester_id))
	response = _add_personality_flavor(response, npc.personality)
	
	# NEW: Final cleanup - fix any standalone lowercase "i"
	var regex := RegEx.new()
	regex.compile("\\bi\\b")
	response = regex.sub(response, "I", true)  # Replace all occurrences
	
	return "[" + npc.name + "]: " + response
```

3. Test with known problematic cases

**Human Checkpoint**: When done, verify the fix works:
- [ ] Run test suite with same frozen personalities as before
- [ ] Search output for " i " or " i." or " i," patterns
- [ ] Confirm zero instances of lowercase standalone "i"
- [ ] Verify "iPhone" or "i.e." don't get affected (they shouldn't - word boundary prevents it)
- [ ] Examples that should now be fixed:
  - `"Interesting... i... No."` → `"Interesting... I... No."`
  - `"Well, i... Of course."` → `"Well, I... Of course."`

---

### Task 1.2: Remove Excessive "I..." Stutter Prefix

**Dependencies**: Task 1.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be ON for this task."

**Implementation**:

1. Locate `ResponseGenerator._add_personality_flavor()` function
2. Find where "I..." hesitation is added (look for code adding "I... " prefix)
3. Make it MUCH more restrictive - current triggers on ~77% of responses:

```gdscript
func _add_personality_flavor(response: String, personality: Personality) -> String:
	# OLD (too frequent):
	# if personality.assertiveness < 0.2 and randf() > 0.5:
	#     response = "I... " + response
	
	# NEW (rare, only for very uncertain characters):
	# Only trigger hesitation for VERY low assertiveness AND low confidence situations
	if personality.assertiveness < -0.4 and personality.stability < -0.3 and randf() > 0.92:
		response = "I... " + response
	
	# Similarly, reduce "Interesting..." prefix frequency
	# OLD: if personality.curiosity > 0.5 and randf() > 0.7
	# NEW: Make it more selective
	elif personality.curiosity > 0.7 and randf() > 0.85:
		# But NOT if response already starts definitively
		if not _starts_with_definitive(response):
			response = "Interesting... " + response
	
	# Add "Listen." for assertive characters (this is good, keep it)
	elif personality.assertiveness > 0.7 and randf() > 0.8:
		response = "Listen. " + response
	
	# Add "Well," for warm characters (keep this)
	elif personality.warmth > 0.5 and randf() > 0.85:
		response = "Well, " + response
	
	return response

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
```

4. The key changes:
   - Assertiveness threshold: -0.2 → -0.4 (much stricter)
   - Random threshold: 0.5 → 0.92 (from 50% to 8% chance)
   - Add stability check (only very unstable characters stutter)
   - Prevent "Interesting..." on definitive statements

**Human Checkpoint**: When done, verify stutter is rare:
- [ ] Run 120 responses (10 NPCs × 12 runs) with frozen personalities
- [ ] Count instances of "I..." prefix
- [ ] Should be < 6 instances (5% or less)
- [ ] Vorak (assertiveness 0.96) should NEVER say "I..."
- [ ] Lyris (assertiveness -0.09) should rarely say "I..." (maybe 1-2 times)
- [ ] Only extremely low assertiveness NPCs should stutter occasionally
- [ ] Print statistics: `"I..." appeared in X/120 responses (Y%)`

---

### Task 1.3: Implement Grammar Compatibility Rules

**Dependencies**: Task 1.2  
**Extended thinking**: ON  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be ON for this task."

**Implementation**:

1. Create compatibility checking system in `ResponseGenerator` class:

```gdscript
class ResponseGenerator:
	# Add these constants at class level
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
```

2. Modify `_add_personality_flavor()` to check compatibility BEFORE adding prefix:

```gdscript
func _add_personality_flavor(response: String, personality: Personality) -> String:
	# Check if response is incompatible with prefixes
	var is_definitive = _starts_with_any(response, INCOMPATIBLE_WITH_HESITATION)
	
	# Only add hesitation if response is NOT definitive
	if not is_definitive:
		if personality.assertiveness < -0.4 and personality.stability < -0.3 and randf() > 0.92:
			response = "I... " + response
		elif personality.curiosity > 0.7 and randf() > 0.85:
			response = "Interesting... " + response
	
	# Assertive prefixes OK for definitive statements
	if personality.assertiveness > 0.7 and randf() > 0.8:
		response = "Listen. " + response
	elif personality.warmth > 0.5 and randf() > 0.85:
		response = "Well, " + response
	
	return response

func _starts_with_any(text: String, prefixes: Array) -> bool:
	for prefix in prefixes:
		if text.begins_with(prefix):
			return true
	return false
```

3. Add suffix compatibility checking for "That is final":

```gdscript
func _add_assertive_ending(response: String, personality: Personality) -> String:
	# Only add strong endings to:
	# 1. Negative responses (refusals, deflections)
	# 2. High assertiveness characters
	if personality.assertiveness > 0.7 and randf() > 0.7:
		# Check if response is already negative/definitive
		if _is_negative_response(response):
			response += " That is final."
	
	return response

func _is_negative_response(response: String) -> bool:
	var negative_indicators = ["No.", "Never.", "Out of the question", "I cannot", "I must decline"]
	for indicator in negative_indicators:
		if response.contains(indicator):
			return true
	return false
```

**Human Checkpoint**: When done, verify no grammar violations:
- [ ] Run test suite with 120 responses
- [ ] Search for incompatible combinations:
  - [ ] No "I... Out of the question"
  - [ ] No "I... Never"
  - [ ] No "I... Absolutely"
  - [ ] No "Interesting... Certainly"
- [ ] "That is final" only appears after negative statements
- [ ] "Listen." prefix is OK with any content (assertive marker)
- [ ] Print all responses containing "That is final" and verify they're all refusals

---

## PHASE 2: Personality Hard Constraints

**Goal**: Prevent personality violations - high warmth never gives harsh rejections, low assertiveness avoids absolute language

### Task 2.1: Implement Warmth-Based Response Filtering

**Dependencies**: Phase 1 complete  
**Extended thinking**: ON  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be ON for this task."

**Implementation**:

1. Locate `ResponseOptionGenerator.generate_response_options()` function
2. Add filtering logic AFTER options are generated but BEFORE scoring:

```gdscript
func generate_response_options(npc: NPC, request: Request) -> Array[ResponseOption]:
	var options: Array[ResponseOption] = []
	
	# ... existing option generation code ...
	
	# NEW: Filter options by personality constraints
	options = _apply_personality_constraints(options, npc.personality)
	
	return options

func _apply_personality_constraints(
	options: Array[ResponseOption], 
	personality: Personality
) -> Array[ResponseOption]:
	var filtered: Array[ResponseOption] = []
	
	# Define harsh rejection templates
	var harsh_rejections = [
		"No. Find someone else",
		"No. This doesn't concern me",
		"No. That's not my problem",
		"Out of the question",
		"Never."
	]
	
	for option in options:
		var is_harsh = false
		for harsh in harsh_rejections:
			if option.response_template.contains(harsh):
				is_harsh = true
				break
		
		# High warmth (>0.7) characters CANNOT use harsh rejections
		if personality.warmth > 0.7 and is_harsh:
			continue  # Skip this option
		
		# Low warmth (<-0.3) characters prefer harsh rejections
		# (keep all options, just boost harsh ones in scoring later)
		
		filtered.append(option)
	
	return filtered
```

3. Add alternative softened rejection options for high-warmth characters:

```gdscript
func generate_response_options(npc: NPC, request: Request) -> Array[ResponseOption]:
	var options: Array[ResponseOption] = []
	
	# ... generate standard options ...
	
	# If high warmth, add softened alternatives
	if npc.personality.warmth > 0.7:
		options.append(_create_soft_refusal())
	
	options = _apply_personality_constraints(options, npc.personality)
	
	return options

func _create_soft_refusal() -> ResponseOption:
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
```

**Human Checkpoint**: When done, verify warmth constraints work:
- [ ] Run test with Mira (warmth 0.84) 20 times
- [ ] Verify Mira NEVER says:
  - [ ] "No. Find someone else"
  - [ ] "No. This doesn't concern me"
  - [ ] "No. That's not my problem"
  - [ ] "Out of the question"
- [ ] Mira's refusals always include softeners like "I'm sorry", "I wish I could", "Unfortunately"
- [ ] Run test with Marcus (warmth 0.80) 20 times, verify same constraints
- [ ] Run test with Vorak (warmth -0.22) 20 times, verify he CAN use harsh language
- [ ] Print: "High warmth NPCs used harsh rejection: 0/40 times (0%)"

---

### Task 2.2: Implement Assertiveness Constraints

**Dependencies**: Task 2.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be ON for this task."

**Implementation**:

1. Add assertiveness filtering to `_apply_personality_constraints()`:

```gdscript
func _apply_personality_constraints(
	options: Array[ResponseOption], 
	personality: Personality
) -> Array[ResponseOption]:
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
		
		# High warmth constraint (existing)
		if personality.warmth > 0.7 and is_harsh:
			continue
		
		# NEW: Low assertiveness constraint
		# Characters with assertiveness < -0.2 should AVOID absolute language
		if personality.assertiveness < -0.2 and is_absolute:
			continue
		
		filtered.append(option)
	
	return filtered
```

2. Add hedged alternatives for low-assertiveness characters:

```gdscript
func generate_response_options(npc: NPC, request: Request) -> Array[ResponseOption]:
	var options: Array[ResponseOption] = []
	
	# ... generate standard options ...
	
	# If high warmth, add softened alternatives
	if npc.personality.warmth > 0.7:
		options.append(_create_soft_refusal())
	
	# NEW: If low assertiveness, add hedged alternatives
	if npc.personality.assertiveness < -0.2:
		options.append(_create_hedged_refusal())
	
	options = _apply_personality_constraints(options, npc.personality)
	
	return options

func _create_hedged_refusal() -> ResponseOption:
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
```

3. Modify suffix addition to respect assertiveness:

```gdscript
# In ResponseGenerator._add_assertive_ending():
func _add_assertive_ending(response: String, personality: Personality) -> String:
	# Only high assertiveness (>0.7) can add "That is final"
	if personality.assertiveness > 0.7 and randf() > 0.7:
		if _is_negative_response(response):
			response += " That is final."
	
	# Low assertiveness should NEVER add absolute endings
	# (this is now enforced by not calling this function for low assertiveness)
	
	return response
```

**Human Checkpoint**: When done, verify assertiveness constraints:
- [ ] Run test with Lyris (assertiveness -0.09) 20 times
- [ ] Verify Lyris NEVER says:
  - [ ] "Never"
  - [ ] "That is final"
  - [ ] "Absolutely not"
  - [ ] "Out of the question"
- [ ] Lyris uses hedged language: "I don't think", "perhaps", "I'm not sure"
- [ ] Run test with Vorak (assertiveness 0.96) 20 times
- [ ] Verify Vorak frequently uses: "That is final", "Listen", strong language
- [ ] Print: "Low assertiveness used absolute language: 0/20 times (0%)"
- [ ] Print: "High assertiveness used absolute language: 12-16/20 times (60-80%)"

---

## PHASE 3: Trait Expression Enhancement

**Goal**: Make Risk-Tolerance and Conscientiousness clearly visible in responses

### Task 3.1: Risk-Tolerance Drives Decision Direction

**Dependencies**: Phase 2 complete  
**Extended thinking**: ON  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be ON for this task."

**Implementation**:

1. Modify `DecisionEngine._calculate_personality_modifier()` to weight risk-tolerance:

```gdscript
func _calculate_personality_modifier(
	personality: Personality, 
	option: ResponseOption
) -> float:
	var modifier = 1.0
	
	# ... existing warmth and assertiveness modifiers ...
	
	# NEW: Risk-Tolerance affects acceptance/refusal likelihood
	if option.response_type in ["AGREE", "AGREE_CONDITIONAL"]:
		# High risk-tolerance = more likely to accept
		modifier += personality.risk_tolerance * 0.5
	elif option.response_type in ["REFUSE", "REFUSE_SOFT", "REFUSE_HEDGED", "DEFLECT"]:
		# Low risk-tolerance = more likely to refuse
		modifier += (1.0 - personality.risk_tolerance) * 0.4
	
	# Adjust conditional responses based on risk
	if option.response_type == "AGREE_CONDITIONAL":
		# Low risk wants MORE conditions
		if personality.risk_tolerance < 0.0:
			modifier += 0.3
	
	return modifier
```

2. Add risk-based reasoning to refusal options:

```gdscript
func _create_refusal_option() -> ResponseOption:
	var option = ResponseOption.new()
	option.response_type = "REFUSE"
	option.base_score = 0.5
	
	# Template will be selected based on risk-tolerance during generation
	option.response_template = "No. {reason}"  # Placeholder
	
	return option

# In ResponseGenerator.generate_response():
func _select_refusal_reason(personality: Personality) -> String:
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
```

**Human Checkpoint**: When done, verify risk affects decisions:
- [ ] Run Zara (risk 0.93) 30 times on same request
- [ ] Count acceptances vs refusals
- [ ] Run Viktor (risk -0.45) 30 times on same request
- [ ] Count acceptances vs refusals
- [ ] Zara should accept MORE than Viktor:
  - [ ] Zara acceptance rate: 50-70%
  - [ ] Viktor acceptance rate: 20-40%
- [ ] Zara's refusals say: "not worth my time", "doesn't interest me"
- [ ] Viktor's refusals say: "too dangerous", "too risky", "must be cautious"
- [ ] Print comparison: "Zara accepted 18/30 (60%), Viktor accepted 8/30 (27%)"

---

### Task 3.2: Risk-Tolerance Vocabulary and Tone

**Dependencies**: Task 3.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be ON for this task."

**Implementation**:

1. Add risk-specific phrase pools to `ResponseGenerator`:

```gdscript
class ResponseGenerator:
	var personality_phrases = {
		# ... existing phrases ...
		
		# NEW: Risk-tolerance phrases
		"high_risk_accept": ["Let's do it!", "Sounds exciting!", "I'm in!", "Why not?", "Absolutely!"],
		"high_risk_enthusiasm": ["gladly", "eagerly", "enthusiastically", "with excitement"],
		"low_risk_accept": ["If we're careful...", "Cautiously, yes", "We must be safe", "Proceed slowly"],
		"low_risk_hedging": ["carefully", "cautiously", "with great care", "if it's safe"]
	}
```

2. Modify `_apply_personality_modifiers()` to inject risk-based vocabulary:

```gdscript
func _apply_personality_modifiers(response: String, personality: Personality) -> String:
	# ... existing warmth/assertiveness modifications ...
	
	# NEW: Risk-Tolerance affects vocabulary
	if personality.risk_tolerance > 0.6:
		# High risk = enthusiastic, bold language
		response = response.replace("I'll ", "I'll gladly ")
		response = response.replace("perhaps", "absolutely")
		response = response.replace("I can", "I'd love to")
		
		# Add enthusiasm markers
		if response.begins_with("Of course"):
			response = response.replace("Of course", "Absolutely")
		
	elif personality.risk_tolerance < -0.4:
		# Low risk = cautious, hedging language
		if response.contains("I'll "):
			response = response.replace("I'll ", "I'll carefully ")
		elif response.contains("I can"):
			response = response.replace("I can", "I can try to")
		
		# Add safety qualifiers
		if not response.contains("careful") and not response.contains("cautious"):
			if randf() > 0.7:
				response = response.replace(". ", ", if it's safe. ")
	
	return response
```

3. Add exclamation marks for high-risk acceptances:

```gdscript
func generate_response(...) -> String:
	# ... build response ...
	
	# NEW: High risk-tolerance adds excitement
	if npc.personality.risk_tolerance > 0.6:
		if chosen_option.response_type in ["AGREE", "AGREE_CONDITIONAL"]:
			# Add excitement - replace period with exclamation
			if response.ends_with(".") and randf() > 0.6:
				response = response.trim_suffix(".") + "!"
	
	return response
```

**Human Checkpoint**: When done, verify risk vocabulary:
- [ ] Run Zara (risk 0.93) 20 times
- [ ] Verify Zara uses:
  - [ ] "gladly", "absolutely", "I'm in", "Let's do it"
  - [ ] Exclamation marks (!) in acceptances
  - [ ] No cautious language like "carefully"
- [ ] Run Viktor (risk -0.45) 20 times
- [ ] Verify Viktor uses:
  - [ ] "carefully", "cautiously", "if it's safe"
  - [ ] "I can try to" instead of "I can"
  - [ ] No enthusiastic language
- [ ] Print examples of contrasting responses for same request

---

### Task 3.3: Add Conscientiousness Expression Variety

**Dependencies**: Task 3.2  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be OFF for this task."

**Implementation**:

1. Add conscientiousness phrase pool to `ResponseGenerator`:

```gdscript
class ResponseGenerator:
	var personality_phrases = {
		# ... existing phrases ...
		
		# NEW: Conscientiousness phrases
		"high_conscientiousness": [
			"correctly", "properly", "precisely", 
			"according to protocol", "by the book", 
			"as it should be done", "with proper procedure"
		],
		"low_conscientiousness": [
			"more or less", "I guess", "probably", 
			"good enough", "doesn't matter much", "whatever works"
		]
	}
```

2. Apply conscientiousness modifiers without overusing "properly":

```gdscript
func _apply_personality_modifiers(response: String, personality: Personality) -> String:
	# ... existing modifications ...
	
	# NEW: Conscientiousness affects how they describe actions
	if personality.conscientiousness > 0.6:
		# High conscientiousness = precise language
		# But ROTATE through different words, don't always use "properly"
		var phrases = personality_phrases["high_conscientiousness"]
		var chosen = phrases[randi() % phrases.size()]
		
		# Only apply 30% of the time to avoid overuse
		if randf() > 0.7:
			if response.contains("I'll take care"):
				response = response.replace("take care", "handle this " + chosen)
			elif response.contains("I can do"):
				response = response.replace("I can do", "I can execute this " + chosen)
	
	elif personality.conscientiousness < -0.3:
		# Low conscientiousness = casual language
		if randf() > 0.75:
			var phrases = personality_phrases["low_conscientiousness"]
			var chosen = phrases[randi() % phrases.size()]
			response = response.replace("I'll ", "I'll " + chosen + " ")
	
	return response
```

**Human Checkpoint**: When done, verify conscientiousness variety:
- [ ] Run Thane (high conscientiousness) 20 times
- [ ] Count uses of each word:
  - [ ] "properly": 2-4 times (not every time!)
  - [ ] "correctly": 2-4 times
  - [ ] "precisely": 1-3 times
  - [ ] "by the book": 1-2 times
- [ ] Verify variety: "No single word appears in >30% of responses"
- [ ] Print word frequency analysis
- [ ] Verify responses feel precise/organized without being repetitive

---

## PHASE 4: Fallback System Improvements

**Goal**: Reduce fallback frequency from 10.3% to <5% and make fallback text personality-specific

### Task 4.1: Create Personality-Specific Fallback Text

**Dependencies**: Phase 3 complete  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be OFF for this task."

**Implementation**:

1. Replace generic fallback in `DecisionEngine` with personality-based selection:

```gdscript
class DecisionEngine:
	func choose_best_option(
		npc: NPC,
		options: Array[ResponseOption],
		request: Request
	) -> ResponseOption:
		# ... existing scoring logic ...
		
		# If no good option, use fallback
		if best_score < FALLBACK_THRESHOLD:
			return _generate_fallback_option(npc)
		
		return best_option
	
	func _generate_fallback_option(npc: NPC) -> ResponseOption:
		var fallback = ResponseOption.new()
		fallback.response_type = "FALLBACK"
		fallback.base_score = 0.3
		
		# Select fallback text based on personality and role
		var fallback_text = _select_fallback_text(npc)
		fallback.response_template = fallback_text
		
		return fallback
	
	func _select_fallback_text(npc: NPC) -> String:
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
```

**Human Checkpoint**: When done, verify personality-specific fallbacks:
- [ ] Run full test suite (12 NPCs × 10 runs)
- [ ] Find all fallback responses
- [ ] Verify fallback text varies by personality/role:
  - [ ] Vorak (warlord, assertive): "consider my position strategically"
  - [ ] Lyris (scholar): "research this matter further"
  - [ ] Kass (rogue): "weigh the risks before deciding"
  - [ ] Lord Aldric (noble): "consult my advisors first"
- [ ] No generic "I need to think about this" for anyone
- [ ] Print: "Fallback text variety: X unique fallback messages across Y fallback instances"

---

### Task 4.2: Reduce Fallback Frequency by Role

**Dependencies**: Task 4.1  
**Extended thinking**: ON  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be ON for this task."

**Implementation**:

1. Add role-based fallback thresholds in `DecisionEngine`:

```gdscript
class DecisionEngine:
	# Base threshold for triggering fallback
	const BASE_FALLBACK_THRESHOLD = 0.3
	
	func choose_best_option(
		npc: NPC,
		options: Array[ResponseOption],
		request: Request
	) -> ResponseOption:
		if options.is_empty():
			return _generate_fallback_option(npc)
		
		# ... score all options ...
		
		# Calculate role-specific fallback threshold
		var fallback_threshold = _get_fallback_threshold(npc)
		
		if best_score < fallback_threshold:
			return _generate_fallback_option(npc)
		
		return best_option
	
	func _get_fallback_threshold(npc: NPC) -> float:
		var threshold = BASE_FALLBACK_THRESHOLD
		
		# Decisive roles have LOWER threshold (harder to trigger fallback)
		if npc.context.role in ["warlord", "noble"]:
			threshold = 0.15  # Very hard to trigger
		elif npc.personality.assertiveness > 0.7:
			threshold = 0.18  # Hard to trigger
		
		# Thoughtful roles have HIGHER threshold (easier to trigger)
		elif npc.context.role in ["scholar", "rogue"]:
			threshold = 0.4  # Easier to trigger
		elif npc.personality.conscientiousness > 0.7:
			threshold = 0.35  # Slightly easier
		
		return threshold
```

2. Improve option generation to reduce fallback need:

```gdscript
func generate_response_options(npc: NPC, request: Request) -> Array[ResponseOption]:
	var options: Array[ResponseOption] = []
	
	# ... generate standard options ...
	
	# NEW: Ensure MINIMUM 4 options always available
	# (so anti-repetition doesn't force fallback)
	while options.size() < 4:
		options.append(_generate_generic_option(request.context.request_type))
	
	options = _apply_personality_constraints(options, npc.personality)
	
	# After filtering, ensure at least 3 remain
	if options.size() < 3:
		# Add back some generic safe options
		options.append(_create_neutral_response())
	
	return options

func _generate_generic_option(request_type: String) -> ResponseOption:
	var option = ResponseOption.new()
	option.response_type = "DEFLECT"
	option.base_score = 0.4
	option.response_template = "Let me think about this"
	return option

func _create_neutral_response() -> ResponseOption:
	var option = ResponseOption.new()
	option.response_type = "NEUTRAL"
	option.base_score = 0.5
	option.response_template = "I'll consider it"
	return option
```

**Human Checkpoint**: When done, verify reduced fallback rate:
- [ ] Run full test suite (12 NPCs × 10 runs = 120 responses)
- [ ] Count fallback instances by role:
  - [ ] Warlords (Vorak, Grimm): 0-2 fallbacks out of 20 total (<10%)
  - [ ] Nobles (Lord Aldric): 0-2 fallbacks out of 10 (<20%)
  - [ ] Scholars (Lyris, Sofia): 3-6 fallbacks out of 20 total (15-30%)
  - [ ] Rogues (Kass): 2-4 fallbacks out of 10 (20-40%)
- [ ] Overall fallback rate: <5% (6 or fewer out of 120)
- [ ] Print statistics: "Total fallback rate: X/120 (Y%) - Target: <5%"
- [ ] Print by role: "Warlords: X%, Nobles: X%, Scholars: X%, Rogues: X%"

---

## PHASE 5: Testing and Validation

**Goal**: Create automated test suite to verify all fixes and prevent regressions

### Task 5.1: Create Comprehensive Test Suite

**Dependencies**: All previous phases complete  
**Extended thinking**: ON  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be ON for this task."

**Implementation**:

1. Create new test file `test_personality_fixes.gd`:

```gdscript
extends Node
class_name PersonalityFixTests

var npc_system: NPCSystemEnhanced
var test_results: Dictionary = {}

func _ready():
	npc_system = NPCSystemEnhanced.new()
	add_child(npc_system)
	await npc_system.ready
	
	print("\n" + "="*80)
	print("NPC PERSONALITY FIX VALIDATION TESTS")
	print("="*80 + "\n")
	
	run_all_tests()
	print_summary()

func run_all_tests():
	test_lowercase_i_fixed()
	test_stutter_frequency()
	test_warmth_constraints()
	test_assertiveness_constraints()
	test_risk_affects_decisions()
	test_risk_vocabulary()
	test_fallback_frequency()
	test_fallback_variety()
	test_grammar_compatibility()

func test_lowercase_i_fixed():
	print("TEST 1: Lowercase 'i' Bug Fixed")
	print("-" * 80)
	
	var responses = _collect_responses(120)  # 10 each from 12 NPCs
	var lowercase_i_count = 0
	
	var regex := RegEx.new()
	regex.compile("\\bi\\b")
	
	for response in responses:
		if regex.search(response):
			lowercase_i_count += 1
			print("  FAIL: Found lowercase 'i' in: " + response)
	
	var passed = (lowercase_i_count == 0)
	_record_result("lowercase_i_fixed", passed, 
		"No lowercase standalone 'i' found: " + str(lowercase_i_count) + "/120")
	print()

func test_stutter_frequency():
	print("TEST 2: 'I...' Stutter Frequency < 5%")
	print("-" * 80)
	
	var responses = _collect_responses(120)
	var stutter_count = 0
	
	for response in responses:
		if "I..." in response:
			stutter_count += 1
	
	var percentage = (float(stutter_count) / 120.0) * 100.0
	var passed = (percentage < 5.0)
	
	_record_result("stutter_frequency", passed,
		"'I...' appears in " + str(stutter_count) + "/120 responses (" + 
		str(snappedf(percentage, 0.1)) + "%) - Target: <5%")
	print()

func test_warmth_constraints():
	print("TEST 3: High Warmth Never Uses Harsh Rejections")
	print("-" * 80)
	
	var high_warmth_npcs = ["Mira", "Marcus"]  # Warmth > 0.7
	var harsh_phrases = [
		"No. Find someone else",
		"No. This doesn't concern me",
		"No. That's not my problem",
		"Out of the question"
	]
	
	var violation_count = 0
	
	for npc_name in high_warmth_npcs:
		var npc_responses = _collect_npc_responses(npc_name, 20)
		for response in npc_responses:
			for harsh in harsh_phrases:
				if harsh in response:
					violation_count += 1
					print("  FAIL: " + npc_name + " used harsh phrase: " + response)
	
	var passed = (violation_count == 0)
	_record_result("warmth_constraints", passed,
		"High warmth harsh rejections: " + str(violation_count) + "/40 - Target: 0")
	print()

func test_assertiveness_constraints():
	print("TEST 4: Low Assertiveness Avoids Absolute Language")
	print("-" * 80)
	
	var low_assert_npcs = ["Lyris"]  # Assertiveness < 0
	var absolute_phrases = [
		"Never",
		"That is final",
		"Absolutely not",
		"Out of the question"
	]
	
	var violation_count = 0
	
	for npc_name in low_assert_npcs:
		var npc_responses = _collect_npc_responses(npc_name, 20)
		for response in npc_responses:
			for absolute in absolute_phrases:
				if absolute in response:
					violation_count += 1
					print("  FAIL: " + npc_name + " used absolute language: " + response)
	
	var passed = (violation_count == 0)
	_record_result("assertiveness_constraints", passed,
		"Low assertiveness absolute language: " + str(violation_count) + "/20 - Target: 0")
	print()

func test_risk_affects_decisions():
	print("TEST 5: Risk-Tolerance Affects Acceptance Rate")
	print("-" * 80)
	
	var test_request = "Help me explore the dangerous ruins?"
	
	# High risk NPC
	var zara_accepts = 0
	for i in range(30):
		var response = npc_system.send_request_to_npc("Zara", test_request)
		if _is_acceptance(response):
			zara_accepts += 1
	
	# Low risk NPC
	var viktor_accepts = 0
	for i in range(30):
		var response = npc_system.send_request_to_npc("Viktor", test_request)
		if _is_acceptance(response):
			viktor_accepts += 1
	
	var zara_rate = (float(zara_accepts) / 30.0) * 100.0
	var viktor_rate = (float(viktor_accepts) / 30.0) * 100.0
	
	var passed = (zara_rate > viktor_rate + 15.0)  # Zara should accept >=15% more
	
	_record_result("risk_affects_decisions", passed,
		"Zara (high risk): " + str(snappedf(zara_rate, 1)) + "% accept, " +
		"Viktor (low risk): " + str(snappedf(viktor_rate, 1)) + "% accept")
	print()

func test_risk_vocabulary():
	print("TEST 6: Risk-Tolerance Affects Vocabulary")
	print("-" * 80)
	
	var high_risk_words = ["gladly", "exciting", "absolutely", "!", "why not"]
	var low_risk_words = ["carefully", "cautiously", "if it's safe", "must be careful"]
	
	var zara_responses = _collect_npc_responses("Zara", 20)
	var viktor_responses = _collect_npc_responses("Viktor", 20)
	
	var zara_high_risk_count = 0
	var viktor_low_risk_count = 0
	
	for response in zara_responses:
		for word in high_risk_words:
			if word in response.to_lower():
				zara_high_risk_count += 1
				break
	
	for response in viktor_responses:
		for word in low_risk_words:
			if word in response.to_lower():
				viktor_low_risk_count += 1
				break
	
	var passed = (zara_high_risk_count > 5 and viktor_low_risk_count > 5)
	
	_record_result("risk_vocabulary", passed,
		"Zara uses high-risk vocabulary: " + str(zara_high_risk_count) + "/20, " +
		"Viktor uses low-risk vocabulary: " + str(viktor_low_risk_count) + "/20")
	print()

func test_fallback_frequency():
	print("TEST 7: Overall Fallback Rate < 5%")
	print("-" * 80)
	
	var responses = _collect_responses(120)
	var fallback_count = 0
	
	for response in responses:
		if "need to think" in response.to_lower() or \
		   "need to consider" in response.to_lower() or \
		   "need to research" in response.to_lower() or \
		   "need to weigh" in response.to_lower():
			fallback_count += 1
	
	var percentage = (float(fallback_count) / 120.0) * 100.0
	var passed = (percentage < 5.0)
	
	_record_result("fallback_frequency", passed,
		"Fallback rate: " + str(fallback_count) + "/120 (" + 
		str(snappedf(percentage, 1)) + "%) - Target: <5%")
	print()

func test_fallback_variety():
	print("TEST 8: Fallback Text is Personality-Specific")
	print("-" * 80)
	
	var generic_fallback = "I need to think about this"
	var responses = _collect_responses(120)
	var generic_count = 0
	
	for response in responses:
		if generic_fallback in response:
			generic_count += 1
	
	var passed = (generic_count == 0)
	
	_record_result("fallback_variety", passed,
		"Generic fallback usage: " + str(generic_count) + "/120 - Target: 0")
	print()

func test_grammar_compatibility():
	print("TEST 9: No Grammar Violations (I... + Definitive)")
	print("-" * 80)
	
	var responses = _collect_responses(120)
	var violation_count = 0
	
	var bad_patterns = [
		"I... Out of the question",
		"I... Never",
		"I... Absolutely",
		"Interesting... Never"
	]
	
	for response in responses:
		for pattern in bad_patterns:
			if pattern in response:
				violation_count += 1
				print("  FAIL: Grammar violation: " + response)
	
	var passed = (violation_count == 0)
	
	_record_result("grammar_compatibility", passed,
		"Grammar violations: " + str(violation_count) + "/120 - Target: 0")
	print()

func _collect_responses(count: int) -> Array:
	var responses = []
	var npc_names = npc_system.get_npc_list()
	var test_request = "Can you help me with this task?"
	
	var per_npc = ceil(float(count) / npc_names.size())
	
	for npc_name in npc_names:
		for i in range(per_npc):
			if responses.size() >= count:
				break
			var response = npc_system.send_request_to_npc(npc_name, test_request)
			responses.append(response)
	
	return responses

func _collect_npc_responses(npc_name: String, count: int) -> Array:
	var responses = []
	var test_request = "Can you help me with this task?"
	
	for i in range(count):
		var response = npc_system.send_request_to_npc(npc_name, test_request)
		responses.append(response)
	
	return responses

func _is_acceptance(response: String) -> bool:
	var accept_indicators = [
		"Of course",
		"Certainly",
		"I'll ",
		"Gladly",
		"Absolutely",
		"Yes"
	]
	
	for indicator in accept_indicators:
		if indicator in response:
			return true
	return false

func _record_result(test_name: String, passed: bool, message: String):
	test_results[test_name] = {"passed": passed, "message": message}
	
	if passed:
		print("  ✓ PASS: " + message)
	else:
		print("  ✗ FAIL: " + message)

func print_summary():
	print("\n" + "="*80)
	print("TEST SUMMARY")
	print("="*80)
	
	var passed_count = 0
	var total_count = test_results.size()
	
	for test_name in test_results:
		if test_results[test_name].passed:
			passed_count += 1
	
	print("\nTests Passed: " + str(passed_count) + "/" + str(total_count))
	
	if passed_count == total_count:
		print("\n🎉 ALL TESTS PASSED! System is ready.")
	else:
		print("\n⚠️  Some tests failed. Review failures above.")
	
	print("="*80 + "\n")
```

2. Add test scene `test_personality_fixes.tscn`:
   - Root: Node (with PersonalityFixTests script attached)
   - Add to autoload or run manually

**Human Checkpoint**: When done, verify test suite works:
- [ ] Run test scene
- [ ] All 9 tests execute
- [ ] Each test prints clear PASS/FAIL status
- [ ] Test summary shows X/9 passed
- [ ] If any test fails, output shows exactly what failed
- [ ] Tests can be re-run to verify fixes
- [ ] Save test output to file for comparison

---

### Task 5.2: Create Final Validation Report

**Dependencies**: Task 5.1  
**Extended thinking**: OFF  
**Reminder**: Before starting, ask human: "Is extended thinking turned on? It should be OFF for this task."

**Implementation**:

1. Run the test suite and capture full output
2. Create comparison report with before/after statistics:

```gdscript
extends Node

func generate_comparison_report():
	var report = []
	
	report.append("="*80)
	report.append("NPC PERSONALITY SYSTEM - FIX VALIDATION REPORT")
	report.append("="*80)
	report.append("")
	
	report.append("BEFORE FIXES:")
	report.append("  'I...' prefix: 1110/1440 responses (77%)")
	report.append("  Lowercase 'i': 85/1440 responses (6%)")
	report.append("  Fallback rate: 148/1440 responses (10.3%)")
	report.append("  Warmth violations: Multiple instances")
	report.append("  Assertiveness violations: Multiple instances")
	report.append("  Risk-Tolerance: Not expressed")
	report.append("")
	
	report.append("AFTER FIXES:")
	# Fill in with actual test results
	report.append("  'I...' prefix: X/120 responses (Y%)")
	report.append("  Lowercase 'i': 0/120 responses (0%)")
	report.append("  Fallback rate: X/120 responses (Y%)")
	report.append("  Warmth violations: 0 instances")
	report.append("  Assertiveness violations: 0 instances")
	report.append("  Risk-Tolerance: Clearly expressed in decisions and vocabulary")
	report.append("")
	
	report.append("KEY IMPROVEMENTS:")
	report.append("  ✓ Grammar bugs eliminated")
	report.append("  ✓ Personality consistency enforced")
	report.append("  ✓ Trait expression enhanced")
	report.append("  ✓ Response variety maintained")
	report.append("  ✓ Fallback system improved")
	report.append("="*80)
	
	var file = FileAccess.open("res://validation_report.txt", FileAccess.WRITE)
	for line in report:
		file.store_line(line)
	file.close()
	
	print("\nValidation report saved to: res://validation_report.txt")
```

**Human Checkpoint**: Final validation complete:
- [ ] All test suite tests pass (9/9)
- [ ] Validation report generated
- [ ] Before/after comparison shows improvements:
  - [ ] "I..." prefix: 77% → <5%
  - [ ] Lowercase "i": 6% → 0%
  - [ ] Fallback rate: 10.3% → <5%
  - [ ] Warmth violations: Multiple → 0
  - [ ] Assertiveness violations: Multiple → 0
  - [ ] Risk expression: None → Clear
- [ ] Run manual spot-check with 5 NPCs, verify natural responses
- [ ] System is production-ready ✓

---

## EXECUTION NOTES

**Recommended Order**:
1. Start with Phase 1 (grammar fixes) - these are critical and affect everything
2. Phase 2 (hard constraints) - prevent personality violations
3. Phase 3 (trait enhancement) - add missing expressiveness
4. Phase 4 (fallback improvements) - polish the edge cases
5. Phase 5 (testing) - validate everything works

**Between Phases**:
- Run quick manual tests to verify phase objectives met
- Don't proceed to next phase if current phase tests fail
- Each phase builds on previous work

**File Backup**:
- Before starting, copy `npc_system_enhanced.gd` to `npc_system_enhanced_backup.gd`
- This allows rollback if needed

**Testing**:
- Use frozen personality values (same as original test data)
- Run minimum 120 responses per validation (10 per NPC × 12 NPCs)
- Compare against baseline from `/mnt/project/test_responses.txt`
