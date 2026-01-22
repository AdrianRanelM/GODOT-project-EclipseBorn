extends EnemyBattleBase

func _ready():
	# 1. Set the Ninja's specific stats
	MAX_HEALTH =50.0
	MAX_MANA = 10.0
	attack_damage = 10
	unit_name = "Slime"
	
	# 2. Set the starting values
	health = MAX_HEALTH
	mana = MAX_MANA
	
	# 3. Call the parent _ready to update the bars on screen
	super._ready()

# You can add a unique Ninja move here later
