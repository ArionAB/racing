class_name Localization
extends RefCounted
## Limbile jocului (nov 2026): engleza sursa + spaniola, portugheza (Brazilia),
## germana, franceza, italiana, japoneza. Fara romana (decizia dezvoltatorului).
##
## Textele stau in `localization/` ca gettext: `toy_racer.pot` e lista
## canonica (msgid = textul englezesc), cate un `.po` per limba. Engleza n-are
## fisier: un msgid fara traducere se afiseaza ca atare.
##
## Cum ajunge textul tradus pe ecran:
##   - un Label / Button al carui text e EXACT un msgid se traduce singur, la
##     desenare (auto-translate al Control-ului);
##   - un text COMPUS trece prin `tr()` pe sablonul intreg („LAP %d/%d"), nu
##     pe bucati lipite: ordinea cuvintelor difera de la o limba la alta;
##   - textele din resurse (`TrackInfo.display_name`, `CarData.display_name`...)
##     raman in engleza in .tres si se traduc la afisare: `tr(info.display_name)`.
##
## Alegerea jucatorului: `GameState.language` ("" = limba telefonului),
## salvata in settings.cfg la `[game] language` ca COD de limba (id stabil, nu
## nume de afis — regula din SaveSchema). Un cod necunoscut (scris de un build
## mai nou, cu o limba in plus) nu se sterge: ramane pe disc, iar jocul cade pe
## limba telefonului. Garda: ProbeLocalization.

## Codurile, in ordinea din SETTINGS. Primul e sursa.
const LOCALES: Array[String] = ["en", "es", "pt_BR", "de", "fr", "it", "ja"]
## Numele fiecarei limbi IN LIMBA EI — nu se traduc niciodata: cine a ajuns din
## greseala in japoneza trebuie sa-si gaseasca „English" fara sa citeasca kanji.
const NATIVE_NAMES: Dictionary = {
	"en": "English",
	"es": "Español",
	"pt_BR": "Português (Brasil)",
	"de": "Deutsch",
	"fr": "Français",
	"it": "Italiano",
	"ja": "日本語",
}
## Fisierele de traducere (le citeste si project.godot, si sonda).
const PO_DIR := "res://localization/"

## Fontul japonez: fallback pentru Barlow si pentru fontul implicit al temei.
## Barlow n-are kana/kanji; fara fallback-ul nostru, textul ar depinde de
## fonturile sistemului (ce are telefonul, in ce stil, sau patratele goale).
const FONT_JP: FontFile = preload("res://assets/fonts/NotoSansJP-Medium.otf")
const FONT_BOLD: FontFile = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
const FONT_MEDIUM: FontFile = preload("res://assets/fonts/BarlowCondensed-Medium.ttf")


## Limba efectiva: alegerea salvata daca e o limba a jocului, altfel limba
## telefonului (`OS.get_locale()`, ex. „pt_PT", „ja_JP", „de_AT").
static func resolve(saved: String, device_locale: String) -> String:
	if saved in LOCALES:
		return saved
	return from_device(device_locale)


## Telefonul -> limba jocului. Portugheza de oriunde (si pt_PT) primeste
## varianta braziliana — singura pe care o avem; tot ce nu e una din limbile
## jocului cade pe engleza.
static func from_device(device_locale: String) -> String:
	var lang := device_locale.to_lower().replace("-", "_").get_slice("_", 0)
	match lang:
		"es": return "es"
		"pt": return "pt_BR"
		"de": return "de"
		"fr": return "fr"
		"it": return "it"
		"ja": return "ja"
	return "en"


## Aplica alegerea (chemat de GameState la pornire si de SETTINGS la schimbare).
## Intoarce limba efectiva.
static func apply(saved: String) -> String:
	var locale := resolve(saved, OS.get_locale())
	TranslationServer.set_locale(locale)
	return locale


## Pune Noto Sans JP in coada fiecarui font de text al jocului. O data, la
## pornire (GameState._ready), inainte sa se modeleze vreun text. Fonturile
## sunt resurse partajate (preload), deci fallback-ul ajunge la toate
## Control-urile care le folosesc, fara nicio schimbare in panouri.
static func install_fonts() -> void:
	var targets: Array[Font] = [FONT_BOLD, FONT_MEDIUM, ThemeDB.fallback_font]
	var theme := ThemeDB.get_default_theme()
	if theme != null and theme.default_font != null:
		targets.append(theme.default_font)
	for font in targets:
		_add_fallback(font, FONT_JP)


static func _add_fallback(font: Font, extra: Font) -> void:
	if font == null or font == extra:
		return
	var list := font.fallbacks
	if extra in list:
		return
	list.append(extra)
	font.fallbacks = list
