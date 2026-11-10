extends GdUnitTestSuite
## Synthesized music: exact loop length, audible, within range, deterministic.

const RATE := 4000


func test_loop_length_and_level() -> void:
	for v in ["hub", "game"]:
		var buf := MusicSynth.render(v, RATE)
		assert_int(buf.size()).is_equal(int(round(MusicSynth.loop_seconds() * RATE)))
		var peak := 0.0
		var energy := 0.0
		for x in buf:
			peak = maxf(peak, absf(x))
			energy += x * x
		assert_float(peak).is_less_equal(0.851)
		assert_float(sqrt(energy / buf.size())).is_greater(0.05)


func test_render_is_deterministic() -> void:
	var first := MusicSynth.render("game", RATE)
	var second := MusicSynth.render("game", RATE)
	assert_bool(first == second).is_true()
	assert_bool(MusicSynth.render("hub", RATE) == MusicSynth.render("game", RATE)).is_false()


func test_pcm_is_16_bit_mono() -> void:
	var buf := MusicSynth.render("hub", RATE)
	assert_int(MusicSynth.to_pcm16(buf).size()).is_equal(buf.size() * 2)
