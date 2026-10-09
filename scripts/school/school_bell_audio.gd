extends RefCounted
## Procedural placeholder bell; no external audio download or import required.
static func create_stream() -> AudioStreamWAV:
	const RATE := 22050
	const SECONDS := 1.6
	var samples := int(RATE * SECONDS)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for index in samples:
		var t := float(index) / RATE
		var strike := fmod(t, 0.4)
		var envelope := minf(strike / 0.004, 1.0) * exp(-strike * 12.0)
		var sample := (sin(TAU * 860.0 * t) + 0.45 * sin(TAU * 1376.0 * t) + 0.2 * sin(TAU * 2193.0 * t)) * envelope * 0.45
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream
