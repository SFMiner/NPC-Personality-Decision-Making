extends Node

# Seeding Diagnostic Test

var npc_manager: NPCSystemEnhanced
@onready var world_db = get_node("/root/WorldDB")

func _ready():
	npc_manager = NpcManager
	
	print("=".repeat(80))
	print("KNOWLEDGE SEEDING DIAGNOSTIC")
	print("=".repeat(80))
	
	# Test 1: Check if seeder exists
	print("\n[TEST 1] Checking seeder...")
	if npc_manager.knowledge_seeder:
		print("  ✓ Seeder exists")
		print("  Seeder type: ", npc_manager.knowledge_seeder.get_class())
	else:
		print("  ✗ ERROR: Seeder is null!")
		print("  This means seeder wasn't initialized in _ready()")
	
	# Test 2: Try manually seeding an NPC
	print("\n[TEST 2] Manual seeding test...")
	var test_npc_id = _get_npc_id("Vorak")
	
	if test_npc_id:
		var vorak = npc_manager.npcs[test_npc_id]
		print("  Vorak archetype: ", vorak.archetype)
		print("  Vorak knowledge before seeding:")
		print("    Known facts: ", vorak.knowledge.known_facts.size())
		print("    Tags: ", vorak.knowledge.knowledge_tags)
		
		# Try to manually seed
		print("\n  Attempting manual seed...")
		if npc_manager.knowledge_seeder:
			npc_manager.knowledge_seeder.seed_npc(vorak.knowledge, vorak.archetype)
			
			print("  Vorak knowledge after seeding:")
			print("    Known facts: ", vorak.knowledge.known_facts.size())
			print("    Tags: ", vorak.knowledge.knowledge_tags)
			
			if vorak.knowledge.known_facts.size() > 0:
				print("  ✓ Seeding worked!")
				print("  Sample facts:")
				var count = 0
				for fact_id in vorak.knowledge.known_facts:
					if count >= 3: break
					var fact = world_db.get_fact(fact_id)
					if fact:
						print("    Fact #%d: %s" % [fact_id, fact.data])
					count += 1
			else:
				print("  ✗ Seeding failed - no facts added")
		else:
			print("  ✗ Cannot seed - seeder is null")
	
	# Test 3: Check seeder configuration
	print("\n[TEST 3] Checking seeder configuration...")
	if npc_manager.knowledge_seeder:
		print("  Checking archetype_knowledge dictionary...")
		var seeder = npc_manager.knowledge_seeder
		
		# Try to access archetype_knowledge
		# (This is a property of the Seeder class)
		print("  Available methods: ", seeder.get_method_list())
		
		# Test if seed_npc method exists
		if seeder.has_method("seed_npc"):
			print("  ✓ seed_npc() method exists")
		else:
			print("  ✗ seed_npc() method missing!")
	
	# Test 4: Check WorldKnowledge facts
	print("\n[TEST 4] Checking facts availability...")
	print("  Total facts in WorldKnowledge: ", world_db.facts.size())
	
	if world_db.facts.size() > 0:
		print("  ✓ Facts exist in database")
		print("  Fact IDs: ", world_db.facts.keys())
		
		# Check if blacksmith fact exists
		var blacksmith_fact = null
		for fact_id in world_db.facts:
			var fact = world_db.facts[fact_id]
			if "blacksmith" in fact.tags:
				blacksmith_fact = fact
				print("\n  ✓ Found blacksmith fact (ID: %d)" % fact_id)
				print("    Tags: ", fact.tags)
				print("    Data: ", fact.data)
				break
		
		if not blacksmith_fact:
			print("  ✗ No blacksmith fact found!")
	else:
		print("  ✗ No facts in database!")
	
	# Test 5: Check create_npc_from_template
	print("\n[TEST 5] Checking NPC creation process...")
	print("  Creating test NPC...")
	
	var test_npc = npc_manager.create_npc_from_template(
		"test_npc",
		"TestChar",
		"warlord"
	)
	
	print("  Test NPC created:")
	print("    Name: ", test_npc.name)
	print("    Archetype: ", test_npc.archetype)
	print("    Known facts: ", test_npc.knowledge.known_facts.size())
	print("    Knowledge tags: ", test_npc.knowledge.knowledge_tags)
	
	if test_npc.knowledge.known_facts.size() > 0:
		print("  ✓ NPC creation includes seeding")
	else:
		print("  ✗ NPC creation does NOT seed knowledge")
		print("  Check create_npc_from_template() - is seeding called?")
	
	print("\n" + "=".repeat(80))
	print("DIAGNOSIS COMPLETE")
	print("=".repeat(80))
	
	get_tree().quit()

func _get_npc_id(npc_name: String) -> String:
	for id in npc_manager.npcs:
		if npc_manager.npcs[id].name == npc_name:
			return id
	return ""
