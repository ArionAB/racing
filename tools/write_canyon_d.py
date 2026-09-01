"""Rescrie nodurile Faleza + BuzaRapei din Track13.tscn din canyon_d_rows.txt.

Numarul de module se schimba intre rulari (rupturile din generator sar peste
unele), deci nu se poate folosi tools/apply_transforms.py, care patch-eaza
noduri EXISTENTE. Aici se sterg cele doua grupuri si se scriu la loc.

Nu se atinge nimic altceva din scena: hornul crapat, Peaks, Scobituri si Path
raman byte-identice (memoria `.tscn-editat-de-mana-nu-se-rescrie`).
"""
import math
import sys

TSCN = "scenes/tracks/Track13.tscn"
ROWS = "canyon_d_rows.txt"
RUBBLE = "canyon_d_rubble.txt"
STRATA = "canyon_d_strata.txt"
BASE = "DecorManual/D) Canionul rosu"


def basis_pitch(yaw: float, pitch: float, sc: float) -> str:
    """Ca `basis`, dar cu o inclinare in jurul axei X inainte de yaw.

    Bolovanii de grohotis nu stau drepti: fara pitch, 61 de blocuri cu aceeasi
    axa verticala ar reface exact "randul de placi paralele" pentru care a
    picat peretele lui POI F.
    """
    cy, sy = math.cos(yaw), math.sin(yaw)
    cp, sp = math.cos(pitch), math.sin(pitch)
    # Ry * Rx, pe coloane.
    x = (cy, 0.0, -sy)
    y = (sy * sp, cp, cy * sp)
    z = (sy * cp, -sp, cy * cp)
    v = [c * sc for c in (x + y + z)]
    return ", ".join("%.5f" % c for c in v)


def basis_box(yaw: float, sx: float, sy: float, sz: float) -> str:
    """Basis pentru o treapta de strat: rotatie in jurul lui Y, scalare
    NEUNIFORMA pe cele trei axe.

    Cutia e un `BoxMesh` unitar (1x1x1) instantiat o singura data ca
    sub-resursa; lungimea benzii, buza de 0.3 m si adancimea intra prin scara,
    deci 184 de trepte nu aduc 184 de mesh-uri.

    Coloanele sunt scrise ca la `basis` (verificat pe un nod real), doar ca
    fiecare coloana isi ia propriul factor.
    """
    c, s_ = math.cos(yaw), math.sin(yaw)
    return "%.5f, 0.00000, %.5f, 0.00000, %.5f, 0.00000, %.5f, 0.00000, %.5f" % (
        c * sx, s_ * sx, sy, -s_ * sz, c * sz)


def basis(yaw: float, sc: float) -> str:
    """Basis-ul lui Transform3D, pe COLOANE — asa il scrie Godot.

    Verificat pe un nod REAL din scena veche, nu dedus din conventie: pentru
    `Strat0_01` (sc 1.291) fisierul avea X = (-0.71590, 0, 1.07432) si
    Z = (-1.07432, 0, -0.71590). De aici ies coloanele de mai jos:
        X = ( c*sc, 0,  s*sc)
        Z = (-s*sc, 0,  c*sc)
    Prima versiune scrisese TRANSPUSA (semnul lui `s` inversat pe amandoua
    coloanele), adica ar fi oglindit fiecare modul. Se prindea numai comparand
    cu un rand vechi — memoria `rotatii-in-builder-semnul`: se deriva, nu se
    ghiceste.
    """
    c, s = math.cos(yaw), math.sin(yaw)
    return "%.5f, 0.00000, %.5f, 0.00000, %.5f, 0.00000, %.5f, 0.00000, %.5f" % (
        c * sc, s * sc, sc, -s * sc, c * sc)


def main() -> int:
    rows = []
    for line in open(ROWS, encoding="utf-8"):
        if not line.strip():
            continue
        p = line.split("\t")
        rows.append({"side": int(p[0]), "tier": int(p[1]), "x": float(p[3]),
                     "y": float(p[4]), "z": float(p[5]), "yaw": float(p[6]),
                     "sc": float(p[7])})

    rubble = []
    for line in open(RUBBLE, encoding="utf-8"):
        if not line.strip():
            continue
        p = line.split("	")
        rubble.append({"x": float(p[0]), "y": float(p[1]), "z": float(p[2]),
                       "yaw": float(p[3]), "pitch": float(p[4]),
                       "sc": float(p[5])})

    # Treptele de strat: cutii, nu instante de GLB (vezi gen_strata_d.gd).
    strata = []
    for line in open(STRATA, encoding="utf-8"):
        if not line.strip():
            continue
        p = line.split("	")
        strata.append({"x": float(p[0]), "y": float(p[1]), "z": float(p[2]),
                       "yaw": float(p[3]), "len": float(p[4]),
                       "lip": float(p[5]), "depth": float(p[6])})


    text = open(TSCN, encoding="utf-8").read()
    cut = text.index('[node name="Faleza" type="Node3D"')
    head = text[:cut]

    out = ['[node name="Faleza" type="Node3D" parent="%s"]' % BASE, ""]
    n_fal = 0
    for r in [r for r in rows if r["side"] == 1]:
        n_fal += 1
        out.append('[node name="Strat%d_%02d" parent="%s/Faleza" '
                   'instance=ExtResource("9_band")]' % (r["tier"], n_fal, BASE))
        out.append("transform = Transform3D(%s, %.3f, %.3f, %.3f)" % (
            basis(r["yaw"], r["sc"]), r["x"], r["y"], r["z"]))
        out.append("")

    out.append('[node name="BuzaRapei" type="Node3D" parent="%s"]' % BASE)
    out.append("")
    n_bz = 0
    for r in [r for r in rows if r["side"] == -1]:
        n_bz += 1
        out.append('[node name="Buza_%02d" parent="%s/BuzaRapei" '
                   'instance=ExtResource("9_band")]' % (n_bz, BASE))
        out.append("transform = Transform3D(%s, %.3f, %.3f, %.3f)" % (
            basis(r["yaw"], r["sc"]), r["x"], r["y"], r["z"]))
        out.append("")

    out.append('[node name="Grohotis" type="Node3D" parent="%s"]' % BASE)
    out.append("")
    for i, r in enumerate(rubble, 1):
        out.append('[node name="Bloc_%02d" parent="%s/Grohotis" '
                   'instance=ExtResource("9_band")]' % (i, BASE))
        out.append("transform = Transform3D(%s, %.3f, %.3f, %.3f)" % (
            basis_pitch(r["yaw"], r["pitch"], r["sc"]),
            r["x"], r["y"], r["z"]))
        out.append("")

    # --- TREPTELE DE STRAT (runda 3) ---------------------------------------
    #
    # `BoxMesh` unitar, scalat: cutii reale scoase din fata modulului, fiindca
    # modulul NU are trepte in profil (ProbeCappProf2: fata merge neted de la
    # z=-3.82 la z=-1.20 pe 12.4 m, deci benzile de pe captura erau exclusiv
    # textura). Numele incepe cu `Treapta_`, deci `prop_classes()` ii da
    # `red_valley_tuff` — acelasi material ca al peretelui, zero in plus.
    out.append('[node name="Strate" type="Node3D" parent="%s"]' % BASE)
    out.append("")
    for i, r in enumerate(strata, 1):
        out.append('[node name="Treapta_%03d" type="MeshInstance3D" '
                   'parent="%s/Strate"]' % (i, BASE))
        out.append('mesh = SubResource("BoxMesh_strat")')
        out.append("transform = Transform3D(%s, %.3f, %.3f, %.3f)" % (
            basis_box(r["yaw"], r["len"], r["lip"], r["depth"]),
            r["x"], r["y"], r["z"]))
        out.append("")

    open(TSCN, "w", encoding="utf-8", newline="\n").write(head + "\n".join(out))
    print("faleza=%d buza=%d grohotis=%d strate=%d total=%d" % (
        n_fal, n_bz, len(rubble), len(strata),
        n_fal + n_bz + len(rubble) + len(strata)))


if __name__ == "__main__":
    sys.exit(main())
