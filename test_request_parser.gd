extends Node

var parser: NPCSystemEnhanced.RequestParser
var output_file: FileAccess

func _ready() -> void:
	parser = NPCSystemEnhanced.RequestParser.new()
	
	output_file = FileAccess.open("res://test_request_pasrsing.txt", FileAccess.WRITE)
	
	if output_file == null:
		push_error("Failed to open output file: " + str(FileAccess.get_open_error()))
		return
	
	output_file.store_line("=" .repeat(80))
	output_file.store_line("REQUEST PARSER TEST SUITE")
	output_file.store_line("=" .repeat(80))
	output_file.store_line("")
	
	var test_requests = [
		"Could you please help me with this quest?",
		"You must give me your sword now!",
		"How about we team up to fight the dragon?",
		"Give me that item or else you'll regret it!",
		"I heard there's treasure in the ruins. What do you know?",
		"I'll trade you 50 gold for that healing potion.",
		"Would you be willing to teach me swordsmanship?",
		"Attack that guard immediately!",
		"Perhaps we could negotiate a peace treaty?",
		"If you don't help me, there will be consequences.",
		"Can you tell me where the blacksmith is?",
		"Join my party! We need someone like you.",
		"You stupid fool! Do what I say!",
		"Please, I desperately need your help right now!",
		"What if we worked together on this problem?"
	]
	
	for i in test_requests.size():
		test_request(i + 1, test_requests[i])
		output_file.store_line("")
	
	output_file.close()
	print("Test complete! Results written to res://test_request_pasrsing.txt")

func test_request(index: int, text: String) -> void:
	output_file.store_line("─" .repeat(80))
	output_file.store_line("TEST #%d" % index)
	output_file.store_line("─" .repeat(80))
	
	var request = parser.parse_request(text)
	
	output_file.store_line("RAW TEXT:")
	output_file.store_line("  \"%s\"" % text)
	output_file.store_line("")
	
	output_file.store_line("PARSED CONTEXT:")
	output_file.store_line("  Request Type:    %s" % request.context.request_type)
	output_file.store_line("  Topic:           %s" % request.context.topic)
	output_file.store_line("  Urgency:         %.2f" % request.context.urgency)
	output_file.store_line("  Formality:       %.2f" % request.context.formality)
	output_file.store_line("  Emotional Tone:  %.2f  %s" % [
		request.context.emotional_tone,
		_get_tone_descriptor(request.context.emotional_tone)
	])
	output_file.store_line("  Requester:       %s" % request.context.requester_id)
	output_file.store_line("")
	
	output_file.store_line("PARSED INTENT PROBABILITIES:")
	var sorted_intents = _sort_dict_by_value(request.parsed_intent)
	for intent_data in sorted_intents:
		var intent_name = intent_data[0]
		var probability = intent_data[1]
		var bar = _create_bar(probability, 30)
		output_file.store_line("  %-15s %.1f%%  %s" % [intent_name + ":", probability * 100, bar])
	output_file.store_line("")
	
	output_file.store_line("GENERATED RESPONSE OPTIONS (%d total):" % request.response_options.size())
	for i in request.response_options.size():
		var option = request.response_options[i]
		output_file.store_line("")
		output_file.store_line("  [%d] %s (Base Score: %.2f, Variant: %d)" % [
			i + 1, 
			option.response_type, 
			option.base_score,
			option.template_variant
		])
		output_file.store_line("      Template: \"%s\"" % option.response_template)
		
		if option.personality_tags.size() > 0:
			var tags = []
			for tag in option.personality_tags:
				tags.append(tag)
			output_file.store_line("      Tags:     %s" % ", ".join(tags))
		
		if option.relationship_impact.size() > 0:
			output_file.store_line("      Impacts:  %s" % str(option.relationship_impact))

func _get_tone_descriptor(tone: float) -> String:
	if tone > 0.5:
		return "(Very Positive)"
	elif tone > 0.2:
		return "(Positive)"
	elif tone > -0.2:
		return "(Neutral)"
	elif tone > -0.5:
		return "(Negative)"
	else:
		return "(Very Negative)"

func _sort_dict_by_value(dict: Dictionary) -> Array:
	var items = []
	for key in dict:
		items.append([key, dict[key]])
	
	items.sort_custom(func(a, b): return a[1] > b[1])
	return items

func _create_bar(value: float, max_width: int) -> String:
	var filled = int(value * max_width)
	var empty = max_width - filled
	return "█".repeat(filled) + "░".repeat(empty)
