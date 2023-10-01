extends Node

@onready var asteroidManager  = get_node("/root/Root/AsteroidManager")

var _aaTimer: float = 1.0
var animal_video_timer: float
var _items: Array[ItemCard]

var _energy_max: int = 100
var _energy_used: int = 0

var catVideo = [
	[ preload("res://Videos/catVideo1.ogv") ],
	[ preload("res://Videos/dogVideo1.ogv"), preload("res://Videos/dogVideo2.ogv") ],
	[ preload("res://Videos/chickenVideo.ogv") ]
]

var colors: Array[String] = [ "RED", "GRN", "BLU" ]

func can_be_placed(card: Card) -> bool:
	if _energy_used + card.energyCost > _energy_max:
		return false
	return true

func get_effect(str: String) -> Array[int]:
	var data: Array[int]
	
	for item in _items:
		if item.card.effects.has(str):
			data.append(int(item.card.effects[str]))
	
	return data

func sum(arr: Array[int]) -> int:
	var val: int = 0
	for nb in arr:
		val += nb
	return val

func _process(delta):
	_aaTimer -= delta
	
	if _aaTimer <= 0.0:
		for i in _items:
			var asteroids = asteroidManager.get_all_asteroids()
			if len(asteroids) == 0:
				break

			var a = asteroids[GameManager.rng.randi_range(0, len(asteroids) - 1)]
			var color = a.type
			if i.card.effects.has("ATK_" + color):
				var eff = i.card.effects["ATK_" + color]
				a.take_damage(eff)
				print("[CM] " + i.card.name + " firing at asteroid for " + str(eff) + " damage (color: " + color + ")")
		
		_aaTimer = 1.0 * 1.0 - sum(get_effect("SPD")) / 100.0
		if _aaTimer <= 0.1: _aaTimer = 0.1

	if animal_video_timer > 0.0:
		animal_video_timer -= delta
		if animal_video_timer <= 0.0:
			play_animal_video()

func register_item(item: ItemCard):
	_energy_used += item.card.energyCost
	_items.append(item)
	if item.card.effects.has("ENG"):
		_energy_used -= int(item.card.effects["ENG"])
		update_ui()
	play_animal_video()
	print("[CM] " + item.card.name + " placed, energy left: " + str(_energy_max - _energy_used))

func delete_item(node: Node3D):
	for item in _items:
		if item.item == node:
			if item.card.effects.has("ENG"):
				_energy_used += int(item.card.effects["ENG"])
				update_ui()
			_items.erase(item)
			if len(get_effect("VID")) == 0:
				get_node("/root/Root/UI/VideoStreamPlayer").stream = null

func play_animal_video():
	var vidCount = sum(get_effect("VID"))
	if vidCount > 0:
		var player: VideoStreamPlayer = get_node("/root/Root/UI/VideoStreamPlayer")
		vidCount -= 1
		if vidCount >= len(catVideo): vidCount = len(catVideo)
		var arr = catVideo[vidCount]
		player.stream = arr[GameManager.rng.randi_range(0, len(arr) - 1)]
		player.play()
		animal_video_timer = 20

func update_ui():
	pass
