extends Node

const Tex = preload("res://скрипты/ядро/текстуры.gd")
const OUT = "res://сцены/отель/отель.tscn"
const TEX_DIR = "res://ассеты/текстуры/отель/"
const NAMES = {
	"MeshInstance3D": "Меш", "StaticBody3D": "Коллизия", "CollisionShape3D": "Форма",
	"OmniLight3D": "Свет", "Label3D": "Надпись", "Node3D": "Узел", "Area3D": "Зона",
	"GPUParticles3D": "Пыль", "MultiMeshInstance3D": "Группа",
}


func _ready():
	await Game.come_back_to_light(0.01)
	Game.progress.settings["quality"] = 1
	var script: GDScript = load("res://скрипты/карты/отель.gd")
	var map = script.new()
	map.force_the_code = true
	map.params["bake"] = true
	add_child(map)
	map.build()

	var big_boss = Node3D.new()
	big_boss.name = "Отель"
	for c in map.get_children():
		map.remove_child(c)
		big_boss.add_child(c)
	var spawn = Marker3D.new()
	spawn.name = "Спавн"
	spawn.transform = map.spawn_spot
	big_boss.add_child(spawn)

	for id in Tex._tex:
		if String(id).ends_with("#n"):
			continue
		var path: String = TEX_DIR + "текстура %s.png" % map.PROC_NAMES.get(id, id)
		(Tex._imgs[id] as Image).save_png(ProjectSettings.globalize_path(path))
		(Tex._tex[id] as Texture2D).take_over_path(path)

	_rename_lol(big_boss)
	_own_lol(big_boss, big_boss)
	var packed = PackedScene.new()
	var err = packed.pack(big_boss)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("Сцена сохранена: ", OUT, " код=", err, " узлов=", _count_lol(big_boss))
	get_tree().quit(0 if err == OK else 1)


func _rename_lol(n: Node):
	for c in n.get_children():
		if String(c.name).begins_with("@"):
			c.name = NAMES.get(c.get_class(), "Узел")
		_rename_lol(c)


func _own_lol(n: Node, big_boss: Node):
	for c in n.get_children():
		c.owner = big_boss
		_own_lol(c, big_boss)


func _count_lol(n: Node) -> int:
	var k = 1
	for c in n.get_children():
		k += _count_lol(c)
	return k
