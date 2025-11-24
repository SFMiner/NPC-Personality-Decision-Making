extends Node

var npc_system: NPCSystemEnhanced
var output_file: FileAccess

func _ready():
	npc_system = NPCSystemEnhanced.new()
	add_child(npc_system)
	
	output_file = FileAccess.open("user://drive_system_detailed.txt", FileAccess.WRITE)
	
	if output_file == null:
		push_error("Failed to open output file: " + str(FileAccess.get_open_error()))
		return
	
	print("\n" + "=".repeat(80))
	print("DETAILED DRIVE SYSTEM TEST - SCORING BREAKDOWN")
	print("=".repeat(80) + "\n")
	
	# Test detailed scoring breakdown
	test_complete_scoring_breakdown()
	
	output_file.close()
	print("\nTest complete! Results written to user://drive_system_detailed.txt")

func test_complete_scoring_breakdown():
	output_file.store_line("=".repeat(80))
	output_file.store_line("COMPLETE SCORING BREAKDOWN TEST")
	output_file.store_line("Shows how personality, drives, relationships, and context combine")
	output_file.store_line("=".repeat(80))
	output_file.store_line("")
	
	# Test Case 1: Vorak (high risk-tolerance warlord) with dangerous mission
	output_file.store_line("-".repeat(80))
	output_file.store_line("TEST CASE 1: Vorak vs Dangerous Combat")
	output_file.store_line("-".repeat(80))
	output_file.store_line("")
	
	test_npc_request_detailed("Vorak", "Help me fight these dangerous bandits.")
	
	output_file.store_line("")
	output_file.store_line("-".repeat(80))
	output_file.store_line("TEST CASE 2: Lyris (low risk-tolerance scholar) vs Dangerous Combat")
	output_file.store_line("-".repeat(80))
	output_file.store_line("")
	
	test_npc_request_detailed("Lyris", "Help me fight these dangerous bandits.")
	
	output_file.store_line("")
	output_file.store_line("-".repeat(80))
	output_file.store_line("TEST CASE 3: Kass (poor rogue) vs Money Offer")
	output_file.store_line("-".repeat(80))
	output_file.store_line("")
	
	test_npc_request_detailed("Kass", "I'll pay you 200 gold to help me.")
	
	output_file.store_line("")
	output_file.store_line("-".repeat(80))
	output_file.store_line("TEST CASE 4: Lord Aldric (rich noble) vs Same Money Offer")
	output_file.store_line("-".repeat(80))
	output_file.store_line("")
	
	test_npc_request_detailed("Lord Aldric", "I'll pay you 200 gold to help me.")
	
	output_file.store_line("")
	output_file.store_line("-".repeat(80))
	output_file.store_line("TEST CASE 5: Vorak at LOW HEALTH (20%) vs Dangerous Combat")
	output_file.store_line("-".repeat(80))
	output_file.store_line("")
	
	# Manually set Vorak's health low
	var vorak_id = _get_npc_id("Vorak")
	if vorak_id:
		npc_system.npcs[vorak_id].context.health = 0.2
		test_npc_request_detailed("Vorak", "Help me fight these dangerous bandits.")
		# Reset health
		npc_system.npcs[vorak_id].context.health = 1.0
	
	output_file.store_line("")
	output_file.store_line("-".repeat(80))
	output_file.store_line("TEST CASE 6: Thane (poor merchant) - Greed vs Safety")
	output_file.store_line("-".repeat(80))
	output_file.store_line("")
	
	# Set Thane poor
	var thane_id = _get_npc_id("Thane")
	if thane_id:
		npc_system.npcs[thane_id].context.wealth = 100
		test_npc_request_detailed("Thane", "I'll pay you 300 gold to fight these bandits.")
		# Reset wealth
		npc_system.npcs[thane_id].context.wealth = 500

func test_npc_request_detailed(npc_name: String, request_text: String):
	# Get NPC
	var npc_id = _get_npc_id(npc_name)
	if not npc_id:
		output_file.store_line("ERROR: NPC not found: " + npc_name)
		return
	
	var npc = npc_system.npcs[npc_id]
	
	# Display NPC stats
	output_file.store_line("NPC: " + npc.name + " (" + npc.context.role.capitalize() + ")")
	output_file.store_line("")
	output_file.store_line("PERSONALITY TRAITS:")
	output_file.store_line("  Warmth:           " + _format_trait(npc.personality.warmth))
	output_file.store_line("  Assertiveness:    " + _format_trait(npc.personality.assertiveness))
	output_file.store_line("  Risk-Tolerance:   " + _format_trait(npc.personality.risk_tolerance))
	output_file.store_line("  Conscientiousness: " + _format_trait(npc.personality.conscientiousness))
	output_file.store_line("  Stability:        " + _format_trait(npc.personality.stability))
	output_file.store_line("")
	
	output_file.store_line("RESOURCES:")
	output_file.store_line("  Wealth:  " + str(npc.context.wealth) + " gold")
	output_file.store_line("  Health:  " + str(snappedf(npc.context.health * 100, 0.1)) + "%")
	output_file.store_line("  Stress:  " + str(snappedf(npc.context.stress_level * 100, 0.1)) + "%")
	output_file.store_line("")
	
	# Show baseline drives with effective weights
	output_file.store_line("BASELINE DRIVES (with resource modifiers):")
	for drive in npc.baseline_drives:
		var effective = npc_system.get_effective_drive_weight(npc, drive)
		var change = effective - drive.weight
		var arrow = ""
		if abs(change) > 0.01:
			arrow = " → " + str(snappedf(effective, 0.1))
			if change > 0:
				arrow += " (↑" + str(snappedf(change, 0.1)) + ")"
			else:
				arrow += " (↓" + str(snappedf(abs(change), 0.1)) + ")"
		output_file.store_line("  " + drive.drive_type.capitalize() + ": " + 
			str(snappedf(drive.weight, 0.1)) + arrow)
	output_file.store_line("")
	
	output_file.store_line("REQUEST: \"" + request_text + "\"")
	output_file.store_line("")
	
	# Parse request
	var request = npc_system.parser.parse_request(request_text)
	
	# Show detected action tags
	output_file.store_line("DETECTED ACTION TAGS:")
	if request.response_options.size() > 0 and request.response_options[0].action_tags.size() > 0:
		for tag in request.response_options[0].action_tags:
			output_file.store_line("  " + tag + ": " + str(request.response_options[0].action_tags[tag]))
	else:
		output_file.store_line("  (none detected)")
	output_file.store_line("")
	
	# Evaluate all response options and show detailed breakdown
	output_file.store_line("RESPONSE OPTIONS EVALUATION:")
	output_file.store_line("")
	
	var best_option = null
	var best_score = -INF
	var option_num = 1
	
	for option in request.response_options:
		# Get the detailed breakdown
		var breakdown = _evaluate_option_detailed(npc, option, request)
		
		output_file.store_line("  [" + str(option_num) + "] " + option.response_type + 
			" (variant " + str(option.template_variant) + ")")
		output_file.store_line("      Template: \"" + option.response_template + "\"")
		output_file.store_line("")
		output_file.store_line("      Base Score:              " + _format_score(breakdown.base_score))
		output_file.store_line("")
		output_file.store_line("      Personality Modifier:    ×" + str(snappedf(breakdown.personality_mult, 0.2)))
		if breakdown.personality_breakdown.size() > 0:
			for component in breakdown.personality_breakdown:
				output_file.store_line("        " + component)
		output_file.store_line("")
		output_file.store_line("      Value Modifier:          ×" + str(snappedf(breakdown.value_mult, 0.2)))
		output_file.store_line("      Relationship Modifier:   ×" + str(snappedf(breakdown.relationship_mult, 0.2)))
		output_file.store_line("      Context Modifier:        ×" + str(snappedf(breakdown.context_mult, 0.2)))
		output_file.store_line("")
		output_file.store_line("      Subtotal (after multiply): " + _format_score(breakdown.subtotal))
		output_file.store_line("")
		output_file.store_line("      Drive Modifier (additive): " + _format_score_signed(breakdown.drive_modifier))
		if breakdown.drive_breakdown.size() > 0:
			for component in breakdown.drive_breakdown:
				output_file.store_line("        " + component)
		output_file.store_line("")
		output_file.store_line("      Random Variation:        " + _format_score_signed(breakdown.random))
		output_file.store_line("")
		output_file.store_line("      ════════════════════════════════════════")
		output_file.store_line("      FINAL SCORE:             " + _format_score(breakdown.final_score, true))
		output_file.store_line("      ════════════════════════════════════════")
		output_file.store_line("")
		
		if breakdown.final_score > best_score:
			best_score = breakdown.final_score
			best_option = option
		
		option_num += 1
	
	# Show chosen option
	output_file.store_line("")
	output_file.store_line(">>> CHOSEN OPTION: " + best_option.response_type + 
		" (score: " + str(snappedf(best_score, 0.2)) + ")")
	output_file.store_line("")
	
	# Generate and show actual response
	var response = npc_system.generator.generate_response(npc, best_option, request)
	output_file.store_line("ACTUAL RESPONSE:")
	output_file.store_line(response)
	output_file.store_line("")

func _evaluate_option_detailed(npc, option, request) -> Dictionary:
	var breakdown = {
		"base_score": option.base_score,
		"personality_mult": 1.0,
		"personality_breakdown": [],
		"value_mult": 1.0,
		"relationship_mult": 1.0,
		"context_mult": 1.0,
		"subtotal": 0.0,
		"drive_modifier": 0.0,
		"drive_breakdown": [],
		"random": 0.0,
		"final_score": 0.0
	}
	
	var score = option.base_score
	
	# Personality modifier
	var pers_mult = _calculate_personality_modifier_detailed(npc.personality, option, breakdown)
	breakdown.personality_mult = pers_mult
	
	# Value modifier
	var val_mult = _calculate_value_modifier(npc.personality.values, option)
	breakdown.value_mult = val_mult
	
	# Relationship modifier
	var relationship = npc.get_relationship(request.context.requester_id)
	var rel_mult = _calculate_relationship_modifier(relationship, request.context)
	breakdown.relationship_mult = rel_mult
	
	# Context modifier
	var ctx_mult = _calculate_context_modifier(npc.context, request.context)
	breakdown.context_mult = ctx_mult
	
	# Calculate subtotal after multiplication
	breakdown.subtotal = score * pers_mult * val_mult * rel_mult * ctx_mult
	
	# Drive modifier (additive)
	var drive_mod = _calculate_drive_modifier_detailed(npc, option, breakdown)
	breakdown.drive_modifier = drive_mod
	
	# Random variation
	var random_var = randf_range(-0.2, 0.2)
	breakdown.random = random_var
	
	# Final score
	breakdown.final_score = breakdown.subtotal + drive_mod + random_var
	
	return breakdown

func _calculate_personality_modifier_detailed(personality, option, breakdown: Dictionary) -> float:
	var modifier = 1.0
	
	for tag in option.personality_tags:
		match tag:
			"is_helpful":
				if option.personality_tags[tag]:
					var bonus = personality.warmth * 0.3
					modifier += bonus
					if abs(bonus) > 0.01:
						breakdown.personality_breakdown.append("Warmth (" + str(snappedf(personality.warmth, 0.2)) + 
							") × 0.3 = +" + str(snappedf(bonus, 0.2)) + " (helpful)")
			
			"is_aggressive":
				if option.personality_tags[tag]:
					var bonus = personality.assertiveness * 0.3
					modifier += bonus
					if abs(bonus) > 0.01:
						breakdown.personality_breakdown.append("Assertiveness (" + str(snappedf(personality.assertiveness, 0.2)) + 
							") × 0.3 = +" + str(snappedf(bonus, 0.2)) + " (aggressive)")
			
			"is_cautious":
				if option.personality_tags[tag]:
					var bonus = (1.0 - personality.risk_tolerance) * 0.3
					modifier += bonus
					if abs(bonus) > 0.01:
						breakdown.personality_breakdown.append("(1.0 - Risk-Tolerance[" + str(snappedf(personality.risk_tolerance, 0.2)) + 
							"]) × 0.3 = +" + str(snappedf(bonus, 0.2)) + " (cautious)")
			
			"is_strategic":
				if option.personality_tags[tag]:
					var bonus = personality.conscientiousness * 0.2
					modifier += bonus
					if abs(bonus) > 0.01:
						breakdown.personality_breakdown.append("Conscientiousness × 0.2 = +" + str(snappedf(bonus, 0.2)) + " (strategic)")
			
			"is_evasive":
				if option.personality_tags[tag]:
					var bonus = (1.0 - personality.assertiveness) * 0.2
					modifier += bonus
					if abs(bonus) > 0.01:
						breakdown.personality_breakdown.append("(1.0 - Assertiveness) × 0.2 = +" + str(snappedf(bonus, 0.2)) + " (evasive)")
	
	# Risk-tolerance affects acceptance/refusal
	if option.response_type in ["AGREE", "AGREE_CONDITIONAL"]:
		var bonus = personality.risk_tolerance * 0.5
		modifier += bonus
		if abs(bonus) > 0.01:
			breakdown.personality_breakdown.append("Risk-Tolerance (" + str(snappedf(personality.risk_tolerance, 0.2)) + 
				") × 0.5 = +" + str(snappedf(bonus, 0.2)) + " (accepts risks)")
	
	elif option.response_type in ["REFUSE", "REFUSE_SOFT", "REFUSE_HEDGED", "DEFLECT"]:
		var bonus = (1.0 - personality.risk_tolerance) * 0.4
		modifier += bonus
		if abs(bonus) > 0.01:
			breakdown.personality_breakdown.append("(1.0 - Risk-Tolerance[" + str(snappedf(personality.risk_tolerance, 0.2)) + 
				"]) × 0.4 = +" + str(snappedf(bonus, 0.2)) + " (avoids risks)")
	
	return max(0.1, modifier)

func _calculate_drive_modifier_detailed(npc, option, breakdown: Dictionary) -> float:
	var total_modifier = 0.0
	
	# Get action tags from option
	var action_tags = option.action_tags
	
	if action_tags.is_empty():
		breakdown.drive_breakdown.append("(no action tags detected)")
		return 0.0
	
	# Evaluate baseline drives
	for drive in npc.baseline_drives:
		var effective_weight = npc_system.get_effective_drive_weight(npc, drive)
		var drive_score = _evaluate_drive_against_action(drive, action_tags, effective_weight)
		
		if abs(drive_score) > 0.01:
			total_modifier += drive_score
			breakdown.drive_breakdown.append(drive.drive_type.capitalize() + " (weight " + 
				str(snappedf(effective_weight, 0.2)) + "): " + _format_score_signed(drive_score))
	
	# Evaluate dynamic drives (if any)
	for drive in npc.dynamic_drives:
		var drive_score = _evaluate_drive_against_action(drive, action_tags, drive.weight)
		
		if abs(drive_score) > 0.01:
			total_modifier += drive_score
			breakdown.drive_breakdown.append(drive.drive_type + " (weight " + 
				str(snappedf(drive.weight, 0.2)) + "): " + _format_score_signed(drive_score))
	
	if breakdown.drive_breakdown.is_empty():
		breakdown.drive_breakdown.append("(no drives activated by action tags)")
	
	return total_modifier

func _evaluate_drive_against_action(drive, action_tags: Dictionary, weight: float) -> float:
	var score = 0.0
	
	match drive.drive_type:
		"SELF_PRESERVATION":
			if action_tags.has("risky"):
				score -= action_tags["risky"] * weight
			if action_tags.has("lethal") and action_tags["lethal"]:
				score -= 1.5 * weight
			if action_tags.has("safe") and action_tags["safe"]:
				score += 0.3 * weight
		
		"AVOID_PAIN":
			if action_tags.has("risky"):
				score -= action_tags["risky"] * 0.5 * weight
			if action_tags.has("high_pain") and action_tags["high_pain"]:
				score -= 1.0 * weight
		
		"SEEK_WEALTH":
			if action_tags.has("money_reward"):
				var amount = action_tags["money_reward"]
				score += (amount / 100.0) * weight
			if action_tags.has("money_cost"):
				var cost = action_tags["money_cost"]
				score -= (cost / 100.0) * weight
		
		"SEEK_GIFTS":
			if action_tags.has("gift_received") and action_tags["gift_received"]:
				score += 0.8 * weight
		
		"SEEK_STATUS":
			if action_tags.has("prestige"):
				score += action_tags["prestige"] * weight
			if action_tags.has("humiliation") and action_tags["humiliation"]:
				score -= 1.0 * weight
		
		"SEEK_KNOWLEDGE":
			if action_tags.has("knowledge_gain") and action_tags["knowledge_gain"]:
				score += 1.0 * weight
	
	return score

func _calculate_value_modifier(values: Dictionary, option) -> float:
	var modifier = 1.0
	match option.response_type:
		"AGREE":
			modifier += values.get("COMMUNITY", 0.0) * 0.2
		"REFUSE":
			modifier += values.get("FREEDOM", 0.0) * 0.2
		"NEGOTIATE":
			modifier += values.get("POWER", 0.0) * 0.3
		"CHALLENGE":
			modifier += values.get("HONOR", 0.0) * 0.3
	return max(0.1, modifier)

func _calculate_relationship_modifier(relationship, request_context) -> float:
	var modifier = relationship.get_influence_multiplier()
	if request_context.emotional_tone < -0.3:
		modifier *= 0.7
	if request_context.emotional_tone > 0.3:
		modifier *= 1.2
	return max(0.1, modifier)

func _calculate_context_modifier(npc_context, request_context) -> float:
	var modifier = 1.0
	if npc_context.stress_level > 0.5:
		modifier *= 0.8
	modifier += request_context.urgency * 0.1
	if not request_context.witnesses.is_empty():
		modifier *= 1.1
	return max(0.1, modifier)

# Helper functions
func _get_npc_id(npc_name: String) -> String:
	for id in npc_system.npcs:
		if npc_system.npcs[id].name == npc_name:
			return id
	return ""

func _format_trait(value: float) -> String:
	return str(snappedf(value, 0.2)).pad_decimals(1)

func _format_score(value: float, bold: bool = false) -> String:
	var formatted = str(snappedf(value, 0.2))
	if bold:
		formatted = ">>> " + formatted + " <<<"
	return formatted

func _format_score_signed(value: float) -> String:
	var formatted = str(snappedf(value, 0.2))
	if value > 0:
		return "+" + formatted
	return formatted
