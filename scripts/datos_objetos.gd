extends RefCounted

## Catálogo de objetos en DATOS: añadir contenido no toca ni el modelo ni la
## UI. Los tres últimos son del universo Kimerian (M5a) y salen en la sala
## para recogerlos (ver RELIQUIAS_MUNDO en main.gd):
##   cristal_corinarius — materiales/corinarius.md (luna caída, azul oscuro)
##   amuleto_mil_islas  — lugares/las-mil-islas.md (archipiélago pirata)
##   botas_abordaje     — lugares/las-mil-islas.md (piratas [CANON])
## efectos: inventario.bonus() suma "vida_max" / "defensa" / "velocidad".
## "vida" de la poción lo usará la acción de uso en M4b.

const OBJETOS: Dictionary = {
	# --- apilables ---
	"pocion": {"nombre": "Poción", "stack": 9, "slot": "", "efectos": {"vida": 2}},
	"moneda": {"nombre": "Moneda", "stack": 99, "slot": "", "efectos": {}},
	# --- cabeza (3, propiedades distintas) ---
	"capucha_viajera": {"nombre": "Capucha de viajero", "stack": 1, "slot": "cabeza",
			"efectos": {"velocidad": 25}},
	"casco_bronce": {"nombre": "Casco de bronce", "stack": 1, "slot": "cabeza",
			"efectos": {"defensa": 1}},
	"diadema_clara": {"nombre": "Diadema clara", "stack": 1, "slot": "cabeza",
			"efectos": {"vida_max": 1}},
	# --- pecho (3) ---
	"tunica_ligera": {"nombre": "Túnica ligera", "stack": 1, "slot": "pecho",
			"efectos": {"velocidad": 15}},
	"coraza_herrera": {"nombre": "Coraza del herrero", "stack": 1, "slot": "pecho",
			"efectos": {"defensa": 2}},
	"peto_andino": {"nombre": "Peto andino", "stack": 1, "slot": "pecho",
			"efectos": {"vida_max": 2}},
	# --- botas (3) ---
	"botas_ligeras": {"nombre": "Botas ligeras", "stack": 1, "slot": "botas",
			"efectos": {"velocidad": 30}},
	"botas_pesadas": {"nombre": "Botas pesadas", "stack": 1, "slot": "botas",
			"efectos": {"defensa": 1}},
	"botas_peregrinas": {"nombre": "Botas peregrinas", "stack": 1, "slot": "botas",
			"efectos": {"vida_max": 1}},
	# --- casco (3: el cuarto slot tal y como lo pidió Edward) ---
	"yelmo_anciano": {"nombre": "Yelmo anciano", "stack": 1, "slot": "casco",
			"efectos": {"defensa": 1}},
	"mascara_ritual": {"nombre": "Máscara ritual", "stack": 1, "slot": "casco",
			"efectos": {"vida_max": 1}},
	"cimera_fiera": {"nombre": "Cimera fiera", "stack": 1, "slot": "casco",
			"efectos": {"velocidad": 10}},
	# --- objetos del universo Kimerian (M5a) ---
	"cristal_corinarius": {"nombre": "Cristal de corinarius", "stack": 1,
			"slot": "cabeza", "efectos": {"vida_max": 2}},
	"amuleto_mil_islas": {"nombre": "Amuleto de Las Mil Islas", "stack": 1,
			"slot": "pecho", "efectos": {"defensa": 1}},
	"botas_abordaje": {"nombre": "Botas de abordaje", "stack": 1,
			"slot": "botas", "efectos": {"velocidad": 20}},
}
