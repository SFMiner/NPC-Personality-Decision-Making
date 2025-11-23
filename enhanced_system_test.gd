extends Node2D

var npc_system = preload("res://npc_system_enhanced.gd").new()
var test_requests = [
	"Help me fight these bandits.",
	"Lend me 200 credits. I promise I'll pay you back.",
	"Tell me everything you know about the ruins.",
	"I need you to take command of the group.",
	"Could you watch over my friend for a while?",
	"Ignore the rules and open the gate for me.",
	"Join me on a dangerous mission.",
	"Please teach me something you’re good at.",
	"I need you to keep a secret for me.",
	"Do you think I'm making the right choice?",
	"Stand aside. I'm ordering you.",
	"Let's work together on this. What do you need from me?"
]

var npcs : Array = ["Vorak", "Thane"]

var output_file := FileAccess.open("res://test_responses.txt", FileAccess.WRITE)
# WRITE mode overwrites the file automatically

func _ready():
	add_child(npc_system)
# Test same request 5 times
	multi_responses_test(npcs, test_requests, 20)

func multi_responses_test(npc_list : Array, request_list : Array, num_times : int):
	for current_request in request_list:
		multi_test_responses(npc_list, current_request, num_times)
		
func multi_test_responses(npc_list : Array, request : String, num_times : int):
	for npc in npc_list:
		test_responses(npc, request, num_times)

func test_responses_old(npc_name : String, request : String, num_times : int):
	print("\n" + npc_name + ":")
	for i in range(num_times):
		var trust = npc_system.get_npc_info(npc_name).relationship.trust
		var respect = npc_system.get_npc_info(npc_name).relationship.respect
		var affection = npc_system.get_npc_info(npc_name).relationship.affection
		print("   Trust = " + str(trust)  + ": Respect = " + str(respect) + ": Affection  = " + str(affection))
		print("   " + npc_system.send_request_to_npc(npc_name, "request"))

func test_responses(npc_name : String, request : String, num_times : int):
	# Header for this NPC section
	var info = npc_system.get_npc_info(npc_name)
	var personality  = info.personality
	var relationship = info.relationship
	var trust = relationship.trust
	var respect = relationship.respect
	var affection = relationship.affection

	output_file.store_line("\n" + npc_name + " - Role : " + info.role + 
		" - Warmth = " + str(personality.warmth) + 
		" - Assertiveness = " + str(personality.assertiveness) + 
		" - Risk-Tolerance = " + str(personality.risk_tolerance) + 
		"\n  Trust = " + str(trust) +
		": Respect = " + str(respect) +
		": Affection  = " + str(affection))
	
	for i in range(num_times):
#		var relationship = info.relationship
#		var trust = relationship.trust
#		var respect = relationship.respect
#		var affection = relationship.affection
		
#		output_file.store_line("   Trust = " + str(trust) +
#			": Respect = " + str(respect) +
#			": Affection  = " + str(affection))
		var response = npc_system.send_request_to_npc(npc_name, request)
		var last_char = response.right(1)
		if not (last_char == "?" or last_char == "." or last_char == "!" or last_char == "…"):
			response = response + "."
		
		output_file.store_line("   " + response)
