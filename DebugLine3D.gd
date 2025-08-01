# DebugLine3D.gd
class_name DebugLine3D extends MeshInstance3D

@export var point_start: Vector3 = Vector3.ZERO
@export var point_end:	 Vector3 = Vector3.ZERO
@export var color:		 Color	 = Color.RED

var _mat: StandardMaterial3D
var _imesh: ImmediateMesh

func _ready() -> void:
	# -- create the line mesh --
	_imesh = ImmediateMesh.new()
	mesh = _imesh

	# 1) Disable casting shadows on this line
	#	 (won’t generate any shadows) :contentReference[oaicite:0]{index=0}
	self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# -- create an unshaded material --
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = color

	# 2) Disable receiving shadows on this material
	#	 (won’t be shadowed by other lights) :contentReference[oaicite:1]{index=1}
	_mat.disable_receive_shadows = true

	# apply material
	material_override = _mat

func _process(_delta: float) -> void:
	if visible:
		_imesh.clear_surfaces()
		_imesh.surface_begin(Mesh.PRIMITIVE_LINES, _mat)
		_imesh.surface_add_vertex(point_start)
		_imesh.surface_add_vertex(point_end)
		_imesh.surface_end()
