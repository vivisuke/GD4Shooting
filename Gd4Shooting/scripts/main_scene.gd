extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	print("KEY_LEFT = ", KEY_LEFT)
	print("KEY_RIGHT = ", KEY_RIGHT)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventKey:
		#var k = InputEventKey(event)
		var kc = event.keycode
		print(kc)
		if event.is_pressed():
			print("pressed")
			if kc == KEY_LEFT:
				$Fighter.position.x -= 10
			elif kc == KEY_RIGHT:
				$Fighter.position.x += 10
		else:
			print("relesed")
