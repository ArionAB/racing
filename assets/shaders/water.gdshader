shader_type spatial;
// Apa insulei — PRIMUL shader custom din proiect.
//
// Contract, in ordinea importantei:
//
// 1. OPAC. Fara TRANSPARENCY, fara alpha, fara depth_prepass. Nu e o alegere
//    estetica: garda din tools/probe_decor.gd numara mesh-uri, materiale si
//    triunghiuri, dar e complet OARBA la overdraw si la sortarea de
//    transparenta — exact costul care omoara fps-ul pe mobil. O suprafata de
//    apa transparenta care acopera jumatate din ecran ar trece garda cu
//    "+1 material" si ar injumatati frame rate-ul pe telefon fara ca nimic
//    sa semnaleze. Adancimea o citim din vertex colors coapte la generare
//    (vezi Track._build_water), nu din DEPTH_TEXTURE.
//
// 2. UNSHADED. Marea nu primeste lumina, umbra sau specular: o oglinda pe apa
//    ar cere reflexii, interzise pe mobil (style_bible §8), iar cascada de
//    umbre e de 90 m — acne garantat pe o suprafata plata de sute de metri.
//
//    Costul deciziei, si e real: apa sare peste pasul de iluminare pe care
//    fiecare alta suprafata din lume il primeste, deci culorile ei nu mai cad
//    singure unde trebuie. S-a incercat si varianta iluminata, tocmai ca sa
//    existe o singura conventie — nu merge: culorile INCHISE hranite ca liniare
//    se umfla, iar lumina de aici nu le mai coboara, si marea iesea palida.
//    Terenul nu are culori inchise, de-asta problema n-a aparut niciodata pana
//    la mare.
//
//    Compensarea sta intr-un singur loc, pe CPU si documentata cu numere:
//    Track.water_tint() — desaturare (adjustment_saturation e 1.18), un gain
//    masurat, si srgb_to_linear. Rezultat verificat: largul #23606E fata de
//    tinta #2E5F6B, reciful #54BCB8 fata de #54BFB8.
//
// 3. ZERO texturi noi. Ondulatia vine din detail_rock.png, textura care exista
//    deja si e incarcata oricum de Palette.world_material(). Doua straturi la
//    scari si viteze diferite, inmultite: tiparul rezultat nu are perioada
//    vizibila. Un asset nou ar fi insemnat +VRAM pentru un efect care se poate
//    face din ce avem.
//
// Ce NU face, intentionat: reflexii (SSR e interzis pe mobil, style_bible §8),
// refractie, spuma din depth fade. Spuma e GEOMETRIE — banda de varfuri unde
// apa atinge tarmul, colorata la generare.
render_mode unshaded, cull_back, depth_draw_opaque;

// detail_rock.png: gri, centrata pe ALB (medie masurata 0.89), tileabila.
// Se INMULTESTE peste culoare, deci intuneca — de-asta amplitudinea e mica.
uniform sampler2D ripple_tex : source_color, filter_linear_mipmap, repeat_enable;

// Scarile sunt in unitati de lume: 0.030 => o repetitie la ~33 m, 0.009 => la
// ~110 m. Necomensurabile intentionat, ca suprapunerea sa nu se repete.
uniform float scale_near : hint_range(0.005, 0.15) = 0.030;
uniform float scale_far : hint_range(0.002, 0.05) = 0.009;
// Deriva, in metri pe secunda. Lenta: la viteza de cursa o apa care curge
// repede citeste ca zgomot, nu ca mare.
uniform vec2 drift_near = vec2(0.55, 0.30);
uniform vec2 drift_far = vec2(-0.28, 0.44);
// Cat de tare bate ondulatia. 0 = culoare plata din vertex colors.
uniform float ripple_strength : hint_range(0.0, 1.0) = 0.35;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Coordonate de LUME, nu UV de mesh: asa ondulatia curge continuu peste
	// toate petecele de apa si nu se vede grila din care e facut planul.
	vec2 p = world_pos.xz;
	vec2 uv_near = p * scale_near + TIME * drift_near * scale_near;
	// Al doilea strat pe coordonate ROTITE 90°. detail_rock.png are strate
	// ORIZONTALE (e o textura de roca sedimentara), deci doua esantioane cu
	// aceeasi orientare se aduna in dungi paralele — la prima randare marea
	// citea ca un gard de scanduri verticale. Rotite, cele doua seturi de dungi
	// se incruciseaza si rezultatul citeste ca unda.
	vec2 uv_far = vec2(p.y, -p.x) * scale_far + TIME * drift_far * scale_far;
	float a = texture(ripple_tex, uv_near).r;
	float b = texture(ripple_tex, uv_far).r;
	float ripple = mix(1.0, a * b, ripple_strength);
	// COLOR = culoarea coapta in mesh: sea_deep / reef_shallow / foam_white,
	// interpolate dupa adancime, si deja corectate de Track.water_tint().
	// Aici doar o modulam — nicio corectie de culoare in shader, ca sa existe
	// un singur loc unde se calibreaza.
	ALBEDO = COLOR.rgb * ripple;
}
