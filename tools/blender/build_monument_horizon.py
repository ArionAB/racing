"""Monument Valley -- FUNDAL (brief monumentvalley_kit §1.8), grupa mv-f.

  monumentvalley/rocks/horizon_mesas.glb   7 siluete, fiecare UN nod copil direct al radacinii:
    EagleMesa_A     masa lata (~90 x 30 x 28 m)
    BrighamsTomb_A  bloc inalt pe soclu lat (~40 x 25 x 35 m)
    Stagecoach_A    masa lunga cu umar mai jos (~50 x 20 x 30 m)
    KingOnThrone_A  tron lat cu un turn pe o margine (~30 x 20 x 32 m)
    Spires_A        3 turle de 25-35 m pe un soclu comun
    FarMesa_A/B     benzi joase de ~150 x 20 x 15 m

CONSUMATORUL: `Track._build_horizon` instantiaza GLB-ul si pastreaza UN nod dupa
nume exact (`_extract_glb_node`: copil direct al radacinii, containerul se
recentreaza cu `-kept.position`), apoi il aseaza la 190-340 m, ingropat 4 m,
rotit la intamplare pe Y si scalat 1,3-2,4x. De aici:
  - cate un nod pe silueta, cu numele din brief, ORIGINEA LA BAZA (XY centrat pe
    silueta, Z min = 0): rotatia pe Y roteste silueta pe loc;
  - VOLUME INCHISE citibile din orice azimut: peretele merge pe tot conturul
    (patru fete), nu doar pe o fata;
  - un nod = o clasa (`horizon_class` = mv_sandstone pe tot nodul), deci rocca,
    calota si grohotisul stau in ACELASI mesh (sloturile raman doar ca rezerva);
  - fara coliziune, `cast_shadow` OFF la integrare (caster departat).
Cele trei etaje se pastreaza (grohotis in trepte, perete cu coloane, calota
palida) dar cu fatete MARI: la 190-340 m si scara 1,3-2,4x o coloana de 8 m
ajunge la 10-20 m si se citeste; una de 2 m ar deveni zgomot (memoria
`caster-departat-fura-umbra` + `silueta-inainte-de-umbrire`: profilul conteaza).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_monument_horizon.py
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

AO_FAR = dict(samples=16, dist=25.0, gradient="vertical",
              low=0.55, high=1.0, power=0.85, floor=0.2)

clear_built()


def shift_into(dst, src, dx, dy, dz=0.0):
    """Copiaza fetele lui `src` in `dst`, mutate cu (dx, dy, dz); elibereaza `src`."""
    for f in src.bm.faces:
        _face(dst, [v.co + Vector((dx, dy, dz)) for v in f.verts], f[src.slot])
    src.bm.free()


def block(b, hx, hy, h, seed, dx=0.0, dy=0.0, dz=0.0, wmin=6.0, wmax=11.0,
          taper=0.08, flare=8.0, foot=3.0, cap_top=True, cap_ox=1.6,
          ledges=(0.0, 0.03, 0.05), prot=1.5, recess=(2.0, 3.5), vf=1.2, ch=1.0):
    """Un bloc de gresie pe tot conturul (coloane late), cu calota palida in 2
    trepte. Coloanele + calota ale unui `block` se aduna in `b` mutate cu (dx, dy,
    dz). Intoarce conturul coloanelor (mutat) pentru alte calote."""
    tmp = Builder()
    cols = wall_columns(tmp, hx, hy, h, ROCK, ROCK_SHADE, seed=seed, wmin=wmin,
                        wmax=wmax, flare_h=flare, foot=foot, taper=taper,
                        ledges=ledges, chamfer_c=ch, recess=recess, prot=prot,
                        vfront=vf, h_var=h * 0.012)
    if cap_top:
        cap_slab(tmp, cols, CAP, h - 1.0, h + 0.9, cap_ox, cap_ox * 1.2)
        cap_slab(tmp, cols, CAP, h + 0.9, h + 1.7, -cap_ox * 2.0, -cap_ox * 2.0)
    shift_into(b, tmp, dx, dy, dz)
    return cols


def skirt(b, hx, hy, D, h_top, seed, pts=32, inner=2.5, ledge=1.0, dx=0.0, dy=0.0):
    """Fusta de grohotis cu coaste radiale, in fatete mari (32 de puncte pe unghi,
    fara bolovani individuali: de la 190+ m nu s-ar vedea decat ca zgomot)."""
    tmp = Builder()
    scree_ribs(tmp, hx, hy, D, h_top, [SCREE_A, SCREE_B], seed=seed, pts=pts,
               inner=inner, ledge=ledge)
    shift_into(b, tmp, dx, dy)


def spire(b, cx, cy, H, hw, hd, seed):
    """Turla de H m: 6 segmente cu praguri, ultimele ingustate spre varf bont,
    baza hw x hd (semi-latimi)."""
    cuts = [0.0, 0.22, 0.45, 0.68, 0.84, 0.95, 1.0]
    sw = [1.0, 0.86, 0.80, 0.66, 0.50, 0.34, 0.16]       # pragul = pas in plus
    sw2 = [0.90, 0.84, 0.72, 0.58, 0.44, 0.30]            # sfarsitul segmentului
    segs = []
    for i in range(6):
        segs.append((cuts[i] * H, hw * sw[i], hd * sw[i],
                     cuts[i + 1] * H, hw * sw2[i] if i < 5 else hw * 0.14,
                     hd * sw2[i] if i < 5 else hd * 0.14))
    tapered_spire(b, cx, cy, segs, ROCK, ROCK_SHADE, seed=seed)


# ---------------------------------------------------------------------------

def build_eagle_mesa():
    """`horizon_mesas.png` (masa lata din stanga-centru) -- elemente numarate:

    - O MASA lunga cu varful PLAT si pereti verticali pe patru fete: ~12
      coloane de 7-12 m, taper ~8%, 2 praguri, talpa evazata.
    - CALOTA: placa palida in 2 trepte, depaseste peretele.
    - GROHOTIS: fusta larga cu coaste radiale pana la ~1/3 din inaltime.
    Cote: ~90 x 30 x 28 m (peretele 27,2 + calota 0,8), origine la baza.
    """
    b = Builder()
    block(b, 45.0, 15.0, 27.2, seed=201, wmin=7.0, wmax=12.0, flare=8.0, foot=3.0)
    skirt(b, 45.0, 15.0, 9.0, 4.5, seed=202, ledge=0.8)
    return to_obj(b, "EagleMesa_A")


def build_brighams_tomb():
    """`horizon_mesas.png` (turnul mare central) -- elemente numarate:

    - TURN inalt (35 m) si ingust (40 x 25 m) cu varf plat si coloane late
      (5-9 m), ridicat pe un SOCLU lat de ~14 m (cu calota proprie, ca o
      treapta/policioara), deci doua etaje de perete + grohotis jos.
    - CALOTA palida pe turn si pe soclu.
    Cote: ~40 x 25 x 35 m (turn 33,9 + calota 1,7); soclu ~46 x 30 x 14 m.
    """
    b = Builder()
    block(b, 23.0, 15.0, 13.0, seed=211, wmin=7.0, wmax=11.0, flare=6.0, foot=2.5,
          taper=0.05, cap_ox=1.2)
    block(b, 17.5, 11.0, 22.4, seed=212, dx=-1.0, dy=0.5, dz=12.6, wmin=5.0,
          wmax=9.0, flare=1.0, foot=0.1, taper=0.1, prot=1.0, recess=(1.5, 2.5),
          vf=1.0, ch=0.9)
    skirt(b, 23.0, 15.0, 7.0, 3.0, seed=213, ledge=0.6)
    return to_obj(b, "BrighamsTomb_A")


def build_stagecoach():
    """`horizon_mesas.png` (butte dublu din dreapta-centru) -- elemente numarate:

    - O MASA lunga (50 x 20 m) de 28 m cu varf plat, 8 coloane de 6-10 m.
    - UMAR: un bloc mai jos (18 m) la capatul +X, mai larg pe Y, ca o treapta
      care coboara spre vale (silueta asimetrica din orice azimut).
    - CALOTA palida pe amandoua; grohotis lat la picior.
    Cote: ~50 x 20 x 30 m (+ umarul ajunge la ~60 m lungime totala).
    """
    b = Builder()
    block(b, 25.0, 10.0, 28.3, seed=221, dx=-4.0, wmin=6.0, wmax=10.0, flare=7.0,
          foot=2.5)
    block(b, 11.0, 8.5, 17.0, seed=222, dx=27.0, dy=-0.8, wmin=5.0, wmax=8.0,
          flare=5.0, foot=2.0, taper=0.06, cap_ox=1.0)
    skirt(b, 25.0, 10.0, 8.0, 4.0, seed=223, dx=-4.0, ledge=0.7)
    return to_obj(b, "Stagecoach_A")


def build_king_on_throne():
    """`horizon_mesas.png` (tronul/turnul masiv din dreapta) -- elemente numarate:

    - TRON: bloc lat (30 x 20 m) de 22 m cu coloane de 5-9 m, 2 praguri.
    - REGELE: un turn mai ingust (14 x 11 m) care continua tronul pana la 32 m,
      asezat spre o margine (silueta cu un umar), cu calota proprie.
    - Calota palida pe tron (umarul liber) si pe turn; grohotis la picior.
    Cote: ~30 x 20 x 32 m (turn 30,3 + calota 1,7).
    """
    b = Builder()
    block(b, 16.0, 11.0, 21.0, seed=231, wmin=5.0, wmax=9.0, flare=6.0, foot=2.5,
          taper=0.05, cap_ox=1.0)
    block(b, 7.0, 5.8, 10.0, seed=232, dx=-3.5, dy=0.8, dz=20.4, wmin=4.0, wmax=7.0,
          flare=0.5, foot=0.05, taper=0.12, prot=0.8, recess=(1.0, 1.8), vf=0.8,
          ch=0.7)
    skirt(b, 16.0, 11.0, 7.0, 3.5, seed=233, ledge=0.7)
    return to_obj(b, "KingOnThrone_A")


def build_spires():
    """`horizon_mesas.png` (turlele din dreapta) -- elemente numarate:

    - 3 TURLE (34 / 27 / 30 m), baza ~8-9 m, in 6 segmente cu praguri care se
      strang spre un varf bont; asezate in linie, usor decalate pe Y.
    - SOCLU COMUN: un platou de grohotis cu coaste radiale (cota ~7 m) din care
      ies turlele, ca sa se citeasca un singur ansamblu.
    Cote: turle 25-35 m, ansamblu ~44 x 20 m, origine la baza.
    """
    b = Builder()
    spire(b, -14.0, 0.5, 34.0, 4.6, 4.0, seed=241)
    spire(b, 0.5, -1.5, 27.0, 3.8, 3.4, seed=242)
    spire(b, 15.5, 1.0, 30.0, 4.2, 3.6, seed=243)
    D, HT, PTS = 6.5, 3.0, 40
    HXs, HYs = 16.0, 6.0
    skirt(b, HXs, HYs, D, HT, seed=244, pts=PTS)
    # capac plat peste soclu (interiorul fustei era gol): n-gon la cota ultimului inel
    z = HT + 2 * 1.0   # ledge implicit 1,0 din skirt()/scree_ribs
    ring = []
    for i in range(PTS):
        th = 2 * math.pi * i / PTS
        x, y = _super_pt(HXs - 1.5, HYs - 1.5, th)
        ring.append((x, y, z))
    f = _face(b, ring, SCREE_A)
    bmesh.ops.triangulate(b.bm, faces=[f])
    return to_obj(b, "Spires_A")


def build_far_mesas():
    """`horizon_mesas.png` (fasia joasa din dreapta, masele palide din spate) --
    elemente numarate:

    A: o banda joasa (150 x 20 m) de 14 m, ~14 coloane de 8-14 m, varful plat,
       calota palida, grohotis scund.
    B: banda ceva mai scurta (140 m) cu o treapta mai inalta (15 m) pe o
       jumatate si una joasa (11 m) pe cealalta, deci profil in doua cote.
    Cote: ~150 x 20 x 15 m, origine la baza. Fatete mari, fara detaliu fin.
    """
    a = Builder()
    block(a, 75.0, 10.0, 14.2, seed=251, wmin=9.0, wmax=15.0, flare=4.0, foot=2.0,
          prot=1.2, recess=(1.5, 2.5), vf=1.0, ch=0.9, cap_ox=1.0)
    skirt(a, 75.0, 10.0, 6.0, 2.2, seed=252, inner=1.8, ledge=0.4)
    bb = Builder()
    block(bb, 38.0, 9.5, 14.0, seed=261, dx=-30.0, wmin=8.0, wmax=13.0, flare=4.0,
          foot=2.0, prot=1.2, recess=(1.5, 2.5), vf=1.0, ch=0.9, cap_ox=1.0)
    block(bb, 36.0, 9.0, 10.2, seed=262, dx=34.0, dy=0.6, wmin=8.0, wmax=13.0,
          flare=3.5, foot=1.8, prot=1.0, recess=(1.2, 2.0), vf=0.9, ch=0.8, cap_ox=0.9)
    skirt(bb, 70.0, 9.5, 6.0, 2.2, seed=263, inner=1.8, ledge=0.4)
    return to_obj(a, "FarMesa_A"), to_obj(bb, "FarMesa_B")


if __name__ == "__main__" or True:
    far_a, far_b = build_far_mesas()
    objs = [build_eagle_mesa(), build_brighams_tomb(), build_stagecoach(),
            build_king_on_throne(), build_spires(), far_a, far_b]
    emit(objs, "rocks/horizon_mesas.glb", AO_FAR, keep_xy=True, budget=60000)
    report()
