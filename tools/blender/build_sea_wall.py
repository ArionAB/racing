"""sea_wall_segment.glb — digul portului (SEA_WALL_SEGMENT, 1.2 m).

Referinta: assets/okinawa_inspiration/, randul ROADSIDE. Parapetul de beton de
pe faleza portului (sectorul 1), pus cap la cap ca sa formeze un zid continuu.

DOUA REGULI care fac diferenta intre "segment" si "cutie":

1. **Se imbina fara rost vizibil.** Fetele de capat sunt PLANE si exact la
   ±LENGTH/2, fara bevel pe muchiile verticale de capat — doua segmente lipite
   trebuie sa arate ca un zid turnat, nu ca doua cutii puse alaturi. De-aia
   bevel-ul e mic (0.03) si conteaza ca panta sa fie continua.
2. **Lungimea e un numar rotund.** 4.0 m fix, ca `_dists` sa poata aseza
   N segmente pe o distanta cunoscuta fara sa ramana o bucata de 37 cm.

Variantele difera doar prin uzura si prin pete, nu prin cote: doua segmente cu
lungimi diferite nu s-ar mai imbina.

  Sea_Wall_A  segment curat
  Sea_Wall_B  segment cu o crapatura si colt ciobit
  Sea_Wall_C  segment cu stalp de amaraj (bolard) — se pune din 3 in 3

Clasa de material: `concrete` pe UV cubic 1.5 m.
"""

LENGTH = 4.00        # contract: segmentele se aseaza cap la cap
HEIGHT = 1.20        # cota din foaia de referinta
THICK = 0.42
CAP_H = 0.13         # coama lata de deasupra, care prinde lumina razanta
BASE_H = 0.20


def body(b):
    """Soclu evazat + corp usor inclinat + coama.

    Inclinarea (corpul e cu 6 cm mai subtire sus decat jos) nu e cosmetica: un
    parapet marin chiar e in panta ca sa sparga valul, si e singurul lucru care
    face un dreptunghi de beton sa citeasca a lucrare de coasta.
    """
    b.box((0.0, 0.0, BASE_H * 0.5), (LENGTH, THICK + 0.16, BASE_H), CONCRETE)
    mid_z = (BASE_H + HEIGHT - CAP_H) * 0.5
    mid_h = HEIGHT - CAP_H - BASE_H
    b.box((0.0, 0.0, mid_z + BASE_H * 0.5), (LENGTH, THICK, mid_h), CONCRETE)
    b.box((0.0, 0.0, HEIGHT - CAP_H * 0.5), (LENGTH, THICK + 0.14, CAP_H),
          CONCRETE)


def clean(b):
    body(b)


def cracked(b):
    body(b)
    # Coltul ciobit: o cutie mica scoasa in afara, la nivelul coamei. Nu e o
    # gaura (n-avem boolean in pipeline) — e o bucata care IESE, ca o aschie de
    # beton desprinsa. La 20 m diferenta nu se vede, silueta rupta da.
    b.box((LENGTH * 0.5 - 0.18, 0.0, HEIGHT - CAP_H - 0.06),
          (0.30, THICK + 0.10, 0.12), CONCRETE)
    b.box((-LENGTH * 0.18, THICK * 0.5, HEIGHT * 0.55),
          (0.07, 0.05, HEIGHT * 0.42), ASPHALT_EDGE)


def bollard(b):
    """Stalp de amaraj: ciuperca de fonta in care se leaga barcile."""
    body(b)
    b.taper_sweep([(0, 0, HEIGHT - CAP_H), (0, 0, HEIGHT + 0.24),
                   (0, 0, HEIGHT + 0.34)],
                  [0.115, 0.095, 0.13], RUST, segments=8)
    b.taper_sweep([(0, 0, HEIGHT + 0.34), (0, 0, HEIGHT + 0.42)],
                  [0.13, 0.06], RUST, segments=8)


AO_SPEC = dict(samples=24, dist=1.6, gradient="vertical",
               low=0.50, high=1.0, power=0.75, floor=0.18)

PARTS = [("Sea_Wall_A", clean), ("Sea_Wall_B", cracked),
         ("Sea_Wall_C", bollard)]

clear_built("Sea_Wall_")
built = []
for name, fill in PARTS:
    b = Builder()
    fill(b)
    obj = b.to_object(name)
    stats = finish(obj, bevel=0.03, ao=AO_SPEC)
    cube_uvs(obj, 1.5)
    built.append(obj)
    d = obj.dimensions
    print("%-14s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "sea_wall_segment.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "sea_wall_segment.blend"))
for i, o in enumerate(built):
    o.location = (0.0, i * 1.4, 0.0)
