extends MeshInstance3D
@onready var timer: Timer = $Timer



func _on_timer_timeout() -> void:
	self.queue_free()
