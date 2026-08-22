extends Node
func _ready() -> void:
    var t := (load("res://scenes/tracks/Track11.tscn") as PackedScene).instantiate() as Track
    add_child(t)
    await get_tree().process_frame
    var sp = t._sampler
    var sea: float = sp.mean_road_y() + t.sea_level_offset
    print("SHORE: nivelul marii y = %.2f" % sea)
    var n := t.baked.size()
    for f in [0.05, 0.07, 0.09, 0.11]:
        var i := int(f * n) % n
        var p: Vector3 = t.baked[i]
        var j := (i + 4) % n
        var dir: Vector3 = t.baked[j] - p; dir.y = 0.0; dir = dir.normalized()
        var out := ""
        for sgn in [1.0, -1.0]:
            var side := Vector3(dir.z * sgn, 0.0, -dir.x * sgn)
            var found := -1.0
            for d in range(3, 260):
                var q: Vector3 = p + side * float(d)
                if sp.ground_y(q.x, q.z) <= sea + 0.3:
                    found = float(d); break
            out += "  %s=%s" % ["dr" if sgn > 0 else "st",
                ("%.0f m" % found) if found > 0 else ">258"]
        print("SHORE: frac %.2f  y=%.2f %s" % [f, p.y, out])
    get_tree().quit()
