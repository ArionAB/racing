extends Node
## Amprenta temelor din Track.themes(): un hash per tema (var_to_str sortat pe chei),
## ca sa se dovedeasca BIT-IDENTITATEA temelor neatinse dupa o schimbare in track.gd.
##   godot --headless --path . res://tools/ProbeThemesHash.tscn

func _ready() -> void:
	var t := Track.new()
	var all: Dictionary = t.themes()
	var keys := all.keys()
	keys.sort()
	for k in keys:
		var d: Dictionary = all[k]
		var ks := d.keys()
		ks.sort()
		var s := ""
		for kk in ks:
			s += "%s=%s;" % [kk, var_to_str(d[kk])]
		print("TEMA %-16s %s" % [k, s.sha256_text()])
	t.free()
	get_tree().quit(0)
