class_name RushHud
extends Control
## Rush overlay: a compact strip on the left under the hole panel (one row per golfer: colour dot,
## name, stroke count, status) and the hole / match result cards. Original layout: no top bar of
## avatars, no chest screens. Colour is never the only cue: every row also has a name and a word.

signal again

const ROW_H := 62.0
const STRIP_W := 430.0

var _rows: Array[Dictionary] = []
var _card: PanelContainer
var _card_title: Label
var _card_body: Label
var _again: Button


func build(top: float, names: PackedStringArray, colors: Array) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in names.size():
		var row := Panel.new()
		row.add_theme_stylebox_override("panel", UiKit.box(Color(0.02, 0.06, 0.1, 0.55), 22))
		row.position = Vector2(24, top + 166 + i * (ROW_H + 8))
		row.size = Vector2(STRIP_W, ROW_H)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		var dot := Panel.new()
		dot.add_theme_stylebox_override("panel", UiKit.box(colors[i], 14))
		dot.position = Vector2(16, 17)
		dot.size = Vector2(28, 28)
		row.add_child(dot)
		var name := UiKit.label(names[i], 30, Color.WHITE, 800)
		name.position = Vector2(58, 10)
		row.add_child(name)
		var status := UiKit.label("", 26, Color(1, 1, 1, 0.8), 600)
		status.position = Vector2(172, 14)
		row.add_child(status)
		var count := UiKit.label("", 30, Color.WHITE, 900)
		count.position = Vector2(STRIP_W - 64, 10)
		count.size = Vector2(48, 40)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(count)
		_rows.append({"row": row, "status": status, "count": count})
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override(
		"panel", UiKit.box(Color(0.05, 0.08, 0.14, 0.92), 36, Color(1, 1, 1, 0.12), 3, 40)
	)
	_card.position = Vector2(90, 560)
	_card.custom_minimum_size = Vector2(900, 0)
	_card.visible = false
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	_card.add_child(col)
	_card_title = UiKit.label("", 60, UiKit.GOLD, 900)
	_card_title.custom_minimum_size = Vector2(820, 0)
	_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_card_title)
	_card_body = UiKit.label("", 36, Color.WHITE, 600)
	_card_body.custom_minimum_size = Vector2(820, 0)
	_card_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_card_body)
	_again = UiKit.button("Play again", UiKit.GREEN, Color.WHITE, 40, 120)
	_again.pressed.connect(func() -> void: again.emit())
	col.add_child(_again)


## Row texts: what each golfer is doing, and their strokes on this hole (right). `thinking(i)`
## -> bool for CPU golfers.
func update(rush: RushMatch, thinking: Callable) -> void:
	for i in _rows.size():
		var t := ""
		match rush.state[i]:
			RushMatch.State.HOLED:
				t = "in the cup"
			RushMatch.State.OUT:
				t = "out of strokes"
			RushMatch.State.MOVING:
				t = "rolling"
			_:
				if i == 0:
					t = "your shot"
				else:
					t = "thinking…" if thinking.call(i) else "lining up"
		if rush.hole_winner >= 0:
			t = "WINS!" if rush.hole_winner == i else ""
		(_rows[i].status as Label).text = t
		(_rows[i].count as Label).text = str(rush.strokes[i])


func show_hole(rush: RushMatch) -> void:
	var w := rush.hole_winner
	if w < 0:
		_card_title.text = "No winner this hole"
	elif w == 0:
		_card_title.text = "You win the hole!"
	else:
		_card_title.text = "%s wins the hole" % rush.names[w]
	_card_body.text = (
		"Hole %d of %d · %s" % [rush.hole_number + 1, rush.holes.size(), _score_line(rush)]
	)
	_again.visible = false
	_pop()


func show_match(rush: RushMatch) -> void:
	var w := rush.winner()
	if w == 0:
		_card_title.text = "You win the match!"
	elif w < 0:
		_card_title.text = "It's a draw"
	else:
		_card_title.text = "%s wins the match" % rush.names[w]
	var lines := PackedStringArray()
	var place := 1
	for i in rush.standings():
		lines.append(
			(
				"%d. %s   %d hole%s · %d strokes"
				% [
					place,
					rush.names[i],
					rush.wins[i],
					"" if rush.wins[i] == 1 else "s",
					rush.total[i]
				]
			)
		)
		place += 1
	_card_body.text = "\n".join(lines)
	_again.visible = true
	_pop()


func hide_card() -> void:
	_card.visible = false


func _score_line(rush: RushMatch) -> String:
	var parts := PackedStringArray()
	for i in rush.players():
		parts.append("%s %d" % [rush.names[i], rush.wins[i]])
	return "  ".join(parts)


func _pop() -> void:
	_card.visible = true
	_card.reset_size()
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2(0.85, 0.85)
	_card.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	tw.tween_property(_card, "modulate:a", 1.0, 0.2)
