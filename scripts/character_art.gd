extends RefCounted
# Original procedural arcade artwork. Coordinates share the gameplay collision centres.
static func oval(c: Node2D, p: Vector2, r: Vector2, color: Color, border: Color = Color.TRANSPARENT) -> void:
 var points := PackedVector2Array()
 for i in range(32):
  var a := TAU * i / 32.0
  points.append(p + Vector2(cos(a), sin(a)) * r)
 c.draw_colored_polygon(points, color)
 if border.a > 0:
  points.append(points[0])
  c.draw_polyline(points, border, 2.4, true)

static func eye(c: Node2D, p: Vector2, direction: float, sleepy: bool = false) -> void:
 oval(c, p, Vector2(6.4, 8.5), Color("fff9e7"), Color("243049"))
 if sleepy:
  c.draw_line(p + Vector2(-4,0), p + Vector2(4,0), Color("243049"), 2.5, true)
 else:
  oval(c, p + Vector2(direction * 2,1), Vector2(2.7,4.7), Color("243049"))
  c.draw_circle(p + Vector2(direction * 2 - 1,-1), 1.2, Color.WHITE)

static func hero(c: Node2D, pos: Vector2, direction: int, clock: float, walking: bool, jumping: bool, blowing: bool) -> void:
 var ink := Color("202842")
 var step := sin(clock * 11) * (4.0 if walking else 0.6)
 var bob := absf(sin(clock*11)) * (1.5 if walking else 0.3)
 c.draw_set_transform(pos + Vector2(0,-bob),0,Vector2(direction,1))
 # Scuffed boots and mismatched trousers.
 oval(c,Vector2(-12,22-step),Vector2(12,6),Color("41415c"),ink)
 oval(c,Vector2(12,22+step),Vector2(13,6),Color("41415c"),ink)
 c.draw_line(Vector2(-13,9),Vector2(-12,21-step),Color("ca9877"),9,true)
 c.draw_line(Vector2(9,9),Vector2(12,21+step),Color("987d99"),9,true)
 # Ragged violet jacket, cream undershirt, patch and buttons.
 c.draw_colored_polygon(PackedVector2Array([Vector2(-18,-12),Vector2(16,-12),Vector2(20,15),Vector2(10,11),Vector2(5,16),Vector2(-4,12),Vector2(-15,16),Vector2(-20,10)]),ink)
 c.draw_colored_polygon(PackedVector2Array([Vector2(-16,-10),Vector2(14,-10),Vector2(17,11),Vector2(9,8),Vector2(4,12),Vector2(-4,9),Vector2(-15,12)]),Color("9f88d9"))
 c.draw_colored_polygon(PackedVector2Array([Vector2(-2,-11),Vector2(9,-11),Vector2(6,12),Vector2(-2,11)]),Color("fff0bf"))
 c.draw_line(Vector2(-5,-9),Vector2(-8,7),Color("7152a2"),3,true)
 c.draw_circle(Vector2(10,0),1.7,Color("ffcd79"))
 c.draw_rect(Rect2(-16,1,7,7),Color("77d9bb"))
 # Reaching zombie arms animate in opposite phase.
 oval(c,Vector2(-20,-3-step*.35),Vector2(7,10),Color("9f88d9"),ink)
 oval(c,Vector2(19,-1+step*.35),Vector2(10,6),Color("9f88d9"),ink)
 oval(c,Vector2(27,-2+step*.35),Vector2(7,5),Color("80dbb5"),ink)
 # Oversized rounded head and ears, with mint skin rather than gore.
 oval(c,Vector2(-21,-22),Vector2(5,7),Color("64bfa3"),ink)
 oval(c,Vector2(3,-24),Vector2(24,24),Color("8ce2ba"),ink)
 oval(c,Vector2(8,-14),Vector2(17,12),Color("a7ebc7"))
 c.draw_colored_polygon(PackedVector2Array([Vector2(-21,-33),Vector2(-22,-44),Vector2(-13,-42),Vector2(-12,-50),Vector2(-4,-43),Vector2(3,-49),Vector2(7,-43),Vector2(15,-46),Vector2(22,-35),Vector2(11,-37),Vector2(1,-33),Vector2(-9,-38)]),ink)
 # One big eye and one sleepy eye.
 eye(c,Vector2(12,-25),1)
 eye(c,Vector2(-5,-24),1,true)
 c.draw_line(Vector2(-14,-33),Vector2(-6,-31),Color("4c977f"),2,true)
 for x in [-13,-10,-7]:
  c.draw_line(Vector2(x,-35),Vector2(x-1,-30),Color("4c977f"),1.4,true)
 oval(c,Vector2(20,-12),Vector2(4,2),Color("f39cac"))
 if blowing:
  oval(c,Vector2(24,-10),Vector2(5,5),ink)
 else:
  c.draw_arc(Vector2(9,-10),9,0.1,2.8,12,ink,2.5,true)
  c.draw_rect(Rect2(7,-4,4,5),Color("fff9e7"))
 # A forehead bandage.
 c.draw_line(Vector2(-1,-39),Vector2(10,-36),Color("ffedc5"),5,true)
 if jumping:
  c.draw_line(Vector2(-14,32),Vector2(-17,39),Color("b5f7e9"),2,true)
 c.draw_set_transform(Vector2.ZERO)

static func monster(c: Node2D, pos: Vector2, kind: int, direction: int, clock: float, trapped: bool = false) -> void:
 var outline := Color("302c50")
 var colors := [Color("f887a7"),Color("ac98ef"),Color("ffc66d"),Color("75cee4")]
 var t := clock * 6
 var bounce := sin(t) * 2
 c.draw_set_transform(pos,0,Vector2(0.68,0.68) if trapped else Vector2.ONE)
 if kind == 1:
  # Plum bat: animated wings and pointed ears.
  var flap := sin(t)*8
  for side in [-1,1]:
   c.draw_colored_polygon(PackedVector2Array([Vector2(side*14,-8),Vector2(side*40,-22+flap),Vector2(side*34,6),Vector2(side*19,13)]),outline)
   c.draw_colored_polygon(PackedVector2Array([Vector2(side*17,-7),Vector2(side*35,-16+flap),Vector2(side*30,2),Vector2(side*19,8)]),Color("7965c4"))
   c.draw_colored_polygon(PackedVector2Array([Vector2(side*8,-16),Vector2(side*17,-36),Vector2(side*22,-12)]),colors[kind])
 elif kind == 2:
  # Tangerine horned beetle.
  for side in [-1,1]:
   c.draw_colored_polygon(PackedVector2Array([Vector2(side*10,-15),Vector2(side*18,-33),Vector2(side*24,-10)]),Color("fff0bd"))
 elif kind == 3:
  # Aqua jelly: springy tentacles and a tiny crown.
  for i in range(4):
   oval(c,Vector2(-15+i*10,18+sin(t+i)*4),Vector2(6,10),Color("489fbf"),outline)
  for i in range(3):
   c.draw_line(Vector2(-9+i*9,-20),Vector2(-13+i*13,-32+(i%2)*-4),Color("ffe399"),4,true)
 if kind != 3:
  oval(c,Vector2(-12,20+sin(t)*3),Vector2(10,5),Color("65517b"),outline)
  oval(c,Vector2(12,20-sin(t)*3),Vector2(10,5),Color("65517b"),outline)
 oval(c,Vector2(0,bounce),Vector2(23,23),colors[kind],outline)
 oval(c,Vector2(-8,-10+bounce),Vector2(9,6),colors[kind].lightened(0.18))
 if kind == 2:
  for i in range(3):
   oval(c,Vector2(-12+i*12,12),Vector2(3,2),Color("e48a54"))
 eye(c,Vector2(-8,-5+bounce),direction,trapped)
 eye(c,Vector2(8,-5+bounce),direction,trapped)
 oval(c,Vector2(-16,7),Vector2(4,2.5),Color("f480a3"))
 oval(c,Vector2(16,7),Vector2(4,2.5),Color("f480a3"))
 if trapped:
  oval(c,Vector2(0,10),Vector2(3,4),outline)
 else:
  c.draw_arc(Vector2(0,6),6,0.2,2.9,12,outline,2,true)
 c.draw_set_transform(Vector2.ZERO)
