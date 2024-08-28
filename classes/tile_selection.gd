class_name TileSelection
extends RefCounted

var tilemap_position : Vector2i

var global_position : Vector2

var objects : Array[Node]


func _init(_global_pos:Vector2=Vector2.ZERO,_objects:Array[Node]=[],_tilemap_position:Vector2i=Vector2i.ZERO)->void:
	tilemap_position = _tilemap_position
	global_position = _global_pos
	objects = _objects


func get_axial()->Vector2i:
	if tilemap_position == Vector2i.ZERO:
		return Vector2i.ZERO
	var col = tilemap_position.x # x -> q | y -> r
	var row = tilemap_position.y - (tilemap_position.x - (tilemap_position.x&1)) / 2
	return Vector2i(col, row)
