extends SceneTree
var game
var checks := 0

func check(ok: bool, label: String) -> void:
 if not ok:
  printerr("FAIL: " + label)
  quit(1)
  return
 checks += 1
 print("PASS: " + label)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 game = load("res://scenes/Main.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game.muted = true
 for n in range(1, 11):
  game.stage = n
  game._load_stage()
  check(game.enemies.size() == n + 2, "stage %d enemy count" % n)
  check(game.platforms.size() >= 3, "stage %d platforms" % n)
  for frame in range(120):
   game._physics_process(1.0 / 60)
  check(not game.finished, "stage %d simulation" % n)
 game.stage = 1
 game._load_stage()
 game.keyboard.right = true
 game._refresh_touch()
 var old_x: float = game.player.x
 game._physics_process(0.1)
 check(game.player.x > old_x, "keyboard movement")
 game._clear_input()
 game.keyboard.jump = true
 game._refresh_touch()
 game._physics_process(0.016)
 check(game.vel.y < 0, "jump")
 game._clear_input()
 game.player = Vector2(400, 464)
 game.vel = Vector2(0, 100)
 game.platforms.assign([Rect2(300,490,200,16)])
 game._physics_process(0.016)
 check(game.player.y == 464 and game._grounded(), "one-way platform landing")
 game._load_stage()
 game.enemies.assign([{"pos":Vector2(800,580),"dir":1,"trapped":false,"phase":0.0,"lane":99}])
 game.bubbles.assign([{"pos":Vector2(800,580),"dir":1,"life":2.0,"enemy":-1}])
 game._physics_process(0.016)
 check(game.enemies[0].trapped, "bubble capture")
 game.bubbles[0].life = 0.001
 game._physics_process(0.016)
 check(not game.enemies[0].trapped and game.bubbles.is_empty(), "capture expiry releases enemy")
 game.enemies.append({"pos":Vector2(1000,580),"dir":1,"trapped":false,"phase":0.0,"lane":99})
 game.enemies[0].trapped = true
 game.bubbles.assign([{"pos":game.player,"dir":1,"life":2.0,"enemy":0}])
 var old_score: int = game.score
 game._physics_process(0.016)
 check(game.score == old_score + 100 and game.enemies.size() == 1, "pop captured enemy")
 game._toggle_pause()
 old_x = game.player.x
 game._physics_process(0.1)
 check(game.player.x == old_x, "pause freezes gameplay")
 game._toggle_pause()
 var touch := InputEventScreenTouch.new()
 touch.index = 0
 touch.position = Vector2(92,647)
 touch.pressed = true
 game._input(touch)
 touch = InputEventScreenTouch.new()
 touch.index = 1
 touch.position = Vector2(1155,647)
 touch.pressed = true
 game._input(touch)
 check(game.keys.left and game.keys.fire, "two-finger movement plus fire")
 touch.pressed = false
 game._input(touch)
 check(game.keys.left and not game.keys.fire, "independent finger release")
 game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(game.paused and not game.keys.left, "focus loss pauses and clears input")
 game._toggle_pause()
 game.stage = 1
 game._load_stage()
 game.lives = 1
 game.invuln = 0
 game.enemies.assign([{"pos":game.player,"dir":1,"trapped":false,"phase":0.0,"lane":99}])
 game.player = Vector2(500,580)
 game.enemies[0].pos = game.player
 game._physics_process(0.001)
 check(game.finished and game.lives == 0, "game over")
 var restart := InputEventKey.new()
 restart.keycode = KEY_ENTER
 restart.pressed = true
 game._input(restart)
 check(not game.finished and game.lives == 3 and game.stage == 1, "restart")
 for n in range(1,11):
  game.stage = n
  game.enemies.clear()
  game._physics_process(0.016)
  check(game.stage == n + 1, "clear stage %d" % n)
 check(game.finished and game.stage == 11, "ten-stage victory")
 game.free()
 print("ALL %d CHECKS PASSED" % checks)
 quit(0)
