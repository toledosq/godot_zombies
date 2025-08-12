class_name BasicEnemy extends CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent

var dead := false

var loot_comp = preload("res://scenes/components/ContainerComponent.tscn")
var int_comp = preload("res://scenes/components/InteractableComponent.tscn")

func _ready() -> void:
	health_component.connect("died", _on_died)

func apply_damage(amount: int) -> void:
	health_component.take_damage(amount)

		
func apply_heal(amount: int) -> void:
	health_component.heal(amount)

func _on_died() -> void:
	if not dead:
		dead = true
		print("Enemy %s died" % self.name)
		var new_loot_comp = loot_comp.instantiate()
		var new_int_comp = int_comp.instantiate()
		
		add_child(new_loot_comp)
		add_child(new_int_comp)
		
		new_int_comp.connect("interacted", new_loot_comp._on_interacted)
	else:
		print("Hes already dead man")
		
