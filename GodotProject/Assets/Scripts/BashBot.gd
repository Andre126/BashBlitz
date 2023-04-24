extends KinematicBody

class_name BashBot

onready var mesh = $polySurface7
onready var cursor = $Cursor
onready var arrow = $polySurface7/Arrow
#onready var crashTexture = $MeshInstance/CrashTexture
onready var camera = get_node("/root/Arena/GlobalCamera")
onready var tuto = get_node("/root/Arena/TutorialHUD")
onready var sfx_countdownBeep1 = get_node("/root/Arena/SFX_CountdownBeep1")
onready var sfx_countdownBeep2 = get_node("/root/Arena/SFX_CountdownBeep2")
onready var sfx_countdownBell = get_node("/root/Arena/SFX_CountdownBell")
onready var sfx_dash = get_node("/root/Arena/SFX_Dash")
onready var sfx_dashCharging = get_node("/root/Arena/SFX_DashCharging")
onready var sfx_clash = get_node("/root/Arena/SFX_Clash")
onready var sfx_fall = get_node("/root/Arena/SFX_Fall")
onready var sfx_respawn = get_node("/root/Arena/SFX_Respawn")

onready var alreadyDashing = false
onready var alreadyFalling = false


onready var world = get_node("/root/Arena/world")
onready var isDashing = false 
#const materials = [preload("res://Matirials/mat0.tres"),preload("res://Matirials/mat1.tres"),preload("res://Matirials/mat2.tres"),preload("res://Matirials/mat3.tres")]
const arrowColors = [Color.red, Color.blue, Color.green, Color.yellow]
#Estas dos variables son necesarias para limitar la velocidad
export var acceleration = 12.5 #75
export var topSpeed = 25

export var dashImpulse = 100
export var dashTime = 1.25
export var damp = 1.0/50.0

#Estas dos son necesarias para el impulso del dash con respecto al daño
export var damageResistance = 6
export var damagePercentage = 0
export var color : Color

var direction : Vector2
#Declaración del producto punto, rotación global del mesh y el puntaje
var bashBotRotation : Vector3
var dotProduct : float
#export var score = 0

var canRespawn = false
var hasFallen = false
var softReset = false
var neuterX : bool
var neuterZ : bool

var cursorPosition = Vector3.ZERO
var dashCharge = 1
var dashPercentage = 0

var Id = 0
var linear_velocity = Vector3.ZERO
export var reboteEstatico = .5
export var reboteDinamico = .025
var frame = 1/60

var isChargingDash = false

var wasTouched = false
var lastTouched = 0

func _input(event):
	#print(Id)
	#print(event.get_device())
	#print(event.as_text())
	if(event.get_device() == Id):
		if event is InputEventJoypadButton:
			var even = event as InputEventJoypadButton
			if even.button_index == 5:
				if even.pressed:
					isChargingDash = true
				else :
					isChargingDash = false
					releaseDash()
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	#set_bounce(1)
	#Estas líneas son necesarias para cambiar el color de la flecha del robot
	var meshColor = SpatialMaterial.new()
	meshColor.albedo_color = arrowColors[Id]
	arrow.set_surface_material(0,meshColor)
	#crashTexture.visible = false
	arrow.set_scale(Vector3(1,.25,1))
	cursor.hide()
	#var mesh = get_node("MeshInstance")
	#mesh.set_surface_material(0,materials[Id])
	

func chargingDash(_delta):
	if alreadyDashing == false:
		sfx_dashCharging.play()
		alreadyDashing = true
	
	isDashing = false
	if dashCharge <= dashTime:
		dashCharge += _delta
	dashPercentage = dashCharge / dashTime
	arrow.set_scale(Vector3(1,dashPercentage+.25,1))
	
func releaseDash():
	sfx_dashCharging.stop()
	alreadyDashing = false
	sfx_dash.play()
	isDashing = true
	var playerPosition = global_transform.origin
	linear_velocity += (Vector3(direction.x,0,direction.y)*(dashPercentage*dashImpulse))
	dashCharge = 0
	arrow.set_scale(Vector3(1,.25,1))
	
func moving(_delta):
	var vel = sqrt(linear_velocity.x*linear_velocity.x+linear_velocity.z*linear_velocity.z)
	if vel <= topSpeed:
		linear_velocity.x += Input.get_axis("move_left"+String(Id), "move_right"+String(Id))*acceleration
		linear_velocity.z += Input.get_axis("move_down"+String(Id), "move_up"+String(Id))*acceleration
			
func run(_delta):
	if isChargingDash:#Input.is_action_pressed("dash") or Input.is_action_pressed("pad_dash"):
		chargingDash(_delta)
	#elif Input.is_action_just_released("dash") or Input.is_action_just_released("pad_dash"):
	#	releaseDash()
	#else:
	moving(_delta)
	lookAtCursor(_delta)
	if abs(global_transform.origin.x) > 25 or abs(global_transform.origin.z) > 18:
		if alreadyFalling == false:
			sfx_fall.play()
			alreadyFalling = true
		hasFallen = true
		#print(global_transform.origin)
	if Input.is_action_just_pressed("Reset"):
		tuto.visible = true
		softReset = true
	if Input.is_action_just_pressed("Enter"):
		tuto.visible = false
		
	if hasFallen and scale > Vector3.ZERO:
		scale -= Vector3(1,1,1)*_delta
	elif scale < Vector3.ZERO:
		canRespawn = false
		hasFallen = false
		linear_velocity.x = 0
		linear_velocity.z = 0
		damagePercentage = 0
		sfx_respawn.play() #
		alreadyFalling = false # 
		scale = Vector3(1,1,1)
		if(wasTouched):
			var score = get_node("/root/Arena/scoreBoard"+str(lastTouched))
			score.addPoint()
		wasTouched = false
		var score = get_node("/root/Arena/scoreBoard"+str(Id))
		score.setDamagePercentage(0)
		world.respawn(Id)
	
	linear_velocity*=1.0-damp

func lookAtCursor(_delta):
	var axis = Input.get_vector("look_left"+String(Id),"look_right"+String(Id),"look_down"+String(Id),"look_up"+String(Id))
	if axis.length() >.001:
		direction = axis.normalized()
		axis = direction*1000
		var lookPos = transform.origin+Vector3(axis.x,0,axis.y)
		#lookPos.y *=2.5
		mesh.look_at(lookPos,Vector3.UP)
	pass

func _physics_process(_delta):
	run(_delta)
	
	if not hasFallen:
		var collicion = move_and_collide(linear_velocity*_delta)
		if(collicion):
			
			var other = collicion.get_collider()
			var thisClass = get_script()
			if other is thisClass and isDashing:
				other.wasTouched = true
				other.lastTouched = Id
				other.damage(linear_velocity.length()/damageResistance)
				other.linear_velocity += linear_velocity*other.damagePercentage*reboteDinamico
				#print("choke"+String(Id))
			linear_velocity = -linear_velocity.reflect(collicion.get_normal())
			linear_velocity.y = 0

func damage(n):
	sfx_clash.play()
	damagePercentage += n
	var scoreBoard = get_node("/root/Arena/scoreBoard"+str(Id))
	scoreBoard.setDamagePercentage(damagePercentage)

func comment(collisionBashbot):
	
	if collisionBashbot.name == "BashBotController":
		
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

		if !isDashing and collisionBashbot.isDashing:#accumulatedForce > 7.5 and dotProduct < collisionBashbot.dotProduct:
			damagePercentage += accumulatedForce/damageResistance
			print(name," is ", damagePercentage, "% damaged")
		elif isDashing:
			#crashTexture.visible = true
			sfx_clash.play()
			#crashTexture.scale = Vector3.ZERO


func _on_Area_body_exited(body):
	print(global_transform.origin)
	if body.name == name:
		#print(body, " exited")
		#print(self.get_translation())
		if alreadyFalling == false:
			sfx_fall.play()
			alreadyFalling = true
		
		hasFallen = true
		Global.cscore += 1

func _integrate_forces(state):
	if canRespawn: 
		alreadyFalling = false
		canRespawn = false
		hasFallen = false
		linear_velocity.x = 0
		linear_velocity.z = 0
		damagePercentage = 0
		#state.set_transform(spawnPoint)
		sfx_respawn.play()
		scale = Vector3(1,1,1)
		world.respawn(Id)
		
		#print("Player 2 = ", Global.cscore)
		#print(self.get_translation())
	
	if softReset:
		softReset = false
		Global.cscore = 0
		#print("Player 2 = ",  Global.cscore)
		hasFallen = true

func _on_BashBot_body_entered(body):
	pass
	#return
	#if(!isDashing):
	#	return
	#var space_state = get_world().direct_space_state
	#var result = space_state.intersect_ray(global_transform.origin, global_transform.origin+linear_velocity.normalized()*100,[self])
	#if result.has("normal"):
	#	linear_velocity = result["normal"]*reboteEstatico*linear_velocity.length()
	# Replace with function body.
