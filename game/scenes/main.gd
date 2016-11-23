extends Node


var placing_building = 0
var rotating_building = 0
var building_node
var building_location
onready var camera = get_node("/root/game/world/camera/Camera")

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action("order"):
		for unit in get_tree().get_nodes_in_group("selected"):
			unit.move(mouse2coords(event))
	if placing_building:
		building_node.set_translation(mouse2coords(event))
		
	if placing_building and event.is_action_pressed("confirm_placement"):
		if !building_location:
			building_location = mouse2coords(event)
		placing_building = 0
		rotating_building = 1
		
	if rotating_building and event.type==InputEvent.MOUSE_MOTION:
		building_node.look_at(mouse2coords(event), Vector3(0,1,0))
		
	if rotating_building and event.is_action_released("confirm_placement"):
		building_node.add_to_group("buildings")
		get_node("UI/HUD/build_menu").update_build_options()
		placing_building = 0
		rotating_building = 0
		building_location = 0
		
	if placing_building and event.is_action("cancel_placement"):
		cancel_building_placement()
		
	if event.is_action("cancel_selection"):
		for unit in get_tree().get_nodes_in_group("selected"):
			unit.deselect()
		
func mouse2coords(event):
	var near = camera.project_ray_origin(event.pos)
	var far = near + camera.project_ray_normal(event.pos)*100
	var click = get_node("world/terrain/map/navigation").get_closest_point_to_segment(near, far)
	return click
	
func start_placing_building(building_nodepath):
	placing_building = 1
	var node = load(building_nodepath)
	building_node = node.instance()
	# could I just load(building_nodepath).instance() ?
	building_node.set_translation(Vector3(0,-9001,0))
	get_node("world/actors/constructions").add_child(building_node)

func cancel_building_placement():
	get_node("world/actors/constructions").remove_child(building_node)
	placing_building = 0
	rotating_building = 0
	
func spawn_unit(nodepath):
	var unit_scene = load(nodepath)
	var unit = unit_scene.instance()
	get_node("world/actors/units").add_child(unit)
	unit.set_translation(get_node("world/actors/constructions").get_node("gear_of_generating").get_translation())