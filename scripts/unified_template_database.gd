class_name IgnoranceResponseTemplates
extends RefCounted

# Pattern constants (what kind of question is being answered)
enum Pattern {
	YES_NO,      # "Do you know...?" "Can you tell me...?"
	IMPERATIVE,  # "Tell me..." "Let me know..."
	WHERE,       # "Where is...?"
	WHO,         # "Who is...?"
	WHAT,        # "What is...?"
	WHEN,        # "When did...?"
	WHY,         # "Why did...?"
	HOW,         # "How does...?"
	INDIRECT,    # "I was wondering if..."
	RUMOR        # "Have you heard any rumors...?"
}

# Style constants (personality-driven tone)
enum Style {
	DIRECT,      # Neutral, straightforward
	APOLOGETIC,  # High warmth
	CURIOUS,     # High curiosity
	DISMISSIVE,  # Low warmth, high assertiveness
	EVASIVE      # Low assertiveness
}

# Master template database
# Each entry: {text: String, patterns: Array[Pattern], styles: Array[Style], subject: bool}
const TEMPLATES = [
	# ========================================================================
	# UNIVERSAL RESPONSES (work for multiple patterns)
	# ========================================================================
	
	# Simple negatives - work for YES/NO and INDIRECT
	{
		"text": "I'm afraid not.",
		"patterns": [Pattern.YES_NO, Pattern.INDIRECT],
		"styles": [Style.DIRECT, Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "No, I don't.",
		"patterns": [Pattern.YES_NO],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "Unfortunately, no.",
		"patterns": [Pattern.YES_NO, Pattern.INDIRECT],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "I'm sorry, but no.",
		"patterns": [Pattern.YES_NO, Pattern.INDIRECT],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "No.",
		"patterns": [Pattern.YES_NO],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "Nope.",
		"patterns": [Pattern.YES_NO],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "I... I don't think so.",
		"patterns": [Pattern.YES_NO, Pattern.INDIRECT],
		"styles": [Style.EVASIVE],
		"subject": false
	},
	{
		"text": "Not that I know of.",
		"patterns": [Pattern.YES_NO],
		"styles": [Style.DIRECT, Style.EVASIVE],
		"subject": false
	},
	
	# Curious variants for YES/NO
	{
		"text": "I'm afraid not, but I'd like to know!",
		"patterns": [Pattern.YES_NO, Pattern.INDIRECT],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "No, but that sounds interesting!",
		"patterns": [Pattern.YES_NO],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "I don't know, but now I'm curious.",
		"patterns": [Pattern.YES_NO],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	
	# ========================================================================
	# IMPERATIVE RESPONSES ("Tell me...", "Let me know...")
	# ========================================================================
	
	{
		"text": "I'm afraid I can't.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.DIRECT, Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "I can't help you with that.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I don't have that information.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I'm sorry, but I can't.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "I wish I could, but I don't know.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "I'd love to help, but I don't know.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "Can't help you.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "Don't know.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "I... I'm afraid I can't.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.EVASIVE],
		"subject": false
	},
	{
		"text": "I don't think I can help.",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.EVASIVE],
		"subject": false
	},
	{
		"text": "I can't, but I wish I could!",
		"patterns": [Pattern.IMPERATIVE],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	
	# ========================================================================
	# WHERE RESPONSES
	# ========================================================================
	
	{
		"text": "I don't know where {subject} is.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.DIRECT],
		"subject": true
	},
	{
		"text": "I don't know the location.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I have no idea where that is.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I wish I knew where {subject} is.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.APOLOGETIC],
		"subject": true
	},
	{
		"text": "I'm sorry, I don't know the location.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "Unfortunately, I don't know where that is.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "Interesting question... but I don't know where {subject} is.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.CURIOUS],
		"subject": true
	},
	{
		"text": "I've wondered that myself. I don't know.",
		"patterns": [Pattern.WHERE, Pattern.WHO, Pattern.WHAT],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "Good question! I don't know where to find {subject}.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.CURIOUS],
		"subject": true
	},
	{
		"text": "No idea where that is.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "Don't know.",
		"patterns": [Pattern.WHERE, Pattern.WHO, Pattern.WHAT, Pattern.WHEN, Pattern.WHY, Pattern.HOW],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "Haven't a clue.",
		"patterns": [Pattern.WHERE, Pattern.WHO, Pattern.WHAT],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "I... I don't think I know where {subject} is.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.EVASIVE],
		"subject": true
	},
	{
		"text": "I'm not sure where that would be.",
		"patterns": [Pattern.WHERE],
		"styles": [Style.EVASIVE],
		"subject": false
	},
	
	# ========================================================================
	# WHO RESPONSES
	# ========================================================================
	
	{
		"text": "I don't know who {subject} is.",
		"patterns": [Pattern.WHO],
		"styles": [Style.DIRECT],
		"subject": true
	},
	{
		"text": "I don't know who that is.",
		"patterns": [Pattern.WHO],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I have no idea who {subject} is.",
		"patterns": [Pattern.WHO],
		"styles": [Style.DIRECT],
		"subject": true
	},
	{
		"text": "I wish I knew who {subject} is.",
		"patterns": [Pattern.WHO],
		"styles": [Style.APOLOGETIC],
		"subject": true
	},
	{
		"text": "I'm sorry, I don't know who that is.",
		"patterns": [Pattern.WHO],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "Interesting... but I don't know who that is.",
		"patterns": [Pattern.WHO],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "Good question! I don't know who {subject} is.",
		"patterns": [Pattern.WHO],
		"styles": [Style.CURIOUS],
		"subject": true
	},
	{
		"text": "No idea.",
		"patterns": [Pattern.WHO, Pattern.WHAT, Pattern.WHEN, Pattern.WHY, Pattern.HOW],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "Never heard of them.",
		"patterns": [Pattern.WHO],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	
	# ========================================================================
	# WHAT RESPONSES
	# ========================================================================
	
	{
		"text": "I don't know what {subject} is.",
		"patterns": [Pattern.WHAT],
		"styles": [Style.DIRECT],
		"subject": true
	},
	{
		"text": "I don't know what that is.",
		"patterns": [Pattern.WHAT],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I have no idea.",
		"patterns": [Pattern.WHAT, Pattern.WHERE, Pattern.WHO],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I wish I knew what {subject} is.",
		"patterns": [Pattern.WHAT],
		"styles": [Style.APOLOGETIC],
		"subject": true
	},
	{
		"text": "I'm sorry, I don't know.",
		"patterns": [Pattern.WHAT, Pattern.WHO, Pattern.WHERE],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "Interesting question... but I don't know.",
		"patterns": [Pattern.WHAT, Pattern.WHY, Pattern.HOW],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "Good question! I don't know what {subject} is.",
		"patterns": [Pattern.WHAT],
		"styles": [Style.CURIOUS],
		"subject": true
	},
	
	# ========================================================================
	# WHEN RESPONSES
	# ========================================================================
	
	{
		"text": "I don't know when {subject} happened.",
		"patterns": [Pattern.WHEN],
		"styles": [Style.DIRECT],
		"subject": true
	},
	{
		"text": "I don't know when that was.",
		"patterns": [Pattern.WHEN],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I have no idea when.",
		"patterns": [Pattern.WHEN],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I wish I knew when {subject} happened.",
		"patterns": [Pattern.WHEN],
		"styles": [Style.APOLOGETIC],
		"subject": true
	},
	{
		"text": "I'm sorry, I don't know when.",
		"patterns": [Pattern.WHEN],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "Interesting... but I don't know when.",
		"patterns": [Pattern.WHEN],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "No idea when.",
		"patterns": [Pattern.WHEN],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	
	# ========================================================================
	# WHY RESPONSES
	# ========================================================================
	
	{
		"text": "I don't know why {subject} happened.",
		"patterns": [Pattern.WHY],
		"styles": [Style.DIRECT],
		"subject": true
	},
	{
		"text": "I don't know why.",
		"patterns": [Pattern.WHY],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I have no idea why.",
		"patterns": [Pattern.WHY],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I wish I knew why {subject} happened.",
		"patterns": [Pattern.WHY],
		"styles": [Style.APOLOGETIC],
		"subject": true
	},
	{
		"text": "I'm sorry, I don't know why.",
		"patterns": [Pattern.WHY],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "Great question... but I don't know why.",
		"patterns": [Pattern.WHY],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "I wish I knew why - it's puzzling.",
		"patterns": [Pattern.WHY],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "No idea why.",
		"patterns": [Pattern.WHY],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "Who knows?",
		"patterns": [Pattern.WHY],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	
	# ========================================================================
	# HOW RESPONSES
	# ========================================================================
	
	{
		"text": "I don't know how {subject} works.",
		"patterns": [Pattern.HOW],
		"styles": [Style.DIRECT],
		"subject": true
	},
	{
		"text": "I don't know how.",
		"patterns": [Pattern.HOW],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I have no idea how.",
		"patterns": [Pattern.HOW],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I wish I knew how {subject} works.",
		"patterns": [Pattern.HOW],
		"styles": [Style.APOLOGETIC],
		"subject": true
	},
	{
		"text": "I'm sorry, I don't know how.",
		"patterns": [Pattern.HOW],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "Interesting question... but I don't know how.",
		"patterns": [Pattern.HOW],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "Good question! I don't know how {subject} works.",
		"patterns": [Pattern.HOW],
		"styles": [Style.CURIOUS],
		"subject": true
	},
	{
		"text": "No idea how.",
		"patterns": [Pattern.HOW],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "Can't tell you.",
		"patterns": [Pattern.HOW],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	
	# ========================================================================
	# RUMOR RESPONSES
	# ========================================================================
	
	{
		"text": "I haven't heard anything.",
		"patterns": [Pattern.RUMOR],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "No rumors that I know of.",
		"patterns": [Pattern.RUMOR],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I haven't heard any gossip.",
		"patterns": [Pattern.RUMOR],
		"styles": [Style.DIRECT],
		"subject": false
	},
	{
		"text": "I wish I had news, but I haven't heard anything.",
		"patterns": [Pattern.RUMOR],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "I'm sorry, I haven't heard any rumors.",
		"patterns": [Pattern.RUMOR],
		"styles": [Style.APOLOGETIC],
		"subject": false
	},
	{
		"text": "I haven't heard anything, but I'd love to know!",
		"patterns": [Pattern.RUMOR],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "Nothing so far, but I'm curious.",
		"patterns": [Pattern.RUMOR],
		"styles": [Style.CURIOUS],
		"subject": false
	},
	{
		"text": "No gossip.",
		"patterns": [Pattern.RUMOR],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
	{
		"text": "Haven't heard anything.",
		"patterns": [Pattern.RUMOR],
		"styles": [Style.DISMISSIVE],
		"subject": false
	},
]

# Runtime-optimized lookup tables (built on first use)
var _pattern_index: Dictionary = {}  # Pattern -> Array of template indices
var _style_index: Dictionary = {}    # Style -> Array of template indices
var _built: bool = false

func _build_indices() -> void:
	if _built:
		return
	
	# Build pattern index
	for pattern in Pattern.values():
		_pattern_index[pattern] = []
	
	# Build style index
	for style in Style.values():
		_style_index[style] = []
	
	# Index all templates
	for i in range(TEMPLATES.size()):
		var template = TEMPLATES[i]
		
		# Add to pattern indices
		for pattern in template.patterns:
			_pattern_index[pattern].append(i)
		
		# Add to style indices
		for style in template.styles:
			_style_index[style].append(i)
	
	_built = true

func get_template(pattern: Pattern, style: Style, subject: String = "") -> String:
	_build_indices()
	
	# Find templates that match BOTH pattern AND style
	var pattern_templates = _pattern_index[pattern]
	var style_templates = _style_index[style]
	
	var matches = []
	for idx in pattern_templates:
		if idx in style_templates:
			var template = TEMPLATES[idx]
			# If template requires subject and we don't have one, skip it
			if template.subject and subject == "":
				continue
			matches.append(idx)
	
	if matches.is_empty():
		# Fallback: just use pattern match with any style
		matches = pattern_templates.duplicate()
		# Filter out subject-required templates if no subject
		if subject == "":
			matches = matches.filter(func(idx): return not TEMPLATES[idx].subject)
	
	if matches.is_empty():
		return "I don't know."  # Ultimate fallback
	
	# Select random from matches
	var selected_idx = matches[randi() % matches.size()]
	var template_text = TEMPLATES[selected_idx].text
	
	# Replace {subject} if present
	if "{subject}" in template_text and subject != "":
		template_text = template_text.replace("{subject}", subject)
	elif "{subject}" in template_text:
		# Remove {subject} placeholder if no subject available
		template_text = template_text.replace(" {subject}", "").replace("{subject} ", "")
	
	return template_text
