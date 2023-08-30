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

var Missile = load("res://missile.tscn")
var Bunker8 = load("res://bunker_8.tscn")
var Enemy1 = load("res://enemy_1.tscn")
var EnemyMissile = load("res://enemy_missile.tscn")
#var Explosion = load("res://explosion.tscn")

var gameOver = false
var paused = false
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
	#print("KEY_LEFT = ", KEY_LEFT)
	#print("KEY_RIGHT = ", KEY_RIGHT)
	setup_enemies()
	setup_bunkers()
	pass # Replace with function body.
func setup_enemies():
	print("level = ", level)
	$UFO.position.x = -1        # UFO を画面外に移動
	nEnemies = ENEMY_N_HORZ * ENEMY_N_VERT      # 初期敵機数
	enemies.resize(ENEMY_N_HORZ * ENEMY_N_VERT)     # 敵機配列をリサイズ
	for y in range(ENEMY_N_VERT):   # 
		# 敵機 y 座標
		var py = (ENEMY_N_VERT - 1 - y + min(level, 4)) * ENEMY_V_PITCH + ENEMY_Y0
		for x in range(ENEMY_N_HORZ):
			var px = x * ENEMY_H_PITCH + ENEMY_X0   # 敵機 x 座標
			var enemy = Enemy1.instantiate()           # 敵機インスタンス作成
			enemy.position = Vector2(px, py)        # 敵機位置設定
			enemy.get_node("Sprite2D").frame = y & 0x1e   # 敵機画像設定
			add_child(enemy)                        # 敵機ノードを画面に追加
			var ix : int = x+y*ENEMY_N_HORZ;        # ix: 敵機通し番号
			enemies[ix] = enemy                     # 敵機ノードを配列で管理
			enemy.set("aryix", ix)      # 敵機ノードプロパティに通し番号追加
			#print(enemy.get("aryix"))
			#print(enemies[ix].get("aryix"))
func setup_bunkers():
	for ix in range(bunkers.size()):
		bunkers[ix].queue_free()
	bunkers = []
	for x in range(4):
		var bkr = Bunker8.instantiate()
		bkr.position = Vector2((x+1)*100, 580)
		add_child(bkr)
		bunkers.push_back(bkr)
func fireEnemyMissile():
	if gameOver || exploding || paused || !nEnemies:
		return
	var r = randi() % nEnemies      # ミサイルを発射する敵
	var ix = 0
	while ix < enemies.size():
		while enemies[ix] == null:  # 空要素はスキップ
			ix += 1
		if r == 0:
			break
		ix += 1
		if ix == enemies.size(): ix = 0
		r -= 1
	if enemies[ix] != null:
		var em = EnemyMissile.instantiate()
		em.position = enemies[ix].position
		em.position.y += ENEMY_MISSILE_OFFSET
		add_child(em)
		while !enemyMissiles.is_empty() && enemyMissiles[0] == null:
			enemyMissiles.pop_front()       # 空要素削除
		enemyMissiles.push_back(em)
	pass
func updateLeftFighter():
	$FrameLayer/NFighter.text = "%d" % nFighter
	$FrameLayer/ReserveFighter1.set_visible(nFighter>1)
	$FrameLayer/ReserveFighter2.set_visible(nFighter>2)
func clearAllMissiles():
	for em in enemyMissiles:
		if em != null:
			em.queue_free()
	enemyMissiles.clear()   
func explodeFighter():
	$Fighter/Sprite2D.hide()
	$Fighter/Explosion.global_position = $Fighter.position
	$Fighter/Explosion.restart()
	exploding = true
	clearAllMissiles();     # 敵ミサイル消去
	dur_expl = 0.0
	nFighter -= 1
	if nFighter == 0:       # 自機：０、ゲームオーバー
		gameOver = true
		$DlgLayer/GameOverDlg.window_title = "GodotShooting"
		$DlgLayer/GameOverDlg.dialog_text = "GAME OVER\nTRY AGAIN ?"
		$DlgLayer/GameOverDlg.popup_centered()
	updateLeftFighter()
	#clearAllMissiles()
	if missile != null:
		missile.queue_free()    # 自機ミサイル消去
		missile = null
func processEnemyMissiles():
	var ix = 0
	for em in enemyMissiles:
		if em != null:
			var bc = em.move_and_collide(emv)
			if bc != null && !exploding:
				if bc.get_collider() == $Fighter:     # 自機に命中
					explodeFighter()
					return
				else:
					bc.get_collider().queue_free()
				em.queue_free()
				enemyMissiles[ix] = null
			elif em.position.y >= 700:
				em.queue_free()
				enemyMissiles[ix] = null
		ix += 1
	pass
func fireMissile():     # 自機ミサイル発射
	if missile == null:
		UFOPntIX += 1
		if UFOPntIX == UFO_POINTS.size():
			UFOPntIX = 0
		missile = Missile.instantiate()
		#var pos = $Fighter.position
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
			if bc != null:      # 敵機に当たった場合
				missile.queue_free()
				missile = null
				if bc.get_collider() == $UFO:         # UFO に当たった場合
					$UFOLabel.position.x = $UFO.position.x
					$UFOLabel.text = "%d" % UFO_POINTS[UFOPntIX]
					$UFOLabel/Timer.start()
					$UFO.position.x = -1
					#print("UFO")
					score += UFO_POINTS[UFOPntIX]
					updateScoreLabel()
				else:
					remove_enemy(bc.get_collider())   # 撃墜した敵機を削除, score更新
					bc.get_collider().queue_free()
			##	$AudioMissile.stop()        # ミサイル発射音停止
			##	$AudioExplosion.play()      # 爆発音
				updateScoreLabel()
				if nEnemies == 0:       # 敵をすべて撃破した場合
					paused = true
					$NextLevel.show()
					#level += 1
					#setup_enemies()
func remove_enemy(ptr):     # 撃墜した敵機を削除
	for ix in range(enemies.size()):
		if enemies[ix] == ptr:
	#var ix : int = ptr.get("aryix")
			var pnt = floor(ix / (ENEMY_N_HORZ*2)) + 1
			score += pnt * 10
			enemies[ix] = null
			nEnemies -= 1
			return
func load_hi_score():
	hi_score = 0
	##var f = File.new()
	##if f.file_exists(HI_SCORE_FN):
	##	var err = f.open(HI_SCORE_FN, File.READ)
	##	if err == OK:
	##		hi_score = f.get_32()
	##	f.close()
func save_hi_score():
	##var f = File.new()
	##var err = f.open(HI_SCORE_FN, File.WRITE)
	##if err == OK:
	##	f.store_32(hi_score)
	##f.close()
	pass
func updateHiScoreLabel():
	var txt = "%05d" % hi_score
	$FrameLayer/HiScore.text = txt
func updateScoreLabel():
	var txt = "%05d" % score
	$FrameLayer/Score.text = txt
	if score > hi_score:
		hi_score = score
		updateHiScoreLabel()
		save_hi_score()
func animateEnemies():  # 敵アニメーション処理
	if gameOver || paused:
		return
	for y in range(ENEMY_N_VERT):
		for x in range(ENEMY_N_HORZ):
			var ix = x+y*ENEMY_N_HORZ
			if enemies[ix] != null:
				var node = enemies[ix].get_node("Sprite")
				#var fr : int = node.frame
				#fr ^= 1
				#print(node.frame)
				node.frame ^= 1
				#print(node.frame)
func next_enemy(ix):        # 次に移動する敵機 ix を取得
	while nEnemies != 0:    # 敵機が残っている間
		ix += 1
		if ix == ENEMY_N_HORZ * ENEMY_N_VERT:   # 最後の敵機を超えた場合
			if move_down:   # 全部の敵機が下に移動した場合
				move_down = false
			elif en_collied:        # 左右端に達している場合
				en_collied = false
				move_right = !move_right    # 左右移動方向反転
				move_down = true            # 下移動フラグON
			ix = 0
		if enemies[ix] != null:     # ix の敵機が生きている場合
			break
	return ix
func moveEnemies():     # 敵移動処理
	if gameOver || paused:      # ゲームオーバー、ポーズ時は移動しない
		return
	if enemies[mv_ix] != null:      # 次の敵機が存在していれば
		if move_down:               # 下方向移動
			enemies[mv_ix].position.y += ENEMY_V_PITCH / 2
		elif move_right:            # 右方向移動
			enemies[mv_ix].position.x += ENEMY_MOVE_UNIT
			if enemies[mv_ix].position.x >= MAX_ENEMY_X:
				en_collied = true;  # 右端に達した → フラグON
		else:                       # 左方向移動
			enemies[mv_ix].position.x -= ENEMY_MOVE_UNIT
			if enemies[mv_ix].position.x <= MIN_ENEMY_X:
				en_collied = true;  # 左端に達した → フラグON
		if enemies[mv_ix].position.y >= MAX_ENEMY_Y:    # 侵略された場合
			invaded = true
	mv_ix = next_enemy(mv_ix)       # 次の移動敵機取得
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
func _physics_process(delta):
	if gameOver || paused:
		return
	if exploding:       # 爆発中
		dur_expl += delta
		if dur_expl >= 2.0 && nFighter != 0:
			exploding = false
			$Fighter/Sprite2D.show()
		else:
			return
	if $UFO.position.x > 0:     # UFO 出現中
		$UFO.position.x -= UFO_MOVE_UNIT*delta
		#$UFO/Sprite.frame ^= 1
	var px = $Fighter.position.x
	if move_fighter == KEY_LEFT:
		$Fighter.position.x -= delta * FIGHTER_MOVE_UNIT
		$Fighter.position.x = max(MIN_FIGHTER_X, $Fighter.position.x)
	elif move_fighter == KEY_RIGHT:
		$Fighter.position.x += delta * FIGHTER_MOVE_UNIT
		$Fighter.position.x = min(MAX_FIGHTER_X, $Fighter.position.x)
	#if px != $Fighter.position.x:
	#	$Fighter/Explosion.global_position = $Fighter.position
	#	print("$Fighter.position.x = ", $Fighter.position.x)
	#	print("exp.pos = ", $Fighter/Explosion.global_position)
	if missile != null:     # 自機ミサイル飛翔中
		processMissile()
	processEnemyMissiles()      # 敵ミサイル処理
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
			if kc == KEY_SPACE:
				fireMissile()       # 自機ミサイル発射
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
func _on_enemy_move_timer_timeout():
	moveEnemies()       # 敵機移動
func _on_enemy_missile_timer_timeout():
	fireEnemyMissile()
func _on_ufo_timer_timeout():
	$UFO.position.x = SCREEN_WIDTH			# UFO出現
func _on_UFOLabelTimer_timeout():
	$UFOLabel.text = ""						# UFO得点消去


