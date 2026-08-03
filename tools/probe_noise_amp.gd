extends SceneTree
## Sonda temporara: anvelopa reala a FBM-ului de dune, pentru calibrarea
## amplitudinii din TrackSideSampler._dunes (issue #96).

func _init() -> void:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.frequency = 0.005
	n.fractal_octaves = 3
	for s in [0, 2513, 4700]:
		n.seed = s
		var lo := INF
		var hi := -INF
		var sum_sq := 0.0
		var count := 0
		for gz in 200:
			for gx in 200:
				var v := n.get_noise_2d(float(gx) * 7.0 - 700.0, float(gz) * 7.0 - 700.0)
				lo = minf(lo, v)
				hi = maxf(hi, v)
				sum_sq += v * v
				count += 1
		print("seed %d: min %.3f max %.3f rms %.3f" % [s, lo, hi, sqrt(sum_sq / count)])
	quit()
