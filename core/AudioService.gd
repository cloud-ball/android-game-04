extends Node
## Small synthesized sound effects (no audio files to license) + haptics. Respects settings.

const MIX_RATE := 22050
const VOICES := 6

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	_streams["tap"] = _tone([[880.0, 0.04]], 0.35)
	_streams["turn"] = _tone([[620.0, 0.025]], 0.18)
	_streams["eat"] = _tone([[660.0, 0.06], [990.0, 0.09]], 0.45)
	_streams["crash"] = _noise(0.45, 0.6)
	_streams["win"] = _tone([[523.0, 0.1], [659.0, 0.1], [784.0, 0.1], [1047.0, 0.25]], 0.45)
	_streams["lose"] = _tone([[440.0, 0.14], [349.0, 0.14], [262.0, 0.3]], 0.4)
	_streams["count"] = _tone([[740.0, 0.08]], 0.35)
	_streams["go"] = _tone([[1100.0, 0.18]], 0.4)


func play(name: String, pitch := 1.0) -> void:
	if not SettingsService.sound_on() or not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.pitch_scale = pitch
	p.play()


func buzz(ms: int) -> void:
	if SettingsService.haptics_on() and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


## notes: [[frequency_hz, seconds], ...] played back to back as soft square-ish blips.
static func _tone(notes: Array, gain: float) -> AudioStreamWAV:
	var total := 0
	for n in notes:
		total += int(n[1] * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(total * 2)
	var i := 0
	for n in notes:
		var count := int(n[1] * MIX_RATE)
		var freq: float = n[0]
		for s in count:
			var t := float(s) / MIX_RATE
			var env := minf(1.0, s / 60.0) * (1.0 - float(s) / count)
			var wave := sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)
			bytes.encode_s16(i * 2, int(clampf(wave * env * gain, -1.0, 1.0) * 32000.0))
			i += 1
	return _wav(bytes)


static func _noise(seconds: float, gain: float) -> AudioStreamWAV:
	var count := int(seconds * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var state := 22222
	var low := 0.0
	for s in count:
		state = (state * 1103515245 + 12345) & 0x7fffffff
		var white := float(state) / 0x7fffffff * 2.0 - 1.0
		low = lerpf(low, white, 0.25)
		var env := pow(1.0 - float(s) / count, 2.0)
		bytes.encode_s16(s * 2, int(clampf(low * env * gain * 2.0, -1.0, 1.0) * 32000.0))
	return _wav(bytes)


static func _wav(bytes: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = bytes
	return w
