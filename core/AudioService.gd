extends Node
## Synthesized sound effects and music (no audio files to license) + haptics. Respects settings.
## Music is rendered once on a worker thread (MusicSynth) and cached in user://.

const MIX_RATE := 22050
const MUSIC_RATE := 16000
const MUSIC_DB := -13.0
const VOICES := 6

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_streams: Dictionary = {}
var _music_wanted := ""
var _render_task := -1


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
	# Pool: short band-limited noise "knocks" with a faint body - real ball clicks are 2-4 ms of
	# broadband noise, not ringing tones (the earlier tonal version sounded like glass).
	# Event: [delay_s, centre_hz, q, decay_s, noise_amp, body_hz, body_decay_s, body_amp]
	_streams["clack"] = _knocks([[0.0, 2400.0, 1.1, 0.0032, 1.0, 1250.0, 0.0022, 0.35]], 0.05, 0.8)
	_streams["cushion"] = _knocks([[0.0, 320.0, 0.8, 0.028, 1.0, 150.0, 0.035, 0.6]], 0.16, 0.75)
	_streams["cue"] = _knocks([[0.0, 1500.0, 0.9, 0.006, 1.0, 650.0, 0.005, 0.4]], 0.06, 0.7)
	_streams["pocket"] = _knocks(
		[
			[0.0, 2100.0, 1.0, 0.003, 0.7, 1100.0, 0.002, 0.2],
			[0.024, 1800.0, 1.0, 0.003, 0.5, 950.0, 0.002, 0.15],
			[0.05, 240.0, 0.7, 0.06, 0.8, 105.0, 0.08, 1.0],
		],
		0.26,
		0.62
	)
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)
	SettingsService.changed.connect(_on_setting_changed)
	if DisplayServer.get_name() != "headless":
		_render_task = WorkerThreadPool.add_task(_render_music)


func _exit_tree() -> void:
	if _render_task != -1:
		WorkerThreadPool.wait_for_task_completion(_render_task)


## "hub" or "game"; "" stops the music. Starts as soon as the loop has been rendered.
func play_music(variant: String) -> void:
	_music_wanted = variant
	_apply_music()


func _apply_music() -> void:
	if _music_wanted == "" or not bool(SettingsService.get_value("music")):
		_music.stop()
		return
	var s: AudioStreamWAV = _music_streams.get(_music_wanted)
	if s == null or (_music.stream == s and _music.playing):
		return
	_music.stream = s
	_music.volume_db = -40.0
	_music.play()
	create_tween().tween_property(_music, "volume_db", MUSIC_DB, 0.8)


func _on_setting_changed(key: String, _value: Variant) -> void:
	if key == "music":
		_apply_music()


## Worker thread: pure computation + file IO only; results go back via call_deferred.
func _render_music() -> void:
	for v in ["hub", "game"]:
		var path := "user://music_v%d_%s.pcm" % [MusicSynth.VERSION, v]
		var bytes := PackedByteArray()
		if FileAccess.file_exists(path):
			bytes = FileAccess.get_file_as_bytes(path)
		if bytes.is_empty():
			bytes = MusicSynth.to_pcm16(MusicSynth.render(v, MUSIC_RATE))
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f != null:
				f.store_buffer(bytes)
				f.close()
		_music_ready.call_deferred(v, bytes)


func _music_ready(variant: String, bytes: PackedByteArray) -> void:
	var w := _wav(bytes, MUSIC_RATE)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = bytes.size() / 2
	_music_streams[variant] = w
	_apply_music()


## volume_db: e.g. scaled from impact speed so soft touches are quiet.
func play(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	if not SettingsService.sound_on() or not _streams.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[name]
	p.pitch_scale = pitch
	p.volume_db = volume_db
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


## Knocks: each event is white noise through a band-pass (biquad) with an exponential envelope,
## plus a quickly damped sine "body". Deterministic noise seed.
static func _knocks(events: Array, seconds: float, gain: float) -> AudioStreamWAV:
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var state := 777
	for e in events:
		var start := int(float(e[0]) * MIX_RATE)
		var w0: float = TAU * float(e[1]) / MIX_RATE
		var alpha: float = sin(w0) / (2.0 * float(e[2]))
		var a0 := 1.0 + alpha
		var b0 := alpha / a0
		var b2 := -alpha / a0
		var a1 := -2.0 * cos(w0) / a0
		var a2 := (1.0 - alpha) / a0
		var x1 := 0.0
		var x2 := 0.0
		var y1 := 0.0
		var y2 := 0.0
		for n in range(start, count):
			var t := float(n - start) / MIX_RATE
			state = (state * 1103515245 + 12345) & 0x7fffffff
			var x := float(state) / 0x7fffffff * 2.0 - 1.0
			var y := b0 * x + b2 * x2 - a1 * y1 - a2 * y2
			x2 = x1
			x1 = x
			y2 = y1
			y1 = y
			var noise: float = y * float(e[4]) * exp(-t / float(e[3])) * 3.0
			var body: float = float(e[7]) * sin(TAU * float(e[5]) * t) * exp(-t / float(e[6]))
			out[n] += (noise + body) * minf(1.0, t * MIX_RATE / 4.0)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for n in count:
		var fade := minf(1.0, (count - n) / 150.0)
		bytes.encode_s16(n * 2, int(clampf(out[n] * gain * fade, -1.0, 1.0) * 32000.0))
	return _wav(bytes)


static func _wav(bytes: PackedByteArray, rate := MIX_RATE) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	return w
