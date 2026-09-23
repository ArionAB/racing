# -*- coding: utf-8 -*-
# Construieste docs/track_briefs/img/fiordland_map.html („Fiordland Recon") din
# sablonul tools/fiordland_recon_template.html + datele REALE:
#   - traseul si scurtatura din scenes/tracks/Track16.tscn (Catmull-Rom, cu cote),
#   - planul adnotat docs/track_briefs/img/fiordland_plan.png (inline, base64),
#   - prompturile §9 / §9.1 din docs/track_briefs/fiordland.md (o singura sursa).
# Rulare din radacina repo-ului:  python tools/build_fiordland_recon.py
import base64, json, math, re

ROOT = "./"
tscn = open(ROOT + "scenes/tracks/Track16.tscn", encoding="utf-8").read()
brief = open(ROOT + "docs/track_briefs/fiordland.md", encoding="utf-8").read()
tpl = open(ROOT + "tools/fiordland_recon_template.html", encoding="utf-8").read()


def curve_points(res_id):
    blk = tscn[tscn.index('id="%s"' % res_id):]
    arr = re.search(r'"points": PackedVector3Array\(([^)]*)\)', blk).group(1)
    v = [float(x) for x in arr.split(",")]
    v = [v[i:i + 9] for i in range(0, len(v), 9)]
    return [(p[6], p[7], p[8]) for p in v]


def catmull(pts, closed, steps):
    out = []
    n = len(pts)
    rng = range(n) if closed else range(n - 1)
    for i in rng:
        p0 = pts[(i - 1) % n] if closed else pts[max(i - 1, 0)]
        p1 = pts[i]
        p2 = pts[(i + 1) % n] if closed else pts[min(i + 1, n - 1)]
        p3 = pts[(i + 2) % n] if closed else pts[min(i + 2, n - 1)]
        for s in range(steps):
            t = s / steps
            q = []
            for k in range(3):
                a, b, c, d = p0[k], p1[k], p2[k], p3[k]
                q.append(0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t ** 3))
            out.append([round(q[0], 1), round(q[1], 1), round(q[2], 1)])
    if not closed:
        out.append([round(v, 1) for v in pts[-1]])
    return out


loop = catmull(curve_points("Curve3D_fiordland"), True, 3)
branch = catmull(curve_points("Curve3D_scurtatura_chasm"), False, 6)
data = {"loop": loop, "branch": branch}

img = base64.b64encode(open(ROOT + "docs/track_briefs/img/fiordland_plan.png", "rb").read()).decode("ascii")


def quoted_block(start_marker, end_marker):
    i = brief.index(start_marker)
    j = brief.index(end_marker, i) if end_marker else len(brief)
    lines = brief[i:j].split("\n")
    out = []
    for l in lines:
        if l.startswith("> "):
            out.append(l[2:])
        elif l == ">":
            out.append("")
    return "\n".join(out).strip()


diorama = quoted_block("## 9. Prompt pentru ChatGPT", "### 9.1 Prompt")
sheet = quoted_block("### 9.1 Prompt", None)


def esc(t):
    return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


html = (tpl.replace("__DATA__", json.dumps(data, separators=(",", ":")))
        .replace("__PLAN_IMG__", "data:image/png;base64," + img)
        .replace("__DIORAMA_PROMPT__", esc(diorama))
        .replace("__SHEET_PROMPT__", esc(sheet)))
out = ROOT + "docs/track_briefs/img/fiordland_map.html"
open(out, "w", encoding="utf-8", newline="\n").write(html)
print("scris", out, len(html) // 1024, "KB; loop", len(loop), "branch", len(branch))
