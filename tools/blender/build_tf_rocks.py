"""Transfagarasan -- stancile de sist (brief docs/asset_briefs/transfagarasan_kit.md §1.4).

  transfagarasan/rocks/schist_outcrop_a.glb   lame ca niste carti, una dominanta   6 x 5 m
  transfagarasan/rocks/schist_outcrop_b.glb   creasta joasa, dinte de fierastrau   3,5 x 8 m
  transfagarasan/rocks/schist_outcrop_c.glb   acul crapat pe lung, cu umar        8 x 4 m
  transfagarasan/rocks/scree_cone.glb         con de grohotis din pietre plate     4 x 12 m

Noduri pe fiecare stanca: `Schist_Schist` (MARBLE_GREY 29 -> clasa tf_schist) si
`Schist_Crack` (VOLCANIC_BLACK 20, fisurile dintre lame, regula 8; nod separat
fiindca clasa sterge sloturile din nodul *_Schist). Vocabularul e in
`tf_shapes_nature.py` (SchistFrame, slab_profile, schist_slab, crack_between,
crack_hull, schist_chip).

Fara muschi/iarba pe stanci (corectura kitului: fara vegetatie lipita; pe
plansa toate trei au pete verzi-galbene). Origine la baza, centrata pe
ansamblu (offset calculat O DATA pe ansamblu, `--origin=assembly`), scala
aplicata. Coliziunea o decide coordonatorul (scree_cone: `none`).

Rulare:
    D:/Blender/blender.exe --background --factory-startup \\
        --python tools/blender/run_build.py -- build_tf_rocks.py
Variabila de mediu TF_ONLY=<piesa> reface doar piesa respectiva.
"""

import math
from mathutils import Vector, Matrix

_here = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(_here, "transfagarasan_shapes.py")).read())
exec(open(os.path.join(_here, "tf_shapes_nature.py")).read())

clear_built()


def _ao(h):
    return dict(samples=24, dist=2.2, gradient="vertical", low=0.62, high=1.0,
                power=0.8, floor=0.30, z_range=(0.0, h))


def _stack(sch, crk, fr, blades, gap):
    """Lamele piesei: `blades` = lista (nume, prof, v0, thick, ridge, seed).
    Fisurile se pun intre perechile (fata, spate) date de v: lama din fata se
    termina la v0+thick, cea din spate incepe la v0+thick+gap."""
    for (_n, prof, v0, th, ridge, seed) in blades:
        schist_slab(sch, fr, prof, v0, th, ridge=ridge, seed=seed)
    for (_na, pa, va, ta, _ra, _sa) in blades:
        for (_nb, pb, vb, _tb, _rb, _sb) in blades:
            if abs(vb - (va + ta + gap)) < 1e-6:
                crack_between(crk, fr, pa, pb, va + ta, gap)


def build_schist_outcrop_a():
    """Aflorimentul de sist A (`schist_outcrop_a`): 6 m inalt, 5 m lat, h/l ~1,2.

    LISTA DE ELEMENTE (din decuparea `schist_outcrop_a.png`, scrisa INAINTE de
    geometrie; cotele din tabel, nu din plansa):
      a) STIVA de 3 lame-placi paralele cu foliatia, asezate una peste alta ca
         niste carti aplecate; fetele lungi coboara toate spre ACEEASI parte
         (dreapta in imagine), varfurile coboara in trepte spre dreapta:
         1. DOMINANTA (pana de baza), varf la ~6,1 m langa marginea stanga,
            spatele aproape vertical (~6 grade);
         2. a doua, peste ea, varf ~4,4 m (pe plansa 4,6 m; iese ~2 m peste
            fata dominantei);
         3. a treia NU mai incape in stiva la 5 m latime (fiecare placa adauga
            t/sin(dip) ~1,2 m); o fac LAMA MICA IN FATA-dreapta, varf ~2,7 m,
            cum o arata si plansa (pare in fata celei de-a doua);
         4. o lama joasa in FATA-stanga, ~3,2 m, peste piciorul dominantei
            (plansa: blocul inalt din stanga-jos).
         Inclinarea: contractul spune "~40 grade". Pe 6 x 5 m (h/l 1,2) fata
         lunga NU poate avea 40 grade fata de orizontala (pana dominanta singura
         ar iesi lata de 7,2 m). Plansa masoara 50-58 grade; iau 62 grade fata de
         orizontala (28 fata de verticala) ca sa intre stiva in ~5 m.
      b) FISURILE: DIAGONALE intre placile stivei (rost de 0,15 m, placa
         `Schist_Crack` adancita in el) + intre lamele din fata si stiva (banda
         de 0,16 m de sub muchia lamei din fata) + AO.
      c) fete mari, plane; fata din fata a fiecarei lame cu o coama (2-3 fatete).
      d) 6 BLOCURI plate la picior (plansa ~8-10, contractul 4-6; iau 6), cu fata
         mare pe aceeasi foliatie.
      e) NU intra: muschiul verde-galben de pe fete (corectura: fara vegetatie
         lipita), pietrisul marunt imprastiat de pe plansa.
    Noduri: Schist_Schist (MARBLE_GREY 29), Schist_Crack (VOLCANIC_BLACK 20).
    Cadru: s (sensul in care coboara foliatia) la 120 grade (spre -X+Y): in 3/4
    din fata (camera pe +X+Y) coboara spre DREAPTA in imagine si fetele lungi
    privesc spre camera, ca pe plansa; v (adancimea placilor) spre -X-Y.
    """
    sch, crk = Builder(), Builder()
    fr = SchistFrame((0.0, 0.0, 0.0), 120.0)
    dip, gap = 68.0, 0.14
    profs, cracks = foliation_stack(0.0, dip, [(6.1, 0.0, 5.0), (4.9, 0.55, 4.0),
                                               (3.6, 0.55, 4.0), (2.4, 0.50, 3.0)],
                                    gap=gap, tip_cut=0.2)
    W = [2.2, 2.0, 1.9, 1.7]
    V0 = [0.0, 0.25, 0.10, 0.40]
    # fata din fata a placilor stivei e plana + coama (fatete); fisura diagonala
    # sta la 0,04 m in spatele celei mai retrase fete din pereche si se vede ca
    # rost; spatele se subtiaza si coboara (pana din lateral, nu cutie)
    for k, prof in enumerate(profs):
        schist_slab(sch, fr, prof, V0[k], W[k], ridge=0.22, taper=0.0, seed=1 + k,
                    jit=0.0, back_taper=0.55, v_drop=0.22)
    for k, poly in enumerate(cracks):
        va = max(V0[k], V0[k + 1]) + 0.04
        vb = min(V0[k] + W[k], V0[k + 1] + W[k + 1]) * 0.55
        crack_strip(crk, fr, poly, va, vb)
    # lama joasa din fata-stanga (v negativ = spre camera)
    fprof = slab_profile(-0.25, 3.2, back_lean=2.0, dip=72.0, tip_cut=0.15, belly=0.05)
    fth = 0.85
    schist_slab(sch, fr, fprof, -0.30 - fth, fth, ridge=0.12, taper=0.3, seed=8)
    crack_between(crk, fr, fprof, profs[0], -0.30, 0.30)
    chips = [(-0.80, 0.60, (1.00, 0.70, 0.45), 0.0),
             (5.05, 1.20, (0.80, 0.60, 0.40), 30.0),
             (2.30, -1.45, (0.90, 0.70, 0.40), -20.0),
             (4.60, -0.80, (0.70, 0.50, 0.35), 50.0),
             (3.60, 2.75, (1.00, 0.80, 0.50), 10.0),
             (0.40, 2.75, (0.80, 0.60, 0.40), -35.0)]
    for i, (s, v, size, yaw) in enumerate(chips):
        schist_chip(sch, fr, s, v, size, dip=34.0, yaw=yaw, seed=50 + i)
    return [sch.to_object("Schist_Schist"), crk.to_object("Schist_Crack")]


def _stack_piece(sch, crk, fr, profs, cracks, W, V0, seed0, ridge=0.18,
                 back_taper=0.5, v_drop=0.2):
    """Placile unei stive `foliation_stack` extrudate pe v (W, V0 per placa) +
    fisurile diagonale dintre ele (adancite 0,04 m in spatele fetei celei mai
    retrase din pereche, pana la ~55% din adancimea comuna)."""
    for k, prof in enumerate(profs):
        schist_slab(sch, fr, prof, V0[k], W[k], ridge=ridge, taper=0.0, seed=seed0 + k,
                    jit=0.0, back_taper=back_taper, v_drop=v_drop)
    for k, poly in enumerate(cracks):
        if len(poly) < 3:
            continue
        va = max(V0[k], V0[k + 1]) + 0.04
        vb = min(V0[k] + W[k], V0[k + 1] + W[k + 1]) * 0.55
        crack_strip(crk, fr, poly, va, vb)


def build_schist_outcrop_b():
    """Aflorimentul de sist B (`schist_outcrop_b`): 3,5 m inalt, 8 m lat, h/l ~0,45.

    LISTA DE ELEMENTE (decuparea `schist_outcrop_b.png` + CORECTURA kitului:
    "variantele difera ca silueta"; pe plansa b e un grup INALT de 3 varfuri,
    aproape identic cu a si c, deci urmez tabelul -- joasa si lata -- si iau
    din plansa doar vocabularul: lame ascutite, fatete mari, fisuri, blocuri):
      a) CREASTA JOASA de 4 placi pe foliatie aproape culcata (27 grade fata de
         orizontala; contractul ~25), stivuite in lungul crestei: din lateral un
         DINTE DE FIERASTRAU cu 4 dinti, varfuri la 2,5 / 3,5 / 3,1 / 2,7 m,
         la s = 0,4 / 1,3 / 3,8 m; fiecare dinte iese 0,8-1,5 m peste fata
         placii de dinainte (runda 1 avea si un al 4-lea dinte, o placa subtire
         care citea ca o cutie asezata deasupra -- scoasa in runda 2).
      b) capatul din aval TAIAT de o fractura abrupta (~65 grade) la 7,7 m, cu
         fata de ~1 m (altfel ultima placa ar cobori pana la 10 m).
      c) FISURILE diagonale dintre placi (`Schist_Crack`), rost de 0,14 m + AO.
      d) 5 lespezi PLATE la picior (0,3 m groase, ingropate 40%), pe ambele
         parti ale crestei (runda 1: blocuri groase care citeau ca "picioare").
      e) NU intra: muschiul, pietrisul marunt.
    Noduri: Schist_Schist (MARBLE_GREY 29), Schist_Crack (VOLCANIC_BLACK 20).
    Cadru ca la `a` (s la 120 grade).
    """
    sch, crk = Builder(), Builder()
    fr = SchistFrame((0.0, 0.0, 0.0), 120.0)
    profs, cracks = foliation_stack(0.0, 27.0, [(2.5, 0.0, 10.0), (3.5, 1.15, 6.0),
                                                (3.1, 0.62, 6.0)],
                                    gap=0.14, tip_cut=0.18)
    profs = [cut_profile(p, 7.7, 25.0) for p in profs]
    cracks = [cut_profile(p, 7.7, 25.0) for p in cracks]
    W = [2.3, 2.6, 2.2]
    V0 = [0.20, 0.0, 0.25]
    _stack_piece(sch, crk, fr, profs, cracks, W, V0, 11, ridge=0.2, back_taper=0.5,
                 v_drop=0.25)
    chips = [(-0.70, 0.90, (1.30, 0.90, 0.32), 10.0),
             (2.60, -0.55, (1.20, 0.80, 0.30), -25.0),
             (5.20, -0.50, (1.40, 0.90, 0.34), 35.0),
             (8.10, 1.10, (1.20, 0.90, 0.32), -10.0),
             (4.40, 2.85, (1.20, 0.80, 0.30), 20.0)]
    for i, (s, v, size, yaw) in enumerate(chips):
        schist_chip(sch, fr, s, v, size, dip=14.0, yaw=yaw, seed=70 + i, sink=0.4)
    return [sch.to_object("Schist_Schist"), crk.to_object("Schist_Crack")]


def build_schist_outcrop_c():
    """Aflorimentul de sist C (`schist_outcrop_c`): ACUL, 8 m inalt, 4 m lat, h/l ~2,0.

    LISTA DE ELEMENTE (decuparea `schist_outcrop_c.png` + CORECTURA kitului; pe
    plansa c e un grup lat cu 2 varfuri principale si 4-5 lame mai mici, aproape
    identic cu b -- urmez tabelul: "un ac: o singura lama verticala, crapata pe
    lung in doua, cu un umar la jumatate"):
      a) ACUL: o singura lama aproape verticala (foliatia la 80 grade), varf
         ascutit, tesit, la 8 m, usor aplecat (fata din spate la 12 grade).
      b) CRAPAT PE LUNG: a doua jumatate e o placa de 0,9 m lipita pe fata lunga
         a acului, despartita de o fisura aproape verticala (`Schist_Crack`) de
         la sol pana la 4,4 m.
      c) UMARUL: varful jumatatii a doua, taiat aproape orizontal la ~4,5 m
         (la jumatatea acului).
      d) 5 blocuri plate la picior (plansa: 8-10 si pietris; iau 5).
      e) NU intra: muschiul, varfurile secundare de pe plansa.
    Noduri: Schist_Schist (MARBLE_GREY 29), Schist_Crack (VOLCANIC_BLACK 20).
    Cadru ca la `a` (s la 120 grade).
    """
    sch, crk = Builder(), Builder()
    fr = SchistFrame((0.0, 0.0, 0.0), 120.0)
    # fata "din spate" a jumatatii a doua e o diaclaza aproape ORIZONTALA (78
    # grade fata de verticala): taie placa in UMAR plat. Cu 4 grade (runda 1)
    # taietura era aproape paralela cu foliatia si iesea o aschie ascutita.
    # runda 3: acul mai ingust (spatele la 7 grade, a doua jumatate 0,75 m,
    # adancimea 1,7 m) si blocurile stranse la picior -- runda 2 masura h/l 1,45
    # fata de 2,0 cerut
    profs, cracks = foliation_stack(0.0, 80.0, [(8.0, 0.0, 7.0), (4.5, 0.75, 78.0)],
                                    gap=0.16, tip_cut=0.25)
    W = [1.7, 1.5]
    V0 = [0.0, 0.12]
    _stack_piece(sch, crk, fr, profs, cracks, W, V0, 21, ridge=0.22, back_taper=0.5,
                 v_drop=0.12)
    chips = [(-0.35, 0.60, (0.90, 0.70, 0.34), 15.0),
             (3.55, 0.40, (0.80, 0.70, 0.32), -30.0),
             (1.60, -0.55, (0.90, 0.60, 0.30), 40.0),
             (2.70, 1.85, (0.90, 0.70, 0.32), 5.0),
             (0.70, 1.95, (0.80, 0.60, 0.30), -20.0)]
    for i, (s, v, size, yaw) in enumerate(chips):
        schist_chip(sch, fr, s, v, size, dip=20.0, yaw=yaw, seed=90 + i, sink=0.4)
    return [sch.to_object("Schist_Schist"), crk.to_object("Schist_Crack")]


ONLY = os.environ.get("TF_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


if _want("schist_outcrop_a"):
    emit_tf(build_schist_outcrop_a(), "rocks/schist_outcrop_a.glb", _ao(6.0),
            keep_xy=False, bevel=0.05, bevels={"_Crack": 0.0}, smooth_angle=None)

if _want("schist_outcrop_b"):
    emit_tf(build_schist_outcrop_b(), "rocks/schist_outcrop_b.glb", _ao(3.5),
            keep_xy=False, bevel=0.05, bevels={"_Crack": 0.0}, smooth_angle=None)

if _want("schist_outcrop_c"):
    emit_tf(build_schist_outcrop_c(), "rocks/schist_outcrop_c.glb", _ao(8.0),
            keep_xy=False, bevel=0.05, bevels={"_Crack": 0.0}, smooth_angle=None)

report_tf()
