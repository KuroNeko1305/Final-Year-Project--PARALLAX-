#extends Node
#
#const IP_ADDRESS = "localhost"
#const PORT = 42069
#
#var peer: ENetMultiplayerPeer
#var voip_streams := {}  # peer_id -> AudioStreamVOIP
#
#func _ready():
	## Wait for multiplayer setup before connecting signals
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	#multiplayer.connection_failed.connect(_on_connection_failed)
#
	## Optional: Try to attach VOIP effect automatically
	#_setup_voip_microphone()
#
#
## --- SERVER / CLIENT CREATION -------------------------------------------------
#
#func start_server():
	#peer = ENetMultiplayerPeer.new()
	#peer.create_server(PORT)
	#multiplayer.multiplayer_peer = peer
	#print("[Server] Started on port:", PORT)
	#_setup_voip_microphone()
	#return [IP_ADDRESS, PORT]
#
#
#func start_client(ip_address: String, port: int):
	#peer = ENetMultiplayerPeer.new()
	#peer.create_client(ip_address, port)
	#multiplayer.multiplayer_peer = peer
	#print("[Client] Connecting to:", ip_address, ":", port)
	#_setup_voip_microphone()
#
#
## --- VOIP MICROPHONE CAPTURE -------------------------------------------------
#
#func _setup_voip_microphone():
	## Find the "Mic" bus and attach packet_ready listener
	#var idx = AudioServer.get_bus_index("Record")
	#if idx == -1:
		#push_warning("VOIP: No 'Record' bus found! Please create one in Audio > Buses.")
		#return
#
	## Expecting an AudioEffectCapture-like effect from the one-voip extension
	#var effect = AudioServer.get_bus_effect(idx, 2)
	#if effect == null:
		#push_warning("VOIP: No microphone capture effect found on 'Record' bus!")
		#return
#
	#if not effect.packet_ready.is_connected(_on_packet_ready):
		#effect.packet_ready.connect(_on_packet_ready)
		#print("[VOIP] Microphone ready and connected to packet_ready signal.")
#
#
#func _on_packet_ready(packet: PackedByteArray) -> void:
	#print("[VOIP] Sending packet of size:", packet.size())
	#for id in multiplayer.get_peers():
		#if id != multiplayer.get_unique_id():
			#multiplayer.send_bytes(packet, id, 1)
#
#
#
## --- RECEIVE VOICE PACKETS ---------------------------------------------------
#
#func _process(_delta):
	## Process incoming VOIP packets from ENet
	#if peer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		#while peer.get_available_packet_count() > 0:
			#var packet: PackedByteArray = peer.get_packet()
			#var sender_id = peer.get_packet_peer()
			#_on_voip_packet_received(packet, sender_id)
#
#
#func _on_voip_packet_received(packet: PackedByteArray, sender_id: int):
	#if not voip_streams.has(sender_id):
		#_create_voip_stream_for_peer(sender_id)
	#voip_streams[sender_id].push_packet(packet)
#
#
## --- PEER MANAGEMENT ----------------------------------------------------------
#
#func _on_peer_connected(id: int):
	#print("[VOIP] Peer connected:", id)
	#_create_voip_stream_for_peer(id)
#
#
#func _on_peer_disconnected(id: int):
	#print("[VOIP] Peer disconnected:", id)
	#if voip_streams.has(id):
		#var stream = voip_streams[id]
		#if stream.get_parent():
			#stream.get_parent().queue_free()
		#voip_streams.erase(id)
#
#
#func _create_voip_stream_for_peer(id: int):
	## Create a player to play incoming audio from this peer
	#var player = AudioStreamPlayer.new()
	#var stream = AudioStreamVOIP.new()
	#player.stream = stream
	#player.autoplay = true
	#add_child(player)
	#voip_streams[id] = stream
	#print("[VOIP] Created AudioStreamVOIP for peer:", id)
#
#
## --- CONNECTION LOGGING -------------------------------------------------------
#
#func _on_connected_to_server():
	#print("[Network] Connected to server.")
#
#func _on_connection_failed():
	#print("[Network] Connection failed.")

extends Node 

const IP_ADDRESS = "localhost" 
const PORT = 42069 

var peer 

func _ready():
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func start_server():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	print('Server started')
	return [IP_ADDRESS, PORT]

func start_client(ip_address: String, port: int):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, port)
	multiplayer.multiplayer_peer = peer
	print('Client started')

func _on_peer_connected(id):
	print("Player connected: ", id)

func _on_peer_disconnected(id):
	print("Player disconnected: ", id)
