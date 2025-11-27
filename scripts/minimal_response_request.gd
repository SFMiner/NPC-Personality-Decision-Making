extends Node


var npc_manager: NPCSystemEnhanced
@onready var world_db = get_node("/root/WorldDB")



func _ready():
	npc_manager = NpcManager
	if world_db.facts.size() > 0:
		print("Sample facts:")
		var count = 0
		for fact_id in world_db.facts:
			if count >= 5: break
			var fact = world_db.facts[fact_id]
			print("  Fact #%d: tags=%s, data=%s" % [fact_id, fact.tags, fact.data])
			count += 1
	else:
		print("  WARNING: No facts in WorldKnowledge!")
	print_multiple_responses(npc_manager, "Vorak", "Where is the blacksmith?", 100)

func print_multiple_responses(npc_manager : NPCSystemEnhanced, char_id : String, request : String, num : int) -> void:
	for i in range(num):
		print_response(npc_manager, char_id, request)
		
func print_response(npc_manager : NPCSystemEnhanced, char_id : String, request : String) -> void:
	print("RESPONSE:")
	print(get_response(npc_manager, char_id, request))
	
func get_response(npc_manager : NPCSystemEnhanced, char_id : String, request : String) -> String:
	var response = npc_manager.send_request_to_npc(char_id, request)
	return response
