extends Node3D

var _buttons: Array[ItemButton]
var _gridManager: Array[GridManager]
@export var _deck: JSON

var _cards: Array[Card]

var _selected_item: Card
var rng = RandomNumberGenerator.new()

var hintObject

func _init_cards():
	for card in _deck.data:
		_cards.append(Card.new(card))

func subscribe_button(b: ItemButton) -> void:
	if len(_cards) == 0:
		_init_cards()
	b.set_card(_cards[rng.randi_range(0, len(_cards) - 1)])
	_buttons.append(b)

func load_item(item: Card) -> void:
	_selected_item = item
	hintObject = item.previewModel.instantiate()
	add_child(hintObject)
	
func _process(delta):
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

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1 and _selected_item != null:
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
			print(result)
			var isDone = false
			for gm in _gridManager:
				for grid in gm.grid_ref:
					if grid.on_grid(result.collider.global_position, Vector3.ONE, gm._space):
						# ... we place it on the grid
						print("It's magic time")
						isDone = true
						break
					else:
						print("Magic is gone booo")
				if isDone:
					break

		# We unselect the item
		hintObject.queue_free()
		hintObject = null
		_selected_item = null

