"""Garda grupului B, val 2: bolta, blocul dominoului, sprijinul restauratorilor.
Citeste GLB-ul EXPORTAT, in coordonate GODOT (Y sus, drumul pe Z, latimea pe X).

    python tools/blender/measure_angkor_w2b.py vault_intact <glb>
    python tools/blender/measure_angkor_w2b.py vault_broken <glb>
    python tools/blender/measure_angkor_w2b.py block <glb> [boulder_roller.glb]
    python tools/blender/measure_angkor_w2b.py prop <glb>
    python tools/blender/measure_angkor_w2b.py --selftest <intact> <broken> <block>

vault_intact: capetele la z = +-2,0; golul >= 6,6 in banda 0-3 m inaltime (masurat
  ca GOL: triunghiurile taiate pe banda, nu AABB), inaltimea libera la cheie
  (|x| < 0,3) >= 6,5 si EXISTA acoperis acolo.
vault_broken: capetele la +-2,0; acelasi gol; NICIUN triunghi in |x| in [0,5, 3,3]
  peste 5,0 m pe toata lungimea (taiat pe banda); niciun triunghi in |x| < 3,3 sub
  1,0 m (molozul sta doar pe margini).
block: anvelopa in +-10% fata de `rocks/boulder_roller.glb` x 0,5 (masurata din
  fisier, la fiecare rulare), amprenta X/Z (X/Y in Blender) cu raport <= 1,15.
prop: ~3 m inaltime (2,7-3,3), noduri Prop_Stone/Prop_Wood, lemn doar 9/28.

`--selftest`: copii sabotate IN MEMORIE (peretii la +-3,2; placa de acoperis care
inchide bolta daramata; un bloc de moloz pe drum; blocul scalat 1,3x) trebuie sa PICE;
originalele trebuie sa treaca.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from measure_angkor_w1b import (world_tris, gap_and_clear, extent, meta, _clip,  # noqa: E402
                                _box_tris, _move)
from measure_angkor import slot_areas  # noqa: E402

TOL = 1e-3
BAND = (0.0, 3.0)
HERE = os.path.dirname(os.path.abspath(__file__))
BOULDER = os.path.join(HERE, "..", "..", "assets", "models", "rocks", "boulder_roller.glb")
BOULDER_SCALE = 0.5
VAULT_NODES = ["Vault_Lichen", "Vault_Stone", "Vault_Streak"]
VAULT_SLOTS = {("Vault_Stone", 3), ("Vault_Lichen", 30), ("Vault_Lichen", 12), ("Vault_Streak", 20)}
BLOCK_NODES = ["Block_Lichen", "Block_Stone"]
BLOCK_SLOTS = {("Block_Stone", 3), ("Block_Lichen", 30), ("Block_Lichen", 12)}
PROP_NODES = ["Prop_Lichen", "Prop_Stone", "Prop_Wood"]
PROP_SLOTS = {("Prop_Stone", 3), ("Prop_Wood", 9), ("Prop_Wood", 28),
              ("Prop_Lichen", 30), ("Prop_Lichen", 12)}


def _band_points(tris, lo, hi):
    """Punctele poligoanelor taiate pe |x| in [lo, hi] (ambele parti), cu nodul lor."""
    out = []
    for name, tri in tris:
        for sgn in (1, -1):
            t = tuple((p[0] * sgn, p[1], p[2]) for p in tri)
            xs = [p[0] for p in t]
            if max(xs) < lo or min(xs) > hi:
                continue
            for p in _clip(list(t), 0, lo, hi):
                out.append((name, p))
    return out


def _common(tris, bad, report, label):
    r, l, _, _ = gap_and_clear(tris, 0.3, band=BAND)
    if report:
        print("%s gol: dreapta %.3f + stanga %.3f = %.3f m (banda %.1f-%.1f m)"
              % (label, r, l, r + l, BAND[0], BAND[1]))
    if r < 3.3 - TOL or l < 3.3 - TOL or r + l < 6.6 - TOL:
        bad.append("gol %.3f (dr %.3f, st %.3f) < 6,6 la 0-3 m" % (r + l, r, l))
    (x0, x1), (y0, y1), (z0, z1) = extent(tris)
    if report:
        print("         capete z [%.3f, %.3f]  x [%.2f, %.2f]  inaltime %.2f (min %.3f)" % (z0, z1, x0, x1, y1, y0))
    return (x0, x1), (y0, y1), (z0, z1)


def check_intact(tris, names=None, xform=None, slots=None, report=True):
    bad = []
    (x0, x1), (y0, y1), (z0, z1) = _common(tris, bad, report, "vault_intact")
    _, _, zc, who = gap_and_clear(tris, 0.3, band=BAND)
    if report:
        print("         inaltime libera la cheie (|x| < 0,3): %.2f m (%s)" % (zc, who))
    if zc > 1e8:
        bad.append("nu exista acoperis la cheie (modulul intact trebuie sa inchida bolta)")
    elif zc < 6.5:
        bad.append("inaltime libera la cheie %.2f < 6,5 (%s)" % (zc, who))
    if abs(z0 + 2.0) > 0.01 or abs(z1 - 2.0) > 0.01:
        bad.append("capetele z [%.3f, %.3f], cerute +-2,0" % (z0, z1))
    if abs(y0) > 0.02:
        bad.append("min Y %.3f != 0" % y0)
    if names is not None and names != VAULT_NODES:
        bad.append("noduri %s, cerute %s" % (names, VAULT_NODES))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    _slots(slots, VAULT_SLOTS, bad, report)
    for b in bad:
        print("   !! " + b)
    return not bad


def check_broken(tris, names=None, xform=None, slots=None, report=True):
    bad = []
    (x0, x1), (y0, y1), (z0, z1) = _common(tris, bad, report, "vault_broken")
    # nimic in banda de cadere a blocurilor, peste 5 m
    hi = [(n, p) for n, p in _band_points(tris, 0.5, 3.3 - TOL) if p[1] > 5.0 + TOL]
    top_in_band = max([p[1] for _, p in _band_points(tris, 0.5, 3.3 - TOL)] or [0.0])
    # moloz pe drum: orice punct din |x| < 3,3 sub 1 m
    low = [(n, p) for n, p in _band_points(tris, 0.0, 3.3 - TOL) if p[1] < 1.0]
    if report:
        print("         cel mai inalt punct in |x| in [0,5, 3,3]: %.2f m (cerut <= 5,0)" % top_in_band)
        print("         puncte in |x| < 3,3 sub 1,0 m: %d (cerut 0)" % len(low))
    if hi:
        bad.append("%d puncte in |x| in [0,5, 3,3] peste 5,0 m (max %.2f, %s): acoperisul nu e deschis"
                   % (len(hi), max(p[1] for _, p in hi), hi[0][0]))
    if low:
        bad.append("%d puncte in |x| < 3,3 sub 1,0 m (%s): moloz pe banda"
                   % (len(low), low[0][0]))
    # capetele: peretii ating +-2,0; nimic nu depaseste cu mai mult de 0,1 (moloz in afara peretilor)
    wall = extent(tris, ["Vault_Stone"])
    if report:
        print("         capete peretilor: z [%.3f, %.3f]" % (wall[2][0], wall[2][1]))
    zs = [p[2] for n, t in tris for p in t if n == "Vault_Stone" and 3.3 <= abs(p[0]) <= 4.4]
    if not zs or abs(min(zs) + 2.0) > 0.01 or abs(max(zs) - 2.0) > 0.01:
        bad.append("peretii nu ating capetele +-2,0 (%s)" % ([min(zs), max(zs)] if zs else "gol"))
    if z0 < -2.0 - 0.05 or z1 > 2.0 + 0.05:
        bad.append("moloz peste capete: z [%.3f, %.3f] (cerut +-2,0, toleranta 0,05)" % (z0, z1))
    if abs(y0) > 0.02:
        bad.append("min Y %.3f != 0" % y0)
    if names is not None and names != VAULT_NODES:
        bad.append("noduri %s, cerute %s" % (names, VAULT_NODES))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    _slots(slots, VAULT_SLOTS, bad, report)
    for b in bad:
        print("   !! " + b)
    return not bad


def _slots(slots, allowed, bad, report):
    if slots is None:
        return
    tot = sum(slots.values())
    orange = sum(v for (n, s_), v in slots.items() if s_ == 30)
    if report:
        print("         arii: total %.0f m2, lichen portocaliu %.2f%%" % (tot, 100 * orange / tot))
    if orange / tot >= 0.03:
        bad.append("lichen portocaliu %.2f%% >= 3%%" % (100 * orange / tot))
    extra = sorted(k for k in slots if k not in allowed)
    if extra:
        bad.append("sloturi in afara tabelului: %s" % extra)


def boulder_env():
    t = world_tris(BOULDER)
    e = extent(t)
    return [(b - a) * BOULDER_SCALE for a, b in e]


def check_block(tris, names=None, xform=None, slots=None, report=True, ref=None):
    bad = []
    ref = ref or boulder_env()
    e = extent(tris)
    dims = [b - a for a, b in e]
    asp = max(dims[0], dims[2]) / max(min(dims[0], dims[2]), 1e-6)
    if report:
        print("block    cote X %.3f  Y %.3f  Z %.3f   (boulder_roller x 0,5: %.3f %.3f %.3f)"
              % (dims[0], dims[1], dims[2], ref[0], ref[1], ref[2]))
        print("         raport amprenta X/Z %.3f   centru (%.2f, %.2f, %.2f)"
              % (asp, (e[0][0] + e[0][1]) / 2, (e[1][0] + e[1][1]) / 2, (e[2][0] + e[2][1]) / 2))
    for ax, (d, r) in zip("XYZ", zip(dims, ref)):
        if abs(d / r - 1.0) > 0.10:
            bad.append("cota %s %.3f in afara +-10%% fata de %.3f (%.1f%%)" % (ax, d, r, 100 * (d / r - 1)))
    if asp > 1.15:
        bad.append("amprenta nu e aproape patrata: raport %.3f > 1,15" % asp)
    if names is not None and names != BLOCK_NODES:
        bad.append("noduri %s, cerute %s" % (names, BLOCK_NODES))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    _slots(slots, BLOCK_SLOTS, bad, report)
    for b in bad:
        print("   !! " + b)
    return not bad


def check_prop(tris, names=None, xform=None, slots=None, report=True):
    bad = []
    e = extent(tris)
    h = e[1][1] - e[1][0]
    if report:
        print("prop     cote %.2f x %.2f x %.2f  (inaltime %.2f, min %.3f)"
              % (e[0][1] - e[0][0], h, e[2][1] - e[2][0], h, e[1][0]))
    if not 2.7 <= h <= 3.3:
        bad.append("inaltime %.2f in afara 2,7-3,3 (~3 m)" % h)
    if abs(e[1][0]) > 0.02:
        bad.append("min Y %.3f != 0" % e[1][0])
    if names is not None and names != PROP_NODES:
        bad.append("noduri %s, cerute %s" % (names, PROP_NODES))
    if xform:
        bad.append("scala/rotatie neaplicata pe radacini: %s" % xform)
    _slots(slots, PROP_SLOTS, bad, report)
    for b in bad:
        print("   !! " + b)
    return not bad


# --- sabotaje -----------------------------------------------------------------

def sabotage_intact(tris):
    c = []
    for n, t in tris:
        if n == "Vault_Stone" and all(3.2 <= abs(p[0]) <= 4.4 for p in t) and max(p[1] for p in t) <= 3.45:
            sgn = 1 if sum(p[0] for p in t) > 0 else -1
            t = tuple((p[0] - sgn * 0.2, p[1], p[2]) for p in t)
        c.append((n, t))
    return [("pereti mutati la +-3,2", c),
            ("cheie coborata 0,5 m",
             _move(tris, lambda n, t: n == "Vault_Stone" and all(abs(p[0]) < 1.4 for p in t) and min(p[1] for p in t) >= 6.5,
                   (0, -0.5, 0)))]


def sabotage_broken(tris):
    c = []
    for n, t in tris:
        if n == "Vault_Stone" and all(3.2 <= abs(p[0]) <= 4.4 for p in t):
            sgn = 1 if sum(p[0] for p in t) > 0 else -1
            t = tuple((p[0] - sgn * 0.2, p[1], p[2]) for p in t)
        c.append((n, t))
    return [("pereti mutati la +-3,2", c),
            ("placa de acoperis inchide bolta",
             tris + _box_tris("Vault_Stone", -3.4, 3.4, 5.6, 6.4, -2.0, 2.0)),
            ("bloc de moloz pe drum",
             tris + _box_tris("Vault_Stone", 1.0, 2.2, 0.0, 0.9, -0.6, 0.6))]


def sabotage_block(tris):
    return [("blocul scalat 1,3x",
             [(n, tuple((p[0] * 1.3, p[1] * 1.3, p[2] * 1.3) for p in t)) for n, t in tris]),
            ("amprenta alungita 1,3x pe X",
             [(n, tuple((p[0] * 1.3, p[1], p[2]) for p in t)) for n, t in tris])]


def selftest(intact, broken, block):
    ok = True
    ref = boulder_env()
    print("== selftest: garda trebuie sa PICE pe copiile sabotate ==")
    for label, path, fn, cases in (
            ("vault_intact", intact, check_intact, sabotage_intact),
            ("vault_broken", broken, check_broken, sabotage_broken),
            ("block", block, lambda t, report=False: check_block(t, report=report, ref=ref), sabotage_block)):
        tris = world_tris(path)
        for name, bad_tris in cases(tris):
            print("-- sabotaj %s: %s" % (label, name))
            if fn(bad_tris, report=False):
                print("   !! SELFTEST ESUAT: garda a TRECUT pe copia sabotata")
                ok = False
            else:
                print("   garda a picat, cum trebuie")
        print("-- originalul %s:" % label)
        if not fn(tris, report=False):
            print("   !! SELFTEST ESUAT: garda pica pe original")
            ok = False
        else:
            print("   originalul trece")
    print("SELFTEST: %s" % ("OK" if ok else "ESUAT"))
    return ok


def main():
    a = sys.argv[1:]
    if a and a[0] == "--selftest" and len(a) >= 4:
        sys.exit(0 if selftest(a[1], a[2], a[3]) else 1)
    if len(a) >= 2 and a[0] in ("vault_intact", "vault_broken", "block", "prop"):
        tris = world_tris(a[1])
        names, xform = meta(a[1])
        slots = slot_areas(a[1])
        fn = {"vault_intact": check_intact, "vault_broken": check_broken,
              "block": check_block, "prop": check_prop}[a[0]]
        sys.exit(0 if fn(tris, names, xform, slots) else 1)
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
