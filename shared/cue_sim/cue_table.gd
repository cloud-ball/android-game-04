class_name CueTable
extends RefCounted
## Table geometry for the cue solver, built once from CueParams (64-bit packed arrays).
## Origin at the table centre, x across (short side), y along (long side). Cushions are line
## segments (rail noses and pocket facings) plus their end points (jaw tips); a pocket is a capture
## circle behind its mouth. Pockets: 0..3 corners (-x-y, +x-y, -x+y, +x+y), 4..5 sides (-x, +x).

## Facing directions (rotated away from the rail into the pocket): corner 38 deg, side 76 deg.
const COS38 := 0.7880107536067219
const SIN38 := 0.6156614753256583
const COS76 := 0.24192189559966767
const SIN76 := 0.9702957262759965
const INV_SQRT2 := 0.7071067811865476

## Segments: start (x, y), unit direction, length, unit normal pointing to the playing side.
var seg_x := PackedFloat64Array()
var seg_y := PackedFloat64Array()
var seg_dx := PackedFloat64Array()
var seg_dy := PackedFloat64Array()
var seg_len := PackedFloat64Array()
var seg_nx := PackedFloat64Array()
var seg_ny := PackedFloat64Array()
## Points (jaw tips and facing ends), collided with at distance = ball radius.
var pt_x := PackedFloat64Array()
var pt_y := PackedFloat64Array()
## Capture circles.
var pocket_x := PackedFloat64Array()
var pocket_y := PackedFloat64Array()
var pocket_r := PackedFloat64Array()
## Half sizes of the playfield.
var hw := 0.0
var hl := 0.0


func _init(p: CueParams = null) -> void:
	if p == null:
		p = CueParams.pool()
	hw = p.table_w * 0.5
	hl = p.table_l * 0.5
	var c := p.corner_mouth * INV_SQRT2  # distance from the corner to each jaw tip along a rail
	var half_side := p.side_mouth * 0.5
	for sx in [-1.0, 1.0]:
		# Long rails (x = sx * hw), split by the side pocket; normal points to the table centre.
		_segment(sx * hw, -(hl - c), sx * hw, -half_side, -sx, 0.0)
		_segment(sx * hw, half_side, sx * hw, hl - c, -sx, 0.0)
	for sy in [-1.0, 1.0]:
		_segment(-(hw - c), sy * hl, hw - c, sy * hl, 0.0, -sy)
	for sy in [-1.0, 1.0]:
		for sx in [-1.0, 1.0]:
			_corner_pocket(p, sx, sy, c)
	for sx in [-1.0, 1.0]:
		_side_pocket(p, sx, half_side)


func _segment(x0: float, y0: float, x1: float, y1: float, nx: float, ny: float) -> void:
	var dx := x1 - x0
	var dy := y1 - y0
	var length := sqrt(dx * dx + dy * dy)
	seg_x.append(x0)
	seg_y.append(y0)
	seg_dx.append(dx / length)
	seg_dy.append(dy / length)
	seg_len.append(length)
	seg_nx.append(nx)
	seg_ny.append(ny)


## A facing from a jaw tip into the pocket; its normal faces the pocket's axis (mouth centre).
func _facing(
	tx: float, ty: float, dx: float, dy: float, length: float, mx: float, my: float
) -> void:
	var nx := -dy
	var ny := dx
	if (mx - tx) * nx + (my - ty) * ny < 0.0:
		nx = -nx
		ny = -ny
	seg_x.append(tx)
	seg_y.append(ty)
	seg_dx.append(dx)
	seg_dy.append(dy)
	seg_len.append(length)
	seg_nx.append(nx)
	seg_ny.append(ny)
	pt_x.append(tx)
	pt_y.append(ty)
	pt_x.append(tx + dx * length)
	pt_y.append(ty + dy * length)


func _corner_pocket(p: CueParams, sx: float, sy: float, c: float) -> void:
	var mx := sx * (hw - c * 0.5)
	var my := sy * (hl - c * 0.5)
	# Tip on the long rail, facing turned 38 deg out of the rail line towards the outside.
	_facing(sx * hw, sy * (hl - c), sx * SIN38, sy * COS38, p.corner_facing, mx, my)
	# Tip on the short rail.
	_facing(sx * (hw - c), sy * hl, sx * COS38, sy * SIN38, p.corner_facing, mx, my)
	var d := p.corner_capture_depth * INV_SQRT2
	pocket_x.append(mx + sx * d)
	pocket_y.append(my + sy * d)
	pocket_r.append(p.corner_capture_radius)


func _side_pocket(p: CueParams, sx: float, half: float) -> void:
	var mx := sx * hw
	for sy in [-1.0, 1.0]:
		_facing(mx, sy * half, sx * SIN76, -sy * COS76, p.side_facing, mx, 0.0)
	pocket_x.append(mx + sx * p.side_capture_depth)
	pocket_y.append(0.0)
	pocket_r.append(p.side_capture_radius)


func segment_count() -> int:
	return seg_x.size()


func point_count() -> int:
	return pt_x.size()


func pocket_count() -> int:
	return pocket_x.size()
