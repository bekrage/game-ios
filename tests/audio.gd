extends SceneTree
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
 var game = load("res://scenes/Main.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 check(game.music.playing, "background music starts")
 check(game.music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "music loops")
 check(game.music.stream.get_length() > 10, "full music phrase")
 for name in ["bubble","jump","capture","pop","hurt","clear","victory","game_over"]:
  check(game.sound_bank[name].get_length() > 0.05, name + " PCM loaded")
 game._sfx("bubble")
 check(game.audio.playing and game.music.playing, "effects coexist with music")
 game._toggle_mute()
 check(not game.audio.playing and not game.music.playing, "mute stops both channels")
 game._toggle_mute()
 check(game.music.playing, "unmute restarts music")
 game._toggle_pause()
 check(game.music.stream_paused, "pause suspends music")
 game._toggle_pause()
 check(not game.music.stream_paused, "resume continues music")
 game.audio.stop()
 game.music.stop()
 await create_timer(0.15).timeout
 game.free()
 await create_timer(0.15).timeout
 print("AUDIO %d CHECKS PASSED" % checks)
 quit()
