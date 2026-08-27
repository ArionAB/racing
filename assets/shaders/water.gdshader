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
// refractie, citire de DEPTH_TEXTURE. "Adancimea" per pixel e COLOR.a, copta
// in vertex colors la generare (canalul era liber — materialul e opac, alfa
// e pur canal de date) si interpolata gratis de rasterizator.
//
// v2 (issue #99): gradient de adancime PER PIXEL (rampa era interpolata pe
// varfuri la 9.5 m si iesea in benzi), spuma animata la tarm, sun glint.
// Toate efectele noi au un uniform de intensitate cu 0 = comportamentul v1 —
// kill-switch pentru profilarea pe device (M4): daca 60fps nu tine, se sting
// pe rand de pe CPU, fara shader nou. Buget static: tot 2 esantioane de
// textura per pixel, plus ~30 de operatii ALU.
//
// v3: hula directionala (umbra in vale, lumina pe creasta, spargeri albe rare)
// si trepte de adancime. Motivul, in doua parti:
//
//   - un BUG: valurile de vertecsi din v2 (+/-12 cm) scufundau grila fina sub
//     placa de larg, care statea cu doar 4 cm mai jos, iar prin gauri se vedea
//     sea_deep. Pe laguna Okinawa ieseau pete mari albastru inchis, cu margini
//     poligonale, care se PLIMBAU (sinusoidele au TIME in ele). Reparatia nu e
//     in shader, ci in Track.SEA_FAR_DROP, acum derivat din amplitudine.
//   - o LIPSA: cu petele stinse, marea deschisa ramanea o placa perfect plata
//     de culoare. Singurul lucru care se misca pe ea era ondulatia din
//     detail_rock — o textura de ROCA, cu straturile ei — deci de la distanta
//     citea ca panza. Hula ii da directie si relief.
//
// Comparatie: docs/asset_briefs/img/okinawa_apa_v3.png.
// Cost adaugat: 1 sin + 1 pow + 1 fwidth per pixel, zero esantioane noi.
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

// Valuri de VERTECSI (nu de pixeli): doua sinusoide in coordonate de lume, cu
// frecvente necomensurabile. Grila fina de 9.5 m exista deja langa tarm —
// valurile au vertecsi exact unde se vad. Cost: vertex-only, zero fill rate,
// zero texturi.
//
// Anvelopa amplitudinii se CALCULEAZA din COLOR.a (adancime normalizata), nu
// se mai citeste direct din el. Pana la v2, alfa purta chiar amplitudinea,
// coapta pe CPU; de cand rampa de culoare are nevoie de adancime per pixel,
// canalul e ocupat de ea, iar anvelopa se reconstituie aici — e oricum o
// functie de adancime. Forma ramane identica: 0 la tarm (un val acolo deschide
// o fisura cu terenul), varf pe recif, 0 spre larg (granita cu planul fix
// SeaFar, pe care un val l-ar strapunge).
//
// Valoarea EFECTIVA vine de pe CPU (Track.SEA_WAVE_AMP), nu de aici: din ea se
// deriva Track.SEA_FAR_DROP, adica cat de jos sta placa de larg fata de grila
// fina. Cand cele doua numere s-au desincronizat (drop 4 cm, val 12 cm), grila
// s-a scufundat sub larg si prin gauri se vedea sea_deep — petele albastre
// poligonale care se plimbau pe laguna. Implicita de aici e doar plasa de
// siguranta pentru cine deschide shaderul singur.
uniform float wave_amp : hint_range(0.0, 0.5) = 0.12;
// Unde cade varful anvelopei, in adancime normalizata: SEA_REEF_DEPTH /
// SEA_NEAR_DEPTH. Setat de Track odata cu restul uniformelor, ca sa nu existe
// doua locuri unde se scrie aceeasi geometrie de recif.
uniform float wave_reef : hint_range(0.05, 0.95) = 0.357;

// --- v2. Toate culorile vin de pe CPU, din Track.water_tint(): un singur loc
// de calibrare, promisiunea din comentariul lui _sea_color ramane adevarata.
// Rampa de adancime, per pixel. 0 = doar vertex colors (v1).
uniform float ramp_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 shore_col; // nisip ud, chiar la linia apei
uniform vec3 shallow_col; // laguna turcoaz
uniform vec3 deep_col; // largul
// Spuma animata la tarm. 0 = doar spuma-geometrie din banda de varfuri.
uniform float foam_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 foam_col;
// Pana la ce adancime normalizata urca spuma pe plaja.
uniform float foam_reach : hint_range(0.01, 0.5) = 0.10;
uniform float foam_speed = 1.1;
// Scanteierea soarelui pe ondulatie. 0 = stinsa.
uniform float glint_strength : hint_range(0.0, 2.0) = 0.0;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0); // SPRE soare, normalizat

// --- v3. Doua adaugiri, amandoua pentru aceeasi problema: din masina, marea
// deschisa era o placa PLATA de culoare, fara nicio informatie de suprafata —
// singurul lucru care se misca pe ea era ondulatia din detail_rock, adica o
// textura de ROCA, cu straturile ei orizontale. La distanta citea ca panza, nu
// ca apa. Vezi capturile din docs/asset_briefs/img/okinawa_apa_v3.png.
//
// CRESTE DE HULA. Linii de val care traverseaza marea pe o directie fixa,
// analitice (fara textura, deci fara tipar care se repeta si fara VRAM). Sunt
// ce da apei DIRECTIE — fara ele nu se poate spune incotro merge marea. Doua
// trenuri cu lungimi de unda necomensurabile si directii la ~20° unul de altul,
// ridicate la putere ca sa iasa linii subtiri de creasta, nu sinusoide grase.
// Cost: 2 sin + 2 pow, zero esantioane de textura.
uniform float crest_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 crest_dir = vec2(0.80, 0.60); // directia hulei, in plan XZ
uniform float crest_len = 26.0; // distanta intre creste, in metri
uniform float crest_speed = 2.6; // cat de repede inainteaza, m/s
uniform float crest_sharp : hint_range(1.0, 64.0) = 12.0;

// BENZI DE ADANCIME. Rampa de culoare e continua, deci tranzitia laguna->larg
// iesea ca un blur de zeci de metri — corect fizic, dar exact opusul liniei
// grafice a jocului (style_bible §1: forme citibile, nu degrade-uri). Aici
// se cuantizeaza adancimea in cateva trepte, iar marginea treptei se
// SERPUIESTE cu ondulatia deja esantionata — altfel ar iesi curbe de nivel
// trase cu compasul, la fel de artificiale ca blur-ul.
uniform float band_strength : hint_range(0.0, 1.0) = 0.0;
uniform float band_count : hint_range(2.0, 12.0) = 5.0;
uniform float band_wobble : hint_range(0.0, 0.4) = 0.09;

// --- v4 (Chongqing). Trei adaugiri, toate pentru aceeasi intrebare: de ce o
// suprafata desaturata si inchisa citea tot CAMP, nu apa.
//
// DOUA RAURI. Rampa de culoare e dupa ADANCIME, deci pe un singur material
// intreaga apa avea o singura familie de culoare. Cu un rau verde la mal si
// unul brun la larg (ce incercase runda 4), fiecare pixel de adancime medie
// cadea intre verde si brun — adica exact pe OLIV. Media dintre verde si maro
// e culoarea unei mirisiti; nu exista reglaj de saturatie care sa o salveze.
// Aici raul nu se mai alege dupa adancime, ci dupa LOC: o dreapta in planul
// XZ imparte apa in doua, fiecare mal cu rampa lui, iar granita e chiar linia
// de confluenta. `split_strength = 0` => o singura apa, ca inainte.
uniform float split_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec2 split_dir = vec2(1.0, 0.0); // normala dreptei, in plan XZ
uniform float split_offset = 0.0;        // dot(p, split_dir) al dreptei
uniform float split_soft = 24.0;         // latimea amestecului, in metri
uniform float split_meander = 40.0;
// Lungimea de unda a serpuirii, in metri (v8, runda 9). Vezi nota de la `sd`
// in fragment: amplitudinea spune CAT se abate granita, asta spune PE CE
// DISTANTA — si fara ea meandrul se lua din zgomotul de suprafata, deci se
// abatea cu zeci de metri pe fiecare metru parcurs.
uniform float split_wave = 260.0;      // cat serpuieste granita (metri)
uniform vec3 shore_col_b;
uniform vec3 shallow_col_b;
uniform vec3 deep_col_b;
// Linia de confluenta: dara de spuma/gunoi care se vede intre doua curenti.
// Se INTUNECA, nu se albeste — o dunga alba pe apa neagra ar fi citit iar
// spuma, iar brief-ul cere explicit fara spuma lata.
uniform float seam_strength : hint_range(0.0, 1.0) = 0.0;

// LUMINA CARE SCLIPESTE. Pana aici scanteierea venea de la soare, iar pe o
// tema de noapte soarele sta la -78 grade (aproape in zenit): reflexia lui
// pleaca in sus, camera de cursa se uita aproape razant, deci pe apa nu ajungea
// aproape nimic — cateva pete izolate in prim-plan. Ce lumineaza un rau de
// oras noaptea sunt felinarele de pe MALUL OPUS, adica o lumina JOASA, dincolo
// de apa. `glint_horizon > 0` inlocuieste soarele cu exact asa ceva: o sursa
// virtuala la inaltimea aia deasupra orizontului, mereu in continuarea privirii
// — de aceea drumul de sclipiri vine spre camera, ca luna pe mare.
uniform float glint_horizon : hint_range(0.0, 1.0) = 0.0;
// Culoarea sclipirii, in LINIAR (se ADUNA peste albedo). Alb = ca pana acum.
uniform vec3 glint_col = vec3(1.0);
// Cat de ALUNGITE sunt reflexiile pe directia privirii. Pe ecran directia aia
// e verticala, deci asta e diferenta dintre "pete pe camp" si "reflexii pe
// apa". Mecanismul: panta suprafetei se comprima pe axa privirii si se
// amplifica pe cea transversala, deci pata speculara se plimba mult in lateral
// si aproape deloc in adancime => dungi verticale. 0 = izotrop, ca in v3.
uniform float glint_streak : hint_range(0.0, 4.0) = 0.0;
// Cat de STRANSA e pata speculara. 48 (soarele) e un punct; cu o lumina joasa
// pe directia privirii, conditia de oglinda e aproape indeplinita pe toata apa
// din departare, iar un exponent mare aprinde o BANDA continua la orizont —
// masurat: toata apa la luminanta 130+, adica dune de nisip. Un exponent mic
// intinde lobul, deci sclipirea nu mai are prag, iar ce o sparge in reflexii
// separate ramane doar ondulatia.
uniform float glint_sharp : hint_range(2.0, 256.0) = 48.0;
// PRAGUL care rupe luciul in reflexii SEPARATE. Fara el, o lumina joasa pe
// directia privirii indeplineste conditia de oglinda pe aproape toata apa —
// masurat: cu intensitate 0.05, mediana apei sarea de la 18 la 44, adica
// efectul nu era o sclipire, era un strat. Cu prag, tot ce e sub el ramane
// apa neagra si doar varfurile rup pragul, deci intensitatea poate fi mare
// fara sa spele suprafata. 0 = fara prag (comportamentul v3, temele vechi).
uniform float glint_cut : hint_range(0.0, 0.95) = 0.0;
// CAT DE MARE e o reflexie. Multiplica scara mastii: sub 1 = tipar mai mare.
// A fost lipsa care a facut runda 5 sa citeasca oras, nu apa: la scara
// ondulatiei (33 m pe dala, deci detalii de ~1.5 m), petele ieseau de cativa
// pixeli si cadeau in randuri regulate — masurat pe captura, exact o grila de
// ferestre aprinse intinsa peste rau. In diorama reflexiile sunt PETE de cativa
// metri, rare si neregulate. 1.0 = masca de dinainte (temele vechi).
uniform float glint_grain : hint_range(0.05, 1.0) = 1.0;
// Raza (in metri) la care reflexiile NU sunt inca alungite. Sub ea petele
// raman rotunde, peste ea se lungesc spre privitor — vezi nota din fragment.
uniform float glint_ref = 120.0;

// --- v5 (Chongqing, runda 6). Pana aici toate reglajele au fost de CULOARE:
// nuanta, saturatie, cat de inchisa e apa. Masurand diorama pixel cu pixel a
// iesit ca problema nu era niciodata culoarea, ci SUPRAFATA — apa noastra n-are
// nicio variatie de valoare pe ea, iar cea din referinta are peste tot:
//
//   percentile 5/25/50/75/90 ale luminantei, pe aceeasi suprafata de apa
//     diorama (bratul verde): 32 / 44 / 49 / 56 / 72   — ecart intercuartilic 12
//     noi (runda 5, cornisa D): 22 / 22 / 22 / 24 / 26 — o placa moarta
//
//   luminanta de baza pe 6 benzi, de la departare spre prim-plan
//     diorama: 22.9 -> 18.1 -> 22.1 -> 41.3 -> 47.2 -> 48.0  (se dubleaza)
//     noi:     22.3 -> 22.3 -> 22.3 -> 22.3 -> 22.3 -> 23.4  (aceeasi valoare)
//
// A doua cifra e cea care rupe iluzia: o suprafata care RECEDE in perspectiva
// si nu isi schimba valoarea nu se citeste ca plan orizontal, se citeste ca
// perete vopsit. De aici cele doua adaugiri, in ordinea in care conteaza.

// FATETE. In diorama apa e un poliedru plat: pete mari, de zeci de metri,
// fiecare de o valoare usor diferita, cu muchii drepte intre ele. Aia e toata
// "textura" ei — nu granulatie, ci trepte de valoare pe suprafete mari.
// `band_strength` face deja asa ceva, dar cuantizeaza ADANCIMEA, iar pe un rau
// adanc peste tot adancimea e constanta, deci nu produce nimic. Aici campul
// cuantizat e SPATIAL: trei sinusoide cu directii si lungimi de unda
// necomensurabile (30-65 m), foarte lente in timp, cu marginea treptei rupta de
// ondulatia deja esantionata ca sa nu iasa curbe de nivel. Cost: 3 sin.
uniform float facet_strength : hint_range(0.0, 1.0) = 0.0;
uniform float facet_count : hint_range(2.0, 12.0) = 5.0;
uniform float facet_scale = 0.10; // rad/m; 0.10 => fatete de ~30-65 m
uniform float facet_wobble : hint_range(0.0, 1.0) = 0.35;
// Cat de tare se indoaie grila de fatete (v8, runda 9). Era scris in cod,
// 0.22, si e chiar butonul dintre "caroiaj de rigla" si "lobi de camuflaj":
// deformarea vine din sinusoide netede, deci cu cat e mai mare, cu atat
// laturile triunghiului se curbeaza mai mult. Diorama are laturi DREPTE cu
// orientari diferite, adica deformare mica pe o tesela deja neregulata.
uniform float facet_warp : hint_range(0.0, 1.0) = 0.22;
uniform float facet_speed = 0.05;
// Cat de mare e o fateta e o marime de LUME, dar ce vede ochiul e o marime de
// ECRAN — iar sub tablier apa incepe la 10 m, deci o fateta de 14 m umplea un
// sfert de cadru. Pe captura ies pete late cat un camion, cu muchii moi: bataturi
// de pamant, nu unde. Apropiindu-te de o apa chiar vezi structura mai fina
// (rezolvi valuri mai mici), deci celula se micsoreaza cu distanta pana la
// `facet_ref` metri, unde ramane cea autorata. 0 = aceeasi marime peste tot,
// adica temele vechi neatinse.
uniform float facet_ref = 0.0;

// --- v10 (Chongqing, runda 11). MARIMEA CELULEI PE ECRAN, in pixeli.
//
// Pana in runda 10 marimea celulei se cerea prin `facet_ref / cam_r`, adica
// printr-o DISTANTA de referinta. Asta functioneaza doar cat timp camera se
// uita la apa mereu de la aceeasi inaltime si cu acelasi FOV — si nu e cazul:
// cornisa D sta la 27 m peste apa, tablierul golfului la 3.3 m. O celula
// calibrata pentru una iese de zece ori gresita in cealalta, si de-aia
// `facet_near` a tot urcat (2.5 -> 5.5 -> 16) fara sa nimereasca vreodata.
//
// Marimea care conteaza e in PIXELI, si se poate cere direct. `fwidth` da cat
// se schimba pozitia in lume de la un pixel la vecinul lui, deci un metru
// costa `1 / fwidth` pixeli — masurat pe fragmentul curent, cu FOV-ul,
// rezolutia si unghiul lui reale, fara nicio constanta de calibrare.
// `facet_px` e latimea dorita a placii, si e o marime pe care o poti CITI din
// referinta: in bar/E_chei.png placile din prim-plan au 17.7 px pe orizontala
// si 7.1 px pe verticala, cele departate 71 si 26 (masurat pe lungimea medie
// de segment intre doua muchii de luminanta >= 8).
//
// 0 = mecanismul vechi (`facet_ref`), adica temele vechi neatinse.
uniform float facet_px = 0.0;
// Plafonul micsorarii, ca raport fata de celula autorata. Exista din acelasi
// motiv pentru care exista si la mecanismul vechi: langa camera cererea
// diverge, iar o placa sub jumatate de metru nu mai e o fateta de apa, e
// granulatie.
uniform float facet_px_max : hint_range(1.0, 128.0) = 32.0;
uniform float facet_near_max : hint_range(1.0, 12.0) = 2.5;

// --- v10 (Chongqing, runda 11). ALUNGIREA RADIALA. Semnul corectat.
//
// Runda 10 a pus corectia pe dos, si asta e chiar defectul care a picat-o.
// Rationamentul era corect — proiectia unui plan orizontal privit razant
// intinde axa radiala de r/h ori, deci o celula patrata in lume iese aschie pe
// ecran — dar reparatia mergea invers. `pa = p + vdir * (dot(p,vdir) * (k-1))`
// INMULTESTE coordonata radiala cu k, deci placa devine de k ori mai SCURTA in
// lume. Adica exact ce facea perspectiva oricum, inca o data.
//
// Ca sa iasa patrata pe ecran, placa trebuie sa fie mai LUNGA in lume pe
// directia privirii, cu chiar factorul cu care proiectia o scurteaza: 1/view.y.
// La 5 m de pe tablier asta cere 1.8x, la 150 m cere 45x. De-aia se si
// plafoneaza (`facet_aniso`): dincolo de plafon placa devine dunga in lume,
// adica pensulatiile scoase in rundele 8-9.
//
// Verificarea e aritmetica si se poate reface pe hartie: un metru transversal
// subintinde 1/(d*k) pixeli, unul radial view.y/(d*k). Ca cei doi sa dea
// acelasi numar de pixeli, latura radiala in metri trebuie sa fie de 1/view.y
// ori cea transversala. Cu semnul din runda 10 raportul iesea view.y, adica
// patratul erorii.
uniform float facet_aniso : hint_range(1.0, 64.0) = 1.0;
uniform float facet_aa : hint_range(0.05, 2.0) = 0.5;
// Perechea lui pentru masca de reflexii. Vezi nota din fragment: punctul de
// esantionare al mastii e comprimat radial, deci mipmap-ul nu-l mai poate
// alege corect si masca se rupe in zgomot la incidenta razanta. 0 = stins.
uniform float glint_aa : hint_range(0.0, 2.0) = 0.0;
// Cat de tare fateteaza raul B fata de A. Vezi nota din fragment: aceeasi
// amplitudine relativa pe o apa mai inchisa da mai putine niveluri de
// luminanta, iar muchia se vede in niveluri. 1.0 = amandoua la fel.
uniform float facet_b_gain : hint_range(0.5, 3.0) = 1.0;
// LINISTEA CORPULUI APEI (v11, runda 12). Exponentul cu care se strange
// distributia valorilor de placa in jurul mijlocului. 1 = trepte
// echiprobabile, adica mecanismul de pana acum (temele vechi neatinse).
// Peste 1, majoritatea placilor cad aproape de aceeasi valoare si doar o
// minoritate se departeaza — vezi nota lunga de la locul folosirii.
uniform float facet_calm : hint_range(1.0, 6.0) = 1.0;
// Cat din amplitudinea de placa ramane pe partea LUMINOASA (v11, runda 12).
// 1 = simetric, adica mecanismul de pana acum. Sub 1, placile se pot inchide
// intreg dar se deschid mai putin, si zona luminoasa a histogramei ramane a
// reflexiilor. Vezi nota de la locul folosirii.
uniform float facet_lid : hint_range(0.1, 1.0) = 1.0;

// --- v9 (Chongqing, runda 10). CAT de mult se lateste lobul speculat cand
// privirea cade razant.
//
// A doua jumatate a aceluiasi defect. `glint_sharp` e exponentul lobului si e
// o constanta, dar produsul scalar pe care il ridica la putere NU e la fel de
// sensibil la orice unghi: razant, reflexia cade aproape de directia privirii
// pe toata apa vizibila, deci `dot(reflect, view)` sta lipit de 1 si lobul
// devine un camp neted fara varf — masurat, acoperire 0.02% pe malul brun de
// pe pod fata de 5.15% in diorama, adica 2 pete fata de 59. Nu lipsea LUMINA
// (aia e simptomul pe care runda 9 l-a diagnosticat gresit si a vrut sa-l
// repare cu o lampa), lipsea CONTRASTUL dintre fete: cand lobul e plat,
// diferenta de panta dintre doua fatete vecine nu mai produce nicio diferenta
// de stralucire, si atunci nici fatetarea nu se mai vede in reflexii.
//
// Exponentul se coboara cu incidenta: la view.y mare ramane `glint_sharp`
// (pata stransa, cum se vede de sus in golf), la view.y -> 0 se imparte la
// `glint_graze`, deci lobul se lateste si prinde si pantele mici pe care le au
// fatetele departate. Lobul mai larg inseamna mai multa apa peste prag — de
// aia poarta de fateta (`facet_gate`) si `glint_cut` raman butoanele care
// hotarasc CATA, si tot de aia acoperirea creste fara ca suprafata sa devina
// foaie de aur. 1.0 = stins.
uniform float glint_graze : hint_range(1.0, 12.0) = 1.0;
// Unghiul (sinusul lui) la care lobul redevine cel autorat. Peste el nu se
// schimba nimic, deci vederile de sus — golful, cornisa — raman ce erau.
uniform float glint_graze_ref : hint_range(0.05, 1.0) = 0.5;
// Cat ramane din INTENSITATEA reflexiei la incidenta razanta (v11, runda 12).
// 1 = neatins (temele vechi). Sub 1, lobul latit de `glint_graze` primeste in
// schimb mai putina lumina, deci reflexiile exista si de pe tablier fara ca
// apa sa se aprinda toata din scaunul soferului. Vezi nota de la folosire.
uniform float glint_graze_cap : hint_range(0.05, 1.0) = 1.0;

// GRADIENT DE PERSPECTIVA. Motivul pentru care apa dioramei se citeste ca plan
// orizontal si a noastra nu. Nu e ceata (aia coloreaza spre cer, aici valoarea
// CREsTE spre prim-plan) si nu e adancime: e unghiul sub care privesti apa.
// Razant, vezi reflexia malului opus — intuneric. De sus, vezi in apa tulbure,
// iar aluviunile in suspensie sunt ce se lumineaza. `view.y` e chiar sinusul
// unghiului ala si nu costa nimic: vectorul spre camera se calculeaza oricum
// pentru glint. view_lo = view_hi = 1.0 => niciun efect (temele vechi).
uniform float view_lo : hint_range(0.2, 2.0) = 1.0;
uniform float view_hi : hint_range(0.2, 3.0) = 1.0;
uniform float view_ref : hint_range(0.02, 1.0) = 0.22; // unghiul de "plin"

// --- v7 (Chongqing, runda 8). LUCIUL RAZANT, adica singurul lucru care
// deosebeste apa de pamant cand te uiti PESTE ea, nu IN ea.
//
// De ce lipsea. Toate reglajele de pana acum au fost calibrate pe cornisa D,
// unde camera sta la 27 m deasupra apei si se uita IN JOS: acolo `view_lo` /
// `view_hi` sunt suficiente, si spun corect ca apa privita de sus e mai
// deschisa (aluviuni luminate) decat cea privita razant (reflexia malului
// intunecat). Dar tablierul de peste golf trece la 3.3 m deasupra apei
// (masurat: drum y=6.3, apa y=3.0), deci de acolo TOATA apa se vede razant, si
// aceeasi regula o face uniform inchisa si mata pana la mal — un camp arat.
//
// Fizic, la incidenta razanta apa devine OGLINDA (Fresnel): departe se vede
// cerul si malul opus, nu adancul. E cel mai puternic semnal de "lichid" pe
// care il are o suprafata orizontala, si e cel pe care nu-l poate imita niciun
// pamant. Aici e un singur termen ADITIV, in liniar, cu culoarea mediului
// reflectat (pe o noapte cu burnita: ceata, adica gri-violaceu rece — NU
// aurul felinarelor, ala e deja glint).
//
// Se AMESTECA, nu se aduna, si asta nu e o preferinta: o oglinda INLOCUIESTE
// ce e sub ea. Adunat, luciul rece peste un rau brun da mov — masurat pe banda
// departata de pe pod, nuanta 324 la saturatie 0.10, adica magenta. Amestecat,
// apa trece pur si simplu in culoarea a ceea ce oglindeste, si nu poate iesi
// nicio nuanta care sa nu fie ori a apei, ori a cerului.
//
// Cost: un pow. 0 = nimic, deci temele vechi sunt neatinse.
uniform float fresnel_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 fresnel_col = vec3(1.0);
uniform float fresnel_sharp : hint_range(1.0, 16.0) = 4.0;

// Cat de adanca e umbra hulei. Pana la v4 era scrisa in cod, 0.12 — calibrata
// pe o mare vazuta de departe, unde crestele sunt ce da relieful. Pe un rau
// vazut de sus e singura modulatie CONTINUA de pe suprafata, deci trebuie sa
// poata fi urcata fara sa se atinga si spargerile albe.
uniform float crest_shade : hint_range(0.0, 0.8) = 0.12;

// MARGINEA si INTERIORUL unei reflexii. Masurat in diorama, petele aurii stau
// la 1.8-2.8x fata de apa pe care se afla, cu halou si cu valoare care variaza
// pe ele; la noi ieseau la 6-7.4x, cu contur de hartie rupta si interior plat —
// adica obiecte lipite pe suprafata, nu lumina in unda. `glint_soft` lateste
// tranzitia, `glint_body` face intensitatea sa creasca cu adancimea fisurii in
// loc sa sara la maxim imediat dupa prag. 0 = taietura de pana acum.
uniform float glint_soft : hint_range(0.02, 0.6) = 0.17;
uniform float glint_body : hint_range(0.0, 1.0) = 0.0;

// --- v6 (Chongqing, runda 8). Scanteierea era pana aici o marime GLOBALA, iar
// pe o pista cu doua rauri asta e o presupunere falsa. Masurand diorama
// (bar/E_chei.png) pe cele doua brate:
//
//              luminanta medie   p99   max   pixeli peste 150
//   verde .......... 55.6        153   ~160        0.4%
//   auriu .......... 78.1        167    201        2.0%
//
// Bratul auriu nu e mai deschis fiindca are alt ALBEDO, e mai deschis fiindca
// pe el cade drumul de reflexii al felinarelor: aceeasi apa, alt unghi. Noi
// faceam exact invers — brunul avea albedo ocru viu (luminanta 45-63, mai
// deschis decat stanca de langa el) si aproape zero sclipiri (p99 = 92-96,
// maximul 143). Adica desenam cu vopsea ce trebuia desenat cu lumina, si de
// aia citea pamant: o suprafata mata, uniforma, mai deschisa decat piatra.
//
// Aici cele doua marimi care hotarasc CATA lumina se aprinde pe apa devin per
// rau, folosind acelasi `side` cu care se aleg si culorile. 1.0 / 0.0 =
// exact comportamentul de pana acum, deci temele cu un singur rau nu se
// schimba.
uniform float glint_b_gain : hint_range(0.0, 6.0) = 1.0; // x glint pe raul B
uniform float glint_b_cut : hint_range(0.0, 0.95) = 0.0; // 0 = acelasi prag

// REFLEXIA E O FATETA, NU O FISURA. Masca sclipirilor se citea pana aici din
// detail_rock.png — o textura de ROCA, deci fisuri RAMIFICATE. Pe apa de
// departe treceau drept pete; pe apa de la 20-40 m (vederea de pe pod) ies
// exact ce sunt: zigzaguri de crapatura, late de zeci de pixeli si legate
// intre ele — flacari pe pamant, nu lumina pe unda.
//
// In diorama (bar/E_chei.png) reflexiile aurii sunt POLIGOANE PLATE cu muchii
// drepte, si stau exact peste tesela de fatete a apei: o fateta ori prinde
// lumina felinarului, ori nu. De aia arata ca hartie de aur pusa pe apa, nu ca
// ceva desenat peste ea.
//
// Aici masca devine un numar CONSTANT PE FATETA: doua campuri de sinusoide
// cuantizate independent (celula = intersectia benzilor lor, deci poligoane
// neregulate de marimi diferite), amestecate intr-o cheie pseudo-aleatoare.
// Muchia celulei o rupe acelasi `facet_wobble` care rupe si fatetele de
// culoare, deci reflexia si suprafata sunt taiate cu acelasi cutit.
// 0 = masca din fisuri, adica exact comportamentul temelor vechi.
// Fisurile nu sunt gresite peste tot: la 150 m o fisura are cativa pixeli si
// citeste chiar pata, iar o celula de fateta ar avea sub un pixel, adica moire.
// Marimea de care depinde alegerea e DISTANTA, deci masca trece de la fatete la
// fisuri pe `glint_facet_far` metri. `glint_b_facet` exista fiindca cele doua
// rauri se vad de la departari diferite in cadrele care conteaza: Jialing de pe
// cornisa (60-250 m), Yangtze de pe pod (20-60 m).
uniform float glint_facet : hint_range(0.0, 1.0) = 0.0;
uniform float glint_b_facet : hint_range(0.0, 1.0) = 0.0;
uniform float glint_facet_far = 130.0;
// Sub ce cheie de fateta o placa nu se aprinde deloc (v8, runda 9). Cu cat e
// mai sus, cu atat mai putine placi prind lumina — butonul de RARITATE, pe
// cand `glint_cut` ramane butonul de cat de adanca trebuie sa fie fisura in
// placile care au voie. Doua marimi, fiindca in diorama reflexiile sunt si
// rare (putine placi), si mici in placile alea.
uniform float facet_gate : hint_range(0.0, 0.95) = 0.0;

varying vec3 world_pos;

// Anvelopa valurilor din adancimea normalizata: urca de la 0 la tarm pana la 1
// pe recif, coboara inapoi la 0 spre larg. Identica cu masca pe care o cocea
// CPU-ul in alfa inainte de v2 — doar ca socotita din singurul numar pe care
// alfa il mai poate purta acum.
float wave_envelope(float depth01) {
	return clamp(depth01 / wave_reef, 0.0, 1.0)
		* clamp((1.0 - depth01) / max(1.0 - wave_reef, 0.001), 0.0, 1.0);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float swell = sin(world_pos.x * 0.55 + TIME * 1.05) * 0.6
		+ cos(world_pos.z * 0.47 - TIME * 0.85) * 0.4;
	VERTEX.y += swell * wave_amp * wave_envelope(COLOR.a);
}

void fragment() {
	// Coordonate de LUME, nu UV de mesh: asa ondulatia curge continuu peste
	// toate petecele de apa si nu se vede grila din care e facut planul.
	vec2 p = world_pos.xz;
	vec2 uv_near = p * scale_near + TIME * drift_near * scale_near;
	// Al doilea strat pe coordonate ROTITE. detail_rock.png are strate
	// ORIZONTALE (e o textura de roca sedimentara), deci doua esantioane cu
	// aceeasi orientare se aduna in dungi paralele — la prima randare marea
	// citea ca un gard de scanduri verticale. Rotite, cele doua seturi de dungi
	// se incruciseaza si rezultatul citeste ca unda.
	//
	// Unghiul a fost 90° si l-am schimbat la 63°: la 90° ambele seturi de dungi
	// raman ALINIATE LA AXE, deci incrucisarea da o GRILA — vizibila ca tesatura
	// in orice captura de sus a largului. Un unghi care nu e multiplu de 90 rupe
	// si alinierea, nu doar paralelismul.
	vec2 rot = vec2(p.x * 0.454 - p.y * 0.891, p.x * 0.891 + p.y * 0.454);
	vec2 uv_far = rot * scale_far + TIME * drift_far * scale_far;
	float a = texture(ripple_tex, uv_near).r;
	float b = texture(ripple_tex, uv_far).r;
	float ripple = mix(1.0, a * b, ripple_strength);

	// COLOR.rgb = culoarea coapta in mesh (v1), COLOR.a = adancimea
	// normalizata (0 = linia apei, 1 = SEA_NEAR_DEPTH sau mai adanc).
	float depth01 = COLOR.a;
	// sqrt intinde partea de mica adancime: laguna turcoaz ocupa mai mult
	// din banda vizibila, exact ca in imaginile de referinta.
	float t = sqrt(depth01);
	// Trepte de adancime. Serpuirea se aplica INAINTE de cuantizare, ca sa
	// deformeze granita; aplicata dupa, ar fi doar zgomotat culoarea plata din
	// interiorul benzii, adica fix ce nu voiam.
	float tw = t + (a * b - 0.79) * band_wobble;
	float tq = floor(tw * band_count) / max(band_count - 1.0, 1.0);
	t = mix(t, clamp(tq, 0.0, 1.0), band_strength);
	float t_shore = smoothstep(0.0, 0.40, t);
	float t_deep = smoothstep(0.40, 1.0, t);
	vec3 ramp = mix(shore_col, shallow_col, t_shore);
	ramp = mix(ramp, deep_col, t_deep);
	// Al doilea rau: aceeasi rampa de adancime, alta familie de culoare.
	// Granita SERPUIESTE cu ondulatia deja esantionata (acelasi a*b ca peste
	// tot in shaderul asta) — o dreapta perfecta ar fi citit ca margine de
	// poligon, nu ca intalnirea a doua ape.
	// RUNDA 9. Serpuirea granitei se lua din `a * b`, adica din chiar
	// esantioanele texturii de ondulatie — un camp de frecventa INALTA, de
	// ordinul metrului. Inmultit cu o amplitudine de zeci de metri, iese o
	// granita care sare inainte si inapoi pe fiecare texel: cele doua ape se
	// intrepatrund in dungi subtiri pe o banda lata de zeci de metri. Pe
	// captura se vede exact asa — pensulatii verzi si brune amestecate, adica
	// marmura, nu confluenta. In natura linia serpuieste pe SUTE de metri, cu
	// raza de zeci; ce nu face niciodata e sa se zimteasca pe metru.
	//
	// Deci meandrul isi ia forma dintr-o singura sinusoida lenta pe directia
	// granitei (lungime de unda `split_wave` metri), nu din zgomotul de
	// suprafata. Ramane o urma mica din `a * b` pentru ca muchia sa nu fie de
	// rigla, dar o zecime, nu intreaga amplitudine.
	vec2 sdir = normalize(split_dir);
	vec2 salong = vec2(-sdir.y, sdir.x);
	float smeander = sin(dot(p, salong) * (6.2831853 / max(split_wave, 1.0)))
			* 0.62
		+ sin(dot(p, salong) * (6.2831853 / max(split_wave * 0.41, 1.0))
			+ 1.7) * 0.38;
	float sd = dot(p, sdir) - split_offset
		+ smeander * split_meander
		+ (a * b - 0.79) * split_meander * 0.10;
	float side = smoothstep(-split_soft, split_soft, sd) * split_strength;
	vec3 ramp_b = mix(shore_col_b, shallow_col_b, t_shore);
	ramp_b = mix(ramp_b, deep_col_b, t_deep);
	ramp = mix(ramp, ramp_b, side);
	// Dara de confluenta: ingusta (putere 6 peste triunghiul de tranzitie),
	// si doar acolo unde amestecul chiar are loc.
	float seam = pow(1.0 - abs(side * 2.0 - 1.0), 6.0) * split_strength;
	ramp *= 1.0 - seam * seam_strength;
	vec3 base = mix(COLOR.rgb, ramp, ramp_strength);

	// Spuma: o banda care "linge" plaja. Pulsul curge SPRE mal (faza scade cu
	// adancimea), iar pragul pe ondulatia deja esantionata ii rupe marginea —
	// fara el iesea o dunga paralela cu tarmul, trasa cu rigla.
	float band = 1.0 - smoothstep(0.0, foam_reach, depth01);
	float pulse = 0.55 + 0.45 * sin(TIME * foam_speed - depth01 * 42.0);
	float ragged = smoothstep(0.72, 0.95, a * b + band * 0.25);
	float foam = clamp(band * pulse * ragged * 2.2, 0.0, 1.0) * foam_strength;
	base = mix(base, foam_col, foam);

	// HULA. Un singur tren de valuri, care da marii directie.
	//
	// Doua incercari gresite inaintea asteia, amandoua din acelasi motiv — am
	// desenat SPUMA acolo unde trebuia desenata FORMA:
	//
	//   1. Doua trenuri de creste ascutite la 20° unul de altul: o PLASA alba
	//      peste toata marea. Doua seturi de linii care se intersecteaza dau o
	//      grila, oricat de necomensurabile ar fi lungimile de unda.
	//   2. Un singur tren de creste albe: linii paralele care converg spre
	//      punctul de fuga, ca liniile unui caiet. Marea vazuta de la 200 m nu
	//      arata linii albe continue — arata alternanta lumina/umbra.
	//
	// Deci hula MODULEAZA LUMINOZITATEA (valea mai intunecata, creasta mai
	// deschisa), si abia peste ea, rar, apar spargeri albe. Suprafata primeste
	// relief citibil fara sa fie acoperita de spuma.
	vec2 cd = normalize(crest_dir);
	float k1 = 6.2831853 / max(crest_len, 1.0);
	// Faza SERPUIESTE cu ondulatia deja esantionata: fara asta crestele sunt
	// drepte pe kilometri, si nimic dintr-o mare nu e drept.
	float phase = dot(p, cd) * k1 - TIME * crest_speed * k1
		+ (a * b - 0.79) * 5.0;
	// ANTIALIASING. Un tipar analitic n-are mipmap-uri: spre orizont o perioada
	// intreaga intra intr-un pixel si iese moire. fwidth(phase) spune cate
	// radiane trece tiparul pe un pixel; peste ~1.2 nu mai e rezolvabil si se
	// stinge. Costul e o derivata, nu un esantion.
	float crest_aa = (1.0 - smoothstep(0.35, 1.2, fwidth(phase)))
		* crest_strength;
	// Umbra de hula: ±6% pe culoarea deja calculata. Cat sa se vada forma, nu
	// cat sa se vada efectul.
	base *= 1.0 + (sin(phase) * 0.5 + 0.5) * crest_shade * crest_aa
		- crest_shade * 0.5 * crest_aa;
	// Spargeri: doar varful crestei, si doar unde o modulatie lenta de-a lungul
	// ei o lasa — altfel toata creasta ar sparge pe toata lungimea, la fel de
	// artificial ca liniile de caiet.
	vec2 along = vec2(-cd.y, cd.x);
	float breaker = pow(max(sin(phase), 0.0), crest_sharp)
		* smoothstep(0.62, 0.98, sin(dot(p, along) * 0.09 + TIME * 0.31) * 0.5
			+ 0.5 + (a * b - 0.79));
	// Se stinge chiar la tarm: acolo comanda banda de spuma, iar doua efecte
	// albe suprapuse pe aceiasi pixeli ies ca o pata laptoasa.
	breaker *= smoothstep(0.0, foam_reach * 2.0, depth01) * crest_aa;
	base = mix(base, foam_col, breaker * (1.0 - foam));

	base *= ripple;

	// FATETE. Un camp spatial lent, cuantizat in trepte: pete mari de valoare
	// usor diferita, cu muchii — ce vezi in diorama cand te uiti la apa de la
	// 60 m. Marginea treptei se rupe cu ondulatia deja esantionata (acelasi
	// a*b ca peste tot aici); fara asta ies contururi de sinusoida, adica
	// exact curbele de nivel pe care band_wobble le evita si el.
	vec3 view = normalize(CAMERA_POSITION_WORLD - world_pos);
	// Directia privirii, proiectata in plan: axa pe care reflexiile trebuie sa
	// se lungeasca (pe ecran e verticala).
	vec2 to_cam = world_pos.xz - CAMERA_POSITION_WORLD.xz;
	float cam_r = length(to_cam);
	vec2 vdir = to_cam / max(cam_r, 1e-4);

	float facet_key = 0.0;
	// Declarata aici, nu in blocul de fatete: poarta de reflexii de mai jos are
	// nevoie de ea ca sa stie pana unde mai are celula marime pe ecran.
	float aniso = 1.0;
	if (facet_strength > 0.0 || glint_facet > 0.0 || glint_b_facet > 0.0) {
		// DOMENIU DEFORMAT, APOI GRILA — nu sinusoide taiate in trepte.
		//
		// Pana in runda 8 fatetele se faceau cuantizand direct suma de
		// sinusoide. Un camp neted taiat in trepte da BENZI, adica exact curbe
		// de nivel, iar doua seturi de benzi aproape paralele se intersecteaza
		// in PANGLICI lungi si serpuite: pe captura de pe pod iesea marmorare,
		// nu tesela. Se vede si in cifre — energia de detaliu la raza 16 px
		// era 29.8 fata de 16.8 in diorama, adica prea multa variatie, dar
		// toata pe frecventa gresita.
		//
		// O placa de apa are muchii DREPTE si e cam la fel de lata pe ambele
		// axe. Deci celula trebuie sa fie o CELULA: o grila patrata careia i
		// se deformeaza coordonatele cu acelasi camp de sinusoide, plus un
		// jitter din ondulatie care ii rupe muchia. Iese un caroiaj neregulat
		// cu laturi drepte pe portiuni — ce se vede in bar/E_chei.png.
		//
		// Din aceeasi celula ies AMANDOUA: valoarea placii (`facet_strength`)
		// si cine prinde lumina (`facet_key`). In diorama reflexiile aurii cad
		// exact pe teselele apei, fiindca reflexia E fateta care s-a inclinat
		// bine — doua tipare independente s-ar fi vazut ca doua straturi.
		// Vezi `facet_ref`: celula se micsoreaza cu apropierea, ca marimea ei
		// pe ecran sa ramana aceeasi. Plafonat la 2.5x, si plafonul e masurat,
		// nu ales: la 6x celula ajungea la 2.3 m sub tablier, iar alungirea
		// reflexiei o intindea in FIRE — pe captura, paie peste pamant. La
		// 2.5x ramane la ~5.5 m, adica tot pata.
		// SCARA CELULEI, IN TREPTE — nu continuu cu distanta.
		//
		// Bug-ul care a picat runda 9 la prima incercare: `fs` se inmultea cu
		// `facet_ref / cam_r`, adica scara grilei se schimba CONTINUU de la un
		// pixel la vecinul lui. O grila careia i se schimba pasul intre doi
		// pixeli vecini nu mai e o grila — e o functie care se FORFECA, si o
		// grila forfecata radial iese exact ce s-a masurat pe captura: dungi
		// lungi care converg spre orizont. Adica pensulatii, ce incercam sa
		// scoatem de trei runde.
		//
		// Se pastreaza intentia (o placa sa aiba cam aceeasi marime pe ecran
		// oriunde e apa) fara sa se piarda grila: raportul se CUANTIZEAZA in
		// puteri de doi. Intre doua inele consecutive scara e constanta, deci
		// celula ramane celula; la trecerea dintre inele latura se
		// injumatateste dintr-o data, si o muchie de placa peste alta muchie
		// de placa nu se vede — asta e chiar mecanismul unui mipmap.
		float fs = facet_scale;
		// Latura autorata, in metri (2*PI/fs e conventia de peste tot aici).
		float cell_m = 6.2831853 / max(facet_scale, 1e-4);
		// Cati pixeli costa un metru TRANSVERSAL pe fragmentul asta. fwidth pe
		// pozitia in lume da metri-per-pixel direct, cu FOV-ul si rezolutia
		// reale; se ia minimul pe cele doua axe fiindca transversala e axa
		// care NU e scurtata de incidenta.
		float m_px = max(min(fwidth(world_pos.x), fwidth(world_pos.z)), 1e-5);
		if (facet_px > 0.0) {
			// Cat trebuie micsorata placa autorata ca sa iasa `facet_px` lata.
			// Se cuantizeaza in puteri de doi din acelasi motiv ca inainte: o
			// scara care se schimba continuu intre doi pixeli vecini forfeca
			// grila, si o grila forfecata radial iese dungi convergente.
			float want = clamp(cell_m / (facet_px * m_px), 1.0, facet_px_max);
			fs *= exp2(floor(log2(want)));
		} else if (facet_ref > 0.0) {
			float want = clamp(facet_ref / max(cam_r, 1.0), 1.0,
				facet_near_max);
			fs *= exp2(floor(log2(want)));
		}
		// CELULA ANIZOTROPA (v9, runda 10). Defectul care a picat runda 9, si
		// e unul singur, geometric — nu de lumina.
		//
		// Celula era PATRATA IN LUME. Dar ochiul nu vede lumea, vede ecranul,
		// iar proiectia unui plan orizontal privit razant NU e izotropa: la
		// inaltimea `h` peste apa si distanta `r`, un metru TRANSVERSAL
		// subintinde 1/r radiani, iar un metru RADIAL doar h/(h^2+r^2), deci
		// raportul e r/h. De pe tablier (h = 3.3 m) asta inseamna 12x la 40 m
		// si 45x la 150 m. Masurat pe captura rundei 9: o fateta autorata la
		// 13.7 m iese 643 px lata si 85 px adanca la 10 m, si 43 x 0.9 px la
		// 150 m. Adica de la 40 m in sus fiecare placa e o ASCHIE orizontala
		// mai subtire de 10 px — vecinele ei se amesteca intr-un singur pixel,
		// si ce ramane pe ecran e un degrade neted. Exact ce s-a masurat:
		// densitate de muchii 8.2% pe pod fata de 20.9% in golf (de sus,
		// unde raportul e ~1) si 19-31% in diorama.
		//
		// De-aia se stingeau si reflexiile: masca de glint calatoreste pe
		// ACEEASI celula (`facet_key`), deci o poarta care se subtiaza sub un
		// pixel nu mai lasa sa treaca nimic — 2 pete pe malul brun fata de 59
		// in diorama. Golul de fatetare si golul de reflexii sunt un singur
		// defect, si asta e el.
		//
		// Reparatia e chiar raportul de mai sus: axa RADIALA a domeniului se
		// comprima cu `view.y` (sinusul unghiului de incidenta, adica h/hypot,
		// deci ~h/r), asa incat o celula scurta in lume sa iasa la fel de
		// inalta pe ecran ca una lata. Nu e o corectie inventata: e chiar
		// jacobianul proiectiei, si la incidenta mare (golf, vedere de sus)
		// view.y -> 1 si nu se schimba nimic — vederea care masura deja
		// ancora ramane neatinsa.
		//
		// Plafonat cu `facet_aniso`: la view.y -> 0 raportul diverge, iar o
		// celula comprimata la infinit devine o DUNGA in lume, adica pensulatii
		// radiale — chiar boala pe care ultimele trei runde au scos-o.
		//
		// DOUA CORECTII CARE NU AU VOIE SA SE INMULTEASCA. `facet_ref / cam_r`
		// de mai sus micsoreaza celula pe AMANDOUA axele cand te apropii, si e
		// tot o corectie de marime pe ECRAN. Prima incercare le-a lasat sa se
		// suprapuna, si cifrele au spus imediat: la 5-20 m celula iesea 0.56 -
		// 1.9 m pe raza fata de 3.42 m transversal, adica panglica de 2-6:1
		// chiar acolo unde perspectiva aproape nu intinde nimic. Pe captura,
		// malul brun avea alungire mediana 9.6 — dungi, exact ce nu vrem.
		//
		// Corectia radiala trebuie deci sa fie doar ce a RAMAS neacoperit:
		// raportul cerut impartit la micsorarea deja aplicata pe ambele axe.
		// La 5 m nu mai ramane nimic (1.8 cerut, 4 deja aplicat) si celula
		// redevine patrata; la 150 m ramane tot, fiindca acolo shrink-ul e 1.
		//
		// Si se CUANTIZEAZA in puteri de doi, din acelasi motiv pentru care se
		// cuantizeaza si shrink-ul: un raport care se schimba continuu de la un
		// pixel la vecinul lui forfeca grila, iar o grila forfecata radial iese
		// dungi convergente spre orizont. In trepte, intre doua inele celula
		// ramane celula.
		if (facet_aniso > 1.0) {
			// Chiar jacobianul proiectiei, si nimic altceva: latura radiala
			// trebuie sa fie de 1/view.y ori cea transversala ca sa iasa
			// patrata pe ecran. Nu se mai imparte la micsorarea deja aplicata
			// — aia lucreaza pe AMANDOUA axele deodata, deci nu schimba
			// raportul dintre ele, iar impartirea la ea (runda 10) stergea
			// tocmai corectia pe care o cerea perspectiva.
			aniso = exp2(floor(log2(clamp(1.0 / max(view.y, 1e-3),
				1.0, facet_aniso))));
		}
		// Domeniul comprimat pe directia privirii. Se aplica INAINTE de
		// sinusoidele de deformare, ca sa se indoaie tot atat de tare si ele —
		// altfel warp-ul ar fi izotrop peste o grila anizotropa si ar reintroduce
		// laturi curbe exact acolo unde celula e cea mai ingusta.
		// Semnul, corectat in runda 11. Coordonata radiala se IMPARTE la
		// `aniso`, deci placa iese de `aniso` ori mai LUNGA in lume pe directia
		// privirii — cat trebuie ca proiectia sa o aduca inapoi la patrat pe
		// ecran. Runda 10 inmultea, deci o scurta inca o data.
		vec2 pa = p - vdir * (dot(p, vdir) * (1.0 - 1.0 / aniso));
		float w1 = sin(dot(pa, vec2(0.83, 0.55) * fs) + TIME * facet_speed)
			+ sin(dot(pa, vec2(-0.47, 1.31) * fs)
				- TIME * facet_speed * 0.74);
		float w2 = sin(dot(pa, vec2(1.67, 1.04) * fs)
				+ TIME * facet_speed * 0.41)
			+ sin(dot(pa, vec2(-1.21, 0.77) * fs)
				- TIME * facet_speed * 0.63);
		// Latura celulei in metri e 2*PI / facet_scale, aceeasi conventie ca
		// lungimea de unda a sinusoidelor de deasupra.
		vec2 wp = pa * (fs * 0.15915494) + vec2(w1, w2) * facet_warp
			+ vec2(a - 0.89, b - 0.89) * facet_wobble * 2.0;
		// TRIUNGHIURI, NU PATRATE DEFORMATE (v8, runda 9).
		//
		// `floor(wp)` da o celula PATRATA, iar deformarea domeniului ii
		// rotunjeste laturile: la deformare mare ies lobi, la deformare mica
		// un caroiaj. Nici una din cele doua nu e ce se vede in diorama, unde
		// apa e taiata in TRIUNGHIURI cu laturi drepte, de marimi diferite —
		// masurat pe captura de pe pod, placile noastre ieseau contururi
		// rotunjite inchise unele in altele, adica exact desenul unui camuflaj.
		//
		// Un triunghi se obtine taind patratul cu diagonala lui: partea de sub
		// diagonala si cea de deasupra sunt doua celule distincte, si amandoua
		// au trei laturi drepte. Diagonala alterneaza dupa paritatea celulei,
		// ca sa nu iasa toate triunghiurile cu varful in aceeasi parte —
		// altfel tesela se citeste ca un tesut in zigzag.
		vec2 cell = floor(wp);
		vec2 f = wp - cell;
		// DIAGONALA, ALEASA PE CELULA (runda 11). Era `mod(cell.x + cell.y, 2)`,
		// adica o tabla de sah: directia diagonalei se repeta din doua in doua
		// celule pe amandoua axele, deci tesela are o perioada de 2x2 oricat de
		// mult ai rupe muchia din `facet_wobble`. Pe captura asta se vede ca un
		// motiv de romburi care se repeta — tapiterie capitonata, nu apa. (Si
		// nu se poate repara din wobble: peste 0.3 muchiile se curbeaza inapoi
		// in lobii de camuflaj scosi in runda 9, masurat.)
		//
		// Cu diagonala trasa dintr-un hash pe celula, doua celule vecine pot
		// avea aceeasi orientare sau orientari diferite, deci triunghiurile ies
		// de marimi si directii amestecate — ce se vede in bar/E_chei.png — iar
		// laturile raman drepte, fiindca taietura e tot o dreapta.
		float flip = step(0.5, fract(sin(dot(cell, vec2(23.14, 61.07)))
			* 31415.9265));
		float diag = mix(f.x + f.y, 1.0 + f.x - f.y, flip);
		float half_id = step(1.0, diag);
		vec3 tri = vec3(cell, half_id);
		float h1 = fract(sin(dot(tri, vec3(12.9898, 78.233, 37.719)))
			* 43758.5453);
		float h2 = fract(sin(dot(tri, vec3(39.3468, 11.1357, 83.155)))
			* 24634.6345);
		// STINGEREA SUB PIXEL, si e regula de igiena a oricarui tipar
		// procedural, nu un reglaj de tema: un tipar cuantizat a carui celula
		// scade sub cativa pixeli nu se mai vede ca tipar, se vede ca ZGOMOT.
		//
		// Compresia radiala (v9) tine celula inalta pe ecran, dar transversal
		// ea ramane de latimea autorata si se micsoreaza cu 1/r ca orice
		// altceva. Cand latimea aia trece sub prag, o poarta care taie pe
		// celula taie in bucati mai mici decat pixelul: masurat pe banda
		// departata a Yangtze-ului, densitate de muchii 32.6% fata de 19.8% in
		// diorama — pe captura, PIETRIS in loc de apa. (Iar fara compresie
		// aceeasi banda dadea 5.7%, adica pamant arat: amandoua gresite,
		// adevarul e intre ele.)
		//
		// `fwidth` da chiar cat se schimba coordonata de celula de la un pixel
		// la vecinul lui, deci masoara direct marimea celulei pe ecran, in
		// unitati de celula. Peste `facet_aa` celule pe pixel, tiparul se
		// stinge in valoarea medie.
		float cell_px = max(fwidth(wp.x), fwidth(wp.y));
		float aa = 1.0 - smoothstep(facet_aa * 0.5, facet_aa, cell_px);
		if (facet_strength > 0.0) {
			// Valoarea placii, in `facet_count` trepte: placi de valori
			// DIFERITE, nu un degrade continuu (style_bible §1).
			float lvl = floor(h1 * facet_count) / max(facet_count - 1.0, 1.0);
			// LINISTEA SUPRAFETEI (v11, runda 12). Vezi `facet_calm`.
			//
			// Treptele de mai sus sunt echiprobabile: cu 4 trepte, un sfert
			// din placi cad pe fiecare nivel, deci FIECARE placa poarta tonul
			// ei si intre doua placi vecine nu ramane nicaieri suprafata
			// neteda. Masurat pe bar/E_chei.png, apa nu arata asa: cuartilele
			// ei stau la 45.0 si 56.3 in jurul medianei 51.0, adica jumatate
			// din suprafata incape in 11 niveluri de luminanta, iar la noi in
			// 19. Apa DIN diorama se odihneste, si abia peste linistea aia se
			// aprind cateva cioburi.
			//
			// Distributia se strange spre mijloc cu o putere impara aplicata
			// pe abaterea semnata: `facet_calm` = 1 lasa scara echiprobabila
			// (temele vechi), iar peste 1 trage majoritatea placilor spre
			// valoarea de mijloc si lasa doar cozile sa se departeze. Puterea
			// e IMPARA ca sa pastreze semnul, deci si placile mai inchise, si
			// cele mai deschise raman de aceeasi parte a medianei.
			//
			// De ce nu se coboara pur si simplu `facet_strength`: aia
			// micsoreaza SI cozile, deci sterge muchia peste tot si suprafata
			// redevine degrade neted (defectul rundelor 8-9). Aici corpul se
			// linisteste iar coada ramane la amplitudinea intreaga.
			if (facet_calm > 1.0) {
				float d = clamp(lvl, 0.0, 1.0) * 2.0 - 1.0;
				d = sign(d) * pow(abs(d), facet_calm);
				// Coada de SUS se taie separat (`facet_lid`). Motivul e
				// masurat, si e chiar diferenta care ramasese: in
				// bar/E_chei.png 61% din pixelii mai luminosi decat mediana+25
				// sunt AURII, adica reflexii de felinar; la noi erau 1%, restul
				// fiind placi verzi palide. Doua suprafete pot avea aceeasi
				// statistica de luminanta si totusi una sa arate ca apa cu
				// lumini pe ea, iar cealalta ca gresie decolorata — ce le
				// deosebeste e din CE sunt facute punctele luminoase.
				//
				// Deci placa are voie sa se INCHIDA cat vrea (umbra dintre
				// valuri e a apei), dar nu are voie sa se deschida mai mult
				// decat `facet_lid`: partea luminoasa a histogramei ramane
				// libera pentru glint, care e auriu. Asimetric intentionat —
				// o apa de noapte primeste lumina in pete, nu pe placi.
				if (d > 0.0) {
					d *= facet_lid;
				}
				lvl = d * 0.5 + 0.5;
			}
			// Amplitudinea e per rau. Modulatia e MULTIPLICATIVA, deci acelasi
			// procent pe o apa mai inchisa da mai putine NIVELURI de luminanta
			// — iar muchia pe care o vede ochiul (si pe care o numara garda) e
			// in niveluri, nu in procente. Yangtze-ul e inmultit cu
			// `water_b_gain` (0.82) peste `water_dim` (0.78), deci pornea de la
			// ~64% din luminanta lui Jialing: masurat, densitate de muchii 6.7%
			// fata de 10.6% pe verde, cu exact aceeasi tesela dedesubt. Nu era
			// tesela mai proasta pe brun, era acelasi contrast pe o baza mai
			// mica.
			float fstr = facet_strength * mix(1.0, facet_b_gain, side);
			base *= 1.0 + (clamp(lvl, 0.0, 1.0) - 0.5) * fstr * aa;
		}
		// Poarta se deschide odata cu stingerea: acolo unde fateta nu se mai
		// vede, reflexia isi recapata forma din fisura texturii (care are
		// mipmaps, deci se stinge singura cum trebuie) in loc sa fie taiata
		// pe o celula sub pixel.
		facet_key = mix(1.0, h2, aa);
	}

	// GRADIENT DE PERSPECTIVA. view.y e sinusul unghiului sub care cade
	// privirea pe apa: aproape 0 la orizont, mare in prim-plan. Suprafata se
	// deschide odata cu el — asta e semnalul "planul asta e orizontal si se
	// departeaza", si e ce lipsea cel mai tare (masurat: valoare identica pe
	// toata adancimea cadrului).
	if (view_lo != 1.0 || view_hi != 1.0) {
		base *= mix(view_lo, view_hi, smoothstep(0.0, view_ref, view.y));
	}
	// Vezi `fresnel_strength`: cu cat privirea cade mai razant, cu atat apa e
	// mai OGLINDA. Se ADUNA, ca glint-ul, si tot in liniar — e lumina venita
	// din alta parte, nu o retusare a culorii de sub ea.
	if (fresnel_strength > 0.0) {
		float fr = fresnel_strength
			* pow(1.0 - clamp(view.y, 0.0, 1.0), fresnel_sharp);
		base = mix(base, fresnel_col, clamp(fr, 0.0, 1.0));
	}

	// Sun glint: NU e specular din pasul de lumina (ramane unshaded — vezi
	// contractul #2), e o scanteiere geometrica din aceleasi doua esantioane.
	// Normala perturbata ieftin din ondulatie; exponentul mic tine pata larga,
	// masca de ripple o sparge in scantei.
	//
	// v3: la perturbarea din textura se adauga PANTA crestelor. Fara ea,
	// scanteierea urma straturile din detail_rock — adica desena pe mare
	// tiparul unei roci — si nu avea nimic de-a face cu valurile pe care le vezi
	// trecand. Cu ea, sclipirea alearga de-a lungul crestelor, care e chiar
	// motivul pentru care apa sclipeste in realitate. Amplitudinea vine din
	// crest_strength: un singur intrerupator pentru tot ce tine de hula.
	float slope = cos(phase) * crest_strength * 0.30;
	vec2 tilt = vec2(
		(a - 0.89) * 0.9 + cd.x * slope, (b - 0.89) * 0.9 + cd.y * slope);
	// Cu `glint_streak`, panta care hotaraste unde e oglinda ramane DOAR cea a
	// hulei — neteda, de zeci de metri. Ondulatia din textura are detalii de
	// ~1.5 m: bagata in normala speculara, sparge lobul in sclipici de cativa
	// pixeli, iar o apa acoperita de sclipici marunt citeste oras, nu rau
	// (masurat, runda 5). Forma reflexiei o da MASCA, care are grauntele ei.
	if (glint_streak > 0.0) {
		tilt = cd * slope;
	}
	float tilt_along = dot(tilt, vdir);
	// Componenta pe adancime se comprima, cea transversala se amplifica:
	// suprafata isi pastreaza aceeasi "energie" de valuri, dar pata speculara
	// nu mai fuge in departare la fiecare rid — ramane pe loc si se intinde.
	tilt = (tilt - vdir * tilt_along) * (1.0 + glint_streak * 0.6)
		+ vdir * tilt_along / (1.0 + glint_streak * 3.0);
	vec3 n = normalize(vec3(tilt.x, 1.0, tilt.y));
	// Sursa: soarele, sau o lumina joasa dincolo de apa (vezi glint_horizon).
	vec3 gl = sun_dir;
	if (glint_horizon > 0.0) {
		gl = normalize(vec3(vdir.x, glint_horizon, vdir.y));
	}
	// Vezi `glint_graze`: exponentul lobului scade cu incidenta, ca sclipirea
	// sa supravietuiasca acolo unde privirea cade razant — adica exact in
	// vederea de cursa, singura pe care jucatorul o are.
	// Rampa are referinta PROPRIE, nu `view_ref`. Aia e unghiul la care se
	// satureaza gradientul de CULOARE si e 0.20 pe tema asta, adica ~15 m de
	// pe tablier: cu ea, latirea lobului se stingea deja in prim-plan, exact
	// unde apa umple cadrul. Sinusul unghiului de incidenta e mic pe TOATA apa
	// vazuta de pe pod (0.55 la 5 m, 0.08 la 40 m), deci pragul lui trebuie sa
	// fie de ordinul lui 0.5, nu 0.2.
	float g_att = 1.0;
	float gsharp = glint_sharp;
	if (glint_graze > 1.0) {
		gsharp /= mix(glint_graze, 1.0,
			smoothstep(0.0, glint_graze_ref, clamp(view.y, 0.0, 1.0)));
	}
	float glint = pow(max(dot(reflect(-gl, n), view), 0.0), gsharp);
	float gmask = smoothstep(0.55, 0.90, a * b);
	if (glint_streak > 0.0) {
		// FORMA reflexiei. Doua lucruri, amandoua invatate masurand:
		//
		// 1. Se citesc CRAPATURILE texturii, nu campul ei. detail_rock.png e
		//    o roca: mediana canalului rosu e 0.96, un sfert din texeli sunt
		//    fix 1.0 — adica e alba cu fisuri rare. Masca de pana acum lua
		//    partea ALBA, deci "reflexie" insemna aproape toata apa, iar ce
		//    ramanea intunecat erau fisurile: rau de aur cu crapaturi verzi.
		//    Inversata, fisurile devin exact ce trebuie — pete rare, cu
		//    marimi diferite si margini neregulate.
		// 2. Deformarea e RADIALA fata de CAMERA, si asta cere o raza de
		//    referinta. Varianta dinainte descompunea pozitia ABSOLUTA pe
		//    directia privirii; termenul dot(camera, vdir) se roteste odata cu
		//    vdir, deci petele ieseau arcuite intr-un evantai in jurul
		//    camerei — pensulatii, nu reflexii. Aici se comprima doar
		//    DISTANTA fata de camera, in jurul lui `glint_ref` metri: la raza
		//    aia scara transversala ramane 1, iar cea radiala scade, deci
		//    petele se lungesc SPRE privitor. Pe ecran, spre verticala.
		float k = 1.0 + glint_streak * 4.0;
		// Compresia distantei e LOGARITMICA in jurul lui `glint_ref`, nu afina.
		// Cu forma afina (rg = ref + (r - ref) / k) tot ce e mult mai APROAPE
		// decat referinta cadea practic in acelasi punct de esantionare: pe pod,
		// apa de la 20-40 m primea o singura pata intinsa pe zeci de metri —
		// limbi de flacara verticale, nu reflexii (masurat, runda 6). Aici
		// factorul de alungire LOCAL e rg / (k * cam_r): mic in prim-plan (pete
		// aproape rotunde, cum se vad de pe chei) si mare in departare (dungi
		// spre privitor, cum se vede luna pe mare). Acelasi `glint_streak`, doar
		// ca acum inseamna acelasi lucru la orice distanta.
		float rg = glint_ref * pow(max(cam_r, 1.0) / glint_ref, 1.0 / k);
		vec2 gp = CAMERA_POSITION_WORLD.xz + vdir * rg;
		float s = scale_near * glint_grain;
		// A doua dala pe axe rotite si la o scara incomensurabila (0.37, nu
		// 1/2 sau 1/3): perioada comuna a celor doua iese in afara cadrului,
		// deci petele nu mai cad intr-o grila.
		vec2 gq = vec2(gp.x * 0.454 - gp.y * 0.891,
			gp.x * 0.891 + gp.y * 0.454);
		float c1 = texture(ripple_tex, gp * s + TIME * drift_near * s).r;
		float c2 = texture(ripple_tex,
			gq * s * 0.37 + TIME * drift_far * s * 0.37).r;
		// `glint_cut` = cat de adanca trebuie sa fie fisura ca sa se aprinda.
		// E singura marime pe care o compar cu diorama: acolo reflexiile aurii
		// tin 2-12% din pixelii apei.
		// Marginea NU e taiata cu cutitul. La 0.09 latime petele ieseau ca
		// hartie rupta — contur zimtat, interior de o singura culoare plata;
		// in diorama fiecare pata are un halou si valoare care variaza pe ea.
		float m = 1.0 - c1 * c2;
		// STINGEREA SUB PIXEL A MASTII, perechea lui `facet_aa` de mai sus si
		// la fel de putin optionala.
		//
		// Punctul de esantionare `gp` e comprimat radial fata de camera, deci
		// NU e o functie afina de pozitia pe ecran — iar selectia de mipmap a
		// placii video presupune tocmai ca este. Rezultat: la incidenta razanta
		// hardware-ul alege un LOD prea fin si masca se esantioneaza sub pixel.
		// Ce iese nu e o reflexie mai mica, e ZGOMOT: masurat pe banda
		// departata a Yangtze-ului, densitate de muchii 24-33% (diorama: 19.8%)
		// si pe captura o suprafata de PIETRIS. Se vede si in ablatie — cu
		// fatetele stinse de tot, banda aia ramanea la 24.4%, deci zgomotul
		// venea de aici, nu din tesela.
		//
		// `fwidth(gp)` masoara direct cat sare punctul de esantionare intre doi
		// pixeli vecini, in metri. Cand saltul depaseste `glint_aa` perioade de
		// textura, masca se stinge in valoarea ei medie si reflexiile dispar
		// neted in culoarea apei, in loc sa se rupa in sclipici.
		if (glint_aa > 0.0) {
			float step_px = max(fwidth(gp.x), fwidth(gp.y)) * s;
			m = mix(m, 0.5, smoothstep(glint_aa * 0.5, glint_aa, step_px));
		}
		// Vezi `glint_facet`: masca trece de la fisurile texturii la cheia
		// constanta pe fateta, deci pata are muchii drepte si interior plat.
		// Doar de aproape: mai departe de `glint_facet_far` celula ar fi sub
		// un pixel, si o cuantizare sub pixel e moire, nu forma.
		// Distanta la care poarta de fateta se stinge. Vezi `glint_facet_far`:
		// pragul exista fiindca departe celula ar cadea sub un pixel si o
		// cuantizare sub pixel e moire.
		//
		// Compresia radiala (v9) tine celula INALTA pe ecran oricat de departe,
		// deci ridica pragul — dar numai pe axa aia. TRANSVERSAL celula ramane
		// de latimea autorata si se micsoreaza cu 1/r ca orice altceva, iar
		// cand latimea aia scade sub cativa pixeli poarta taie tot in bucati
		// mai mici decat pixelul: nu mai ies fatete, ies PUNCTE. S-a masurat
		// cand pragul a fost ridicat cu `aniso` intreg — banda departata de pe
		// pod urca la densitate de muchii 32.5% fata de 19.8% in diorama, si pe
		// captura malul opus se citea PIETRIS, nu apa.
		//
		// Deci extinderea se plafoneaza: cel mult de doua ori, adica exact cat
		// castiga o celula care nu mai e aschie, nu cat cere compresia.
		float ffar = glint_facet_far * min(aniso, 2.0);
		float gf = mix(glint_facet, glint_b_facet, side)
			* (1.0 - smoothstep(ffar * 0.55, ffar, cam_r));
		// RUNDA 9. Aici era un `mix(m, facet_key, gf)`, si asta e chiar bugul
		// care a picat runda 8. Amestecat la 0.85, `facet_key` — care e
		// CONSTANT pe toata celula — inlocuia aproape complet forma din
		// textura: o celula ori trecea de prag pe toata suprafata ei, ori nu
		// trecea deloc. Rezultatul nu e o reflexie, e o celula VOPSITA. Pe apa
		// de sub tablier, unde celula subintinde zeci de mii de pixeli, iese
		// exact ce s-a masurat: pete de aur cu contur de amiba, 25% acoperire,
		// gauri intunecate in mijloc — piele de vaca peste noroi.
		//
		// Fateta trebuie sa spuna CARE placi prind lumina, nu sa deseneze ea
		// pata. Deci `facet_key` devine o POARTA multiplicativa peste masca de
		// textura: placile cu cheie mica raman stinse oricat de adanca e
		// fisura pe ele, cele cu cheie mare lasa fisurile sa se aprinda — si
		// forma dinauntru ramane a fisurii, adica pete de metri cu halou.
		// Asa se obtine si acoperirea mica din diorama (2-12%): poarta taie
		// intai placile, masca taie apoi in ele.
		//
		// `gf` ramane aceeasi cheie si se stinge tot cu distanta, dar acum
		// interpoleaza intre "poarta deschisa peste tot" (1.0) si "poarta
		// dupa fateta", nu intre doua desene diferite.
		m *= mix(1.0, smoothstep(facet_gate, 1.0, facet_key), gf);
		// Pragul e per rau: in diorama bratul auriu are de cinci ori mai multi
		// pixeli aprinsi decat cel verde (11.8% fata de 2.4% peste luminanta
		// 90), iar pragul e chiar butonul care regleaza acoperirea.
		float cut = glint_b_cut > 0.0 ? mix(glint_cut, glint_b_cut, side)
			: glint_cut;
		gmask = smoothstep(cut, cut + glint_soft, m);
		// Interiorul nu e plat: cu cat fisura e mai adanca, cu atat pata e mai
		// aprinsa. Fara asta o pata e o singura culoare pana la contur, adica
		// hartie decupata; in diorama fiecare reflexie are miez si halou.
		gmask *= mix(1.0, smoothstep(cut, 1.0, m), glint_body);
	}
	// PLAFONUL DE LA VOLAN (v11, runda 12). Vezi `glint_graze_cap`.
	//
	// `glint_graze` de mai sus lateste lobul cand privirea cade razant, ca sa
	// existe reflexii si de pe tablier. Corect ca FORMA, dar are un cost care
	// se vede abia din scaunul soferului: la 1.2 m peste sosea toata apa din
	// cadru e razanta, deci lobul latit se aprinde peste tot deodata si banda
	// de apa iese crema plina. Masurat pe vederea D: 15.4% din pixelii apei
	// peste mediana+25 si doar 4.4% din suprafata la +-4 de mediana, fata de
	// 4.7% si 36.5% in bar/E_chei.png — adica exact inversul linistii pe care
	// o repara runda asta, si in singura vedere din care se conduce.
	//
	// Deci ce se lateste ca forma se stinge ca INTENSITATE: lobul mai larg
	// prinde mai multe pante (ca sa nu dispara reflexiile), dar fiecare dintre
	// ele primeste mai putina lumina (ca sa nu se aprinda toata apa). Cele
	// doua se compenseaza, si acoperirea ramane a temei, nu a unghiului.
	if (glint_graze_cap < 1.0) {
		g_att = mix(glint_graze_cap, 1.0,
			smoothstep(0.0, glint_graze_ref, clamp(view.y, 0.0, 1.0)));
	}
	float g = glint * gmask * g_att;
	base += g * glint_strength * mix(1.0, glint_b_gain, side) * glint_col;

	ALBEDO = base;
}
