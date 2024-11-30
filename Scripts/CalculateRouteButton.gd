extends Button

# Cargar el script con la clase Graph
const AStarScript = preload("res://Scripts/astar.gd")

# Variables
var graph_instance = null  # Instancia de Graph
var graph = null
#@onready var start_station = $"../CalculateRouteButton/StartStation"  # Es un OptionButton
#@onready var end_station = $"../CalculateRouteButton/EndStation"     # Es un OptionButton

@onready var pressBut = $"."
@onready var start = $"../Start"
@onready var end = $"../End"
@onready var transCheck: CheckBox = $"../CheckBox"
@onready var errorMsg : Label = $"../Error"
var shortest_path: Array = []

func _ready() -> void:
	# Crear una instancia de Graph
	graph_instance = AStarScript.new()
	add_child(graph_instance)
	graph = graph_instance.load_graph_from_file("res://Scripts/data.txt")
	#_populate_stations()
	
	pressBut.pressed.connect(_on_pressed.bind())

#func _populate_stations() -> void:
	# Limpiar las opciones previas
	# print("Botón clicado. Ejecutando la lógica para cargar las estaciones...")
	#start_station.clear()
	#end_station.clear()
	
	# Añadir las estaciones disponibles
	#for station in graph.nodes.keys():
		#start_station.add_item(station)
		#end_station.add_item(station)

func _on_pressed() -> void:
	
	for child in $"Dibujo".get_children():
		child.queue_free()
	
	
	
	print("Pressed")
	
	#var start = start_station.text
	#var end = end_station.text
	
	var start = start.text
	var end = end.text
	transCheck = $"../CheckBox"
	var evitar_trans = transCheck.button_pressed
	
	
	
	
	if(start == "Selecciona estación de origen" or end == "Selecciona estación de destino"):
		print("Selecciona estaciones válidas.")
		errorMsg.visible = true
		return
		
	for child in $"Dibujo".get_children():
		child.queue_free()
	
	
	if start == "Callao D":
		start = "Callao1"
	elif start == "Callao B":
		start = "Callao2"
	elif start == "Independencia C":
		start = "Independencia1"
	elif start == "Independencia E":
		start = "Independencia2"
	
	if end == "Callao D":
		end = "Callao1"
	elif end == "Callao B":
		end = "Callao2"
	elif end == "Independencia C":
		end = "Independencia1"
	elif end == "Independencia E":
		end = "Independencia2"
	
	#for s in graph.nodes:
	#	for e in graph.nodes:
	#		var pathcalc = graph_instance.Algor.new(graph, s, e)
	#		add_child(pathcalc)
	#		var currnodename
	#		var ret =  await pathcalc.a_star()
	
	if start == "" or end == "":
		return
	errorMsg.visible = false

	pressBut.disabled = true
	# Calcular la ruta usando la instancia de Graph
	var pathcalc = graph_instance.Algor.new(graph, start, end)
	pathcalc.evitartrans = evitar_trans
	add_child(pathcalc)
	var currnodename
	shortest_path =  await pathcalc.a_star()
	
	# ver transbordos
	for e in shortest_path:
		print(graph.transbordos[e])
	
	var travel_len: float = 1500
	
		
	var x = 400
	var y = 1500
	var posarray
	
	print(calcularTiempo(shortest_path))
	
	if shortest_path.size() > 1:
		travel_len = 3000/(shortest_path.size()-1)
	else:
		x += 1500
	
	var hey: Sprite2D = $"../../Metro/Nodos/A/A_ALBERTI"
	
	var dup = hey.duplicate(true)
	
	dup.position = Vector2(x,y)
	dup.modulate = Color8(0,0,0,255)
	var dup2 = dup.duplicate(true)
	dup2.scale = Vector2(1.1,1.1)
	dup.scale = Vector2(1,1)
	dup.modulate = Color8(255,255,255,255)
	dup.z_index = 8
	
	var label = Label.new()
	label.text = shortest_path[0]
	label.position = Vector2(x,y-150)
	label.modulate = Color.BLACK
	label.set("theme_override_font_sizes/font_size", 65)
	label.z_index = 19
	label.rotation_degrees = -70.0
	
	
	$"Dibujo".add_child(dup)
	$"Dibujo".add_child(dup2)
	$"Dibujo".add_child(label)
	
	
	
	
	
	
	
	for i: int in range(shortest_path.size() - 1):
		var istrans: bool = false
		var painted: bool = false
		for element in graph.transbordos[shortest_path[i]]:
			if element[0] == shortest_path[i+1]:
				# es un transbordo
				istrans = true
		var line: Line2D = Line2D.new()
		$"Dibujo".add_child(line)
		posarray = [Vector2(x,y)]
		x = x + travel_len
		posarray.append(Vector2(x,y))
		line.points = posarray
		line.default_color = getColor(graph.lineas[shortest_path[i+1]])
		line.width = 40
		if(istrans):
			line.default_color = Color8(125,125,125,255)
		
		
		dup = hey.duplicate(true)
		
		dup.position = Vector2(x,y)
		dup.modulate = Color8(0,0,0,255)
		dup2 = dup.duplicate(true)
		dup2.scale = Vector2(1.1,1.1)
		dup.scale = Vector2(1,1)
		dup.modulate = Color8(255,255,255,255)
		dup.z_index = 8
		label = Label.new()
		label.text = shortest_path[i+1]
		label.position = Vector2(x,y-150)
		label.modulate = Color.BLACK
		label.set("theme_override_font_sizes/font_size", 65)
		label.z_index = 19
		label.rotation_degrees = -70.0
		
		
		$"Dibujo".add_child(dup)
		$"Dibujo".add_child(dup2)
		$"Dibujo".add_child(label)
		
		
		
		
		
	
	

	if shortest_path:
		print("Ruta más corta:", shortest_path)
	else:
		print("No se pudo encontrar una ruta entre las estaciones seleccionadas.")
	
	
	pressBut.disabled = false

func calcularTiempo(path) -> int:
	var time: int = 0
	for i in range(path.size()):
		var nei = graph.get_neighbors(path[i])
		if(i < path.size()-1):
			# buscar siguiente nodo en vecinos y sacar tiempo
			for elem in nei:
				if elem[0] == path[i+1]:
					time += elem[1]
	return time/60/5.4

func getColor(line: String) -> Color:
	if line == "A":
		return Color8(0,175,220,255)
	elif line == "B":
		return Color8(240,25,40,255)
	elif line == "C":
		return Color8(0,100,180,255)
	elif line == "D":
		return Color8(0,130,100,255)
	elif line == "E":
		return Color8(100,30,130,255)
	else:
		print("ADJSG")
		return Color8(125,125,125,255)
	
