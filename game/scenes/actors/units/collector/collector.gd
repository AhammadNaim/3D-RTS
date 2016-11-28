extends Spatial

# Member variables
const SPEED = 4.0

var begin = 0 #Vector3()
var end = 0 #Vector3()
var m = FixedMaterial.new()

var path = []
var draw_line = true
var destination = Vector3()
var gray_mat = FixedMaterial.new()
var selected = 0
var auto_collecting = 0

onready var line_timer = Timer.new()
onready var camera = get_node("/root/game/world/camera/Camera")
onready var navigation = get_node("/root/game/world/terrain/map/navigation")
onready var im = ImmediateGeometry.new()
onready var anchor = Position3D.new()

func _ready():
	set_process_input(true)
	m.set_line_width(2)
	m.set_point_size(2)
	m.set_fixed_flag(FixedMaterial.FLAG_USE_POINT_SIZE, true)
	m.set_parameter(FixedMaterial.PARAM_DIFFUSE, Color(0.2, 0.8, 0.2))
	m.set_flag(Material.FLAG_UNSHADED, true)
	add_child(line_timer)
	
	#we recycle line timer for this short timeout after spawn for proper init
	line_timer.connect("timeout", self, "start_collecting")
	get_node("/root/game/world").add_child(im)
	
	begin = get_global_transform()
	begin = begin.origin
	spawn_timer()
	
#start collecting after you have properly spawned and been translated to your location
func spawn_timer():
	line_timer.set_one_shot(true)
	line_timer.set_wait_time(0.2)
	line_timer.set_active(true)
	line_timer.start()
	
	

func start_collecting():
	add_to_group("automatic_collector")
	#TODO: make this actually work
	var closest = find_closest_resource()
	draw_line = false
	move(closest.get_translation())

func select():
	add_to_group("selected")
	get_node("mesh").set_material_override(gray_mat)

func deselect():
	remove_from_group("selected")
	get_node("mesh").set_material_override(null)
	
func move(point):
	if ("selected" in get_groups() or "automatic_collector" in get_groups()):
		begin = navigation.get_closest_point(get_translation())
		end = point
		if begin.distance_to(end) > 0.1:
			_update_path()
			if (draw_line):
				line_timer.set_one_shot(true)
				line_timer.set_wait_time(1)
				line_timer.set_active(true)
				line_timer.start()

func _process(delta):
	if (path.size() > 1):
		var to_walk = delta*SPEED
		var to_watch = Vector3(0, 1, 0)
		while(to_walk > 0 and path.size() >= 2):
			var pfrom = path[path.size() - 1]
			var pto = path[path.size() - 2]
			to_watch = (pto - pfrom).normalized()
			var d = pfrom.distance_to(pto)
			if (d <= to_walk):
				path.remove(path.size() - 1)
				to_walk -= d
			else:
				path[path.size() - 1] = pfrom.linear_interpolate(pto, to_walk/d)
				to_walk = 0
		
		var atpos = path[path.size() - 1]
		var atdir = to_watch
		atdir.y = 0
		
		var t = Transform()
		t.origin = atpos
		t=t.looking_at(atpos + atdir, Vector3(0, 1, 0))
		get_node(".").set_transform(t)
		
		if (draw_line):
			if line_timer.get_time_left() > 0:
				var current_unit = get_node("/root/game/world/actors/units/"+get_name()).get_translation()
				var end_point = Vector3(end.x,end.y+0.2,end.z)
				current_unit.y = 0.2
				im.clear()
				im.set_material_override(m)
				im.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
				im.add_vertex(current_unit)
				im.add_vertex(end_point)
				im.end()
			else:
				im.clear()
		
		if (path.size() < 2):
			path = []
			set_process(false)
		
	else:
		set_process(false)

func _update_path():
	var p = navigation.get_simple_path(begin, end, true)
	path = Array(p) # Vector3array too complex to use, convert to regular array
	path.invert()
	set_process(true)
	
func find_closest_resource():
	var best_resource = 0
	# I really hope someone doesn't make too big map
	var shortest_path = 9001
	for resource in get_tree().get_nodes_in_group("resources"):
		var path = navigation.get_simple_path(get_translation(), resource.get_translation() , true)
		var sum = 0
		for vector in path:
			sum += vector.length()
		if sum < shortest_path:
			shortest_path = sum
			best_resource = resource
	return best_resource