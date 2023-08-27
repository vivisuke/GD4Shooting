extends Node2D

const FIGHTER_LR_SPEED = 100	# 自機移動速度 px/sec

var move_fighter = 0			# 自機移動方向、0 | KEY_LEFT | KEY_RIGHT

# Called when the node enters the scene tree for the first time.
func _ready():
	print("KEY_LEFT = ", KEY_LEFT)
	print("KEY_RIGHT = ", KEY_RIGHT)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if move_fighter == KEY_LEFT:
		$Fighter.position.x -= delta * FIGHTER_LR_SPEED
	elif move_fighter == KEY_RIGHT:
		$Fighter.position.x += delta * FIGHTER_LR_SPEED
	pass

func _input(event):
	if event is InputEventKey:
		#var k = InputEventKey(event)
		var kc = event.keycode
		print(kc)
		if event.is_pressed():
			print("pressed")
			if kc == KEY_LEFT || kc == KEY_RIGHT:
				move_fighter = kc
			#if kc == KEY_LEFT:
			#	$Fighter.position.x -= 10
			#elif kc == KEY_RIGHT:
			#	$Fighter.position.x += 10
		else:
			print("relesed")
			move_fighter = 0
