class_name AStarHexMap
extends TileMapLayer

signal tile_clicked_primary(tile_selection:TileSelection)
signal tile_clicked_secondary(tile_selection:TileSelection)
signal tile_hovered(tile_selection:TileSelection)

var astar : AStar2D
var points : Dictionary # { tilemap_pos : astar_point_id }

## The nodes in these groups reserve a point on a tile they are positioned on. Update positions via [member update_reserved_points]
@export var obstacle_groups : Array[StringName] = [] 


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var tile_map_pos = mouse_screen_pos_to_tilemap_position(event.global_position)
		var tile_center_pos = mouse_screen_pos_to_tile_center_position(event.global_position)
		var objects = get_tracked_group_objects(tile_center_pos)
		tile_hovered.emit(TileSelection.new(tile_center_pos,objects,tile_map_pos))
		return
	if event.is_action_pressed("screen_select_primary"):
		var mouse_pos = get_global_mouse_position()
		var tile_map_pos = global_pos_to_tilemap_position(mouse_pos)
		var tile_center_pos = global_pos_to_tile_center_position(mouse_pos)
		var objects = get_tracked_group_objects(global_pos_to_tilemap_position(mouse_pos))
		tile_clicked_primary.emit(TileSelection.new(tile_center_pos,objects,tile_map_pos))
	if event.is_action_pressed("screen_select_secondary"):
		var mouse_pos = get_global_mouse_position()
		var tile_map_pos = global_pos_to_tilemap_position(mouse_pos)
		var tile_center_pos = global_pos_to_tile_center_position(mouse_pos)
		var objects = get_tracked_group_objects(global_pos_to_tilemap_position(mouse_pos))
		tile_clicked_secondary.emit(TileSelection.new(tile_center_pos,objects,tile_map_pos))


func initialize()->void:
	astar = AStar2D.new()
	var used_cells = get_used_cells()
	for cell in used_cells:
		var id = astar.get_available_point_id()
		points[cell] = id
		astar.add_point(id,cell)
	for point_id in astar.get_point_ids():
		var cell_coords = astar.get_point_position(point_id)
		var surrounding_cells = get_surrounding_cells(cell_coords)
		for surrounding_cell in surrounding_cells:
			if points.has(surrounding_cell):
				var cell_id = points[surrounding_cell]
				if astar.has_point(cell_id):
					astar.connect_points(point_id,cell_id)
	reset_reserved_points()


func reset_reserved_points(override_tracked_groups:Array[StringName]=obstacle_groups)->void:
	_reset_disabled_points()
	var all_tracked_nodes : Array = []
	for group in override_tracked_groups:
		all_tracked_nodes.append_array(get_tree().get_nodes_in_group(group))
	for node in all_tracked_nodes:
		if not "global_position" in node:
			continue
		var tilemap_pos = local_to_map(to_local(node.global_position))
		if not points.has(tilemap_pos):
			continue
		var pos_id = points[tilemap_pos]
		astar.set_point_disabled(pos_id)


func _reset_disabled_points()->void:
	for point in astar.get_point_ids():
		astar.set_point_disabled(point,false)


func set_tile_disabled(tilemap_pos_oddq: Vector2i, disabled: bool=true)->void:
	if !points.has(tilemap_pos_oddq):
		push_error("tilemap_pos not found in points Dictionary")
		return
	astar.set_point_disabled(points[tilemap_pos_oddq],disabled)


#region QUERIES

func get_astar_path(from:Vector2,to:Vector2)->PackedVector2Array:
	var path : PackedVector2Array = []
	var from_tilemap_pos = local_to_map(to_local(from))
	if !points.has(from_tilemap_pos):
		return path
	var to_tilemap_pos = local_to_map(to_local(to))
	if !points.has(to_tilemap_pos):
		return path
	for point in astar.get_point_path(points[from_tilemap_pos],points[to_tilemap_pos]):
		path.append(to_global(map_to_local(point)))
	return path


var cached_astar_grid_info : Dictionary
func get_astar_grid_info()->Dictionary:
	var frame = get_tree().get_frame()
	print("get_astar_grid_info")
	if cached_astar_grid_info:
		if cached_astar_grid_info.frame == frame:
			return cached_astar_grid_info
	var positions_dictionary : Dictionary = {
		"frame" : frame
		#"global_pos" : Dictionary
	}
	for point_id in astar.get_point_ids():
		var pos_dict : Dictionary = {}
		pos_dict["tilemap_position"] = astar.get_point_position(point_id)
		pos_dict["global_position"] = to_global(map_to_local(pos_dict["tilemap_position"]))
		pos_dict["is_disabled"] = astar.is_point_disabled(point_id)
		#pos_dict["surrounding_cells"] = tilemap.get_surrounding_cells(pos_dict["tilemap_position"])
		pos_dict["connected_points"] = []
		for point in astar.get_point_connections(point_id):
			pos_dict["connected_points"].append(to_global(map_to_local(astar.get_point_position(point))))
		positions_dictionary[pos_dict["tilemap_position"]] = pos_dict
	cached_astar_grid_info = positions_dictionary
	return positions_dictionary




func get_tracked_group_objects(at_tilemap_position:Vector2i,override_groups:Array[StringName]=obstacle_groups)->Array[Node]:
	var nodes : Array[Node] = []
	for group_name in override_groups:
		for node in get_tree().get_nodes_in_group(group_name):
			if not "global_position" in node:
				continue
			var node_tilemap_position = local_to_map(to_local(node.global_position))
			if node_tilemap_position == at_tilemap_position:
				nodes.append(node)
	return nodes


func get_tracked_group_objects_global(at_global_position:Vector2i,override_groups:Array[StringName]=obstacle_groups)->Array[Node]:
	var tilemap_position = local_to_map(to_local(at_global_position))
	return get_tracked_group_objects(tilemap_position,override_groups)




#endregion

#region POSITION CONVERSION

func mouse_screen_pos_to_tile_center_position(mouse_screen_position:Vector2)->Vector2:
	var tilemap_local_mouse_pos = get_canvas_transform().affine_inverse()*mouse_screen_position
	var tilemap_pos = local_to_map(tilemap_local_mouse_pos)
	var tile_local_pos = map_to_local(tilemap_pos)#+tilemap.position
	return to_global(tile_local_pos)


func mouse_screen_pos_to_tilemap_position(mouse_screen_position:Vector2)->Vector2i:
	var tilemap_local_mouse_pos = get_canvas_transform().affine_inverse()*mouse_screen_position
	var tilemap_pos = local_to_map(tilemap_local_mouse_pos)
	return tilemap_pos


func global_pos_to_tile_center_position(_global_position:Vector2)->Vector2:
	#var tilemap_local_mouse_pos = tilemap.get_canvas_transform().affine_inverse()*global_mouse_position
	var tilemap_pos = local_to_map(_global_position)
	var tile_local_pos = map_to_local(tilemap_pos)#+tilemap.position
	return to_global(tile_local_pos)


func global_pos_to_tilemap_position(_global_position:Vector2)->Vector2i:
	#var tilemap_local_mouse_pos = tilemap.get_canvas_transform().affine_inverse()*global_mouse_position
	var tilemap_pos = local_to_map(_global_position)
	return tilemap_pos


func get_tile_center_position(at_global_position:Vector2)->void:
	var tilemap_local_pos = to_local(at_global_position)#tilemap.get_canvas_transform().affine_inverse()*at_global_position
	return map_to_local(local_to_map(tilemap_local_pos))


func global_to_screen_pos(global_pos)->Vector2:
	#var local_pos = tilemap.to_local(global_pos)
	#var screen_coord = tilemap.get_viewport_transform() * (tilemap.get_global_transform() * local_pos)
	var screen_coord = get_viewport_transform() * global_pos
	return screen_coord


func tile_map_to_screen_pos(tilemap_pos:Vector2i)->Vector2:
	var local_pos = map_to_local(tilemap_pos)
	var screen_coord = get_viewport_transform() * (get_global_transform() * local_pos)
	return screen_coord


#endregion


#region utility

func is_position_blocked_axial(tilemap_pos_axial:Vector2i)->bool:
	var as_oddq = Hex.axial_to_oddq(tilemap_pos_axial)
	return is_position_blocked(as_oddq)


func is_position_blocked(tilemap_pos:Vector2i)->bool:
	var pos_id = points[tilemap_pos]
	var result = astar.is_point_disabled(pos_id)
	return result

#endregion

#region RANGE

func cells_in_range_axial(of:Vector2i,move_range:int)->Array[Vector2i]:
	var cells : Array[Vector2i] = []
	var q = -move_range
	while q <= move_range:
		var r = max(-move_range, -q-move_range)
		while r <= min(move_range,-q+move_range):
			cells.append(Hex.axial_add(of,Vector2i(q,r)))
			r+=1
		q+=1 
	return cells


func cells_in_range_oddq(of_position_oddq:Vector2i,move_range:int)->Array[Vector2i]:
	var of_position_axial = Hex.oddq_to_axial(of_position_oddq)
	var cells = cells_in_range_axial(of_position_axial,move_range)
	for i in range(cells.size()):
		cells[i] = Hex.axial_to_oddq(cells[i])
	return cells


func tile_coords_to_global(vector_arr:Array,source_coordinate_system:Hex.COORD_SYSTEM=Hex.COORD_SYSTEM.ODDQ)->Array[Vector2]:
	#print("before: ",vector_arr)
	match source_coordinate_system:
		Hex.COORD_SYSTEM.ODDQ:
			pass
		Hex.COORD_SYSTEM.AXIAL:
			for i in range(vector_arr.size()):
				vector_arr[i] = Hex.axial_to_oddq(vector_arr[i])
			#print("inbetween: ",vector_arr)
		Hex.COORD_SYSTEM.AXIAL:
			for i in range(vector_arr.size()):
				vector_arr[i] = Hex.cube_to_oddq(vector_arr[i])
	var new_arr : Array[Vector2] = [] 
	for vec in vector_arr:
		new_arr.append(to_global(map_to_local(vec)))
	#print("after: ",new_arr)
	return new_arr


func get_reachable_cells(axial_tilemap_pos:Vector2i,move_range:int)->Array[Vector2i]:
	var visited : Array[Vector2i] = [] # set of hexes
	visited.append(axial_tilemap_pos) #add start to visited
	var fringes = [] # array of arrays of hexes

	fringes.append([axial_tilemap_pos])
	var k = 1
	while k <= move_range:
		fringes.append([])
		for axial_vector in fringes[k-1]:
			for dir in Hex.AXIAL_DIRECTION:
				var neighbor = Hex.axial_neighbor(axial_vector, dir)
				if not points.has(Hex.axial_to_oddq(neighbor)): # ignore unused tilemap cells
					continue
				if  not visited.has(neighbor) and not is_position_blocked_axial(neighbor):
					visited.append(neighbor) #add neighbor to visited
					fringes[k].append(neighbor)
		k+=1
	visited.erase(axial_tilemap_pos)
	return visited # as Axial

# INTERSECTION

func intersect(center_cube_1:Vector3i,center_cube_2:Vector3i,move_range:int)->Array[Vector2i]:
	var results : Array[Vector2i] = []
	var q_min = max(center_cube_1.x - move_range, center_cube_2.x - move_range)
	var q_max = min(center_cube_1.x + move_range, center_cube_2.x + move_range)
	var r_min = max(center_cube_1.y - move_range, center_cube_2.y - move_range)
	var r_max = min(center_cube_1.y + move_range, center_cube_2.y + move_range)
	var s_min = max(center_cube_1.z - move_range, center_cube_2.z - move_range)
	var s_max = min(center_cube_1.z + move_range, center_cube_2.z + move_range)
	var q = q_min
	while q <= q_max:
		var r_loop_min = max(r_min, -q-s_max)
		var r_loop_max = min(r_max, -q-s_min)
		var r = r_loop_min
		while r <= r_loop_max:
			results.append(Vector2i(q, r))
			r+=1
		q+=1
	return results

#endregion

#endregion
