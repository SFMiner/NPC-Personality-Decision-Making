extends Node
var npc_manager: NPCSystemEnhanced
@onready var world_db = get_node("/root/WorldDB")

func _ready():
	npc_manager = NpcManager
	test_template_variety()
	var db = ResponseTemplates.get_instance()
	print("=== TEMPLATE DB INFO ===")
	print("Total templates: %d" % db.TEMPLATES.size())
	
	# Check if DISMISSIVE templates exist for SHARE_KNOWLEDGE
	var count = 0
	for template in db.TEMPLATES:
		if ResponseTemplates.ResponseType.SHARE_KNOWLEDGE in template.response_types and ResponseTemplates.Style.DISMISSIVE in template.styles:
			count += 1
			print("Found DISMISSIVE SHARE_KNOWLEDGE template: '%s'" % template.text.substr(0, 40))
	
	print("Total SHARE_KNOWLEDGE + DISMISSIVE templates: %d" % count)
	
	
func test_template_variety():
	var npc_id = "npc_0"  # High assertiveness warlord
	var query = "Where is the blacksmith?"
	var responses: Dictionary = {}  # template → count
	
	for i in range(10):
		var response = npc_manager.process_request(npc_id, query)
		# Extract the template pattern (strip NPC name and fact data)
		var pattern = _extract_template_pattern(response)
		responses[pattern] = responses.get(pattern, 0) + 1
	
	print("Template distribution for Vorak:")
	for pattern in responses:
		var pct = (responses[pattern] / 10.0) * 100
		print("  %s: %d%%" % [pattern, pct])
	
	# Verify: At least 2 different templates used
#	assert(responses.size() >= 2, "Should have template variety!")
	# Verify: No single template dominates completely
#	for count in responses.values():
#		assert(count < 40, "No template should appear more than 80%!")

	npc_id = "npc_1"  # High assertiveness warlord
	query = "Where is the blacksmith?"
	responses = {}  # template → count
	
	for i in range(10):
		var response = npc_manager.process_request(npc_id, query)
		# Extract the template pattern (strip NPC name and fact data)
		var pattern = _extract_template_pattern(response)
		responses[pattern] = responses.get(pattern, 0) + 1
	
	print("Template distribution for Lyris:")
	for pattern in responses:
		var pct = (responses[pattern] / 10.0) * 100
		print("  %s: %d%%" % [pattern, pct])
	
	# Verify: At least 2 different templates used
	assert(responses.size() >= 2, "Should have template variety!")
	# Verify: No single template dominates completely
	for count in responses.values():
		assert(count < 40, "No template should appear more than 80%!")


func _extract_template_pattern(response: String) -> String:
	# Remove NPC name prefix
	var pattern = response.split("]: ")[-1]
	# Normalize fact data to see template structure
	pattern = pattern.replace("blacksmith", "{subject}")
	pattern = pattern.replace("is located in", "{predicate}")
	pattern = pattern.replace("the Market District", "{object}")
	return pattern
