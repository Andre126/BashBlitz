extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (Input.is_action_just_pressed("sonido")):
		$AudioStreamPlayer.play(true)
	elif (Input.is_action_just_pressed("sonido2")):
		$AudioStreamPlayer2.play(true)
	elif (Input.is_action_just_pressed("sonido3")):
		$AudioStreamPlayer3.play(true)
	elif (Input.is_action_just_pressed("sonido4")):
		$AudioStreamPlayer4.play(true)
	elif (Input.is_action_just_pressed("sonido5")):
		$AudioStreamPlayer5.play(true)
	else:
		pass
