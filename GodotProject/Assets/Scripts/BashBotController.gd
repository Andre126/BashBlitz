extends RigidBody

#Estas dos variables son necesarias para limitar la velocidad
export var acceleration = 75
export var topSpeed = 25

export var movementDamp = 7.5
export var dashImpulse = 45
export var dampMultiplier = 10
export var dashTime = 1.25
export var dashDamp = 15
export var axisDecceleration = 40

#Estas dos son necesarias para el impulso del dash con respecto al daño
export var damageResistance = 6.1
export var damagePercentage = 0
export var color : Color

onready var spawnPoint = global_transform
onready var mesh = $MeshInstance
onready var cursor = $Cursor
onready var arrow = $MeshInstance/Arrow
onready var camera = get_node("/root/Arena/GlobalCamera")
onready var tuto = get_node("/root/Arena/TutorialHUD")
onready var sfx_clash = get_node("/root/Arena/SFX_Clash")
onready var sfx_fall = get_node("/root/Arena/SFX_Fall")
onready var sfx_respawn = get_node("/root/Arena/SFX_Respawn")
onready var crashTexture = $MeshInstance/CrashTexture
onready var isDashing = false

var dashCharge = 1
var dashPercentage = 0
var cursorPosition = Vector3.ZERO


#Condicional de caída
var canRespawn = false
var hasFallen = false
var softReset = false
var neuterX : bool
var neuterZ : bool

#Declaración del producto punto, rotación global del mesh y el puntaje
var bashBotRotation : Vector3
var dotProduct : float
#export var score = 0

func getMousePos():
	var playerPosition = global_transform.origin
	var camPosition = camera.get_camera_transform().origin
	var mouse_pos = get_viewport().get_mouse_position()
	return camera.project_position(mouse_pos,playerPosition.y-camPosition.y)

func _ready():
	#Estas líneas son necesarias para cambiar el color de la flecha del robot
	var meshColor = SpatialMaterial.new()
	meshColor.albedo_color = color
	arrow.set_surface_material(0,meshColor)
	crashTexture.visible = false
	contact_monitor = true
	contacts_reported = 5
	arrow.set_scale(Vector3(1,.25,1))
	cursor.hide()

func run(_delta):
	Global.cdamage = damagePercentage

	if linear_damp < movementDamp:
		linear_damp += _delta*dampMultiplier

	if crashTexture.visible and crashTexture.scale <= Vector3(1.5,1.5,0):
		crashTexture.scale += Vector3(_delta*5,_delta*5,0)
	elif crashTexture.scale > Vector3(dashPercentage/100,dashPercentage/100,0):
		crashTexture.visible = false

	neuterX = true
	neuterZ = true

	if Input.is_action_pressed("pad_dash"):
		isDashing = false
		linear_damp = dashDamp
		if dashCharge <= dashTime:
			dashCharge += _delta
		dashPercentage = dashCharge * 1 / dashTime
		arrow.set_scale(Vector3(1,dashPercentage+.25,1))
		
	elif Input.is_action_just_released("pad_dash"):
		print(name," dashed")
		isDashing = true
		linear_velocity = Vector3.ZERO
		var direction = cursor.global_transform.origin - global_transform.origin
		direction = direction.normalized()
		apply_central_impulse(direction*(dashPercentage*dashImpulse))
		linear_damp = 1
		dashCharge = 0
		arrow.set_scale(Vector3(1,.25,1))

	else:
		#Estos son los nuevos parámetros para acceder a la función y limitan la velocidad
		if linear_velocity.x >= topSpeed*-1 and linear_velocity.x <= topSpeed:
			if Input.get_action_strength("stick_left") > 0:
				if linear_velocity.x > 0:
					apply_central_impulse(linear_velocity*-1)
					linear_velocity.x = 0
				else:
					neuterX = false
					linear_damp = 1
					linear_velocity.x -= acceleration*Input.get_action_strength("stick_left")*_delta
				isDashing = false
				#moving(Axis.X, false)
			if Input.get_action_strength("stick_right") > 0:
				if linear_velocity.x < 0:
					apply_central_impulse(linear_velocity*-1)
					linear_velocity.x = 0
				else:
					neuterX = false
					linear_damp = 1
					linear_velocity.x += acceleration*Input.get_action_strength("stick_right")*_delta
				isDashing = false
		if linear_velocity.z >= topSpeed*-1 and linear_velocity.z <= topSpeed:
			if Input.get_action_strength("stick_up") > 0:
				if linear_velocity.z > 0:
					apply_central_impulse(linear_velocity*-1)
					linear_velocity.z = 0
				else:
					neuterZ = false
					linear_damp = 1
					linear_velocity.z -= acceleration*Input.get_action_strength("stick_up")*_delta
				isDashing = false
				#moving(Axis.Z, false)
			if Input.get_action_strength("stick_down") > 0:
				if linear_velocity.z < 0:
					apply_central_impulse(linear_velocity*-1)
					linear_velocity.z = 0
				else:
					neuterZ = false
					linear_damp = 1
					linear_velocity.z += acceleration*Input.get_action_strength("stick_down")*_delta
				isDashing = false
		#Botón de Reseteado
		if Input.is_action_just_pressed("Reset"):
			tuto.visible = true
			softReset = true
		if Input.is_action_just_pressed("Enter"):
			tuto.visible = false

	if Input.get_action_strength("aim_left")>0:
		cursorPosition.x -= Input.get_action_strength("aim_left")			
	if Input.get_action_strength("aim_right")>0:
		cursorPosition.x += Input.get_action_strength("aim_right")
	if Input.get_action_strength("aim_up")>0:
		cursorPosition.z -= Input.get_action_strength("aim_up")
	if Input.get_action_strength("aim_down")>0:
		cursorPosition.z += Input.get_action_strength("aim_down")
	if cursorPosition != Vector3.ZERO:
		cursorPosition = cursorPosition.normalized()
		cursor.global_transform.origin = cursorPosition * 2.5 + global_transform.origin

	mesh.look_at(cursor.global_transform.origin, Vector3.UP)

	if neuterX and !neuterZ and !isDashing:
		if linear_velocity.x > 0:
			linear_velocity.x -= _delta * axisDecceleration
		elif linear_velocity.x < 0:
			linear_velocity.x += _delta * axisDecceleration
	if neuterZ and !neuterX and !isDashing:
		if linear_velocity.z > 0:
			linear_velocity.z -= _delta * axisDecceleration
		elif linear_velocity.z < 0:
			linear_velocity.z += _delta * axisDecceleration

	#Esta línea de abajo se usa para obtener el producto punto
	bashBotRotation = mesh.rotation_degrees - rotation_degrees + Vector3(0,90,0)

	#Condicional de caída
	if hasFallen and scale > Vector3.ZERO:
		scale -= Vector3(1,1,1)*_delta
	elif scale < Vector3.ZERO:
		canRespawn = true

func _physics_process(_delta):
	run(_delta)

func _on_BashBot_collision(collisionBashbot):
	if collisionBashbot is RigidBody and collisionBashbot.isDashing:
		linear_velocity = collisionBashbot.linear_velocity*damagePercentage/100
		damagePercentage += collisionBashbot.linear_velocity.length()
		
	else:
		linear_velocity.x *= -1
		linear_velocity.z *= -1
		
	global_transform.origin.y = .163
	
func comment(collisionBashbot):
	if collisionBashbot.name == "BashBotKeyboard":
		var accumulatedForce = 0
		if collisionBashbot.linear_velocity.x < 0:
			accumulatedForce += collisionBashbot.linear_velocity.x*-1
		else:
			accumulatedForce += collisionBashbot.linear_velocity.x
		if collisionBashbot.linear_velocity.z < 0:
			accumulatedForce += collisionBashbot.linear_velocity.z*-1
		else:
			accumulatedForce += collisionBashbot.linear_velocity.z
		accumulatedForce /= 2

		var facingDirection = collisionBashbot.mesh.global_transform.origin.direction_to(mesh.global_transform.origin)
		dotProduct = facingDirection.dot(collisionBashbot.bashBotRotation)

		if !isDashing and collisionBashbot.isDashing: #accumulatedForce > 7.5 and dotProduct < collisionBashbot.dotProduct:
			linear_damp = 1
			damagePercentage += accumulatedForce/damageResistance
			print(name," is ", damagePercentage, "% damaged")
			apply_central_impulse(facingDirection*(accumulatedForce/damageResistance)*(damagePercentage/damageResistance))
		elif isDashing:
			linear_damp = dashDamp
			crashTexture.visible = true
			sfx_clash.play()
			crashTexture.scale = Vector3.ZERO


func _on_Area_body_exited(body):
	if body.name == name:
		#print(body, " exited")
		#print(self.get_translation())
		sfx_fall.play()
		hasFallen = true
		Global.kscore += 1
		

func _integrate_forces(state):
	if canRespawn: 
		canRespawn = false
		hasFallen = false
		linear_velocity.x = 0
		linear_velocity.z = 0
		damagePercentage = 0
		#print("Player 1 = ", Global.kscore)
		state.set_transform(spawnPoint)
		sfx_respawn.play()
		#print(self.get_translation())

	if softReset:
		softReset = false
		Global.kscore = 0
		#print("Player 1 = ",  Global.kscore)
		hasFallen = true
