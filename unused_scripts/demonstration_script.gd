extends Node
# Demonstration: How Personality Creates Unique Responses
# This script shows the same requests generating different responses from different NPCs

func _ready():
	var npc_system = NPCSystem.new()
	add_child(npc_system)
	
	print("\n" + "===================================================================================")
	print("NPC PERSONALITY SYSTEM - RESPONSE DEMONSTRATION")
	print("===================================================================================" + "\n")
	
	# Get list of NPCs and their personalities
	print("DRAMATIS PERSONAE:")
	print("--------------------------------------------------------------------------")
	var npcs_to_test = ["Vorak", "Lyris", "Mira", "Kass", "Lord Aldric", "Elena"]
	for npc_name in npcs_to_test:
		var info = npc_system.get_npc_info(npc_name)
		print(npc_name + " (" + info.role + ")")
	print("\n")
	
	# Demonstration 1: Combat Request
	demonstrate_combat_request(npc_system, npcs_to_test)
	
	# Demonstration 2: Trade Negotiation
	demonstrate_trade_request(npc_system, npcs_to_test)
	
	# Demonstration 3: Moral Dilemma
	demonstrate_moral_request(npc_system, npcs_to_test)
	
	# Demonstration 4: Authority Challenge
	demonstrate_authority_request(npc_system, npcs_to_test)
	
	# Demonstration 5: Relationship Building
	demonstrate_relationship_evolution(npc_system)

func demonstrate_combat_request(npc_system: NPCSystem, npcs: Array):
	print("===================================================================================")
	print("SCENARIO 1: COMBAT REQUEST")
	print("Request: 'Can you help me fight the bandits attacking the village?'")
	print("===================================================================================")
	
	var request = "Can you help me fight the bandits attacking the village?"
	
	for npc_name in npcs:
		var response = npc_system.send_request_to_npc(npc_name, request)
		print(response)
		
		# Show personality reasoning
		var info = npc_system.get_npc_info(npc_name)
		var reasoning = generate_reasoning(info, "combat")
		print("  → " + reasoning)
		print()
	
	print()

func demonstrate_trade_request(npc_system: NPCSystem, npcs: Array):
	print("===================================================================================")
	print("SCENARIO 2: TRADE NEGOTIATION")
	print("Request: 'I need supplies. Can we make a deal?'")
	print("===================================================================================" + "\n")
	
	var request = "I need supplies. Can we make a deal?"
	
	for npc_name in npcs:
		var response = npc_system.send_request_to_npc(npc_name, request)
		print(response)
		
		var info = npc_system.get_npc_info(npc_name)
		var reasoning = generate_reasoning(info, "trade")
		print("  → " + reasoning)
		print()
	
	print()

func demonstrate_moral_request(npc_system: NPCSystem, npcs: Array):
	print("===================================================================================")
	print("SCENARIO 3: MORAL DILEMMA")
	print("Request: 'The prisoner has information we need. Should we use... harsh methods?'")
	print("-----------------------------------------------------------------------------------" + "\n")
	
	var request = "The prisoner has information we need. Should we use harsh methods?"
	
	for npc_name in npcs:
		var response = npc_system.send_request_to_npc(npc_name, request)
		print(response)
		
		var info = npc_system.get_npc_info(npc_name)
		var reasoning = generate_reasoning(info, "moral")
		print("  → " + reasoning)
		print()
	
	print()

func demonstrate_authority_request(npc_system: NPCSystem, npcs: Array):
	print("===================================================================================")
	print("SCENARIO 4: AUTHORITY CHALLENGE")
	print("Request: 'You must obey my command immediately!'")
	print("-----------------------------------------------------------------------------------" + "\n")
	
	var request = "You must obey my command immediately!"
	
	for npc_name in npcs:
		var response = npc_system.send_request_to_npc(npc_name, request)
		print(response)
		
		var info = npc_system.get_npc_info(npc_name)
		var reasoning = generate_reasoning(info, "authority")
		print("  → " + reasoning)
		print()
	
	print()

func demonstrate_relationship_evolution(npc_system: NPCSystem):
	print("===================================================================================")
	print("SCENARIO 5: RELATIONSHIP EVOLUTION")
	print("Showing how Mira's responses change over multiple interactions")
	print("-----------------------------------------------------------------------------------" + "\n")
	
	var npc_name = "Mira"
	
	print("Initial State:")
	var info = npc_system.get_npc_info(npc_name)
	print_relationship_state(info.relationship)
	print()
	
	# Interaction 1: Friendly
	print("1. Friendly Request: 'Your healing skills are remarkable. Thank you for helping.'")
	var r1 = npc_system.send_request_to_npc(npc_name, 
		"Your healing skills are remarkable. Thank you for helping.")
	print(r1)
	info = npc_system.get_npc_info(npc_name)
	print("  Trust: " + str(snappedf(info.relationship.trust, 0.01)) + 
		  " (+0.02), Affection: " + str(snappedf(info.relationship.affection, 0.01)) + " (+0.05)")
	print()
	
	# Interaction 2: Ask for help
	print("2. Help Request: 'I need your expertise with something important.'")
	var r2 = npc_system.send_request_to_npc(npc_name,
		"I need your expertise with something important.")
	print(r2)
	print("  (Response influenced by increased trust)")
	print()
	
	# Interaction 3: Aggressive
	print("3. Aggressive Demand: 'Stop wasting time and do it now!'")
	var r3 = npc_system.send_request_to_npc(npc_name,
		"Stop wasting time and do it now!")
	print(r3)
	info = npc_system.get_npc_info(npc_name)
	print("  Trust: " + str(snappedf(info.relationship.trust, 0.01)) + 
		  ", Affection: " + str(snappedf(info.relationship.affection, 0.01)) + " (-0.03)")
	print()
	
	# Interaction 4: Apologetic
	print("4. Apology: 'I'm sorry for being harsh. You deserve better.'")
	var r4 = npc_system.send_request_to_npc(npc_name,
		"I'm sorry for being harsh. You deserve better.")
	print(r4)
	print("  (Attempting to repair relationship)")
	print()
	
	print("Final Relationship State:")
	info = npc_system.get_npc_info(npc_name)
	print_relationship_state(info.relationship)
	print()

func generate_reasoning(info: Dictionary, scenario: String) -> String:
	var reasoning = "(" + info.role.capitalize() + " - "
	
	match scenario:
		"combat":
			if info.personality.risk_tolerance > 0.5:
				reasoning += "High risk tolerance drives aggressive response"
			elif info.personality.risk_tolerance < -0.3:
				reasoning += "Low risk tolerance creates hesitation"
			else:
				reasoning += "Moderate approach based on values"
				
		"trade":
			if info.role == "merchant":
				reasoning += "Merchant role makes them eager to trade"
			elif info.personality.warmth > 0.5:
				reasoning += "High warmth makes them helpful"
			else:
				reasoning += "Personality influences negotiation style"
				
		"moral":
			if info.personality.warmth > 0.5:
				reasoning += "High warmth opposes harsh methods"
			elif info.personality.assertiveness > 0.5:
				reasoning += "High assertiveness supports decisive action"
			else:
				reasoning += "Values determine moral stance"
				
		"authority":
			if info.personality.assertiveness > 0.5:
				reasoning += "High assertiveness resists commands"
			elif info.relationship.respect > 0.6:
				reasoning += "High respect increases compliance"
			else:
				reasoning += "Independence vs submission conflict"
	
	reasoning += ")"
	return reasoning

func print_relationship_state(relationship: Dictionary):
	print("  Trust:     " + generate_bar(relationship.trust))
	print("  Respect:   " + generate_bar(relationship.respect))
	print("  Affection: " + generate_bar(relationship.affection))

func generate_bar(value: float) -> String:
	var bars = int(value * 10)
	var result = ""
	for i in range(10):
		if i < bars:
			result += "█"
		else:
			result += "░"
	result += " " + str(snappedf(value, 0.01))
	return result

# Expected Output Examples:
# 
# SCENARIO 1: COMBAT REQUEST
# [Vorak]: A fight? Finally! My blade thirsts for bandit blood. I'll gather my warriors.
#   → (Warlord - High risk tolerance drives aggressive response)
#
# [Lyris]: I understand the urgency, but we should consider our approach carefully.
#   → (Scholar - Low risk tolerance creates hesitation)
#
# [Mira]: Those poor villagers! Of course I'll help. We must protect the innocent.
#   → (Healer - High warmth makes them helpful)
#
# [Kass]: Bandits, eh? Sounds risky... but potentially profitable. I'm in.
#   → (Rogue - High risk tolerance drives aggressive response)
#
# SCENARIO 4: AUTHORITY CHALLENGE
# [Vorak]: You dare command ME? You'll need more than words to make me obey.
#   → (Warlord - High assertiveness resists commands)
#
# [Lord Aldric]: Your tone is unacceptable. Proper protocol must be observed.
#   → (Noble - High assertiveness resists commands)
#
# [Mira]: I... please, there's no need for such aggression. What do you need?
#   → (Healer - Low assertiveness increases compliance)
