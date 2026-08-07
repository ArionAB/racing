"""tetrapod.glb — spargatoare de val de beton (Okinawa), trei variante.

Referinta: assets/okinawa_inspiration/, randul TETRAPODS. Tetrapodul e piesa
care spune "coasta japoneza" mai tare decat orice altceva: dig de beton, patru
picioare tronconice dintr-un butuc central, unul in sus si trei sprijinite. Pe
pista strajuiesc causeway-ul (sectorul 8) pe ambele laturi.

  Tetrapod_01        1.8 m — piesa de umplere, se aseaza in siruri dese
  Tetrapod_04        3.5 m — piesa mare, la capetele digului
  Tetrapod_Stack_01  3.0 m — gramada aruncata de utilaj: sase piese incalecate
                             in unghiuri diferite. Asta e cum arata un dig
                             ADEVARAT — tetrapozii nu se aseaza frumos, se
                             descarca.

Geometrie: patru trunchiuri de con pe directiile unui tetraedru regulat.
Unghiul dintre picioare e 109.47°, nu o valoare aleasa de ochi — cu orice
altceva piesa nu mai sta pe trei picioare fara sa se legene, si se vede.

Clasa de material: `concrete` pe UV cubic (betonul e o suprafata mare si plata,
exact cazul in care culoarea plata din atlas citeste ca plastic).
"""

import math
from mathutils import Vector, Matrix

# Proportiile sunt fractiuni din lungimea piciorului, ca o singura constanta de
# scara sa dea toate variantele. Prima versiune avea patru cote absolute si
# scalarea insemna patru editari corelate.
R_HUB = 0.276           # raza la butuc
R_WAIST = 0.196         # cea mai subtire sectiune, la ~66% din picior
R_FOOT = 0.222          # talpa se largeste inapoi — asa arata un tetrapod real

# Inaltimea unui tetrapod cu un varf in sus e 4/3 din lungimea piciorului, plus
# razele de la capete. Masurat: 1.556 x LEG_LEN. Cifra e folosita ca sa derivam
# lungimea piciorului din cota CERUTA, in loc s-o nimerim prin incercari.
H_PER_LEG = 1.556


def tetra_dirs(rot=None):
    """Cele patru directii ale tetraedrului, cu un varf pe +Z.

    Picioarele de jos stau la z = -1/3 si raza sqrt(8)/3 — coordonatele exacte
    ale tetraedrului regulat inscris in sfera. Rotunjite "aproximativ", piesa
    se sprijina pe doua picioare si intra cu al treilea in nisip.
    """
    dirs = [Vector((0.0, 0.0, 1.0))]
    for k in range(3):
        a = math.radians(90.0 + k * 120.0)
        dirs.append(Vector((math.cos(a) * math.sqrt(8.0) / 3.0,
                            math.sin(a) * math.sqrt(8.0) / 3.0,
                            -1.0 / 3.0)))
    if rot is not None:
        dirs = [rot @ d for d in dirs]
    return dirs


def tetrapod(b, slot, center=(0, 0, 0), leg_len=2.25, segments=8, rot=None):
    """Un tetrapod complet, in orice pozitie si orientare."""
    c = Vector(center)
    # Butucul: o sfera turtita ar fi fost 4224 de triunghiuri (nota din
    # CLAUDE.md); un bolovan cu 8 segmente si 3 inele face acelasi lucru cu 48.
    b.rock(c, (R_HUB * 2.05 * leg_len,) * 3, slot, seed=3, segments=segments,
           rings=3, taper=0.9)
    # Statiile sunt dese la capete si rare la mijloc, ca bevel-ul sa aiba unde
    # sa prinda muchia talpii.
    stations = [0.0, 0.22, 0.66, 0.93, 1.0]
    radii = [R_HUB, R_HUB * 0.82, R_WAIST, R_FOOT * 0.97, R_FOOT]
    for d in tetra_dirs(rot):
        path = [c + d * (leg_len * s) for s in stations]
        # Primul punct porneste din centru: picioarele se intrepatrund in butuc
        # si devin un singur volum dupa bevel, fara sa fie nevoie de boolean.
        b.taper_sweep(path, [r * leg_len for r in radii], slot,
                      segments=segments, cap_start=False, cap_end=True)


def single(name, height, segments=8):
    b = Builder()
    tetrapod(b, CONCRETE, leg_len=height / H_PER_LEG, segments=segments)
    return b.to_object(name)


def pile(name, height, count=6, seed=17):
    """Gramada: piese mai mici, rotite aleator, care se intrepatrund.

    Piesele sunt la 55% din cota gramezii si au 6 laturi in loc de 8 — la sase
    bucati incalecate, fatetele individuale nu se mai citesc, iar bugetul se
    inmulteste cu sase.
    """
    b = Builder()
    rnd = _lcg(seed)
    leg = (height * 0.62) / H_PER_LEG
    for k in range(count):
        rot = (Matrix.Rotation(rnd() * math.tau, 4, "Z")
               @ Matrix.Rotation(rnd() * math.tau, 4, "Y")
               @ Matrix.Rotation(rnd() * math.tau, 4, "X"))
        # Raza SCADE cu inaltimea si cotele URCA: iese o movila. Prima versiune
        # tinea raza constanta (~1.2 x piciorul) si punea piesele aproape la
        # aceeasi cota — rezultatul era un sir de tetrapozi imprastiati pe
        # 4.5 m, nu o gramada de 3. Suprapunerea e deliberata: tetrapozii
        # descarcati de utilaj chiar stau incalecati.
        t = k / max(count - 1, 1)
        r = leg * (0.78 - t * 0.58) * (0.60 + rnd() * 0.50)
        a = rnd() * math.tau
        z = leg * (0.80 + t * 1.00) + rnd() * leg * 0.16
        tetrapod(b, CONCRETE, center=(math.cos(a) * r, math.sin(a) * r, z),
                 leg_len=leg, segments=6, rot=rot)
    return b.to_object(name)


AO_SPEC = dict(samples=28, dist=2.0, gradient="vertical",
               low=0.52, high=1.0, power=0.85, floor=0.18)

clear_built("Tetrapod_")
built = []
for obj, uv in ((single("Tetrapod_01", 1.80), 0.9),
                (single("Tetrapod_04", 3.50), 1.5),
                (pile("Tetrapod_Stack_01", 3.00), 1.2)):
    # AO vertical pe TOATA piesa: partea de jos, prinsa intre picioare si nisip,
    # chiar sta la umbra permanent.
    stats = finish(obj, bevel=0.05, ao=AO_SPEC)
    # Beton: UV cubic la ~40% din cota piesei, deci tiparul prinde 2-3 repetitii
    # pe inaltime indiferent de marime — destul cat sa nu se citeasca ca tapet.
    cube_uvs(obj, uv)
    built.append(obj)
    d = obj.dimensions
    print("%-18s %4d tris  AO %.2f..%.2f  bbox %.2f x %.2f x %.2f m"
          % (obj.name, stats["tris"], stats["ao_min"], stats["ao_max"],
             d.x, d.y, d.z))

print("TOTAL: %d tris" % sum(tri_count(o) for o in built))
print("GLB:  %s (%d B)" % export_glb(built, "structures/tetrapod.glb"))
print("BLEND: %s (%d B)" % save_blend(built, "tetrapod.blend"))
for i, o in enumerate(built):
    o.location = (i * 5.0, 0.0, 0.0)
