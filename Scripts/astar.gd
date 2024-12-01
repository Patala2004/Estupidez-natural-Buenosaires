extends Node


@onready var StartDropdown = $"../../Start"
@onready var EndDropdown = $"../../End"



var data_string = """
Nodes
# Linea azul claro (A)
Linea A
Alberti,-34.6098889,-58.4022383
Pasco,-34.6098006,-58.4000067
Congreso,-34.6093782,-58.3941471
Saenz Peña,-34.6096207,-58.3898709
Lima,-34.6094405,-58.3851738
Piedras,-34.6091704,-58.3808303
Perú,-34.6089209,-58.3776653
Plaza de Mayo,-34.6088032,-58.3747191

# Linea roja (B)
Linea B
Pasteur,-34.6046449,-58.4002802
Callao2,-34.6045416,-58.3936271
Uruguay,-34.60396,-58.3881074
Carlos Pellegrini,-34.6031203,-58.3824338
Florida,-34.6033139,-58.3755052
Leandro N. Alem,-34.6029489,-58.3707529

# Linea azul oscuro (C)
Linea C
Retiro,-34.5928119,-58.3765932
San Martín,-34.5947557,-58.3785689
Lavalle,-34.6020931,-58.3788688
Diagonal Norte,-34.6047992,-58.3809299
Avenida de Mayo,-34.6084535,-58.38168
Moreno,-34.611637,-58.3816721
Independencia1,-34.6177357,-58.3814756
San Juan,-34.6214342,-58.3812285
Constitución,-34.6270691,-58.3821521

# Linea verde (D)
Linea D
Facultad de medicina,-34.5996257,-58.3951539
Callao1,-34.5995227,-58.3939018
Tribunales,-34.6002554,-58.3886161
9 de Julio,-34.6044156,-58.3801764
Catedral,-34.6075557,-58.3743275

# Linea morada (E)
Linea E
Pichincha,-34.6231991,-58.3973942
Entre Ríos,-34.6227073,-58.3930417
San José,-34.6221889,-58.3858086
Independencia2,-34.6178598,-58.3818726
Belgrano,-34.6127849,-58.3782079
Bolívar,-34.608878,-58.3753088

Edges
#Linea azul claro (A)
Alberti,Pasco,280
Pasco,Congreso,500
Congreso,Saenz Peña,550
Saenz Peña,Lima,350
Lima,Piedras,500
Piedras,Perú,350
Perú,Plaza de Mayo,350

#Linea roja (B)
Pasteur,Callao2,600
Callao2,Uruguay,450
Uruguay,Carlos Pellegrini,450
Carlos Pellegrini,Florida,550
Florida,Leandro N. Alem,350

#Linea azul oscuro (C)
Retiro,San Martín,450
San Martín,Lavalle,750
Lavalle,Diagonal Norte,350
Diagonal Norte,Avenida de Mayo,500
Avenida de Mayo,Moreno,350
Moreno,Independencia1,550
Independencia1,San Juan,500
San Juan,Constitución,500

#Linea verde (D)
Facultad de medicina,Callao1,400
Callao1,Tribunales,1000
Tribunales,9 de Julio,350
9 de Julio,Catedral,500

#Linea morada (E)
Pichincha,Entre Ríos,500
Entre Ríos,San José,600
San José,Independencia2,750
Independencia2,Belgrano,900
Belgrano,Bolívar,350

#Transbordos
Transbordos
#A -> C
Avenida de Mayo,Lima,260
#A -> D
Perú,Catedral,110
#A -> E
Perú,Bolívar,160
#D -> E
Catedral,Bolívar,270
#E -> C
Independencia2,Independencia1,180
#B -> D
Carlos Pellegrini,9 de Julio,50
#D -> C
9 de Julio,Diagonal Norte,50
#B -> C
Carlos Pellegrini,Diagonal Norte,100
"""




class Graph:
	var nodes : Dictionary = {}
	var edges : Dictionary = {}
	var transbordos : Dictionary = {}
	var lineas : Dictionary = {}
	func __init():
		nodes= {}                 #dictionary
		edges = {}

	func add_node(name: String, x: float, y: float) -> void:
		self.nodes[name] = [0, x, y] # (Heuristic, latitude, longitude)
		self.edges[name] = []
		self.transbordos[name] = []

	func add_edge(name_from: String, name_to: String, cost: float) -> void:
		self.edges[name_from].append([name_to,cost])
		self.edges[name_to].append([name_from,cost])
	
	func add_trans(name_from: String, name_to: String, cost: float) -> void:
		self.transbordos[name_from].append([name_to,cost])
		self.transbordos[name_to].append([name_from,cost])

	func get_neighbors(node):
		return self.edges.get(node, [])   #returns the list of neighbors . if finds none return empty list

	func heuristic(nodea, nodeb) -> float:
		# Distance between 2 nodes (Not as easy as just 2 x and y positions, as GPS coordinates are given in angles)
		# Formula stolen from https://stackoverflow.com/questions/639695/how-to-convert-latitude-or-longitude-to-meters#11172685
		var earth_radius_km: float = 6378.137
		var longitude_index: int = 2
		var latitude_index: int = 1
		
		
		var lata = deg_to_rad(nodea[latitude_index])
		var latb = deg_to_rad(nodea[latitude_index])
		
		var longa = deg_to_rad(nodea[longitude_index])
		var longb = deg_to_rad(nodeb[longitude_index])
		
		var distance_latitude: float = latb - lata
		var distance_longitude: float = longb - longa
		var a: float = sin(distance_latitude/2) * sin(distance_latitude/2) * cos(lata) \
			* cos(latb * (PI/180)) * sin(distance_longitude/2) * sin(distance_longitude/2)
		var c = 2 * atan2(sqrt(a), sqrt(1-a))
		var distancekm = earth_radius_km * c
		return distancekm * 100000 # Meters
	
	func get_node_by_name(name: String):
		return self.nodes[name]
		
	func get_name_by_node(x : float, y : float):
		for name in nodes:
			if int(nodes[name][1]*10000) == int(x*10000) and ( int(nodes[name][2]*10000) == int(y*10000) ):
				return name
		return null

func load_graph_from_file(file_path: String):
	var graph = Graph.new()

	var mode = null
	var curr_linea = "NONE"
	var data_lines = data_string.split('\n')
	for line in data_lines:
		line = line.strip_edges()                
		if not line:
			continue
		if line.begins_with('#'):
			continue
		if line.begins_with("Nodes"):
			mode = 'Nodes'
			continue
		elif line.begins_with("Edges"):
			mode = 'Edges'
			continue
		elif line.begins_with("Transbordos"):
			mode = 'Transbordos'
			curr_linea = "TRANSBORDO"
			continue
		elif line.begins_with("Linea"):
			curr_linea = line.split(" ")[1]
			continue
		
		if mode == 'Nodes':
			var split = line.split(',')
			var node = split[0]
			var lat = split[1]
			var long = split[2]
			
			
			graph.add_node(node, float(lat), float(long))
			graph.lineas[node] = curr_linea

			if node == "Callao1":
				node = "Callao D"
			elif node == "Callao2":
				node = "Callao B"
			elif node == "Independencia1":
				node = "Independencia C"
			elif node == "Independencia2":
				node = "Independencia E"
			StartDropdown.add_item(node)
			EndDropdown.add_item(node)
			
			
			#node, lat, long= line.split(',')      #removes the ',' from the line and therefore treats the symbol before the 
													# ',' seperate from the symbol after
			
		elif mode == 'Edges'  or mode == 'Transbordos':
			var split = line.split(',')
			var name_from = split[0]
			var name_to = split[1] 
			var cost = split[2]
			
			if(mode == 'Transbordos'):
				graph.add_edge(name_from, name_to, float(cost))
				graph.add_trans(name_from, name_to, float(cost))
			else:
				graph.add_edge(name_from, name_to, float(cost))
	return graph

class Algor extends Node:
	
	var open_list
	var closed_list
	var g_cost
	var parents
	var mandarina
	var graph
	var start
	var goal
	var anterior = ""
	var finished = false
	var evitartrans: bool = false
	
	@onready var parent_node: Node = $"../../../Metro/Nodos"
	@onready var parent_edge: Node = $"../../../Metro/Aristas"
	
	func _init(graph_in: Graph,start_in: String,goal_in: String):
		
		start = start_in
		goal = goal_in
		graph = graph_in

		#Open List as priority queue
		#open_list = []
		#heapq.heappush(open_list,(0,start))      #(cost, node)
		
		open_list = PriorityQueue.new()
		open_list.insert( Vector2(graph.get_node_by_name(start)[1],graph.get_node_by_name(start)[2]), INF)
		#tracking
		g_cost = {start: 0}  #dictionary with key and value pair
		parents = {start: null}

		#closed List (visited nodes)
		closed_list = {}
		
		# Color start and endnode
		print(parent_node)
		

		
		
		mandarina = null
		
		

	func a_star():
		
		#Add the heuristic to every node in graph 
		
		
		
		cleanEdges()
		cleanNodes()
		
		
		for n: Sprite2D in findNode(parent_node,start):
			n.modulate = Color8(123,14,19,255)
			
		for n: Sprite2D in findNode(parent_node, goal):
			n.modulate = Color8(255,0,255,255)
			
			
		while not open_list.empty():
			
			#current_cost, current_node = heapq.heappop(open_list)   #gets us the node with the smallest cost
			var top = open_list.extract()
			var current_node2 = top[0]
			var current_node = top[1]
			
			var node_name = graph.get_name_by_node(top[0], top[1])
			mandarina = node_name
			#print(current_node,current_cost)
			#if we reached goal then reconstruct the path
			if node_name == goal:
				var path = []
				while node_name:
					path.append(node_name)
					node_name = parents[node_name]
				#return path[::-1] #return reversed path 
				path.reverse()
				cleanEdges()
				for i in range(path.size()-1):
					var edge = findEdge(parent_edge, path[i], path[i+1])
					edge.default_color = Color8(255,255,0,255)
					edge.z_index = 2
					
					
				finished = true
				return path
				
				#(-34.61164, -58.38167)
		
			closed_list[node_name] = true

			#main part
			var thisNode:Node = findNode(parent_node,node_name)[0]
			for nh in graph.get_neighbors(node_name):
				var neighbor = nh[0]
				var cost = nh[1]
				if(evitartrans):
					for element in graph.transbordos[node_name]:
							if element[0] == neighbor:
								# es un transbordo
								cost += 100000000
								break
				
				if neighbor in closed_list:
					continue
				
				var way_cost = g_cost[node_name] + cost   #cost for the edges to this node, doesnt include heuristic yet
				

				if way_cost < g_cost.get(neighbor,INF):   #if node isnt in g_cost then its not reachable at this moment
					g_cost[neighbor] = way_cost
					
					var istrans = false
					for element in graph.transbordos[node_name]:
						if element[0] == neighbor:
							# es un transbordo
							istrans = true
					
					var h = graph.heuristic(graph.get_node_by_name(neighbor), graph.get_node_by_name(goal)) * graph.heuristic(graph.get_node_by_name(neighbor), graph.get_node_by_name(goal))
					var f_cost = way_cost + h
					#heapq.heappush(open_list, (f_cost,neighbor))
					var nei = Vector2(graph.get_node_by_name(neighbor)[1], graph.get_node_by_name(neighbor)[2])

					open_list.insert(nei, f_cost)
					parents[neighbor] = node_name
					var neigNode: Node = findNode(parent_node,neighbor)[0]
					var connectingEdge: Line2D = findEdge(parent_edge, node_name, neighbor)
					connectingEdge.default_color = Color8(170,170,170,255)
				
					await get_tree().create_timer(0.05).timeout
		return ""
		return null  #if node isnt reachable at all
	
	
	func findNode(parent : Node, substring : String) -> Array:
		var matching_nodes = []
		var s = substring.to_lower().replace(".","")
		
		for child in parent.get_children():
			if s in child.name.to_lower():
				matching_nodes.append(child)
			matching_nodes += findNode(child, substring)
		return matching_nodes
	
	func findEdge(parent : Node, substring1 : String, substring2 : String) -> Line2D:
		var matching_nodes
		var s1 = substring1.to_lower().replace(".","")
		var s2 = substring2.to_lower().replace(".","")
		
		for child in parent.get_children():
			var caux = child.name.split("-")
			var c1 = caux[0].to_lower()
			var c2 = caux[1].to_lower()
			if (s1 in c1 and s2 in c2) or (s1 in c2 and s2 in c1):
				matching_nodes = child
		return matching_nodes
	
	func cleanEdges():
		for child: Line2D in parent_edge.get_children():
			child.default_color = Color8(255,255,255,0)
			child.z_index = 0
		
	func cleanNodes():
		for child2 in parent_node.get_children():
			for child in child2.get_children():
				child.modulate = Color8(255,255,255,255)
	
	func wait(seconds: float) -> void:
		await get_tree().create_timer(seconds).timeout
			

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

