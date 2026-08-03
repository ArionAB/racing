"""rock_cluster.glb — 5 grupuri de bolovani. Brief: docs/asset_briefs/rock_cluster.md

Aici se plateste densitatea decorului. UN GRUP = UN MESH: patru pietre asezate
impreuna in Blender costa un singur draw call in joc, in loc de patru. Cu ~180 de
grupuri pe pista, diferenta e intre 180 si 700+ de instante.

Buget: S <= 100, M <= 240, L <= 350 tris. Total <= 900.

Cifrele au fost revizuite in sus fata de estimarea initiala (60/130/250, total
630), care ignora ce costa bevel-ul: el adauga o banda de geometrie la FIECARE
muchie, iar un grup de 3 pietre are de ~3 ori mai multe muchii decat o piatra
singura. Compensam acolo unde conteaza — grupurile mici, care sunt cele mai
numeroase pe pista, primesc bevel zero.

Sloturi: rock_light (corp), rock_dark (pietrele mici de la baza).
"""

import bpy


def cluster(name, pieces, seg=6, rings=3, bevel=0.15):
    """pieces: lista de (offset_xyz, marime_xyz, slot, seed).

    Pietrele se INTREPATRUND deliberat (offseturile sunt mai mici decat razele):
    un grup in care pietrele doar se ating citeste ca obiecte separate puse
    alaturi, nu ca o formatiune.

    `bevel` scade cu dimensiunea grupului. style_bible §3 cere 0.15 pentru stanci,
    dar aia e valoarea pentru bolovani mari: pe o pietricica de 40 cm, o banda de
    15 cm inseamna o treime din obiect — arata umflat SI dubleaza triunghiurile,
    pentru ca bevel-ul adauga geometrie la fiecare muchie.
    """
    b = Builder()
    for (off, size, slot, seed) in pieces:
        b.rock(off, size, slot, seed=seed, segments=seg, rings=rings,
               taper=0.45, squash=0.8)
    obj = b.to_object(name)
    stats = finish(
        obj,
        bevel=bevel,
        ao=dict(samples=24, dist=2.0, gradient="vertical",
                low=0.45, high=1.0, power=0.8, floor=0.14),
    )
    return obj, stats


CLUSTERS = [
    # S: pietricele de langa drum, 0.6-0.9 m. Fara coliziune in joc.
    #
    # 4 laturi, 2 inele, bevel ZERO: sunt cele mai numeroase (peste 100 pe pista)
    # si cele mai putin vizibile. Cu bevel costau 180 tris, fara costa 88 — iar la
    # 70 cm inaltime, vazute in trecere, silueta e tot ce se citeste.
    ("Cluster_S1", [
        ((0.0, 0.0, 0.0), (0.85, 0.70, 0.55), ROCK_LIGHT, 5),
        ((0.42, 0.18, 0.0), (0.45, 0.40, 0.32), ROCK_LIGHT, 23),
        ((-0.30, -0.22, 0.0), (0.36, 0.34, 0.26), ROCK_DARK, 41),
    ], 4, 2, 0.0),
    ("Cluster_S2", [
        ((0.0, 0.0, 0.0), (0.70, 0.62, 0.62), ROCK_LIGHT, 59),
        ((-0.38, 0.16, 0.0), (0.40, 0.36, 0.30), ROCK_DARK, 71),
    ], 4, 2, 0.0),

    # M: bolovani de 2.0-2.8 m, banda de mijloc. Cu coliziune.
    ("Cluster_M1", [
        ((0.0, 0.0, 0.0), (2.40, 2.00, 2.10), ROCK_LIGHT, 89),
        ((1.15, 0.45, 0.0), (1.10, 0.95, 0.85), ROCK_LIGHT, 103),
        ((-0.85, -0.55, 0.0), (0.80, 0.72, 0.55), ROCK_DARK, 127),
    ], 5, 2, 0.08),
    ("Cluster_M2", [
        ((0.0, 0.0, 0.0), (2.00, 2.30, 2.60), ROCK_LIGHT, 149),
        ((-1.00, 0.35, 0.0), (0.95, 0.85, 0.70), ROCK_DARK, 167),
    ], 5, 2, 0.08),

    # L: formatiune de 6-7 m pentru banda din spate. Un dominant + sateliti.
    # Singura care primeste bevel-ul complet din style_bible.
    ("Cluster_L1", [
        ((0.0, 0.0, 0.0), (5.40, 4.60, 6.20), ROCK_LIGHT, 191),
        ((2.60, 1.10, 0.0), (2.20, 1.90, 2.40), ROCK_LIGHT, 211),
        ((-2.20, -0.90, 0.0), (1.80, 1.60, 1.50), ROCK_DARK, 233),
    ], 6, 3, 0.15),
]

clear_built("Cluster_")
built = []
for i, (name, pieces, seg, rings, bev) in enumerate(CLUSTERS):
    obj, stats = cluster(name, pieces, seg, rings, bev)
    obj.location = (i * 8.0, 0.0, 0.0)
    built.append(obj)
    print("%-12s %d pietre -> %3d tris | AO %.2f..%.2f"
          % (name, len(pieces), stats["tris"], stats["ao_min"], stats["ao_max"]))

print("TOTAL: %d tris (buget 900)" % sum(tri_count(o) for o in built))

for o in built:
    o.location = (0.0, 0.0, 0.0)
print("GLB:  %s (%d B)" % export_glb(built, "rock_cluster.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "rock_cluster.blend"))
for i, o in enumerate(built):
    o.location = (i * 8.0, 0.0, 0.0)
