extends Node

var tree_pool := []
var building_pool := []
const POOL_SIZE := 500

var tree_scene = preload("res://scenes/Tree.tscn")
var building_scene = preload("res://scenes/Terminal.tscn")

func _ready():
	for i in range(POOL_SIZE):
		var tree = tree_scene.instantiate()
		tree.visible = false
		tree_pool.append(tree)
		
		var building = building_scene.instantiate()
		building.visible = false
		building_pool.append(building)

func get_tree0() -> Node3D:
	if tree_pool.size() > 0:
		return tree_pool.pop_back()
	else:
		return tree_scene.instantiate()

func get_building() -> Node3D:
	if building_pool.size() > 0:
		return building_pool.pop_back()
	else:
		return building_scene.instantiate()

func return_tree(tree: Node3D):
	tree.get_parent().remove_child(tree)
	tree.visible = false
	tree.position = Vector3.ZERO
	tree.scale = Vector3.ONE
	tree_pool.append(tree)

func return_building(building: Node3D):
	building.get_parent().remove_child(building)
	building.visible = false
	building.position = Vector3.ZERO
	building.scale = Vector3.ONE
	building_pool.append(building)
