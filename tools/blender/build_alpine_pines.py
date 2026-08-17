"""Kitul alpin — CONIFERELE (#222).

  Pine_A  trees/alpine_pines.glb   ~2.6 x 2.6 x 7 m   <= 400
  Pine_B  (acelasi GLB)            ~3.2 x 3.2 x 10 m  <= 550
  Pine_C  (acelasi GLB)            ~3.8 x 3.8 x 13 m  <= 600
  Pine_D  (acelasi GLB)            ~2.2 x 2.2 x 5 m   <= 300  (pui, tufa de sub)

Trei variante de talie plus un pui, ca padurea sa aiba silueta neregulata:
un rand de conifere identice citeste ca gard de brazi de Craciun. Toate in
ACELASI GLB, copii directi ai radacinii — vezi §"GLB-uri cu variante" din
blender_export.md; asa TrackDecor le poate alege cu `pick_from_glb`.

DE CE CONURI SUPRAPUSE, si nu un con: un molid are etaje de crengi, iar
silueta lui reala e o stiva de conuri care se ingusteaza spre varf. Un
singur con da un brad de plastic. Doua-patru etaje sunt destule la 60 km/h
(style_bible §3: fara detaliu de frecventa inalta) si costa ~3x mai putin
decat crengile individuale.

INALTIMEA E DERIVATA, NU ALEASA. Plafonul din frustumul lui ChaseCamera
(vezi memoria "inaltimea-obiectelor-si-camera") cere ca un obiect lipit de
drum sa nu depaseasca ~12 m, altfel varful iese din cadru si obiectul devine
un zid. Pinul mare (13 m) e DELIBERAT peste plafon: el nu se pune langa
asfalt, ci pe flancuri si in banda departata, unde distanta il aduce inapoi
in cadru. Cine il pune la 2 m de sosea greseste, si se vede imediat.

CULOAREA: verdele conifer nu are slot propriu in atlas (24..31 raman
magenta, vezi kit-alpin). CACTUS_GREEN e verde oliv sters — exact tenta unui
molid batut de vant la altitudine — iar tint_gradient il duce spre inchis la
baza (unde crengile se umbresc reciproc) si spre deschis la varf (unde
lujerii tineri prind soare). WOOD pentru trunchi.

TEXTURA (august 2026): coroana NU mai ramane pe atlas. In joc primeste clasa
triplanara `pine_needles` (Palette, ace pictate — vezi
tools/paint_pine_needles.py), iar vertex color-ul de mai sus (AO + gradient)
se inmulteste peste ea. Consecinte pentru geometrie, aici:
  - COROANA SI TRUNCHIUL SUNT OBIECTE SEPARATE (`Pine_X` + copilul `Trunk_X`).
    Clasa se aplica pe prefix de nume de nod (Palette.apply_class_materials),
    iar un singur mesh ar fi primit acele si pe trunchi. Trunchiul ramane pe
    atlas (WOOD).
  - MARGINEA DE JOS A FIECARUI ETAJ E ZIMTATA. Cu textura, conul neted
    devenea o palarie imbracata in tapet: silueta e cea care spune "crengi",
    nu suprafata. Inelul de jos alterneaza varfuri care atarna (raza intreaga,
    coborate) cu crestaturi (raza 0.82, ridicate); din profil, etajul are
    coltii pe care ii are un molid. Costa 12-14 segmente in loc de 6-7 —
    ~2x triunghiuri pe un asset care oricum era la 1/3 din buget.
  - AO MAI ADANC sub etaje (`low` 0.42 -> 0.30): cu detaliu in textura,
    umbra dintre etaje trebuie sa fie mai hotarata ca sa se citeasca fata de
    ace, altfel textura o inghite.
"""

import math

# Talia si numarul de etaje. Raportul inaltime/latime (~2.7) e cel al unui
# molid de munte, nu al unui pin mediteraneean — la altitudine coroana e
# ingusta fiindca zapada trebuie sa alunece de pe ea.
PINES = (
    # nume,    h_total, r_baza, etaje, trunchi_h, seed
    ("Pine_A",  7.0,   1.30,  3,  1.15,  5),
    ("Pine_B", 10.0,   1.60,  4,  1.45, 13),
    ("Pine_C", 13.0,   1.90,  4,  1.80, 23),
    ("Pine_D",  5.0,   1.10,  2,  0.80, 31),
)


def build_trunk(h_total, r_base, tiers, trunk_h, seed):
    b = Builder()
    # Trunchiul: se subtiaza vizibil (0.55x sus). Un cilindru drept citeste a
    # stalp, iar la un copac tocmai conicitatea spune "e viu". Urca pana sub
    # etajul al doilea, ca sa nu ramana gol intre primul etaj si ax cand
    # zimtii coboara sub linia conului.
    r_trunk = r_base * 0.115
    h = trunk_h + (h_total - trunk_h) * 0.35
    b.frustum((0.0, 0.0, h * 0.5), r_trunk, r_trunk * 0.55, h, WOOD,
              segments=6)
    return b


def _jag_bottom_ring(b, faces, z_bottom, tier_h, seed):
    """Zimteaza inelul de jos al unui etaj: varfurile impare atarna, cele pare
    se retrag. Alternanta pe indexul unghiular, nu la zar — un zimt lipsa
    citeste ca o gaura in coroana."""
    verts = set()
    for f in faces:
        for v in f.verts:
            if abs(v.co.z - z_bottom) < 1e-4:
                verts.add(v)
    ring = sorted(verts, key=lambda v: math.atan2(v.co.y, v.co.x))
    rand = _lcg(seed)
    for i, v in enumerate(ring):
        # putina variatie ca doi copaci vecini sa nu aiba acelasi profil
        j = rand() * 0.06
        if i % 2 == 0:
            v.co.z -= tier_h * (0.16 + j)          # coltul care atarna
        else:
            v.co.x *= 0.82 - j
            v.co.y *= 0.82 - j
            v.co.z += tier_h * 0.04                # crestatura


def build_pine(h_total, r_base, tiers, trunk_h, seed):
    b = Builder()
    # Etajele de crengi: conuri care se suprapun pe verticala.
    #
    # Suprapunerea (0.34 din inaltimea etajului) NU e ornament: fara ea, intre
    # conuri raman inele de trunchi gol si copacul citeste ca o stiva de palarii.
    # Cu ea, silueta e continua si crestaturile dintre etaje se vad doar in
    # contur — exact cum arata un molid.
    canopy_h = h_total - trunk_h
    tier_h = canopy_h / (tiers - 0.34 * (tiers - 1))
    z = trunk_h
    for i in range(tiers):
        t = i / float(max(tiers - 1, 1))
        # Raza scade spre varf; ultimul etaj se termina in ascutis (r_top=0).
        r_bot = r_base * (1.0 - 0.42 * t)
        r_top = r_bot * (0.0 if i == tiers - 1 else 0.34)
        # Segmente PARE, 12-14: zimtarea alterneaza varf/crestatura, deci
        # cere numar par; 12 vs 14 pe etaje alternante rupe simetria dintre
        # etaje (si dintre copaci vecini rotiti diferit). Sunt mai multe decat
        # cele 6-7 de dinainte — fatetele late (style_bible §3) raman pe
        # ETAJ, dar marginea are nevoie de rezolutie ca sa fie zimtata.
        segs = 14 if i % 2 == 0 else 12
        faces = b.frustum((0.0, 0.0, z + tier_h * 0.5), r_bot, r_top, tier_h,
                          CACTUS_GREEN, segments=segs)
        _jag_bottom_ring(b, faces, z, tier_h, seed + i * 7)
        z += tier_h * 0.66
    return b


# ------------------------------------------------------------------ build
AO_PINE = dict(samples=20, dist=2.5, gradient="vertical", low=0.30, high=1.0,
               power=0.9, floor=0.14)
AO_TRUNK = dict(samples=12, dist=1.5, gradient="vertical", low=0.5, high=0.9,
                power=1.0, floor=0.2)

clear_built("Pine")
clear_built("Trunk")
pine_objs = []
export_objs = []
for name, h_total, r_base, tiers, trunk_h, seed in PINES:
    b = build_pine(h_total, r_base, tiers, trunk_h, seed)
    obj = b.to_object(name)
    # Bevel MIC (0.02): la un con de 2 m diametru, o tesitura mai mare rotunjeste
    # varfurile de etaj si coniferul isi pierde exact ce il face conifer.
    # origin="none": coroana incepe la trunk_h, dar originea trebuie sa ramana
    # la SOL (z=0), unde e si a trunchiului — "base" ar fi urcat-o la primul
    # etaj si copacul s-ar fi infipt in pamant pana la crengi.
    stats = finish(obj, bevel=0.02, bevel_angle=40.0, ao=AO_PINE,
                   smooth_angle=50.0, origin="none")
    # Baza spre umbra rece (crengile de jos stau in propria umbra), varful spre
    # lujer tanar — acelasi tratament ca la AlpineShrub, si din acelasi motiv:
    # fara el masa verde e plata si padurea citeste ca fetru. Cu textura,
    # baza NU coboara mai mult: incercat 0.40 peste AO-ul adancit, si etajele
    # de jos ieseau aproape negre pe captura de sofer — umbra vine deja din
    # `low` 0.30, iar textura isi aduce singura fondul intunecat.
    tint_gradient(obj, base=(0.46, 0.56, 0.46), tip=(1.08, 1.02, 0.82))

    tb = build_trunk(h_total, r_base, tiers, trunk_h, seed)
    trunk = tb.to_object(name.replace("Pine_", "Trunk_"))
    tstats = finish(trunk, bevel=0.015, bevel_angle=40.0, ao=AO_TRUNK,
                    smooth_angle=50.0, origin="none")
    trunk.parent = obj
    trunk.matrix_parent_inverse = trunk.matrix_parent_inverse.Identity(4)

    me = obj.data
    dims = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices)
            for i in range(3)]
    print("%-8s %5d + %3d tris | %.1f x %.1f x %.1f m | AO %.2f..%.2f"
          % (name, stats["tris"], tstats["tris"], dims[0], dims[1],
             dims[2] + trunk_h, stats["ao_min"], stats["ao_max"]))
    obj.location = (0.0, 0.0, 0.0)
    trunk.location = (0.0, 0.0, 0.0)
    pine_objs.append(obj)
    export_objs += [obj, trunk]

print("GLB:   %s (%d B)" % export_glb(export_objs, "trees/alpine_pines.glb"))
print("BLEND: %s (%d B)" % save_blend(export_objs, "alpine_pines.blend"))
