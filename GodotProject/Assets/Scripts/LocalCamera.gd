extends Camera

onready var player = get_parent()
var offset : Vector3
var globalOffset = Vector3.ZERO

func _init():
	set_as_toplevel(true)

func _ready():
	offset = get_global_transform().origin
	#globalOffset = get_node("/root/Arena/GlobalCamera").get_global_transform().origin

func _physics_process(delta):
	var target = get_parent().get_global_transform().origin
	var pos = offset + target # - globalOffset
	var up = Vector3(0, 1, 0)
	look_at_from_position(pos, target, up)
