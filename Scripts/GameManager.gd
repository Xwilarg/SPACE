extends Node3D

var _buttons: Array[CardUI]
@export var _deck: JSON

var _cards: Array[Card]

var _selected_card: Card
var rng = RandomNumberGenerator.new()

var hintObject: Node3D
var current_button: CardUI

var time_start: int = 0
var time_now: int = 0
var elapsed_time: int
var meteo: String

var destroyed_asteroids = 0
var timers: Dictionary

func _init_cards():
	for card in _deck.data:
		_cards.append(Card.new(card))

	for g in GridManager._grids:
		if g.help_slot != null:
			for c in _cards:
				if c.key == "sensor":
					place_at_pos(g.help_slot, c)
					break

func subscribe_button(b: CardUI) -> void:
	if len(_cards) == 0:
		_init_cards()
	update_button(b, false)
	_buttons.append(b)

func load_item(b: CardUI, card: Card) -> void:
	_selected_card = card
	if hintObject != null:
		hintObject.queue_free()
	hintObject = card.previewModel.instantiate()
	add_child(hintObject)
	current_button = b
	timers[b] = -1

func on_meteo_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var unitTemperature = str(json["current_weather"]["temperature"]) if json.has("current_weather") else "°C"
	var unitWind = str(json["current_weather"]["windspeed"]) if json.has("current_weather") else "km/h"
	meteo = tr("TEMPERATURE") + tr("COLON") + " " + str(json["current_weather"]["temperature"]) + unitTemperature + "\n"
	meteo += tr("WIND_SPEED") + tr("COLON") + " " + str(json["current_weather"]["windspeed"]) + unitWind
	print("[GM] Meteo loaded: " + meteo)

func _ready():
	time_start = Time.get_unix_time_from_system()
	meteo = "Can't contact meteo API"
	Ghttp.request_completed.connect(on_meteo_completed)
	var resp = Ghttp.request("https://api.open-meteo.com/v1/forecast?latitude=48.85&longitude=2.35&current_weather=true")

func round_to_dec(num, digit): # https://ask.godotengine.org/29110/how-to-round-to-a-specific-decimal-place
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func _process(delta):
	time_now = Time.get_unix_time_from_system()
	elapsed_time = time_now - time_start
	
	if hintObject != null:
		var camera3d = get_node("/root/Root/Camera3D")
		var space_state = get_tree().get_root().get_world_3d().direct_space_state
		var m_pos = get_viewport().get_mouse_position()

		var from = camera3d.project_ray_origin(m_pos)
		var to = from + camera3d.project_ray_normal(m_pos) * 100000.0
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask |= (1 << 1)
		query.collision_mask |= (1 << 2)

		var result = space_state.intersect_ray(query)
		if len(result) > 0:
			hintObject.global_position = result.position
	
	# update UI
	if get_node("/root/Root/UI/CaptorInfo"):
		for key in timers.keys():
			if !key.visible:
				timers[key] -= delta
				if timers[key] <= 0:
					key.visible = true

		var info_level = CardManager.sum(CardManager.get_effect("SEN"))
		var text = ""
		
		if info_level > 0: # Ship HP
			var spaceship = get_node("/root/Root/spaceship")
			text += tr("SHIP_HULL") + tr("COLON") + " " + str(spaceship.current_hp) + "/" + str(spaceship.max_hp) + "\n"
			text += tr("SHIELD") + tr("COLON") + " " + str(spaceship.current_shield) + "\n\n"
		
		if info_level > 1: # Energy
			var asteroids = get_node("/root/Root/AsteroidManager").get_all_asteroids()
			text += tr("ENERGY") + tr("COLON") + " " + str(CardManager._energy_max - CardManager._energy_used) + "/" + str(CardManager._energy_max) + "\n\n"

		if info_level > 2: # Attack power
			var u_r = CardManager.sum(CardManager.get_effect("UPG_RED"))
			var u_g = CardManager.sum(CardManager.get_effect("UPG_GRN"))
			var u_b = CardManager.sum(CardManager.get_effect("UPG_BLU"))
			var upg = {
				"RED": u_r - (u_g / 2) - (u_b / 2),
				"GRN": u_g - (u_r / 2) - (u_b / 2),
				"BLU": u_b - (u_g / 2) - (u_r / 2)
			}

			var tt = CardManager.sum(CardManager.get_effect("ATK_GRN")) + 1 * (upg["GRN"] / 100)
			tt += CardManager.sum(CardManager.get_effect("ATK_BLU")) + 1 * (upg["BLU"] / 100)
			tt += CardManager.sum(CardManager.get_effect("ATK_RED")) + 1 * (upg["RED"] / 100)
			
			var speed = 1 + CardManager.sum(CardManager.get_effect("SPD")) / 100.0

			if info_level == 3:
				text += tr("ATTACK_POWER") + tr("COLON") + " " + str(round_to_dec(tt / 3.0 * speed, 2))
			else:
				text += tr("ATTACK_POWER") + "\n"
				text += tr("GRN_DMG") + tr("COLON") + " " + str(CardManager.sum(CardManager.get_effect("ATK_GRN")) + 1 * (upg["GRN"] / 100.0) * speed) + "\n"
				text += tr("BLU_DMG") + tr("COLON") + " " + str(CardManager.sum(CardManager.get_effect("ATK_BLU")) + 1 * (upg["BLU"] / 100.0) * speed) + "\n"
				text += tr("RED_DMG") + tr("COLON") + " " + str(CardManager.sum(CardManager.get_effect("ATK_RED")) + 1 * (upg["RED"] / 100.0) * speed)
				text += "\n\n"

		if info_level > 5:
			text += tr("METEO") + "\n" + meteo + "\n\n"

		if info_level > 6:
			text += tr("FAVORITE_CHEESE") + "\n" + tr("FETA") + "\n" + tr("GRUYERE") + "\n" + tr("AMERICAN_CHEESE") + "\n\n"
		
		get_node("/root/Root/UI/CaptorInfo").text = text

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1 and _selected_card != null:
		
		if !CardManager.can_be_placed(_selected_card):
			var energy_alert = get_node(("/root/Root/UI/MissingEnergy"))
			energy_alert.text = "[center]" + tr("MISSING_ENERGY") + "[/center]"
			$EnergyAlert.start()
			hintObject.queue_free()
			hintObject = null
			_selected_card = null
			return
		
		# We do a raycast to see where we click
		var camera3d = get_node("/root/Root/Camera3D")
		var space_state = get_tree().get_root().get_world_3d().direct_space_state
		var m_pos = event.position

		var from = camera3d.project_ray_origin(m_pos)
		var to = from + camera3d.project_ray_normal(m_pos) * 100000.0
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 2

		var result = space_state.intersect_ray(query)
		
		if len(result) > 0: # If we clicked on a slot...
			var s: Slot = result.collider.get_node("..")
			if s.grid.can_place(s, _selected_card):
				place_at_pos(result.collider.get_node(".."), _selected_card)
				update_button(current_button, true)
		# We unselect the card
		hintObject.queue_free()
		hintObject = null
		_selected_card = null


func place_at_pos(slot: Node3D, card: Card):
	var item = card.model.instantiate()
	CardManager.register_item(ItemCard.new(card, item))
	add_child(item)
	var t = slot.global_position
	item.global_position = Vector3(t.x, t.y + .5, t.z)
	slot.grid.place(slot, card, item)
	

func verify_all_buttons():
	var upgradeLevel = CardManager.sum(CardManager.get_effect("UPG")) + 1
	for b in _buttons:
		if b._curr_card.level > upgradeLevel:
			update_button(b, true)

var is_first = true
func update_button(b: CardUI, hide: bool):
	var upgradeLevel = CardManager.sum(CardManager.get_effect("UPG")) + 1
	var nextCard = b._curr_card
	var name: String
	if nextCard != null: name = b._curr_card.name
	if is_first:
		for c in _cards:
			if c.key == "flak1":
				nextCard = c
				is_first = false
				break
	else:
		while nextCard == null or nextCard.name == name or nextCard.level > upgradeLevel:
			nextCard = _cards[rng.randi_range(0, len(_cards) - 1)]
	print("[GM] Loading card " + nextCard.name + " of level " + str(nextCard.level) + " (Current level: " + str(upgradeLevel) + ")")
	b.set_card(nextCard)
	if hide:
		b.visible = false
		timers[b] = 5


func _on_energy_alert_timeout():
	var energy_alert = get_node(("/root/Root/UI/MissingEnergy"))
	energy_alert.text = ""
	$EnergyAlert.wait_time = 3
	$EnergyAlert.stop()
	
