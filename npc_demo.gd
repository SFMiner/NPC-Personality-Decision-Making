extends Node

# A simple NPC personality and decision demo for Godot
#
# This script defines a `Personality` class, an `ActionOption` class,
# and a `decide_action` function that scores action options based on
# personality traits.

class Personality:
	var warmth: float
	var assertiveness: float
	var conscientious: float
	var curiosity: float
	var risk_tolerance: float
	var stability: float
	var values: Dictionary

	func _init(arg_warmth: float, arg_assertiveness: float, arg_conscientious: float, arg_curiosity: float, arg_risk_tolerance: float, arg_stability: float, arg_values: Dictionary) -> void:
		self.warmth = arg_warmth
		self.assertiveness = arg_assertiveness
		self.conscientious = arg_conscientious
		self.curiosity = arg_curiosity
		self.risk_tolerance = arg_risk_tolerance
		self.stability = arg_stability
		self.values = arg_values


class ActionOption:
	var name: String
	var base_score: float
	var is_risky: bool
	var involves_power: bool
	var involves_honor: bool
	var involves_helping: bool
	var is_aggressive: bool

	func _init(arg_name: String, arg_base_score: float = 0.5, arg_is_risky: bool = false, arg_involves_power: bool = false, arg_involves_honor: bool = false, arg_involves_helping: bool = false, arg_is_aggressive: bool = false) -> void:
		self.name = arg_name
		self.base_score = arg_base_score
		self.is_risky = arg_is_risky
		self.involves_power = arg_involves_power
		self.involves_honor = arg_involves_honor
		self.involves_helping = arg_involves_helping
		self.is_aggressive = arg_is_aggressive


class ScenarioRequest:
	var name : String
	var options : Array[ActionOption]
	
	func _init(arg_name: String, arg_options: Array[ActionOption]):
		self.name = arg_name
		self.options = arg_options

func decide_action(personality: Personality, scenario: ScenarioRequest) -> String:
	var best_action: String = ""
	var best_score: float = -INF
	var actions = scenario.options

	for action in actions:
		# Start with base score
		var score: float = action.base_score

		# Apply personality modifiers
		if action.is_risky:
			score += personality.risk_tolerance * 0.5

		if action.involves_helping:
			score += personality.warmth * 0.2

		if action.is_aggressive:
			score += personality.assertiveness * 0.3

		# Apply value modifiers
		if action.involves_power:
			var power_weight: float = personality.values.get("POWER", 0.0)
			score += power_weight * 0.4

		if action.involves_honor:
			var honor_weight: float = personality.values.get("HONOR", 0.0)
			score += honor_weight * 0.3

		# Add slight randomness to avoid deterministic ties
		score += randf_range(0.0, 0.1)

		# Track best action
		if score > best_score:
			best_score = score
			best_action = action.name

	return best_action

	
			
func _ready() -> void:
	# Define two NPCs with different personalities
	var vorak = Personality.new(-0.3, 0.8, 0.2, -0.1, 0.7, 0.3, {"POWER": 0.8, "HONOR": 0.4})
	var lyris = Personality.new(0.5, -0.4, 0.7, 0.6, -0.3, 0.8, {"POWER": 0.2, "HONOR": 0.8})

	# Define the rebellion scenario as action options
	var rebellion_scenario : Array[ActionOption]= [
		ActionOption.new("Support", 0.5, true, true, false, true, true),
		ActionOption.new("Refuse", 0.5, false, false, true, false, false)
	]
	
	
	
	
	# SCENARIO 1: Diplomatic Crisis - Border Dispute
	# A neighboring faction is encroaching on your territory
	var diplomatic_crisis : Array[ActionOption]  = [
		ActionOption.new("Negotiate Treaty", 0.5, false, false, true, false, false),
		# Safe, honorable diplomacy - appeals to cautious, honor-focused NPCs
		
		ActionOption.new("Military Threat", 0.5, true, true, false, false, true),
		# Risky power play - appeals to aggressive, power-seeking NPCs
		
		ActionOption.new("Offer Concessions", 0.5, false, false, false, true, false),
		# Helping/compromising - appeals to warm, community-focused NPCs
		
		ActionOption.new("Secret Sabotage", 0.5, true, true, false, false, false)
		# Risky, power-seeking but not openly aggressive - sneaky approach
	]


	# SCENARIO 2: Ancient Ruins Discovery
	# Scouts report mysterious ruins with possible treasure and danger
	var ruins_exploration : Array[ActionOption]  = [
		ActionOption.new("Lead Expedition", 0.5, true, false, false, false, false),
		# Risky exploration - appeals to curious, risk-tolerant NPCs
		
		ActionOption.new("Send Scouts Only", 0.5, false, false, false, false, false),
		# Cautious approach - baseline safe choice
		
		ActionOption.new("Ignore It", 0.5, false, false, true, false, false),
		# Honor-based (keeping people safe) - very cautious
		
		ActionOption.new("Claim and Fortify", 0.5, true, true, false, false, true)
		# Aggressive territorial expansion - power + aggression + risk
	]

	# SCENARIO 3: Moral Dilemma - Burning Village
	# Enemy soldiers are burning a village. You could save civilians or pursue your military objective
	var moral_choice : Array[ActionOption]  = [
		ActionOption.new("Save Civilians", 0.5, true, false, true, true, false),
		# Risky, honorable, helping - classic heroic choice
		
		ActionOption.new("Complete Mission", 0.5, false, true, false, false, false),
		# Focus on power/strategic goals - cold pragmatism
		
		ActionOption.new("Split Forces", 0.5, true, false, false, true, false),
		# Risky compromise - trying to do both (helping but risky)
		
		ActionOption.new("Retreat", 0.5, false, false, false, false, false)
		# Safe but accomplishes nothing - default low score
	]

	# SCENARIO 4: Leadership Challenge
	# A subordinate is openly questioning your authority in front of the group
	var leadership_crisis : Array[ActionOption]  = [
		ActionOption.new("Public Demotion", 0.5, false, true, false, false, true),
		# Assert power aggressively - not risky if you have authority
		
		ActionOption.new("Private Discussion", 0.5, false, false, true, false, false),
		# Honorable, measured response - respects both parties
		
		ActionOption.new("Debate Openly", 0.5, true, false, true, false, false),
		# Risky (might lose) but honorable - showing confidence
		
		ActionOption.new("Delegate More", 0.5, false, false, false, true, false)
		# Helping/collaborative approach - less about maintaining power
	]

	# SCENARIO 5: Social Manipulation
	# A wealthy merchant could be useful. How do you approach them?
	var social_approach : Array[ActionOption]  = [
		ActionOption.new("Genuine Friendship", 0.5, false, false, false, true, false),
		# Helping/warm approach - appeals to high warmth NPCs
		
		ActionOption.new("Flattery & Gifts", 0.5, false, true, false, false, false),
		# Power-seeking through manipulation - subtle
		
		ActionOption.new("Intimidation", 0.5, false, true, false, false, true),
		# Power through aggression - direct approach
		
		ActionOption.new("Avoid Entirely", 0.5, false, false, true, false, false)
		# Honor-based (not using people) - principled distance
	]

	# SCENARIO 6: Resource Scarcity
	# Food is running low. What do you do?
	var resource_crisis : Array[ActionOption]  = [
		ActionOption.new("Raid Neighbors", 0.5, true, true, false, false, true),
		# Aggressive power play - takes from others
		
		ActionOption.new("Ration Equally", 0.5, false, false, true, true, false),
		# Honorable, helping - community-focused
		
		ActionOption.new("Trade Valuables", 0.5, false, false, false, true, false),
		# Helping community by sacrificing wealth
		
		ActionOption.new("Hunt Dangerous Game", 0.5, true, false, false, false, false)
		# Risky solution - appeals to risk-takers
	]

	# SCENARIO 7: Betrayal Discovered
	# You've discovered a trusted ally has been spying for an enemy
	var betrayal_response : Array[ActionOption] = [
		ActionOption.new("Execute Publicly", 0.5, false, true, false, false, true),
		# Aggressive power move - sends a message
		
		ActionOption.new("Exile Quietly", 0.5, false, false, true, false, false),
		# Honorable mercy - less disruptive
		
		ActionOption.new("Turn Double Agent", 0.5, true, true, false, false, false),
		# Risky power play - trying to use the situation
		
		ActionOption.new("Forgive Completely", 0.5, true, false, false, true, false)
		# Risky helping - very warm/trusting response
	]
	

	var requests : Array[ScenarioRequest] = [ScenarioRequest.new("Rebellion Scenario", rebellion_scenario), ScenarioRequest.new("Diplomatic Crisis", diplomatic_crisis), ScenarioRequest.new("Ruins Exploration", ruins_exploration), ScenarioRequest.new("Moral Choice", moral_choice), ScenarioRequest.new("Leadership Crisis", leadership_crisis), ScenarioRequest.new("Social Approach", social_approach), ScenarioRequest.new("Resource Crisis", resource_crisis), ScenarioRequest.new("Betrayal Response", betrayal_response)]

	
	
	for request in requests:
		var vorak_choice = decide_action(vorak, request)
		var lyris_choice = decide_action(lyris, request)
		print("NPC Decision Demo: " + str(request.name))
		print("Vorak chooses: ", vorak_choice)
		print("Lyris chooses: ", lyris_choice)
