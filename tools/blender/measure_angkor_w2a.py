"""Garzi Angkor, val 2, grupul A -- terasa elefantilor, stalpul, statuia, radacina-rampa.

    python tools/blender/measure_angkor_w2a.py terrace <module.glb> [<end.glb>]
    python tools/blender/measure_angkor_w2a.py pillar <glb>
    python tools/blender/measure_angkor_w2a.py statue <glb>
    python tools/blender/measure_angkor_w2a.py ramp <glb>
    python tools/blender/measure_angkor_w2a.py --selftest <module.glb> <ramp.glb>

Citeste GLB-ul EXPORTAT (coordonate GODOT: Y sus, Blender +Y = Godot -Z).
Contracte (kit §1.4):
  * terasa: nimic peste Y = 4,0 (+0,02): drumul e pe coama; modulul L = 8,0 pe Z, capetele
    plane la Z = +-4,0 si IDENTICE (aceeasi sectiune); grosime <= 1,5; capatul: L 6-8, capatul
    de sud (Z maxim) cu aceeasi sectiune ca modulul; noduri Terrace_Stone/Lichen/Streak;
  * rampa: latime >= 7,0, inaltime 1,2 +-0,05, lungime 6-8 (+0,05); planul de rulare (|x| <= 3,5):
    inaltimea suprafetei de sus, esantionata pe grila prin raze, se potriveste pe UN plan cu
    abatere <= 0,05; panta <= 20% (urca spre -Z); inclinare laterala <= 2%; niciun varf de
    triunghi peste plan cu > 0,05 in banda; un singur nod `Root_Ramp`, slot 19.
Iese cu cod 1 la incalcare. `--selftest`: copii sabotate (bula pe rampa, terasa ridicata cu
0,3 m, rampa mai abrupta) care TREBUIE sa pice.
"""
import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify_glb import load_glb  # noqa: E402
from measure_angkor import slot_areas, _write_glb  # noqa: E402
from measure_angkor_w1a import world_tris, _edit_positions  # noqa: E402

TOP_MAX = 4.0
BAND = 3.5


def basics(path):
    g, blob = load_glb(path)[:2]
    tris = world_tris(g, blob)
    pts = [p for t in tris for p in t]
    names = sorted((n.get("name") or "").split(".")[0] for n in g["nodes"] if "mesh" in n)
    kids = {c for n in g["nodes"] for c in n.get("children", [])}
    xform = []
    for i, n in enumerate(g["nodes"]):
        if i in kids:
            continue
        s = n.get("scale", [1, 1, 1])
        r = n.get("rotation", [0, 0, 0, 1])
        if any(abs(v - 1) > 1e-4 for v in s) or any(abs(r[k]) > 1e-4 for k in range(3)):
            xform.append(n.get("name"))

    def ext(a):
        return (min(p[a] for p in pts), max(p[a] for p in pts))
    return dict(tris=tris, pts=pts, x=ext(0), y=ext(1), z=ext(2), names=names, xform=xform)


def section(m, z_end, tol=0.002):
    """Multimea (x, y) a varfurilor din planul capatului Z = z_end."""
    return {(round(p[0], 2), round(p[1], 2)) for p in m["pts"] if abs(p[2] - z_end) < tol}


def common(m, nodes, bad):
    if m["names"] != sorted(nodes):
        bad.append("noduri %s, cerute %s" % (m["names"], sorted(nodes)))
    if m["xform"]:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % m["xform"])
    if abs(m["y"][0]) > 0.02:
        bad.append("min Y %.3f != 0 (originea la baza)" % m["y"][0])


def check_terrace(path, end=None, report=True):
    m = basics(path)
    L = m["z"][1] - m["z"][0]
    th = m["x"][1] - m["x"][0]
    h = m["y"][1]
    if report:
        print("modul     L %.3f  grosime %.3f  inaltime max %.3f (cerut <= %.2f)" % (L, th, h, TOP_MAX + 0.02))
    bad = []
    common(m, ["Terrace_Stone", "Terrace_Lichen", "Terrace_Streak"], bad)
    if h > TOP_MAX + 0.02:
        bad.append("ceva peste cota drumului: Y max %.3f > %.2f" % (h, TOP_MAX + 0.02))
    if h < TOP_MAX - 0.03:
        bad.append("coama sub 4,0: %.3f" % h)
    if abs(L - 8.0) > 0.02:
        bad.append("L %.3f != 8,0" % L)
    if th > 1.5 + 0.01:
        bad.append("grosime %.3f > 1,5" % th)
    s_a, s_b = section(m, m["z"][0]), section(m, m["z"][1])
    ends_ok = abs(m["z"][0] + 4.0) < 0.01 and abs(m["z"][1] - 4.0) < 0.01
    if not ends_ok or not s_a or s_a != s_b:
        bad.append("capetele nu sunt plane/identice la Z=+-4,0 (%d vs %d puncte)" % (len(s_a), len(s_b)))
    if report and ends_ok and s_a == s_b:
        print("capete    plane la Z=+-4,0, sectiune identica (%d puncte)" % len(s_a))
    if end and not bad:
        e = basics(end)
        Le = e["z"][1] - e["z"][0]
        if report:
            print("capat     L %.3f  inaltime max %.3f" % (Le, e["y"][1]))
        eb = []
        common(e, ["Terrace_Stone", "Terrace_Lichen", "Terrace_Streak"], eb)
        if e["y"][1] > TOP_MAX + 0.02:
            eb.append("capatul: Y max %.3f > 4,02" % e["y"][1])
        if not 6.0 <= Le <= 8.0 + 0.05:
            eb.append("capatul: L %.3f in afara 6-8" % Le)
        if e["x"][1] - e["x"][0] > 1.5 + 0.01:
            eb.append("capatul: grosime peste 1,5")
        se = section(e, e["z"][1])
        if se != s_b:
            eb.append("capatul de sud nu are sectiunea modulului (%d vs %d puncte)" % (len(se), len(s_b)))
        bad += eb
    if not bad:
        ar = slot_areas(path)
        tot = sum(ar.values())
        orange = sum(v for (n, s_), v in ar.items() if s_ == 30)
        ok_slots = {("Terrace_Stone", 3), ("Terrace_Lichen", 30), ("Terrace_Lichen", 12), ("Terrace_Streak", 20)}
        extra = sorted(k for k in ar if k not in ok_slots)
        if report:
            print("arii      %.1f m2, lichen portocaliu %.2f%%" % (tot, 100 * orange / tot))
        if orange / tot >= 0.03:
            bad.append("lichen portocaliu >= 3%")
        if extra:
            bad.append("sloturi in afara tabelului: %s" % extra)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def check_pillar(path, report=True):
    m = basics(path)
    w, d, h = m["x"][1] - m["x"][0], m["z"][1] - m["z"][0], m["y"][1]
    if report:
        print("stalp     %.3f x %.3f x %.3f" % (w, d, h))
    bad = []
    common(m, ["Pillar_Stone", "Pillar_Lichen", "Pillar_Streak"], bad)
    if not (1.5 <= w <= 1.7 and 1.5 <= d <= 1.7):
        bad.append("amprenta %.2f x %.2f != ~1,6 x 1,6" % (w, d))
    if abs(h - 4.0) > 0.05:
        bad.append("inaltime %.3f != 4,0 +-0,05" % h)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def check_statue(path, report=True):
    m = basics(path)
    w, d, h = m["x"][1] - m["x"][0], m["z"][1] - m["z"][0], m["y"][1]
    if report:
        print("statuie   %.3f x %.3f x %.3f" % (w, d, h))
    bad = []
    common(m, ["Statue_Stone", "Statue_Lichen", "Statue_Streak"], bad)
    if not 3.4 <= h <= 3.8:
        bad.append("inaltime totala %.3f (cerut ~3,6)" % h)
    if w > 2.6 or d > 2.6:
        bad.append("amprenta prea mare (%.2f x %.2f)" % (w, d))
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def top_height(tris, x, z):
    """Cea mai mare inaltime Y a suprafetei in punctul (x, z) (raza verticala)."""
    best = None
    for (a, b, c) in tris:
        if x < min(a[0], b[0], c[0]) - 1e-9 or x > max(a[0], b[0], c[0]) + 1e-9:
            continue
        if z < min(a[2], b[2], c[2]) - 1e-9 or z > max(a[2], b[2], c[2]) + 1e-9:
            continue
        d = (b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2])
        if abs(d) < 1e-12:
            continue
        l1 = ((b[2] - c[2]) * (x - c[0]) + (c[0] - b[0]) * (z - c[2])) / d
        l2 = ((c[2] - a[2]) * (x - c[0]) + (a[0] - c[0]) * (z - c[2])) / d
        l3 = 1 - l1 - l2
        if min(l1, l2, l3) < -1e-7:
            continue
        y = l1 * a[1] + l2 * b[1] + l3 * c[1]
        if best is None or y > best:
            best = y
    return best


def fit_plane(samples):
    """y = a*x + b*z + c prin cele mai mici patrate (sistem 3x3, Cramer)."""
    n = len(samples)
    sx = sum(s[0] for s in samples)
    sz = sum(s[1] for s in samples)
    sy = sum(s[2] for s in samples)
    sxx = sum(s[0] ** 2 for s in samples)
    szz = sum(s[1] ** 2 for s in samples)
    sxz = sum(s[0] * s[1] for s in samples)
    sxy = sum(s[0] * s[2] for s in samples)
    szy = sum(s[1] * s[2] for s in samples)
    M = [[sxx, sxz, sx], [sxz, szz, sz], [sx, sz, n]]
    R = [sxy, szy, sy]

    def det(A):
        return (A[0][0] * (A[1][1] * A[2][2] - A[1][2] * A[2][1])
                - A[0][1] * (A[1][0] * A[2][2] - A[1][2] * A[2][0])
                + A[0][2] * (A[1][0] * A[2][1] - A[1][1] * A[2][0]))
    D = det(M)
    out = []
    for k in range(3):
        A = [row[:] for row in M]
        for i in range(3):
            A[i][k] = R[i]
        out.append(det(A) / D)
    return out


def check_ramp(path, report=True):
    m = basics(path)
    w, L, h = m["x"][1] - m["x"][0], m["z"][1] - m["z"][0], m["y"][1] - m["y"][0]
    tris = m["tris"]
    samples = []
    for i in range(15):
        x = -BAND + 2 * BAND * i / 14.0
        for j in range(15):
            z = -3.4 + 6.8 * j / 14.0
            y = top_height(tris, x, z)
            if y is not None:
                samples.append((x, z, y))
    bad = []
    if len(samples) < 200:
        print("   !! suprafata de sus incompleta in banda (%d/225 esantioane)" % len(samples))
        return False
    a, b, c = fit_plane(samples)
    dev = max(abs(y - (a * x + b * z + c)) for x, z, y in samples)
    slope = (a * a + b * b) ** 0.5
    below = min(y - (a * x + b * z + c) for x, z, y in samples)
    above = max(p[1] - (a * p[0] + b * p[2] + c) for p in m["pts"] if abs(p[0]) <= BAND and abs(p[2]) <= 3.5)
    if report:
        print("rampa     latime %.3f  lungime %.3f  inaltime %.3f" % (w, L, h))
        print("planul    abatere max %.4f m (<=0,05)  panta %.1f%% (<=20)  lateral %.2f%%  "
              "varf peste plan max %.4f (<=0,05)  cel mai jos sub plan %.4f (>=-0,05)"
              % (dev, 100 * slope, 100 * abs(a), above, below))
    common(m, ["Root_Infill", "Root_Ramp", "Root_Stone"], bad)
    if below < -0.05:
        bad.append("gol in suprafata de rulare: %.3f m sub plan intre radacini (> 0,05)" % -below)
    if w < 7.0:
        bad.append("latime %.2f < 7,0" % w)
    if not 6.0 <= L <= 8.05:
        bad.append("lungime %.2f in afara 6-8" % L)
    if abs(h - 1.2) > 0.05:
        bad.append("inaltime %.3f != 1,2 +-0,05" % h)
    if dev > 0.05:
        bad.append("suprafata de rulare nu e un plan: abatere %.3f > 0,05" % dev)
    if slope > 0.20:
        bad.append("panta %.1f%% > 20%%" % (100 * slope))
    if b > -0.05:
        bad.append("rampa nu urca spre -Z (b=%.3f)" % b)
    if abs(a) > 0.02:
        bad.append("inclinare laterala %.1f%%" % (100 * abs(a)))
    if above > 0.05:
        bad.append("geometrie peste planul de rulare cu %.3f m in banda" % above)
    if not bad:
        ar = slot_areas(path)
        extra = sorted(k for k in ar if k not in {("Root_Ramp", 19), ("Root_Infill", 28), ("Root_Stone", 3)})
        if extra:
            bad.append("sloturi in afara tabelului: %s" % extra)
    for b_ in bad:
        print("   !! " + b_)
    return not bad


def selftest(module, ramp):
    ok = True
    tmp = tempfile.mkdtemp(prefix="angkor_w2a_sabotaj_")
    cases = []
    g0, blob0 = load_glb(module)[:2]
    g = json.loads(json.dumps(g0))
    cases.append(("terasa ridicata cu 0,3 m", "terrace", g,
                  _edit_positions(g, blob0, lambda x, y, z: (x, y + 0.3, z))))
    g1, blob1 = load_glb(ramp)[:2]

    def bump(x, y, z):
        if abs(x) < 1.3 and abs(z) < 1.3 and y > 0.3:
            return (x, y + 0.2 * max(0.0, 1 - (x * x + z * z) / 1.7), z)
        return (x, y, z)
    g = json.loads(json.dumps(g1))
    cases.append(("bula de 0,2 m pe suprafata rampei", "ramp", g, _edit_positions(g, blob1, bump)))
    def slot(x, y, z):
        if abs(x) < 0.26 and abs(z) < 3.3 and y > 0.3:
            return (x, y - 0.2 * (1 - abs(x) / 0.26), z)
        return (x, y, z)
    g = json.loads(json.dumps(g1))
    cases.append(("rost de 0,2 m adanc intre radacini", "ramp", g, _edit_positions(g, blob1, slot)))
    g = json.loads(json.dumps(g1))
    cases.append(("panta rampei mai abrupta (x1,4)", "ramp", g,
                  _edit_positions(g, blob1, lambda x, y, z: (x, y * 1.4, z))))
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, kind, g, blob in cases:
        p = os.path.join(tmp, "s.glb")
        _write_glb(p, g, blob)
        print("-- sabotaj: %s" % label)
        passed = check_terrace(p) if kind == "terrace" else check_ramp(p)
        if passed:
            print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
            ok = False
        else:
            print("   garda a picat, cum trebuie")
        os.remove(p)
    os.rmdir(tmp)
    print("-- originalele:")
    if not (check_terrace(module, report=False) and check_ramp(ramp, report=False)):
        print("   !! SELFTEST ESUAT: garda pica pe original")
        ok = False
    else:
        print("   originalele trec")
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    a = sys.argv[1:]
    if a and a[0] == "--selftest" and len(a) >= 3:
        sys.exit(0 if selftest(a[1], a[2]) else 1)
    if len(a) >= 2 and a[0] == "terrace":
        sys.exit(0 if check_terrace(a[1], a[2] if len(a) > 2 else None) else 1)
    if len(a) >= 2 and a[0] == "pillar":
        sys.exit(0 if check_pillar(a[1]) else 1)
    if len(a) >= 2 and a[0] == "statue":
        sys.exit(0 if check_statue(a[1]) else 1)
    if len(a) >= 2 and a[0] == "ramp":
        sys.exit(0 if check_ramp(a[1]) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
