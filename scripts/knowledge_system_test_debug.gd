extends Node

# Comprehensive Knowledge System Debug Test
# This will show exactly what's happening at each step

var npc_manager: NPCSystemEnhanced
@onready var world_db = get_node("/root/WorldDB")

func _ready():
	npc_manager = NpcManager
	
	print("=".repeat(80))
	print("KNOWLEDGE SYSTEM DIAGNOSTIC TEST")
	print("=".repeat(80))
	
	# Test 1: Check if WorldKnowledge has facts
	print("\n[TEST 1] Checking WorldKnowledge database...")
	print("Total facts in database: ", world_db.facts.size())
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
	
	# Test 2: Check NPC knowledge
	print("\n[TEST 2] Checking NPC knowledge...")
	var vorak_id = _get_npc_id("Vorak")
	var lyris_id = _get_npc_id("Lyris")
	
	if vorak_id:
		var vorak = npc_manager.npcs[vorak_id]
		print("\nVorak's knowledge:")
		print("  Known facts: ", vorak.knowledge.known_facts.size())
		print("  Knowledge tags: ", vorak.knowledge.knowledge_tags)
		if vorak.knowledge.known_facts.size() > 0:
			print("  Sample known facts:")
			var count = 0
			for fact_id in vorak.knowledge.known_facts:
				if count >= 3: break
				var known = vorak.knowledge.known_facts[fact_id]
				var fact = world_db.get_fact(fact_id)
				if fact:
					print("    Fact #%d (strength %.2f): %s" % [fact_id, known.strength, fact.data])
				count += 1
		else:
			print("  WARNING: Vorak has no known facts!")
	
	if lyris_id:
		var lyris = npc_manager.npcs[lyris_id]
		print("\nLyris's knowledge:")
		print("  Known facts: ", lyris.knowledge.known_facts.size())
		print("  Knowledge tags: ", lyris.knowledge.knowledge_tags)
		if lyris.knowledge.known_facts.size() > 0:
			print("  Sample known facts:")
			var count = 0
			for fact_id in lyris.knowledge.known_facts:
				if count >= 3: break
				var known = lyris.knowledge.known_facts[fact_id]
				var fact = world_db.get_fact(fact_id)
				if fact:
					print("    Fact #%d (strength %.2f): %s" % [fact_id, known.strength, fact.data])
				count += 1
		else:
			print("  WARNING: Lyris has no known facts!")
	
	# Test 3: Test query parsing
	print("\n[TEST 3] Testing knowledge query parsing...")
	var test_query = "Where is the blacksmith located?"
	var k_query = KnowledgeQuery.parse(test_query)
	print("  Query: '%s'" % test_query)
	print("  Detected type: %s" % KnowledgeQuery.QueryType.keys()[k_query.query_type])
	print("  Extracted tags: %s" % str(k_query.extracted_tags))
	print("  Subject: '%s'" % k_query.subject)
	
	# Test 4: Test knowledge execution
	print("\n[TEST 4] Testing knowledge query execution...")
	if vorak_id:
		var vorak = npc_manager.npcs[vorak_id]
		var k_executor = KnowledgeQuery.QueryExecutor.new(world_db)
		var k_result = k_executor.execute(vorak.knowledge, k_query)
		
		print("  Executing query for Vorak: '%s'" % test_query)
		print("  Success: %s" % k_result.success)
		print("  Confidence: %.2f" % k_result.confidence)
		print("  Facts returned: %d" % k_result.facts.size())
		print("  Partial knowledge: %s" % k_result.partial_knowledge)
		
		if k_result.success and k_result.facts.size() > 0:
			print("  Retrieved fact data:")
			for fact in k_result.facts:
				print("    %s" % fact.data)
		elif k_result.partial_knowledge:
			print("  NPC has forgotten this information")
		else:
			print("  NPC does not know this information")
	
	# Test 5: Test full request processing with detailed breakdown
	print("\n[TEST 5] Testing full request processing...")
	test_detailed_request("Vorak", "Where is the blacksmith located?")
	
	print("\n" + "=".repeat(80))
	print("DIAGNOSTIC TEST COMPLETE")
	print("=".repeat(80))
	
	get_tree().quit()

func test_detailed_request(npc_name: String, query: String):
	print("\n  Testing: [%s] <- '%s'" % [npc_name, query])
	
	var npc_id = _get_npc_id(npc_name)
	if not npc_id:
		print("    ERROR: NPC not found!")
		return
	
	var npc = npc_manager.npcs[npc_id]
	
	# Parse request
	var request = npc_manager.parser.parse_request(query)
	print("    Request type: %s" % request.context.request_type)
	print("    Topic: %s" % request.context.topic)
	print("    Standard options generated: %d" % request.response_options.size())
	
	# Check if knowledge query
	var k_query = KnowledgeQuery.parse(query)
	print("    Knowledge query type: %s" % KnowledgeQuery.QueryType.keys()[k_query.query_type])
	
	if k_query.query_type != KnowledgeQuery.QueryType.GENERAL:
		# Execute knowledge query
		var k_executor = KnowledgeQuery.QueryExecutor.new(world_db)
		var k_result = k_executor.execute(npc.knowledge, k_query)
		
		print("    Knowledge result:")
		print("      Success: %s" % k_result.success)
		print("      Confidence: %.2f" % k_result.confidence)
		print("      Facts: %d" % k_result.facts.size())
		
		# Create knowledge options
		var k_options = npc_manager._create_knowledge_options(k_result)
		print("    Knowledge options created: %d" % k_options.size())
		
		for opt in k_options:
			print("      - %s (base_score: %.2f)" % [opt.response_type, opt.base_score])
		
		# Add to request
		request.response_options.append_array(k_options)
		print("    Total options after adding knowledge: %d" % request.response_options.size())
	
	# Score all options
	print("\n    Scoring all options:")
	var best_option = null
	var best_score = -INF
	
	for option in request.response_options:
		var score = npc_manager.decision_engine.evaluate_response(npc, option, request, npc_manager)
		print("      [%s] score: %.3f" % [option.response_type, score])
		
		if score > best_score:
			best_score = score
			best_option = option
	
	if best_option:
		print("\n    WINNER: %s (score: %.3f)" % [best_option.response_type, best_score])
		print("    Base score: %.2f" % best_option.base_score)
		print("  Extracted tags: ", k_query.extracted_tags)
		
		# Generate response
		var response = npc_manager.generator.generate_response(npc, best_option, request)
		print("\n    Final response: %s" % response)
	else:
		print("    ERROR: No option selected!")

func _get_npc_id(npc_name: String) -> String:
	for id in npc_manager.npcs:
		if npc_manager.npcs[id].name == npc_name:
			return id
	return ""
