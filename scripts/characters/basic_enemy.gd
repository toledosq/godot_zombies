class_name BasicEnemy extends CharacterBody3D

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	health_component.connect("died", _on_died)

func apply_damage(amount: int) -> void:
	health_component.take_damage(amount)

func apply_heal(amount: int) -> void:
	health_component.heal(amount)

func _on_died() -> void:
	print("Enemy %s died" % self.name)
