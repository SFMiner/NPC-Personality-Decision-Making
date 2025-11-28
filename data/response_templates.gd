# res://data/response_templates.gd
class_name ResponseTemps  # Different from preload name
extends RefCounted

# ============================================================================
# ENUMS - Define all the categories
# ============================================================================

# What the NPC is doing with their response
enum ResponseType {
	# Action responses
	AGREE,
	AGREE_CONDITIONAL,
	REFUSE,
	REFUSE_SOFT,
	REFUSE_HEDGED,
	NEGOTIATE,
	DEFLECT,
	CHALLENGE,
	
	# Knowledge responses
	SHARE_KNOWLEDGE,
	SHARE_CAUTIOUS,
	ADMIT_IGNORANCE,
	DENY_KNOWLEDGE,
	ADMIT_FORGOTTEN,
}

# What kind of request/situation is this
enum ContextPattern {
	# Question types (for knowledge queries)
	YES_NO_QUESTION,   # "Do you know...?" "Can you tell me...?"
	IMPERATIVE,        # "Tell me..." "Let me know..."
	WHERE_QUESTION,    # "Where is...?"
	WHO_QUESTION,      # "Who is...?"
	WHAT_QUESTION,     # "What is...?"
	WHEN_QUESTION,     # "When did...?"
	WHY_QUESTION,      # "Why...?"
	HOW_QUESTION,      # "How...?"
	RUMOR_QUESTION,    # "Have you heard...?"
	
	# Action request types
	ASK_ACTION,        # "Can you help me?"
	DEMAND_ACTION,     # "Do this now!"
	THREATEN,          # "Do it or else!"
	OFFER_TRADE,       # "I'll give you X for Y"
	
	# Universal
	GENERAL            # Works in any context
}

# Personality-driven emotional tone
enum Style {
	DIRECT,            # Neutral, straightforward
	APOLOGETIC,        # High warmth
	ENTHUSIASTIC,      # High warmth + positive
	CURIOUS,           # High curiosity
	DISMISSIVE,        # Low warmth, high assertiveness
	EVASIVE,           # Low assertiveness
	AGGRESSIVE,        # High assertiveness + low warmth
	FORMAL,            # High conscientiousness
	CASUAL             # Low conscientiousness, high warmth
}

# ============================================================================
# TEMPLATE CLASS - Single template entry
# ============================================================================

class Template:
	var text: String                              # Template with {placeholders}
	var response_types: Array                     # Which ResponseTypes use this
	var context_patterns: Array                   # Which ContextPatterns apply
	var styles: Array                             # Which Styles fit
	var required_placeholders: Array              # Must have these
	var optional_placeholders: Array              # Nice to have
	
	func _init(
		p_text: String,
		p_response_types: Array,
		p_context_patterns: Array,
		p_styles: Array,
		p_required: Array = [],
		p_optional: Array = []
	):
		text = p_text
		response_types = p_response_types
		context_patterns = p_context_patterns
		styles = p_styles
		required_placeholders = p_required
		optional_placeholders = p_optional

# ============================================================================
# SINGLETON PATTERN
# ============================================================================

static var _instance: ResponseTemps = null

static func get_instance() -> ResponseTemps:
	if _instance == null:
		_instance = ResponseTemps.new()
	return _instance

# ============================================================================
# HELPER: Convert Personality to Style
# ============================================================================

static func personality_to_style(personality) -> Style:
	# Assumes personality has: warmth, curiosity, assertiveness, conscientiousness
	
	# High warmth = Apologetic
	if personality.warmth > 0.5:
		return Style.APOLOGETIC
	
	# High curiosity = Curious
	elif personality.curiosity > 0.6:
		return Style.CURIOUS
	
	# Low warmth + high assertiveness = Dismissive
	elif personality.warmth < -0.3 and personality.assertiveness > 0.4:
		return Style.DISMISSIVE
	
	# Low assertiveness = Evasive
	elif personality.assertiveness < -0.2:
		return Style.EVASIVE
	
	# High assertiveness + low warmth = Aggressive
	elif personality.assertiveness > 0.6 and personality.warmth < 0:
		return Style.AGGRESSIVE
	
	# High conscientiousness = Formal
	elif personality.conscientiousness > 0.7:
		return Style.FORMAL
	
	# Low conscientiousness + high warmth = Casual
	elif personality.conscientiousness < -0.3 and personality.warmth > 0.3:
		return Style.CASUAL
	
	# Default
	else:
		return Style.DIRECT

# ============================================================================
# MASTER TEMPLATE DATABASE
# ============================================================================

# FIXED: Changed from const to var (can't call .new() in const)
var TEMPLATES = [
	# ========================================================================
	# UNIVERSAL REFUSALS (work for refusing actions AND admitting ignorance)
	# ========================================================================
	
	Template.new(
		"I'm afraid not.",
		[ResponseType.REFUSE, ResponseType.REFUSE_SOFT, ResponseType.ADMIT_IGNORANCE, ResponseType.DENY_KNOWLEDGE],
		[ContextPattern.YES_NO_QUESTION, ContextPattern.ASK_ACTION],
		[Style.DIRECT, Style.APOLOGETIC]
	),
	
	Template.new(
		"No.",
		[ResponseType.REFUSE, ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.YES_NO_QUESTION],
		[Style.DISMISSIVE, Style.AGGRESSIVE]
	),
	
	Template.new(
		"Unfortunately, no.",
		[ResponseType.REFUSE, ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.YES_NO_QUESTION],
		[Style.APOLOGETIC]
	),
	
	Template.new(
		"I'm sorry, but no.",
		[ResponseType.REFUSE_SOFT, ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.YES_NO_QUESTION],
		[Style.APOLOGETIC]
	),
	
	Template.new(
		"I... I don't think so.",
		[ResponseType.REFUSE_HEDGED, ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.YES_NO_QUESTION],
		[Style.EVASIVE]
	),
	
	Template.new(
		"Not that I know of.",
		[ResponseType.REFUSE, ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.YES_NO_QUESTION],
		[Style.DIRECT, Style.EVASIVE]
	),
	
	# Curious variants
	Template.new(
		"I'm afraid not, but I'd like to know!",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.YES_NO_QUESTION],
		[Style.CURIOUS]
	),
	
	Template.new(
		"No, but that sounds interesting!",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.YES_NO_QUESTION],
		[Style.CURIOUS]
	),
	
	# ========================================================================
	# IMPERATIVE REFUSALS ("Tell me..." → "I can't")
	# ========================================================================
	
	Template.new(
		"I'm afraid I can't.",
		[ResponseType.REFUSE, ResponseType.REFUSE_SOFT, ResponseType.DENY_KNOWLEDGE],
		[ContextPattern.IMPERATIVE, ContextPattern.ASK_ACTION],
		[Style.DIRECT, Style.APOLOGETIC]
	),
	
	Template.new(
		"I can't help you with that.",
		[ResponseType.REFUSE],
		[ContextPattern.IMPERATIVE],
		[Style.DIRECT]
	),
	
	Template.new(
		"I don't have that information.",
		[ResponseType.DENY_KNOWLEDGE],
		[ContextPattern.IMPERATIVE],
		[Style.DIRECT]
	),
	
	Template.new(
		"I wish I could, but I don't know.",
		[ResponseType.ADMIT_IGNORANCE, ResponseType.REFUSE_SOFT],
		[ContextPattern.IMPERATIVE],
		[Style.APOLOGETIC]
	),
	
	Template.new(
		"Can't help you.",
		[ResponseType.REFUSE, ResponseType.DENY_KNOWLEDGE],
		[ContextPattern.IMPERATIVE],
		[Style.DISMISSIVE]
	),
	
	Template.new(
		"I don't think I can help.",
		[ResponseType.REFUSE_HEDGED],
		[ContextPattern.IMPERATIVE],
		[Style.EVASIVE]
	),
	
	# ========================================================================
	# WHERE QUESTION RESPONSES
	# ========================================================================
	
	Template.new(
		"I don't know where {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION],
		[Style.DIRECT],
		["subject"]
	),
	
	Template.new(
		"I don't know the location.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION],
		[Style.DIRECT]
	),
	
	Template.new(
		"I have no idea where that is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION],
		[Style.DIRECT]
	),
	
	Template.new(
		"I wish I knew where {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION],
		[Style.APOLOGETIC],
		["subject"]
	),
	
	Template.new(
		"I'm sorry, I don't know the location.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION],
		[Style.APOLOGETIC]
	),
	
	Template.new(
		"Interesting question... but I don't know where {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION],
		[Style.CURIOUS],
		["subject"]
	),
	
	Template.new(
		"I've wondered that myself. I don't know.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.CURIOUS]
	),
	
	Template.new(
		"Good question! I don't know where to find {subject}.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION],
		[Style.CURIOUS],
		["subject"]
	),
	
	Template.new(
		"No idea where that is.",
		[ResponseType.ADMIT_IGNORANCE, ResponseType.DENY_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION],
		[Style.DISMISSIVE]
	),
	
	Template.new(
		"I... I don't think I know where {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION],
		[Style.EVASIVE],
		["subject"]
	),
	
	# ========================================================================
	# WHO QUESTION RESPONSES
	# ========================================================================
	
	Template.new(
		"I don't know who {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHO_QUESTION],
		[Style.DIRECT],
		["subject"]
	),
	
	Template.new(
		"I don't know who that is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHO_QUESTION],
		[Style.DIRECT]
	),
	
	Template.new(
		"I have no idea who {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHO_QUESTION],
		[Style.DIRECT],
		["subject"]
	),
	
	Template.new(
		"I wish I knew who {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHO_QUESTION],
		[Style.APOLOGETIC],
		["subject"]
	),
	
	Template.new(
		"I'm sorry, I don't know who that is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHO_QUESTION],
		[Style.APOLOGETIC]
	),
	
	Template.new(
		"Interesting... but I don't know who that is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHO_QUESTION],
		[Style.CURIOUS]
	),
	
	Template.new(
		"Good question! I don't know who {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHO_QUESTION],
		[Style.CURIOUS],
		["subject"]
	),
	
	Template.new(
		"No idea.",
		[ResponseType.ADMIT_IGNORANCE, ResponseType.DENY_KNOWLEDGE],
		[ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION, ContextPattern.WHEN_QUESTION,
		 ContextPattern.WHY_QUESTION, ContextPattern.HOW_QUESTION],
		[Style.DISMISSIVE]
	),
	
	Template.new(
		"Never heard of them.",
		[ResponseType.ADMIT_IGNORANCE, ResponseType.DENY_KNOWLEDGE],
		[ContextPattern.WHO_QUESTION],
		[Style.DISMISSIVE]
	),
	
	# ========================================================================
	# WHAT QUESTION RESPONSES
	# ========================================================================
	
	Template.new(
		"I don't know what {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHAT_QUESTION],
		[Style.DIRECT],
		["subject"]
	),
	
	Template.new(
		"I don't know what that is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHAT_QUESTION],
		[Style.DIRECT]
	),
	
	Template.new(
		"I have no idea.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHAT_QUESTION, ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION],
		[Style.DIRECT]
	),
	
	Template.new(
		"I wish I knew what {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHAT_QUESTION],
		[Style.APOLOGETIC],
		["subject"]
	),
	
	Template.new(
		"I'm sorry, I don't know.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHAT_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHERE_QUESTION],
		[Style.APOLOGETIC]
	),
	
	Template.new(
		"Interesting question... but I don't know.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHAT_QUESTION, ContextPattern.WHY_QUESTION, ContextPattern.HOW_QUESTION],
		[Style.CURIOUS]
	),
	
	Template.new(
		"Good question! I don't know what {subject} is.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHAT_QUESTION],
		[Style.CURIOUS],
		["subject"]
	),
	
	# ========================================================================
	# WHEN/WHY/HOW QUESTION RESPONSES (basics added)
	# ========================================================================
	
	Template.new(
		"I don't know when that happened.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHEN_QUESTION],
		[Style.DIRECT]
	),
	
	Template.new(
		"I wish I knew when.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHEN_QUESTION],
		[Style.APOLOGETIC]
	),
	
	Template.new(
		"I don't know why.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHY_QUESTION],
		[Style.DIRECT]
	),
	
	Template.new(
		"I wish I knew why.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHY_QUESTION],
		[Style.APOLOGETIC]
	),
	
	Template.new(
		"I don't know how.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.HOW_QUESTION],
		[Style.DIRECT]
	),
	
	Template.new(
		"I wish I knew how.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.HOW_QUESTION],
		[Style.APOLOGETIC]
	),
	
	# ========================================================================
	# UNIVERSAL "DON'T KNOW" (works for all WH-questions)
	# ========================================================================
	
	Template.new(
		"I don't know.",
		[ResponseType.ADMIT_IGNORANCE, ResponseType.DENY_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION,
		 ContextPattern.WHEN_QUESTION, ContextPattern.WHY_QUESTION, ContextPattern.HOW_QUESTION],
		[Style.DIRECT, Style.DISMISSIVE]
	),
	
	Template.new(
		"Don't know.",
		[ResponseType.ADMIT_IGNORANCE, ResponseType.DENY_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION,
		 ContextPattern.WHEN_QUESTION, ContextPattern.WHY_QUESTION, ContextPattern.HOW_QUESTION],
		[Style.DISMISSIVE]
	),
	
	Template.new(
		"Haven't a clue.",
		[ResponseType.ADMIT_IGNORANCE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.DISMISSIVE]
	),
	
	# ========================================================================
	# ADMIT_FORGOTTEN RESPONSES (added)
	# ========================================================================
	
	Template.new(
		"I feel like I knew that once...",
		[ResponseType.ADMIT_FORGOTTEN],
		[ContextPattern.GENERAL],
		[Style.APOLOGETIC, Style.CURIOUS]
	),
	
	Template.new(
		"That sounds familiar, but I can't quite remember.",
		[ResponseType.ADMIT_FORGOTTEN],
		[ContextPattern.GENERAL],
		[Style.EVASIVE, Style.APOLOGETIC]
	),
	
	Template.new(
		"I used to know, but it escapes me now.",
		[ResponseType.ADMIT_FORGOTTEN],
		[ContextPattern.GENERAL],
		[Style.DIRECT, Style.APOLOGETIC]
	),
	
	# ========================================================================
	# SHARE_KNOWLEDGE RESPONSES
	# ========================================================================
	
	# DIRECT style
	Template.new(
		"{subject} {predicate} {object}.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.DIRECT],
		["subject", "predicate", "object"]
	),
	
	Template.new(
		"I can tell you that {subject} {predicate} {object}.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.FORMAL, Style.DIRECT],
		["subject", "predicate", "object"]
	),
	
	# DISMISSIVE style
	Template.new(
		"{object}. Everyone knows that.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.DISMISSIVE, Style.CASUAL],
		["object"]
	),
	
	Template.new(
		"{subject} {predicate} {object}.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.DISMISSIVE],
		["subject", "predicate", "object"]
	),
	
	Template.new(
		"{object}.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.DISMISSIVE],
		["object"]
	),
	
	# AGGRESSIVE style (for warriors/aggressive NPCs)
	Template.new(
		"{object}.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.AGGRESSIVE],
		["object"]
	),
	
	Template.new(
		"{subject} {predicate} {object}.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.AGGRESSIVE],
		["subject", "predicate", "object"]
	),
	
	Template.new(
		"{object}. Obvious.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.AGGRESSIVE],
		["object"]
	),
	
	# APOLOGETIC style
	Template.new(
		"I believe {subject} {predicate} {object}.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.APOLOGETIC],
		["subject", "predicate", "object"]
	),
	
	# CURIOUS style
	Template.new(
		"From what I know, {subject} {predicate} {object}.",
		[ResponseType.SHARE_KNOWLEDGE],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.CURIOUS],
		["subject", "predicate", "object"]
	),
	
	# SHARE_CAUTIOUS
	Template.new(
		"If I recall correctly, {subject} {predicate} {object}.",
		[ResponseType.SHARE_CAUTIOUS],
		[ContextPattern.WHERE_QUESTION, ContextPattern.WHO_QUESTION, ContextPattern.WHAT_QUESTION],
		[Style.EVASIVE, Style.FORMAL],
		["subject", "predicate", "object"]
	),
	
	# ========================================================================
	# ACTION RESPONSES - AGREE
	# ========================================================================
	
	Template.new(
		"I'll {action}.",
		[ResponseType.AGREE],
		[ContextPattern.ASK_ACTION],
		[Style.DIRECT],
		["action"]
	),
	
	Template.new(
		"{enthusiasm}, I can {action}.",
		[ResponseType.AGREE],
		[ContextPattern.ASK_ACTION],
		[Style.ENTHUSIASTIC, Style.APOLOGETIC],
		["action", "enthusiasm"]
	),
	
	Template.new(
		"Of course.",
		[ResponseType.AGREE],
		[ContextPattern.ASK_ACTION],
		[Style.DIRECT, Style.ENTHUSIASTIC]
	),
	
	Template.new(
		"Gladly.",
		[ResponseType.AGREE],
		[ContextPattern.ASK_ACTION],
		[Style.ENTHUSIASTIC]
	),
	
	# ========================================================================
	# ACTION RESPONSES - AGREE_CONDITIONAL (added)
	# ========================================================================
	
	Template.new(
		"I'll {action}, but {condition}.",
		[ResponseType.AGREE_CONDITIONAL],
		[ContextPattern.ASK_ACTION],
		[Style.DIRECT],
		["action", "condition"]
	),
	
	Template.new(
		"I can help, but only if {condition}.",
		[ResponseType.AGREE_CONDITIONAL],
		[ContextPattern.ASK_ACTION],
		[Style.DIRECT],
		["condition"]
	),
	
	# ========================================================================
	# ACTION RESPONSES - REFUSE
	# ========================================================================
	
	Template.new(
		"I cannot {action}.",
		[ResponseType.REFUSE],
		[ContextPattern.ASK_ACTION, ContextPattern.DEMAND_ACTION],
		[Style.DIRECT],
		["action"]
	),
	
	Template.new(
		"I wish I could, but I cannot {action}.",
		[ResponseType.REFUSE_SOFT],
		[ContextPattern.ASK_ACTION],
		[Style.APOLOGETIC],
		["action"]
	),
	
	Template.new(
		"No. {harsh_reason}",
		[ResponseType.REFUSE],
		[ContextPattern.ASK_ACTION, ContextPattern.DEMAND_ACTION],
		[Style.DISMISSIVE, Style.AGGRESSIVE],
		[],
		["harsh_reason"]
	),
	
	Template.new(
		"I'd rather not.",
		[ResponseType.REFUSE_HEDGED],
		[ContextPattern.ASK_ACTION],
		[Style.EVASIVE]
	),
	
	# ========================================================================
	# ACTION RESPONSES - DEFLECT (added)
	# ========================================================================
	
	Template.new(
		"That's interesting, but I have other matters to attend to.",
		[ResponseType.DEFLECT],
		[ContextPattern.ASK_ACTION],
		[Style.EVASIVE, Style.FORMAL]
	),
	
	Template.new(
		"Perhaps you should ask someone else.",
		[ResponseType.DEFLECT],
		[ContextPattern.ASK_ACTION],
		[Style.EVASIVE]
	),
	
	# ========================================================================
	# ACTION RESPONSES - NEGOTIATE
	# ========================================================================
	
	Template.new(
		"Perhaps, but {condition}.",
		[ResponseType.NEGOTIATE],
		[ContextPattern.ASK_ACTION, ContextPattern.OFFER_TRADE],
		[Style.DIRECT],
		["condition"]
	),
	
	Template.new(
		"I might consider it if {condition}.",
		[ResponseType.NEGOTIATE],
		[ContextPattern.ASK_ACTION],
		[Style.EVASIVE, Style.DIRECT],
		["condition"]
	),
	
	Template.new(
		"What's in it for me?",
		[ResponseType.NEGOTIATE],
		[ContextPattern.ASK_ACTION, ContextPattern.OFFER_TRADE],
		[Style.AGGRESSIVE, Style.DIRECT]
	),
	
	# ========================================================================
	# ACTION RESPONSES - CHALLENGE (added)
	# ========================================================================
	
	Template.new(
		"You dare threaten me?",
		[ResponseType.CHALLENGE],
		[ContextPattern.THREATEN],
		[Style.AGGRESSIVE]
	),
	
	Template.new(
		"Is that a threat? Choose your next words carefully.",
		[ResponseType.CHALLENGE],
		[ContextPattern.THREATEN],
		[Style.AGGRESSIVE, Style.FORMAL]
	),
]

# ============================================================================
# RUNTIME LOOKUP INDICES (built on first use)
# ============================================================================

var _response_type_index: Dictionary = {}
var _context_pattern_index: Dictionary = {}
var _style_index: Dictionary = {}
var _built: bool = false

# FIXED: Cache regex object instead of creating new one each time
var _placeholder_cleanup_regex: RegEx = null

func _init():
	# Initialize regex once
	_placeholder_cleanup_regex = RegEx.new()
	_placeholder_cleanup_regex.compile("\\{[^}]+\\}")

func _build_indices() -> void:
	if _built:
		return
	
	# Build indices
	for i in range(TEMPLATES.size()):
		var template = TEMPLATES[i]
		
		# Index by response type
		for rt in template.response_types:
			if not _response_type_index.has(rt):
				_response_type_index[rt] = []
			_response_type_index[rt].append(i)
		
		# Index by context pattern
		for cp in template.context_patterns:
			if not _context_pattern_index.has(cp):
				_context_pattern_index[cp] = []
			_context_pattern_index[cp].append(i)
		
		# Index by style
		for s in template.styles:
			if not _style_index.has(s):
				_style_index[s] = []
			_style_index[s].append(i)
	
	_built = true

# ============================================================================
# MAIN LOOKUP FUNCTION
# ============================================================================

func get_template(
	response_type: ResponseType,
	context_pattern: ContextPattern,
	style: Style,
	placeholders: Dictionary = {}
) -> String:
	# ADDED: Validate enum inputs
	assert(response_type >= 0 and response_type < ResponseType.size(), 
		"Invalid ResponseType: %d" % response_type)
	assert(context_pattern >= 0 and context_pattern < ContextPattern.size(), 
		"Invalid ContextPattern: %d" % context_pattern)
	assert(style >= 0 and style < Style.size(), 
		"Invalid Style: %d" % style)
	
	_build_indices()
	
	# Find intersection of all three indices
	var response_matches = _response_type_index.get(response_type, [])
	var context_matches = _context_pattern_index.get(context_pattern, [])
	var style_matches = _style_index.get(style, [])
	
#	print("\n=== DETAILED DEBUG ===")
#	print("Looking for: RT=%s, CP=%s, Style=%s" % [
#		ResponseType.keys()[response_type],
#		ContextPattern.keys()[context_pattern],
#		Style.keys()[style]
#	])
	
	# Check if AGGRESSIVE is even in the style index
#	if style == Style.AGGRESSIVE:
#		print("AGGRESSIVE style_matches: %s" % str(style_matches))
	
#	print("response_matches (SHARE_KNOWLEDGE): %s" % str(response_matches))
#	print("context_matches (WHERE_QUESTION): %s" % str(context_matches))
#	print("style_matches (AGGRESSIVE): %s" % str(style_matches))
	
	# Find templates that match ALL criteria
	var matches = []
	for idx in response_matches:
#		print("  Checking idx %d:" % idx)
#		print("    in context? %s" % (idx in context_matches))
#		print("    in style? %s" % (idx in style_matches))

		if idx in context_matches and idx in style_matches:
#			print("    PASSED initial check")
			var template = TEMPLATES[idx]
			
			# Check placeholders
			var has_required = true
			for req in template.required_placeholders:
				if not placeholders.has(req) or placeholders[req] == "":
#					print("    FAILED - missing placeholder '%s'" % req)
					has_required = false
					break
			
			if has_required:
#				print("    ✓ FULL MATCH!")
				matches.append(idx)

#	print("Total matches found: %d" % matches.size())
	
	if matches.is_empty():
		print("WARNING: No matches! Checking why...")
		print("  response_type_index has %d entries for SHARE_KNOWLEDGE" % _response_type_index.get(ResponseType.SHARE_KNOWLEDGE, []).size())
		print("  style_index has %d entries for AGGRESSIVE" % _style_index.get(Style.AGGRESSIVE, []).size())
	
	# Fallback 1: Try without context pattern requirement
	if matches.is_empty():
		for idx in response_matches:
			if idx in style_matches:
				var template = TEMPLATES[idx]
				var has_required = true
				for req in template.required_placeholders:
					if not placeholders.has(req) or placeholders[req] == "":
						has_required = false
						break
				if has_required:
					matches.append(idx)
	
	# Fallback 2: Try with just response type (ignore style)
	if matches.is_empty():
		matches = response_matches.filter(
			func(idx): return TEMPLATES[idx].required_placeholders.is_empty()
		)
	
	# Ultimate fallback
	if matches.is_empty():
		# ADDED: Warning for debugging
		push_warning("ResponseTemps: No template found for ResponseType=%s, ContextPattern=%s, Style=%s" % 
			[ResponseType.keys()[response_type], ContextPattern.keys()[context_pattern], Style.keys()[style]])
		return "I..."
	
	# Select random from matches
	var selected_idx = matches[randi() % matches.size()]
	var template = TEMPLATES[selected_idx]
	var result = template.text
	
	# Replace placeholders
	for key in placeholders:
		var placeholder = "{" + key + "}"
		if placeholder in result:
			result = result.replace(placeholder, str(placeholders[key]))
	
	# FIXED: Use cached regex instead of creating new one
	result = _placeholder_cleanup_regex.sub(result, "", true)
	
	return result
