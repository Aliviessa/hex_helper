class_name Hex
extends Object

## This is a helper class for games/applications that use a hex based grid. 
## 
## This is based on the methods described at redblobgames ([url]https://www.redblobgames.com/grids/hexagons[/url]).
## [br][br]
## Some methods are functionally the same as a simple Vector addition/subtraction. They are kept in the class for informational purposes and readability of certain functions.
## The class is intentionally unoptimized, as it helped me in the learning process to have things as expressive as possible.

enum DIR { SOUTHWEST, SOUTH, SOUTHEAST, NORTHEAST, NORTH, NORTHWEST }

enum COORD_SYSTEM { AXIAL, CUBE, ODDQ}

## This maps 1:1 to [member DIR] (SW,S,SE,NE,N,NW). Allows for better readability by using 'DIR.SOUTH' instead of '1' when using AXIAL_DIRECTION.
static var AXIAL_DIRECTION : Array = [Vector2i(-1, 1),Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0)] # SW,S,SE,NE,N,NW


#region CONVERSION

static func cube_to_axial(cube:Vector3i)->Vector2i:
	var q = cube.x
	var r = cube.y
	return Vector2i(q, r)


static func axial_to_cube(hex:Vector2i)->Vector3i:
	var q = hex.x
	var r = hex.y
	var s = -q-r
	return Vector3i(q, r, s)


static func axial_to_oddq(coord:Vector2i)->Vector2i:
	if coord == Vector2i.ZERO:
		return Vector2i.ZERO
	var col = coord.x # x -> q | y -> r
	var row = coord.y + (coord.x - (coord.x&1)) / 2
	return Vector2i(col, row)


static func oddq_to_axial(coord:Vector2i)->Vector2i:
	if coord == Vector2i.ZERO:
		return Vector2i.ZERO
	var q = coord.x # x->column | y->row
	var r = coord.y - (coord.x - (coord.x&1)) / 2
	return Vector2i(q, r)


static func oddq_to_cube(coord:Vector2i)->Vector3i:
	return axial_to_cube(oddq_to_axial(coord))


static func cube_to_oddq(coord:Vector3i)->Vector2i:
	return axial_to_oddq(Vector2i(coord.x,coord.y))

#endregion

#region AXIAL

static func axial_add(hex_coord:Vector2i, add_vector:Vector2i)->Vector2i:
	return Vector2i(hex_coord.x + add_vector.x, hex_coord.y + add_vector.y)


static func axial_subtract(a:Vector2i, b:Vector2i)->Vector2i:
	return Vector2i(a.x - b.x, a.y - b.y)


static func axial_neighbor(hex_coord:Vector2i, direction:Vector2i)->Vector2i:
	return axial_add(hex_coord, direction)


static func axial_distance(a:Vector2i, b:Vector2i)->Vector2i:
	var vec = axial_subtract(a, b)
	return (abs(vec.x)
		+ abs(vec.x + vec.y)
		+ abs(vec.y)) / 2

#endregion

#region CUBE

static func cube_add(hex: Vector3i, vec: Vector3i)->Vector3i:
	return Vector3i(hex.x + vec.x, hex.y + vec.y, hex.z + vec.z)


static func cube_subtract(a: Vector3i, b: Vector3i)->Vector3i:
	return Vector3i(a.x - b.x, a.y - b.y, a.z - b.z)


static func cube_distance(a: Vector3i, b: Vector3i):
	var vec = cube_subtract(a, b)
	return (abs(vec.x) + abs(vec.y) + abs(vec.z)) / 2

#endregion

#region ROTATION (CONVERT TO CUBE FIRST)



static func get_rotation_steps(from_dir:DIR, to_dir:DIR)->int:
	if from_dir < to_dir:
		# Counter-Clockwise
		return -(from_dir - to_dir)
	else:
		# Clockwise
		return to_dir - from_dir


static func _rotate_clockwise(vec: Vector3i)->Vector3i:
	var return_vector: Vector3i = Vector3i(-vec.z,-vec.x,-vec.y)
	return return_vector


static func _rotate_counter_clockwise(vec: Vector3i)->Vector3i:
	var return_vector: Vector3i = Vector3i(-vec.y,-vec.z,-vec.x)
	return return_vector


static func rotate(vec: Vector3i,rotation_steps:int)->Vector3i:
	for step in range(abs(rotation_steps)):
		if rotation_steps > 0:
			vec = _rotate_clockwise(vec)
		else:
			vec = _rotate_counter_clockwise(vec)
	return vec
	

#endregion
