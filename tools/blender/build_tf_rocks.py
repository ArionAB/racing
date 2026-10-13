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


ONLY = os.environ.get("TF_ONLY", "")


def _want(name):
    return not ONLY or ONLY == name


if _want("schist_outcrop_a"):
    emit_tf(build_schist_outcrop_a(), "rocks/schist_outcrop_a.glb", _ao(6.0),
            keep_xy=False, bevel=0.05, bevels={"_Crack": 0.0}, smooth_angle=None)

report_tf()
