extends Node2D

const Art = preload("res://scripts/character_art.gd")

const W := 1280.0
const H := 720.0
const FLOOR := 610.0
const GRAV := 1500.0
const SPEED := 310.0
const JUMP := -650.0
var player := Vector2(130, FLOOR - 26)
var vel := Vector2.ZERO
var facing := 1
var stage := 1
var score := 0
var lives := 3
var enemies: Array[Dictionary] = []
var bubbles: Array[Dictionary] = []
var keys := {"left":false,"right":false,"jump":false,"fire":false}
var touch_actions: Dictionary = {}
var fire_timer := 0.0
var invuln := 0.0
var audio: AudioStreamPlayer
var music: AudioStreamPlayer
var finished := false
var paused := false
var muted := false
var platforms: Array[Rect2] = []
var keyboard := {"left":false,"right":false,"jump":false,"fire":false}
var stage_banner := 0.0
var animation_clock := 0.0
var particles: Array[Dictionary] = []
var sound_bank: Dictionary = {}
const STAGE_NAMES := ["Lantern Lobby", "Moonlit Cellar", "Candy Crypt", "Velvet Attic", "Clockwork Hall", "Crystal Vault", "Ghost Terrace", "Violet Chapel", "Pumpkin Parade", "Midnight Rooftop"]
const PALETTES := ["15243f", "173b40", "40263f", "242448", "403325", "183c51", "24435a", "35204f", "462a32", "173d37"]

func _ready() -> void:
 audio = AudioStreamPlayer.new()
 add_child(audio)
 music = AudioStreamPlayer.new()
 add_child(music)
 for sound in ["bubble","jump","capture","pop","hurt","clear","victory","game_over"]:
  sound_bank[sound] = load("res://assets/audio/" + sound + ".wav")
 var tune := load("res://assets/audio/garden_loop.wav") as AudioStreamWAV
 tune.loop_mode = AudioStreamWAV.LOOP_FORWARD
 tune.loop_begin = 0
 tune.loop_end = tune.data.size() / 2
 music.stream = tune
 music.volume_db = -7.0
 music.play()
 _load_stage()

func _load_stage() -> void:
 stage_banner = 2.0
 invuln = 1.8
 fire_timer = 0.0
 platforms.clear()
 # One-way ledges: every layout has reachable steps (rise <= 120).
 for n in range(3 + stage % 3):
  var x := 260.0 + float(n % 3) * 300.0 + float((stage * 37) % 80)
  var y := 490.0 - float(n / 3) * 120.0
  platforms.append(Rect2(x, y, 200 - stage * 3, 16))
 particles.clear()
 enemies.clear()
 bubbles.clear()
 player = Vector2(130, FLOOR - 26)
 vel = Vector2.ZERO
 for i in range(2 + stage):
  enemies.append({"pos":Vector2(570 + (i % 5) * 128, FLOOR - 23 - (i / 5) * 160),"dir":-1 if i % 2 == 0 else 1,"trapped":false,"phase":float(i),"kind":i % 4,"lane":i % (platforms.size() + 1)})
 queue_redraw()

func _physics_process(delta: float) -> void:
 if finished or paused:
  return
 animation_clock += delta
 for i in range(particles.size()-1,-1,-1):
  particles[i]["life"] -= delta
  particles[i]["pos"] += particles[i]["vel"] * delta
  particles[i]["vel"].y += 250 * delta
  if particles[i]["life"] <= 0:
   particles.remove_at(i)
 stage_banner = maxf(0.0, stage_banner - delta)
 fire_timer = maxf(0.0, fire_timer - delta)
 invuln = maxf(0.0, invuln - delta)
 var axis := int(keys["right"]) - int(keys["left"])
 vel.x = axis * SPEED
 if axis != 0:
  facing = axis
 if keys["jump"] and _grounded():
  vel.y = JUMP
  _sfx("jump")

 var old_bottom := player.y + 26
 vel.y += GRAV * delta
 player += vel * delta
 player.x = clampf(player.x, 28, W - 28)
 if vel.y >= 0:
  for ledge in platforms:
   if old_bottom <= ledge.position.y + 1 and player.y + 26 >= ledge.position.y and player.x > ledge.position.x - 16 and player.x < ledge.end.x + 16:
    player.y = ledge.position.y - 26
    vel.y = 0
 if player.y > FLOOR - 26:
  player.y = FLOOR - 26
  vel.y = 0
 if keys["fire"] and fire_timer <= 0:
  fire_timer = 0.32
  bubbles.append({"pos":player + Vector2(facing * 33, -8),"dir":facing,"life":2.6,"enemy":-1})
  _sfx("bubble")
 for i in range(enemies.size()):
  var e := enemies[i]
  if e["trapped"]:
   continue
  var p: Vector2 = e["pos"]
  p.x += float(e["dir"]) * (85 + stage * 9) * delta
  var left := 365.0
  var right := W - 35
  var ground := FLOOR
  if int(e["lane"]) < platforms.size():
   var ledge := platforms[int(e["lane"])]
   left = ledge.position.x + 22
   right = ledge.end.x - 22
   ground = ledge.position.y
  if p.x < left or p.x > right:
   e["dir"] = -int(e["dir"])
  p.x = clampf(p.x, left, right)
  e["phase"] += delta * 3
  p.y = ground - 23 - absf(sin(float(e["phase"]))) * (22 + stage * 2)
  e["pos"] = p
  enemies[i] = e
  if invuln <= 0 and player.distance_to(p) < 40:
   lives -= 1
   invuln = 1.8
   vel.y = -380
   _sfx("hurt")
   _burst(player, Color("ffc9a3"))
   if lives <= 0:
    finished = true
    _sfx("game_over")
    music.stop()
 for bi in range(bubbles.size() - 1, -1, -1):
  var b := bubbles[bi]
  b["life"] -= delta
  var bp: Vector2 = b["pos"]
  bp += Vector2(float(b["dir"]) * 115 * delta, -75 * delta)
  b["pos"] = bp
  if int(b["enemy"]) == -1:
   for ei in range(enemies.size()):
    if not enemies[ei]["trapped"] and bp.distance_to(enemies[ei]["pos"]) < 43:
     b["enemy"] = ei
     enemies[ei]["trapped"] = true
     b["life"] = 3.2
     _sfx("capture")
     _burst(bp, Color("b9faff"))
     break
  else:
   var ei: int = b["enemy"]
   if ei < enemies.size():
    enemies[ei]["pos"] = bp
   if player.distance_to(bp) < 48:
    enemies.remove_at(ei)
    bubbles.remove_at(bi)
    for bj in range(bubbles.size()):
     if int(bubbles[bj]["enemy"]) > ei:
      bubbles[bj]["enemy"] -= 1
    score += 100
    _sfx("pop")
    _burst(bp, Color("fff1a6"))
    continue
  if b["life"] <= 0 or bp.y < 55 or bp.x < 15 or bp.x > W - 15:
   if int(b["enemy"]) >= 0 and int(b["enemy"]) < enemies.size():
    enemies[int(b["enemy"])]["trapped"] = false
   bubbles.remove_at(bi)
  else:
   bubbles[bi] = b
 if enemies.is_empty():
  stage += 1
  if stage > 10:
   finished = true
   _sfx("victory")
   music.stop()
  else:
   _load_stage()
   _sfx("clear")
 queue_redraw()

func _draw() -> void:
 draw_rect(Rect2(0, 0, W, H), Color(PALETTES[mini(stage,10) - 1]))
 _draw_cavern()
 for i in range(45):
  draw_circle(Vector2(float((i * 233 + 39) % 1280), float((i * 117 + 73) % 490)), 2.0, Color("566f98"))
 draw_rect(Rect2(0, FLOOR, W, 110), Color("366f64"))
 draw_rect(Rect2(0, FLOOR, W, 13), Color("69c69b"))
 for i in range(11):
  draw_rect(Rect2(i * 120 + 15, FLOOR + 40, 70, 8), Color("28584f"))
 _txt(Vector2(25, 50), "BUBBLE ZOMBIE", 32, Color("91f6d0"))
 _txt(Vector2(470, 50), "STAGE %02d / 10" % mini(stage, 10), 28, Color.WHITE)
 _txt(Vector2(790, 50), "SCORE %05d" % score, 28, Color.WHITE)
 _txt(Vector2(1080, 50), "LIFE %d" % lives, 28, Color("ffb2aa"))
 for ledge in platforms:
  draw_style_box(_ledge_style(), ledge)
 if stage_banner > 0:
  _txt(Vector2(450, 110), STAGE_NAMES[mini(stage,10)-1], 30, Color("91f6d0"))
 _txt(Vector2(390, 696), "Capture, then touch the bubble to pop!", 20, Color("bce4ed"))
 _txt(Vector2(450, 82), "PAUSE" if not paused else "RESUME", 18, Color.WHITE)
 _txt(Vector2(690, 82), "SOUND OFF" if muted else "SOUND ON", 18, Color.WHITE)
 for e in enemies:
  if e["trapped"]:
   continue
  var ep: Vector2 = e["pos"]
  Art.oval(self,ep+Vector2(0,25),Vector2(20,4),Color(0.02,0.04,0.10,0.25))
  Art.monster(self,ep,int(e.get("kind",int(e["lane"])%4)),int(e["dir"]),animation_clock+float(e["phase"]))
 for b in bubbles:
  var bp: Vector2 = b["pos"]
  var shimmer := sin(animation_clock*4 + bp.x)*0.08
  draw_circle(bp,29,Color(0.4,0.9,1.0,0.12+shimmer))
  draw_arc(bp,29,0,TAU,48,Color("adf0ff"),2.5,true)
  draw_arc(bp,26,0.3,2.1,18,Color("ffbfe8"),2,true)
  draw_arc(bp,27,3.1,4.6,18,Color("c9ffe1"),3,true)
  draw_circle(bp+Vector2(-10,-13),5,Color(1,1,1,0.8))
  draw_circle(bp+Vector2(-17,-5),2,Color.WHITE)
  if int(b["enemy"]) >= 0 and int(b["enemy"]) < enemies.size():
   var caught := enemies[int(b["enemy"])]
   Art.monster(self,bp,int(caught.get("kind",0)),1,animation_clock,true)
 Art.oval(self,Vector2(player.x,player.y+27),Vector2(24,4),Color(0.02,0.04,0.1,0.35))
 if invuln <= 0 or int(animation_clock*10) % 2 == 0:
  Art.hero(self,player,facing,animation_clock,absf(vel.x)>1,not _grounded(),fire_timer>0.2)
 for bit in particles:
  var bp: Vector2 = bit["pos"]
  var tint: Color = bit["color"]
  tint.a = clampf(float(bit["life"])*2,0,1)
  draw_line(bp-Vector2(3,0),bp+Vector2(3,0),tint,2,true)
  draw_line(bp-Vector2(0,3),bp+Vector2(0,3),tint,2,true)
 _button(Vector2(92, 647), 55, "<", "left")
 _button(Vector2(220, 647), 55, ">", "right")
 _button(Vector2(1010, 647), 55, "JUMP", "jump")
 _button(Vector2(1155, 647), 55, "BUBBLE", "fire")
 if paused:
  draw_rect(Rect2(330, 240, 620, 170), Color(0.05,0.08,0.15,0.95))
  _txt(Vector2(480, 310), "PAUSED", 48, Color.WHITE)
  _txt(Vector2(420, 365), "Tap RESUME / press P", 28, Color.WHITE)
 if finished:
  draw_rect(Rect2(270, 225, 740, 230), Color(0.05,0.08,0.15,0.93))
  _txt(Vector2(400, 310), "YOU WIN!" if stage > 10 else "GAME OVER", 55, Color("91f6d0"))
  _txt(Vector2(375, 385), "TAP SCREEN TO RESTART", 32, Color.WHITE)

func _txt(p: Vector2, s: String, size: int, color: Color) -> void:
 draw_string(ThemeDB.fallback_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _button(p: Vector2, r: float, label: String, action: String) -> void:
 draw_circle(p, r, Color(0.3,0.65,0.85,0.42 if keys[action] else 0.22))
 draw_arc(p, r, 0, TAU, 40, Color("8ad9f4"), 3)
 var fs := 20 if label.length() > 2 else 38
 var width := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
 _txt(p + Vector2(-width / 2, fs / 3), label, fs, Color.WHITE)

func _action_at(p: Vector2) -> String:
 for item in [{"p":Vector2(92,647),"a":"left"},{"p":Vector2(220,647),"a":"right"},{"p":Vector2(1010,647),"a":"jump"},{"p":Vector2(1155,647),"a":"fire"}]:
  if p.distance_to(item["p"]) < 65:
   return item["a"]
 return ""

func _input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  _menu_at(event.position)
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
   _toggle_pause()
  if event.keycode == KEY_M:
   _toggle_mute()
 if event is InputEventScreenTouch:
  if event.pressed and _menu_at(event.position):
   return
  if finished and event.pressed:
   stage = 1
   score = 0
   lives = 3
   finished = false
   if not muted:
    music.play()
   _clear_input()
   _load_stage()
   return
  if event.pressed:
   touch_actions[event.index] = _action_at(event.position)
  else:
   touch_actions.erase(event.index)
  _refresh_touch()
 elif event is InputEventScreenDrag:
  touch_actions[event.index] = _action_at(event.position)
  _refresh_touch()
 elif event is InputEventKey:
  if event.keycode == KEY_LEFT or event.keycode == KEY_A:
   keyboard["left"] = event.pressed
  elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
   keyboard["right"] = event.pressed
  elif event.keycode == KEY_SPACE or event.keycode == KEY_UP:
   keyboard["jump"] = event.pressed
  elif event.keycode == KEY_X:
   keyboard["fire"] = event.pressed
  elif finished and event.pressed and event.keycode == KEY_ENTER:
   stage = 1
   score = 0
   lives = 3
   finished = false
   if not muted:
    music.play()
   _clear_input()
   _load_stage()
  _refresh_touch()

func _refresh_touch() -> void:
 for a in keys.keys():
  keys[a] = keyboard[a] or a in touch_actions.values()

func _sfx(sound: String) -> void:
 if muted or not sound_bank.has(sound):
  return
 audio.stream = sound_bank[sound]
 audio.play()

func _burst(pos: Vector2, tint: Color) -> void:
 for i in range(10):
  var angle := TAU*i/10.0
  particles.append({"pos":pos,"vel":Vector2(cos(angle),sin(angle))*125,"life":0.55,"color":tint})

func _draw_cavern() -> void:
 # Chunky masonry, soft halo windows and hanging lanterns.
 for row in range(7):
  for col in range(11):
   var x := col*128.0 + (64 if row%2 else 0)
   draw_rect(Rect2(x,row*72.0+110,124,68),Color(0.4,0.55,0.7,0.025))
 for i in range(6):
  var p := Vector2(100+i*220,190+int(i%2)*70)
  Art.oval(self,p,Vector2(56,76),Color(0.12,0.22,0.32,0.35))
  Art.oval(self,p,Vector2(42,62),Color(0.2,0.4,0.5,0.07))
  draw_line(p+Vector2(0,-60),p+Vector2(0,60),Color("27394d"),4)
  draw_line(p+Vector2(-40,0),p+Vector2(40,0),Color("27394d"),4)
 for side in [45,1235]:
  draw_line(Vector2(side,105),Vector2(side,240),Color("456174"),3,true)
  draw_circle(Vector2(side,250),24,Color(1.0,0.75,0.35,0.06))
  Art.oval(self,Vector2(side,250),Vector2(8,13),Color("ffdb8c"))
  draw_arc(Vector2(side,250),14,0,TAU,20,Color("638b96"),3,true)

func _grounded() -> bool:
 if absf(player.y + 26 - FLOOR) < 1:
  return true
 for ledge in platforms:
  if absf(player.y + 26 - ledge.position.y) < 1 and player.x > ledge.position.x - 16 and player.x < ledge.end.x + 16:
   return true
 return false

func _ledge_style() -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = Color("52627f")
 style.border_color = Color("92e9c7")
 style.border_width_top = 4
 style.corner_radius_top_left = 6
 style.corner_radius_top_right = 6
 return style

func _clear_input() -> void:
 touch_actions.clear()
 for action in keyboard:
  keyboard[action] = false
 _refresh_touch()

func _toggle_pause() -> void:
 if finished:
  return
 paused = not paused
 _clear_input()
 music.stream_paused = paused
 queue_redraw()

func _toggle_mute() -> void:
 muted = not muted
 if muted:
  music.stop()
  audio.stop()
 elif not finished:
  music.play()
  music.stream_paused = paused
 queue_redraw()

func _menu_at(p: Vector2) -> bool:
 if Rect2(430, 56, 150, 38).has_point(p):
  _toggle_pause()
  return true
 if Rect2(675, 56, 150, 38).has_point(p):
  _toggle_mute()
  return true
 return false

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
  _clear_input()
  if not paused and not finished:
   _toggle_pause()

func _exit_tree() -> void:
 if is_instance_valid(audio):
  audio.stop()
  audio.stream = null
 if is_instance_valid(music):
  music.stop()
  music.stream = null
