"""Monument Valley -- stanci mici si grohotis (brief monumentvalley_kit §1.2), grupa mv-f.

  monumentvalley/rocks/butte_small_a.glb     bloc cu calota pe con propriu, 14 m
  monumentvalley/rocks/butte_small_b.glb     turla ingusta pe con, 18 m
  monumentvalley/rocks/butte_small_c.glb     bloc in 3 trepte care se strang, 12 m
  monumentvalley/rocks/rock_fin.glb          arip subtire verticala, 12 x 4 x 2,5 m
  monumentvalley/rocks/hoodoo.glb            coloana cu cap de piatra mai lat, 7 m
  monumentvalley/rocks/talus_boulders_a.glb  grup de 7 bolovani, ~4 x 4 x 2,5 m
  monumentvalley/rocks/talus_boulders_b.glb  grup lat si jos, 10 bolovani, ~5 x 4 x 2 m

Se instantiaza cu zecile pe tur: siluete DISTINCTE intre ele (coloane/trepte/
turla/aripa/ciuperca), fara fete inutile (grohotis cu 32 de puncte pe unghi,
bolovani din 24 de puncte, nu icosfere de 80 de triunghiuri). Acelasi vocabular
ca la monoliti: `wall_columns` + `cap_slab` + `scree_ribs`; bolovanii din
grohotis si din grupurile `talus_*` sunt blocuri teșite cu fatete late (cum sunt
blocurile arcului), nu bile.

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_monument_rocks_small.py
"""

import math
from mathutils import Vector, Matrix

exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "monument_shapes.py")).read())

ROCK = TILE_TERRACOTTA
ROCK_SHADE = RUST
SCREE_A = RUST
SCREE_B = LARCH_RUST
CAP = SAND_LIGHT

# AO: piese de 7-18 m; gradient vertical (baza in umbra, varf in soare)
AO_SMALL = dict(samples=16, dist=3.5, gradient="vertical",
                low=0.55, high=1.0, power=0.85, floor=0.2)
AO_TALUS = dict(samples=16, dist=1.5, gradient="vertical",
                low=0.6, high=1.0, power=0.9, floor=0.3)

clear_built()


# ---------------------------------------------------------------------------
# bolovan teșit (bloc cu fatete late) -- local, ca sa nu atingem vocabularul
# comun pe care il editeaza si alte grupe
# ---------------------------------------------------------------------------

def faceted_rock(b, center, size, slots, seed=0, jag=0.16, flat=0.18, peak=0.25,
                 tilt=0.5, foot=0.0):
    """Bolovan colturos: cub cu TOATE muchiile si colturile teșite (24 de puncte:
    permutarile lui (±1, ±1, ±r)), fiecare punct impins aleator, rotit pe Z si
    putin inclinat, cu baza taiata plat (`flat` din inaltime). Invelisul convex
    da fatete late (~40 de triunghiuri), ca blocurile arcului. `slots` =
    (slot_lateral, slot_sus): fetele cu normala in sus pe al doilea."""
    rnd = _lcg(seed)
    r = 0.62 + 0.12 * rnd()
    base = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sr in (-1, 1):
                base += [(sx, sy, sr * r), (sx, sr * r, sy), (sr * r, sx, sy)]
    rz = rnd() * math.pi * 2
    rx = (rnd() - 0.5) * tilt
    ry = (rnd() - 0.5) * tilt
    rot = (Matrix.Rotation(rz, 3, "Z") @ Matrix.Rotation(rx, 3, "X")
           @ Matrix.Rotation(ry, 3, "Y"))
    pts = []
    for p in base:
        k = 1.0 - jag * 0.5 + rnd() * jag
        q = Vector((p[0] * size[0] * 0.5 * k, p[1] * size[1] * 0.5 * k,
                    p[2] * size[2] * 0.5 * k))
        pts.append(rot @ q)
    zlo = min(p.z for p in pts)
    zhi = max(p.z for p in pts)
    zcut = zlo + (zhi - zlo) * flat
    verts = []
    for p in pts:
        z = max(p.z, zcut) - zlo
        t = min(1.0, z / max(zhi - zlo, 1e-6))
        sh = (1.0 - peak * t ** 1.3) * (1.0 - foot * (1.0 - t) ** 1.5)   # varf/talpa mai inguste
        verts.append(b.bm.verts.new((p.x * sh + center[0], p.y * sh + center[1],
                                     z + center[2])))
    res = bmesh.ops.convex_hull(b.bm, input=verts, use_existing_faces=False)
    bmesh.ops.delete(b.bm, geom=res["geom_interior"], context="VERTS")
    for f in res["geom"]:
        if isinstance(f, bmesh.types.BMFace):
            f.normal_update()
            f[b.slot] = slots[1] if f.normal.z > 0.55 else slots[0]


def scatter(b, hx, hy, D, h_top, n_big, n_small, big, small, seed, pts=32,
            zmax=99.0, skip_in=1.0):
    """Bolovani pe fusta `scree_ribs`: `big` = (min, max) marimea mare, `small`
    = (min, max). Cei mari stau pe margine si in vai (indice par), cei mici
    imprastiati dincolo de margine. Slotul alterneaza pe bolovan."""
    rnd = _lcg(seed)
    nb, tries = 0, 0
    while nb < n_big and tries < 4000:
        tries += 1
        i = 2 * int(rnd() * pts / 2)
        th = 2 * math.pi * (i + (rnd() - 0.5) * 0.8) / pts
        d = 0.8 + (D - 0.4) * (rnd() ** 0.55)
        x, y = _super_pt(hx + d, hy + d, th)
        if abs(x) < hx + skip_in and abs(y) < hy + skip_in:
            continue
        sz = big[0] + (big[1] - big[0]) * rnd()
        z = scree_height(x, y, hx, hy, D, h_top, inner=0.8, ledge=0.2, pts=pts)
        if z + sz * 0.7 > zmax:
            continue
        al = nb % 2 == 0
        faceted_rock(b, (x, y, z - sz * 0.1), (sz * 1.2, sz, sz * 0.8),
                     (SCREE_A, SCREE_B) if al else (SCREE_B, SCREE_A),
                     seed=seed * 11 + nb)
        nb += 1
    for ns in range(n_small):
        th = rnd() * 2 * math.pi
        d = D - 0.3 + rnd() * 1.0
        x, y = _super_pt(hx + d, hy + d, th)
        sz = small[0] + (small[1] - small[0]) * rnd()
        z = scree_height(x, y, hx, hy, D, h_top, inner=0.8, ledge=0.2, pts=pts)
        faceted_rock(b, (x, y, z - sz * 0.05), (sz * 1.3, sz, sz * 0.7),
                     (SCREE_A, SCREE_B) if ns % 2 else (SCREE_B, SCREE_A),
                     seed=seed * 13 + 500 + ns)


def shifted(cols, dx, dy):
    """Copia coloanelor cu conturul exterior mutat (pentru calota unei trepte)."""
    return [dict(h=c["h"], outer=[(p[0] + dx, p[1] + dy) for p in c["outer"]])
            for c in cols]


def move_xy(b, dx, dy, dz=0.0):
    for v in b.bm.verts:
        v.co.x += dx
        v.co.y += dy
        v.co.z += dz


# ---------------------------------------------------------------------------
# butte_small_a/b/c
# ---------------------------------------------------------------------------

def build_butte_small_a():
    """`butte_small_a.png` -- elemente numarate pe decupare:

    - TURN: un trunchi de con ingust, ~9 coloane late (1,2-2,2 m) pe tot conturul,
      cu iesiri diferite si muchii teșite, strans ~20% spre varf, 2 praguri slabe;
      coloanele din centrul fetei sunt cele mai inalte si late.
    - CALOTA: o placa palida in 2 trepte, mica, putin iesita din perete.
    - CON DE GROHOTIS: lat, urca pana la ~1/5 din turn, cu coaste radiale;
      deasupra lui ~14 bolovani teșiti (0,7-1,6 m) pe margine si in vai si
      ~10 mici imprastiati; un bolovan mare lipit de picior in fata.
    Cote: 14 m (13,4 perete + 0,6 calota), amprenta ~11 m, origine la baza.
    """
    HX, HY, TOP = 3.7, 3.3, 13.4
    rock = Builder()
    cols = wall_columns(rock, HX, HY, TOP, ROCK, ROCK_SHADE, seed=71, wmin=1.4,
                        wmax=2.6, flare_h=4.5, foot=0.9, taper=0.36,
                        chamfer_c=0.22, recess=(0.3, 0.55), prot=0.35,
                        vfront=0.25, h_var=0.3)
    cap = Builder()
    cap_slab(cap, cols, CAP, TOP - 0.35, TOP + 0.3, 0.3, 0.4)
    cap_slab(cap, cols, CAP, TOP + 0.3, TOP + 0.6, -0.5, -0.5)
    scree = Builder()
    D, HT = 1.9, 2.4
    scree_ribs(scree, HX, HY, D, HT, [SCREE_A, SCREE_B], seed=72, pts=32,
               inner=0.8, ledge=0.2)
    scatter(scree, HX, HY, D, HT, 14, 10, (0.8, 1.7), (0.3, 0.6), 73, zmax=3.4)
    faceted_rock(scree, (1.2, HY + 1.6, 0.0), (2.6, 2.2, 2.0), (SCREE_A, SCREE_B), seed=74)
    return (to_obj(rock, "ButteA_Rock"), to_obj(scree, "ButteA_Scree"),
            to_obj(cap, "ButteA_Cap"))


def build_butte_small_b():
    """`butte_small_b.png` -- elemente numarate pe decupare:

    - TURLA: ingusta si inalta (h/l ~1,8), ~8 coloane de 0,9-1,5 m, 3 praguri
      clare (retrageri ~10%) care o fac in trepte, taper ~12%, varful plat.
    - CALOTA: o placa mica, palida, in 2 trepte.
    - CON: mic dar inalt (urca ~1/8 din turla), coaste radiale, ~9 bolovani
      0,5-1,1 m, in stanga jos un bolovan mare lipit de turla (2,6 m).
    Cote: 18 m, amprenta ~7,5 m, origine la baza.
    """
    HX, HY, TOP = 2.3, 1.95, 17.4
    rock = Builder()
    cols = wall_columns(rock, HX, HY, TOP, ROCK, ROCK_SHADE, seed=81, wmin=1.5,
                        wmax=2.4, flare_h=3.2, foot=0.6, taper=0.2,
                        ledges=(0.0, 0.07, 0.12), chamfer_c=0.18,
                        recess=(0.2, 0.4), prot=0.3, vfront=0.2, h_var=0.35)
    cap = Builder()
    cap_slab(cap, cols, CAP, TOP - 0.4, TOP + 0.3, 0.25, 0.3)
    cap_slab(cap, cols, CAP, TOP + 0.3, TOP + 0.6, -0.4, -0.4)
    scree = Builder()
    D, HT = 1.2, 2.2
    scree_ribs(scree, HX, HY, D, HT, [SCREE_A, SCREE_B], seed=82, pts=24,
               inner=0.6, ledge=0.2)
    scatter(scree, HX, HY, D, HT, 9, 7, (0.6, 1.3), (0.25, 0.5), 83, pts=24, zmax=3.2)
    faceted_rock(scree, (-HX - 0.9, -0.4, 0.0), (2.8, 2.4, 2.6), (SCREE_A, SCREE_B), seed=84)
    return (to_obj(rock, "ButteB_Rock"), to_obj(scree, "ButteB_Scree"),
            to_obj(cap, "ButteB_Cap"))


def build_butte_small_c():
    """`butte_small_c.png` -- elemente numarate pe decupare:

    - 3 ETAJE care se strang: treapta de jos lata (~8,6 x 7,6 m, 6 m), una de
      mijloc mai mica retrasa spre stanga-spate (5,8 x 5,2 m), una de sus mica
      (3,4 x 3 m); fiecare cu coloane de 1-2,4 m, muchii teșite; treapta de
      jos are varful plat vizibil (policioara) in fata.
    - CALOTA: placa palida mica doar pe ultimul etaj.
    - GROHOTIS: fusta joasa, larga, coaste radiale + ~12 bolovani 0,6-1,4 m
      si ~10 mici; la picior in dreapta-fata un bolovan mare (2,4 m).
    Cote: 12 m (11,5 + 0,5 calota), amprenta ~11,5 m, origine la baza.
    """
    rock = Builder()
    t1 = wall_columns(rock, 4.3, 3.8, 6.0, ROCK, ROCK_SHADE, seed=91, wmin=2.0,
                      wmax=3.2, flare_h=2.2, foot=0.6, taper=0.1, chamfer_c=0.25,
                      recess=(0.3, 0.6), prot=0.35, vfront=0.3, h_var=0.35)
    t2b = Builder()
    t2 = wall_columns(t2b, 2.9, 2.6, 4.4, ROCK, ROCK_SHADE, seed=92, wmin=1.6,
                      wmax=2.6, flare_h=1.0, foot=0.05, taper=0.1, chamfer_c=0.22,
                      recess=(0.2, 0.35), prot=0.15, vfront=0.2, h_var=0.3)
    move_xy(t2b, -0.8, 0.4, 5.1)
    t3b = Builder()
    t3 = wall_columns(t3b, 2.1, 1.9, 2.9, ROCK, ROCK_SHADE, seed=93, wmin=1.3,
                      wmax=1.9, flare_h=0.8, foot=0.05, taper=0.1, chamfer_c=0.18,
                      recess=(0.2, 0.35), prot=0.25, vfront=0.2, h_var=0.2)
    move_xy(t3b, -1.1, 0.7, 9.0)
    for src in (t2b, t3b):
        for f in src.bm.faces:
            _face(rock, [v.co.copy() for v in f.verts], f[src.slot])
        src.bm.free()
    TOP = 11.8
    cap = Builder()
    cols = shifted(t3, -1.1, 0.7)
    cap_slab(cap, cols, CAP, TOP - 0.4, TOP + 0.2, 0.22, 0.28)
    cap_slab(cap, cols, CAP, TOP + 0.2, TOP + 0.5, -0.4, -0.4)
    scree = Builder()
    D, HT = 1.6, 2.2
    scree_ribs(scree, 4.3, 3.8, D, HT, [SCREE_A, SCREE_B], seed=94, pts=32,
               inner=0.8, ledge=0.2)
    scatter(scree, 4.3, 3.8, D, HT, 12, 10, (0.7, 1.5), (0.3, 0.6), 95, zmax=3.0)
    faceted_rock(scree, (3.4, 4.9, 0.0), (2.6, 2.2, 2.2), (SCREE_A, SCREE_B), seed=96)
    return (to_obj(rock, "ButteC_Rock"), to_obj(scree, "ButteC_Scree"),
            to_obj(cap, "ButteC_Cap"))


# ---------------------------------------------------------------------------
# rock_fin, hoodoo
# ---------------------------------------------------------------------------

def build_rock_fin():
    """`rock_fin.png` -- elemente numarate pe decupare:

    - ARIPA: o turla subtire care se ingusteaza spre un varf ascutit, 6 segmente
      cu praguri (retrageri) la ~1/3 si ~2/3, fete late teșite (octogon turtit,
      4 m lat x 2,5 m gros la baza, h/l ~3), cu 2 COASTE verticale lipite de
      fata (7,2 si 5,4 m) ca fetele in V din decupare.
    - UMAR: un al doilea element mai scund (7,5 m), lipit pe dreapta, in
      trepte, care se uneste cu aripa pe jumatate din inaltime.
    - GROHOTIS: inel mic la baza, coaste radiale joase, ~8 bolovani 0,4-0,9 m.
    - Nu are calota (varful e ascutit, ca pe decupare).
    Cote: 12 m, 4 m lat, 2,5 m gros (peretele), origine la baza.
    """
    rock = Builder()
    segs = [(0.0, 2.0, 1.25, 3.5, 1.9, 1.2),
            (3.5, 1.75, 1.1, 7.0, 1.5, 1.0),
            (7.0, 1.35, 0.95, 9.6, 1.1, 0.8),
            (9.6, 0.95, 0.7, 10.9, 0.8, 0.6),
            (10.9, 0.65, 0.5, 11.6, 0.4, 0.3),
            (11.6, 0.35, 0.28, 12.0, 0.08, 0.08)]
    tapered_spire(rock, 0.0, 0.0, segs, ROCK, ROCK_SHADE, seed=101)
    # doua coaste verticale lipite de fata (+Y), inaltimi diferite
    buttress(rock, -0.7, 1.1, 1.1, 0.45, 7.2, ROCK, ROCK_SHADE, seed=103, foot=0.3)
    buttress(rock, 0.9, 1.1, 1.2, 0.4, 5.4, ROCK, ROCK_SHADE, seed=104, foot=0.3)
    sh = [(0.0, 1.0, 0.8, 3.5, 0.95, 0.75),
          (3.5, 0.85, 0.7, 7.5, 0.5, 0.45)]
    tapered_spire(rock, 1.9, -0.3, sh, ROCK, ROCK_SHADE, seed=102)
    scree = Builder()
    D, HT = 1.1, 0.9
    scree_ribs(scree, 2.0, 1.25, D, HT, [SCREE_A, SCREE_B], seed=103, pts=24,
               inner=0.5, ledge=0.12)
    scatter(scree, 2.0, 1.25, D, HT, 5, 4, (0.45, 0.9), (0.25, 0.45), 104, pts=24,
            zmax=1.4, skip_in=0.6)
    return (to_obj(rock, "Fin_Rock"), to_obj(scree, "Fin_Scree"))


def build_hoodoo():
    """`hoodoo.png` -- elemente numarate pe decupare:

    - COLOANA: 3 segmente cu fete late teșite (octogon), baza groasa (3 m) care
      se ingusteaza la ~2,2 m, apoi un GAT subtire (1,6 m) la ~5,2 m.
    - CAP: bolovan poliedric rotunjit (~10-14 fete), putin mai lat decat gatul
      (~1,6 x 1,4 x 1,3 m), maro-bej: fetele de sus ROCK_LIGHT 3, cele din
      umbra SAND_SHADOW 2 (decizia coordonatorului, nu SAND_LIGHT).
    - CON MIC: la baza, cu coaste radiale, ~7 bolovani 0,3-0,7 m, ~4 mici.
    Cote: 7 m, h/l ~2,3, origine la baza.
    """
    rock = Builder()
    segs = [(0.0, 1.5, 1.4, 2.2, 1.3, 1.2),
            (2.2, 1.5, 1.35, 3.8, 1.25, 1.1),
            (3.8, 0.95, 0.9, 5.0, 0.9, 0.82),
            (5.0, 0.8, 0.75, 5.6, 0.7, 0.65)]
    tapered_spire(rock, 0.0, 0.0, segs, ROCK, ROCK_SHADE, seed=111)
    cap = Builder()
    faceted_rock(cap, (0.0, 0.0, 5.45), (3.0, 2.7, 1.55), (SAND_SHADOW, ROCK_LIGHT),
                 seed=112, jag=0.22, flat=0.0, peak=0.4, foot=0.35, tilt=0.2)
    scree = Builder()
    D, HT = 1.2, 0.9
    scree_ribs(scree, 1.5, 1.4, D, HT, [SCREE_A, SCREE_B], seed=113, pts=24,
               inner=0.5, ledge=0.12)
    scatter(scree, 1.5, 1.4, D, HT, 6, 4, (0.35, 0.75), (0.2, 0.4), 114, pts=24,
            zmax=1.4, skip_in=0.6)
    return (to_obj(rock, "Hoodoo_Rock"), to_obj(scree, "Hoodoo_Scree"),
            to_obj(cap, "Hoodoo_Cap"))


# ---------------------------------------------------------------------------
# talus
# ---------------------------------------------------------------------------

def build_talus(kind):
    """`talus_boulders_a/b.png` -- elemente numarate pe decupare:

    a: 7 bolovani colturosi: 1 mare central inalt (2,5 m), 2 medii laterale
       (1,7 m stanga, 1,8 m dreapta, cel din dreapta mai larg), 1 mediu in fata
       dreapta (0,9 m), 3 mici in fata (0,5-0,8 m); fete late teșite, fetele de
       sus mai luminoase (LARCH_RUST), laturile RUST_METAL. Un singur nod.
    b: 10 bolovani, mai lati si mai jos (2 m max): 1 central (2,0 m), 2 medii
       (1,5 m) spate-dreapta si spate-stanga, 3 in fata-dreapta (1,0-1,3 m),
       4 mici imprastiati (0,4-0,7 m).
    """
    s = Builder()
    if kind == "a":
        spec = [(0.2, 0.2, 2.5, 1.5, 1.4), (-1.2, -0.3, 1.7, 1.5, 1.3),
                (1.3, -0.1, 1.8, 1.7, 1.4), (1.1, 1.1, 0.9, 1.1, 0.9),
                (-0.5, 1.2, 0.8, 1.0, 0.8), (-1.6, 1.0, 0.55, 0.8, 0.7),
                (0.4, 1.5, 0.5, 0.7, 0.6)]
        seed0 = 121
    else:
        spec = [(0.0, 0.0, 2.0, 2.0, 1.6), (-1.7, -0.7, 1.5, 1.5, 1.3),
                (1.8, -0.5, 1.5, 1.7, 1.4), (1.5, 0.9, 1.1, 1.4, 1.1),
                (0.2, 1.4, 1.0, 1.2, 1.0), (-1.4, 0.8, 1.3, 1.5, 1.2),
                (-2.3, -0.1, 0.6, 0.8, 0.7), (2.5, 0.2, 0.5, 0.7, 0.6),
                (0.8, -1.5, 0.6, 0.9, 0.7), (-0.5, 2.0, 0.4, 0.6, 0.5)]
        seed0 = 131
    for i, (x, y, h, w, d) in enumerate(spec):
        faceted_rock(s, (x, y, 0.0), (w, d, h),
                     (SCREE_A, SCREE_B) if i % 2 == 0 else (SCREE_B, SCREE_A),
                     seed=seed0 + i * 3, jag=0.3, flat=0.15,
                     peak=0.55 if h > 1.4 else 0.35, tilt=0.35)
    return (to_obj(s, "Talus_Scree"),)


if __name__ == "__main__" or True:
    emit(list(build_butte_small_a()), "rocks/butte_small_a.glb", AO_SMALL,
         keep_xy=True, budget=6000)
    emit(list(build_butte_small_b()), "rocks/butte_small_b.glb", AO_SMALL,
         keep_xy=True, budget=6000)
    emit(list(build_butte_small_c()), "rocks/butte_small_c.glb", AO_SMALL,
         keep_xy=True, budget=9000)
    emit(list(build_rock_fin()), "rocks/rock_fin.glb", AO_SMALL,
         keep_xy=True, budget=3000)
    emit(list(build_hoodoo()), "rocks/hoodoo.glb", AO_SMALL,
         keep_xy=True, budget=3000)
    emit(list(build_talus("a")), "rocks/talus_boulders_a.glb", AO_TALUS,
         keep_xy=False, budget=1500)
    clear_built()
    emit(list(build_talus("b")), "rocks/talus_boulders_b.glb", AO_TALUS,
         keep_xy=False, budget=1800)
    report()
