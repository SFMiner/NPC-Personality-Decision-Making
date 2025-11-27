extends Node

# Reference the Autoload/Singleton instances
var npc_manager : NPCSystemEnhanced
# Assuming you named your WorldKnowledge Autoload "WorldDB"
@onready var world_db = get_node("/root/WorldDB") 

var current_npc_name: String = "Vorak"
var test_queries: Array[String] = [
	# Test 1: Known fact (Merchant "Vorak" should know about trade/locations)
	"Where is the blacksmith located?",
	
	# Test 2: Unknown fact (Scholar "Lyris" should not know about a simple tavern)
	"Tell me about the Rusty Sword tavern.", 
	
	# Test 3: Complex query/General query (Should fall back to the generic response)
	"What should I do today?",
	
	# Test 4: Fact about the king (Should be known by the scholar)
	"What is the King's name?",
	
	# Test 5: Fact that requires a high skill level (Should be unknown by default NPCs)
	"Do you know King Aldric's secret?"
]

var query_index: int = 0
var delay_timer: Timer

func _ready():
	npc_manager = NpcManager
	print("--- Knowledge System Test Initiated ---")
	print("Available NPCs: ", npc_manager.get_npc_list())
	delay_timer = Timer.new()
	add_child(delay_timer)
	delay_timer.timeout.connect(_run_next_query)
	
	# Start the test sequence
	_run_next_query()

func _run_next_query():
	if query_index >= test_queries.size():
		print("--- Knowledge System Test Complete ---")
		get_tree().quit() # Quit the app after testing
		return

	var query = test_queries[query_index]
	
	# Switch NPC every two queries
	if query_index % 2 == 0:
		if current_npc_name == "Vorak":
			current_npc_name = "Lyris"
		else:
			current_npc_name = "Vorak"
	
	print("\n[Player] speaking to [%s]: %s" % [current_npc_name, query])
	
	# Run the request through the NPCManager Autoload
	var response = npc_manager.send_request_to_npc(current_npc_name, query)
	
	print(response)
	
	query_index += 1
	
	# Wait 2 seconds before running the next query
	delay_timer.start(2.0)
