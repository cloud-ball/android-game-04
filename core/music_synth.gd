class_name MusicSynth
extends RefCounted
## Original background music, synthesized in code (no audio files or licences needed).
## An 8-bar loop at 112 BPM over a minor i-VI-III-VII progression, in two mixes:
##   "hub"  - pad + soft arpeggio + light bass
##   "game" - adds drums, a busier arpeggio and a driving bass line
## Deterministic: same variant + rate -> identical samples (tested).

const VERSION := 1
const BPM := 112.0
const BARS := 8
## Chords as MIDI notes: bass root, then three chord tones.
const CHORDS := [[45, 57, 60, 64], [41, 53, 57, 60], [48, 60, 64, 67], [43, 55, 59, 62]]
const ARP_A := [0, 1, 2, 1, 0, 1, 2, 3, 0, 1, 2, 1, 3, 2, 1, 2]
const ARP_B := [0, 2, 3, 2, 1, 2, 3, 2, 0, 3, 2, 3, 1, 3, 2, 1]


static func loop_seconds() -> float:
	return BARS * 4.0 * 60.0 / BPM


## Mono samples in -1..1, exactly one loop long.
static func render(variant: String, rate: int) -> PackedFloat32Array:
	var n := int(round(loop_seconds() * rate))
	var buf := PackedFloat32Array()
	buf.resize(n)
	var beat := 60.0 / BPM
	var game := variant == "game"
	for bar in BARS:
		var ch: Array = CHORDS[bar % CHORDS.size()]
		var t0 := bar * 4.0 * beat
		for v in 3:
			_note(buf, rate, t0, 4.0 * beat, _hz(ch[v + 1] - 12), 0.05, "pad")
		var arp: Array = ARP_A if bar < 4 or not game else ARP_B
		for s in 16:
			var idx: int = arp[s]
			var midi: int = ch[1 + mini(idx, 2)] + (12 if idx == 3 else 0) + 12
			var amp := (0.11 if game else 0.07) * (1.0 if s % 4 == 0 else 0.75)
			_note(buf, rate, t0 + s * beat / 4.0, beat * 0.45, _hz(midi), amp, "pluck")
		var bass_steps := 8 if game else 2
		for s in bass_steps:
			var octave := 12 if game and s % 4 == 2 else 0
			var note_len := beat * (0.45 if game else 1.8)
			var t := t0 + s * 4.0 * beat / bass_steps
			_note(buf, rate, t, note_len, _hz(ch[0] + octave), 0.22 if game else 0.16, "bass")
		if game:
			for b in 4:
				_kick(buf, rate, t0 + b * beat, 0.55)
				_hat(buf, rate, t0 + (b + 0.5) * beat, 0.06, bar * 4 + b)
			_snare(buf, rate, t0 + beat, 0.2, bar)
			_snare(buf, rate, t0 + 3.0 * beat, 0.2, bar + 50)
			_kick(buf, rate, t0 + 3.5 * beat, 0.35)
	_normalize(buf, 0.85)
	return buf


static func to_pcm16(buf: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	return bytes


static func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## Adds one note; samples past the loop end wrap to the start so the loop is seamless.
static func _note(
	buf: PackedFloat32Array, rate: int, t: float, dur: float, hz: float, amp: float, kind: String
) -> void:
	var n := buf.size()
	var start := int(t * rate)
	var count := int(dur * rate)
	var w := TAU * hz / rate
	for i in count:
		var x := float(i) / count
		var ph := w * i
		var v := 0.0
		match kind:
			"pad":
				var env := minf(1.0, x * 6.0) * minf(1.0, (1.0 - x) * 4.0)
				v = (sin(ph) + 0.5 * sin(ph * 1.003 + 1.0) + 0.25 * sin(ph * 2.0)) * env
			"pluck":
				v = (sin(ph) + 0.33 * sin(ph * 3.0)) * exp(-x * 5.0) * minf(1.0, i / 40.0)
			_:
				v = (sin(ph) + 0.3 * sin(ph * 2.0)) * exp(-x * 2.5) * minf(1.0, i / 60.0)
		buf[(start + i) % n] += v * amp


static func _kick(buf: PackedFloat32Array, rate: int, t: float, amp: float) -> void:
	var n := buf.size()
	var start := int(t * rate)
	var count := int(0.22 * rate)
	var ph := 0.0
	for i in count:
		var x := float(i) / count
		ph += TAU * lerpf(150.0, 45.0, sqrt(x)) / rate
		buf[(start + i) % n] += sin(ph) * pow(1.0 - x, 2.0) * amp


static func _snare(
	buf: PackedFloat32Array, rate: int, t: float, amp: float, seed_value: int
) -> void:
	_noise(buf, rate, t, 0.16, amp, seed_value, 0.5)
	var n := buf.size()
	var start := int(t * rate)
	for i in int(0.08 * rate):
		var x := i / (0.08 * rate)
		buf[(start + i) % n] += sin(TAU * 190.0 * i / rate) * (1.0 - x) * amp * 0.6


static func _hat(buf: PackedFloat32Array, rate: int, t: float, amp: float, seed_value: int) -> void:
	_noise(buf, rate, t, 0.04, amp, seed_value * 7 + 3, 0.95)


## Decaying noise; `bright` 0..1 is a crude high-pass (more = thinner, hat-like).
static func _noise(
	buf: PackedFloat32Array,
	rate: int,
	t: float,
	dur: float,
	amp: float,
	seed_value: int,
	bright: float
) -> void:
	var n := buf.size()
	var start := int(t * rate)
	var count := int(dur * rate)
	var state := (seed_value * 2654435761 + 1) & 0x7fffffff
	var low := 0.0
	for i in count:
		state = (state * 1103515245 + 12345) & 0x7fffffff
		var white := float(state) / 0x7fffffff * 2.0 - 1.0
		low = lerpf(low, white, 0.3)
		var v := lerpf(low, white - low, bright)
		buf[(start + i) % n] += v * pow(1.0 - float(i) / count, 3.0) * amp


static func _normalize(buf: PackedFloat32Array, peak: float) -> void:
	var m := 0.0
	for v in buf:
		m = maxf(m, absf(v))
	if m <= 0.0:
		return
	var k := peak / m
	for i in buf.size():
		buf[i] *= k
