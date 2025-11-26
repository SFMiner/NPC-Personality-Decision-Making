extends Control
# Test Interface for NPC Request System
# Demonstrates arbitrary request handling with personality-based responses

@onready var npc_system: NPCSystem
@onready var output_label: RichTextLabel
@onready var input_field: LineEdit  
@onready var npc_selector: OptionButton
@onready var npc_info_label: RichTextLabel

# Sample requests for testing
var test_requests = [
	"Can you help me fight the bandits?",
	"I demand you give me your gold!",
	"What if we worked together on this?",
	"Tell me about the ancient ruins.",
	"You must join my cause or face the consequences!",
	"I need someone I can trust. Will you help?",
	"This is urgent - we need to move now!",
	"Perhaps we could make a deal?",
	"Your expertise would be valuable here.",
	"I heard you know about the missing artifact.",
	"Would you teach me your skills?",
	"Join me and we'll split the treasure.",
	"I order you to stand down!",
	"Can I buy some supplies from you?",
	"We should form an alliance against our enemies."
]

func _ready():
	# Initialize NPC system
	npc_system = NPCSystem.new()
	add_child(npc_system)
	
	# Setup UI
	_setup_ui()
	
	# Populate NPC selector
	_populate_npc_selector()
	
	# Display initial info
	_update_npc_info()
	
	# Run automated tests if desired
	if OS.has_feature("editor"):
		_run_automated_tests()

func _setup_ui():
	# Create output display
	output_label = RichTextLabel.new()
	output_label.set_position(Vector2(20, 20))
	output_label.set_size(Vector2(600, 400))
	output_label.bbcode_enabled = true
	add_child(output_label)
	
	# Create input field
	input_field = LineEdit.new()
	input_field.set_position(Vector2(20, 440))
	input_field.set_size(Vector2(500, 30))
	input_field.placeholder_text = "Type your request here..."
	input_field.text_submitted.connect(_on_input_submitted)
	add_child(input_field)
	
	# Create send button
	var send_button = Button.new()
	send_button.set_position(Vector2(530, 440))
	send_button.set_size(Vector2(90, 30))
	send_button.text = "Send"
	send_button.pressed.connect(_on_send_pressed)
	add_child(send_button)
	
	# Create NPC selector
	npc_selector = OptionButton.new()
	npc_selector.set_position(Vector2(20, 480))
	npc_selector.set_size(Vector2(200, 30))
	npc_selector.item_selected.connect(_on_npc_selected)
	add_child(npc_selector)
	
	# Create random request button
	var random_button = Button.new()
	random_button.set_position(Vector2(230, 480))
	random_button.set_size(Vector2(150, 30))
	random_button.text = "Random Request"
	random_button.pressed.connect(_on_random_request)
	add_child(random_button)
	
	# Create NPC info display
	npc_info_label = RichTextLabel.new()
	npc_info_label.set_position(Vector2(650, 20))
	npc_info_label.set_size(Vector2(300, 300))
	npc_info_label.bbcode_enabled = true
	add_child(npc_info_label)
	
	# Create test all button
	var test_all_button = Button.new()
	test_all_button.set_position(Vector2(390, 480))
	test_all_button.set_size(Vector2(100, 30))
	test_all_button.text = "Test All NPCs"
	test_all_button.pressed.connect(_test_all_npcs)
	add_child(test_all_button)

func _populate_npc_selector():
	var npc_names = npc_system.get_npc_list()
	for npc_name in npc_names:
		npc_selector.add_item(npc_name)

func _on_input_submitted(text: String):
	_send_request(text)

func _on_send_pressed():
	_send_request(input_field.text)

func _send_request(request_text: String):
	if request_text.is_empty():
		return
	
	var selected_npc = npc_selector.get_item_text(npc_selector.selected)
	var info = npc_system.get_npc_info(selected_npc)
	
	# Send request to NPC
	var response = npc_system.send_request_to_npc(selected_npc, request_text)
	
	# Display in output
	_add_to_output("[b]You:[/b] " + request_text)
	_add_to_output(response)
	_add_to_output("Test")
	print("Request: " + request_text + "\n Response: " + response + "\n Trust: " + str(info.relationship.trust) + "\n Respect: " + str(info.relationship.respect) + "\n Respect: " + str(info.relationship.affection))
	# Clear input
	input_field.text = ""
	
	# Update NPC info (relationships may have changed)
	_update_npc_info()

func _on_npc_selected(_index: int):
	_update_npc_info()

func _update_npc_info():
	var selected_npc = npc_selector.get_item_text(npc_selector.selected)
	var info = npc_system.get_npc_info(selected_npc)
	
	if info.is_empty():
		return
	
	var info_text = "[b]" + info.name + "[/b]\n"
	info_text += "Role: " + info.role.capitalize() + "\n\n"
	
	info_text += "[b]Personality:[/b]\n"
	info_text += "Warmth: " + _format_trait(info.personality.warmth) + "\n"
	info_text += "Assertiveness: " + _format_trait(info.personality.assertiveness) + "\n"
	info_text += "Risk Tolerance: " + _format_trait(info.personality.risk_tolerance) + "\n\n"
	
	info_text += "[b]Relationship with You:[/b]\n"
	info_text += "Trust: " + _format_relationship(info.relationship.trust) + "\n"
	info_text += "Respect: " + _format_relationship(info.relationship.respect) + "\n"
	info_text += "Affection: " + _format_relationship(info.relationship.affection) + "\n"
	
	npc_info_label.clear()
	npc_info_label.append_text(info_text)

func _format_trait(value: float) -> String:
	if value > 0.6:
		return "[color=green]High (" + str(snappedf(value, 0.01)) + ")[/color]"
	elif value > 0.2:
		return "[color=yellow]Medium (" + str(snappedf(value, 0.01)) + ")[/color]"
	elif value > -0.2:
		return "Neutral (" + str(snappedf(value, 0.01)) + ")"
	elif value > -0.6:
		return "[color=orange]Low (" + str(snappedf(value, 0.01)) + ")[/color]"
	else:
		return "[color=red]Very Low (" + str(snappedf(value, 0.01)) + ")[/color]"

func _format_relationship(value: float) -> String:
	var bars = int(value * 10)
	var result = ""
	for i in range(10):
		if i < bars:
			result += "█"
		else:
			result += "░"
	result += " " + str(snappedf(value, 0.01))
	return result

func _add_to_output(text: String):
	output_label.append_text(text + "\n")
	
	# Auto-scroll to bottom
	output_label.scroll_to_line(output_label.get_line_count() - 1)

func _on_random_request():
	var request = test_requests[randi() % test_requests.size()]
	input_field.text = request
	_send_request(request)

func _test_all_npcs():
	# Test same request with all NPCs to see personality differences
	var test_request = test_requests[randi() % test_requests.size()]
	
	_add_to_output("[b][color=yellow]Testing all NPCs with: \"" + test_request + "\"[/color][/b]\n")
	
	var npc_names = npc_system.get_npc_list()
	for npc_name in npc_names:
		var response = npc_system.send_request_to_npc(npc_name, test_request)
		_add_to_output(response)
	
	_add_to_output("")

func _run_automated_tests():
	# Run some automated tests to demonstrate the system
	print("\n=== NPC SYSTEM AUTOMATED TESTS ===\n")
	
	# Test 1: Same request, different NPCs
	print("TEST 1: How different NPCs respond to combat request")
	print("Request: 'Can you help me fight the bandits?'\n")
	
	var combat_request = "Can you help me fight the bandits?"
	var npc_names = npc_system.get_npc_list()
	
	for i in range(min(4, npc_names.size())):
		var response = npc_system.send_request_to_npc(npc_names[i], combat_request)
		print(response)
	
	print("\n---")
	
	# Test 2: Different request types to same NPC
	print("\nTEST 2: Different request types to same NPC (Vorak)")
	var test_npc = "Vorak"
	
	var varied_requests = [
		"Please help me with this task.",
		"I demand you give me your weapons!",
		"What if we formed an alliance?",
		"You're going to regret crossing me!"
	]
	
	for request in varied_requests:
		print("Request: " + request)
		var response = npc_system.send_request_to_npc(test_npc, request)
		print(response + "\n")
	
	print("\n---")
	
	# Test 3: Relationship evolution
	print("\nTEST 3: How repeated interactions affect responses")
	var relationship_npc = "Mira"
	
	print("Initial friendly request:")
	var response1 = npc_system.send_request_to_npc(
		relationship_npc,
		"Would you like to work together?"
	)
	print(response1)
	
	print("\nAfter positive interaction:")
	var response2 = npc_system.send_request_to_npc(
		relationship_npc,
		"I need your help with something important."
	)
	print(response2)
	
	print("\nAggressive request:")
	var response3 = npc_system.send_request_to_npc(
		relationship_npc,
		"You fool! Do as I say immediately!"
	)
	print(response3)
	
	print("\nTrying to rebuild trust:")
	var response4 = npc_system.send_request_to_npc(
		relationship_npc,
		"I'm sorry. Can we start over?"
	)
	print(response4)
	
	print("\n=== END AUTOMATED TESTS ===\n")
