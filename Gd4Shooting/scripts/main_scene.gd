extends Node2D

const SCREEN_WIDTH = 500        # スクリーン幅
const UFO_MOVE_UNIT = 150       # UFO 飛翔速度
#const MOVE_UNIT = 200           # 自機左右移動速度
const FIGHTER_MOVE_UNIT = 200	# 自機移動速度 px/sec
const FIGHTER_LR_SPC = 64
const MIN_FIGHTER_X = FIGHTER_LR_SPC
const MAX_FIGHTER_X = SCREEN_WIDTH - FIGHTER_LR_SPC
const MISSILE_DY = -10
const ENEMY_X0 = 64
const ENEMY_Y0 = 200
const ENEMY_H_PITCH = 48
const ENEMY_V_PITCH = 48
const ENEMY_N_HORZ = 8
const ENEMY_N_VERT = 5
const ENEMY_LR_SPC = 48
const ENEMY_MOVE_UNIT = 4
const ENEMY_MISSILE_OFFSET = 16 + 32 + 8    # 敵ミサイル発射位置
const MIN_ENEMY_X = ENEMY_LR_SPC
const MAX_ENEMY_X = SCREEN_WIDTH - ENEMY_LR_SPC
const MAX_ENEMY_Y = 620
const ENEMY_MISSILE_DY = 5
const UFO_POINTS = [10, 10, 50, 10, 10, 50, 10, 10, 300, 10, 10, 50, 10, 10]
const HI_SCORE_FN = "user://data.txt"

var Missile = load("res://Missile.tscn")
var Bunker8 = load("res://Bunker8.tscn")
var Enemy1 = load("res://Enemy1.tscn")
var EnemyMissile = load("res://EnemyMissile.tscn")
var Explosion = load("res://Explosion.tscn")

var gameOver = false
var paused = true
var level = 0
var invaded = false         # 敵機が最下段に到達
#var gameOverDlg = null
var exploding = false       # 爆発中
var nFighter = 3            # 自機残機数
var score = 0               # スコア
var hi_score = 0            # ハイスコア
var UFOPntIX = 0
var autoMoving : bool = false       # 自機自動移動中
var autoMoveX = 0                   # 自機自動移動先座標
var missile = null
var mv = Vector2(0, MISSILE_DY)
var emv = Vector2(0, ENEMY_MISSILE_DY)
#var dur = 0.0      # for 敵アニメーション
#var dur2 = 0.0     # for 敵移動
#var dur_em = 0.0   # for 敵ミサイル発射
var dur_expl = 0.0      # 爆発中カウンタ
var mv_ix = 0
var move_down : bool = false        # 敵機下移動
var move_right : bool = false       # 敵機右移動
var en_collied : bool = false       # 敵機が左右端に達した
var enemies = []        # 敵機管理用配列
var nEnemies = 0        # 敵機数
var enemyMissiles = []  # 敵ミサイル
var bunkers = []        # バンカー（防御壁）
var leftPressed : bool = false
var rightPressed : bool = false


var move_fighter = 0			# 自機移動方向、0 | KEY_LEFT | KEY_RIGHT

# Called when the node enters the scene tree for the first time.
func _ready():
	print("KEY_LEFT = ", KEY_LEFT)
	print("KEY_RIGHT = ", KEY_RIGHT)
	pass # Replace with function body.
func fireMissile():     # 自機ミサイル発射
	if missile == null:
		UFOPntIX += 1
		if UFOPntIX == UFO_POINTS.size():
			UFOPntIX = 0
		missile = Missile.instantiate()
		missile.position = $Fighter.position
		#print(missile.position)
		#bullet.position.x += 6
		add_child(missile)
		##$AudioMissile.play()
func processMissile():              # 自機ミサイル処理
	if missile != null:
		if missile.position.y < 0:  # 画面上部に出た場合
			missile.queue_free()
			missile = null
		else:
			var bc = missile.move_and_collide(mv)
			#print(bc)
			##if bc != null:      # 敵機に当たった場合
			##	missile.queue_free()
			##	missile = null
			##	if bc.collider == $UFO:         # UFO に当たった場合
			##		$UFOLabel.rect_position.x = $UFO.position.x
			##		$UFOLabel.text = "%d" % UFO_POINTS[UFOPntIX]
			##		$UFOLabel/Timer.start()
			##		$UFO.position.x = -1
			##		#print("UFO")
			##		score += UFO_POINTS[UFOPntIX]
			##		updateScoreLabel()
			##	else:
			##		remove_enemy(bc.collider)   # 撃墜した敵機を削除, score更新
			##		bc.collider.queue_free()
			##	$AudioMissile.stop()        # ミサイル発射音停止
			##	$AudioExplosion.play()      # 爆発音
			##	updateScoreLabel()
			##	if nEnemies == 0:       # 敵をすべて撃破した場合
			##		paused = true
			##		$NextLevel.show()
			##		#level += 1
			##		#setup_enemies()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _physics_process(delta):
	if move_fighter == KEY_LEFT:
		$Fighter.position.x -= delta * FIGHTER_MOVE_UNIT
		$Fighter.position.x = max(MIN_FIGHTER_X, $Fighter.position.x)
	elif move_fighter == KEY_RIGHT:
		$Fighter.position.x += delta * FIGHTER_MOVE_UNIT
		$Fighter.position.x = min(MAX_FIGHTER_X, $Fighter.position.x)
	if missile != null:     # 自機ミサイル飛翔中
		processMissile()
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


func _on_left_button_button_down():
	move_fighter = KEY_LEFT
func _on_left_button_button_up():
	move_fighter = 0
func _on_right_button_button_down():
	move_fighter = KEY_RIGHT
func _on_right_button_button_up():
	move_fighter = 0


func _on_fire_button_button_down():
	fireMissile()       # 自機ミサイル発射
