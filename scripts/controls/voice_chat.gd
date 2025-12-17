#extends Node
#
## Audio settings
#const SAMPLE_RATE = 16000
#const MIX_RATE = 44100
#const BUFFER_SIZE = 1024
#
## Voice activation detection (VAD)
#const VOICE_THRESHOLD = 0.1
#const SILENCE_FRAMES = 1
#
#var voice_player: AudioStreamPlayer
#var mic_player: AudioStreamPlayer
#
#var voice_enabled = false
#var push_to_talk = false
#
## Microphone capture
#var audio_effect_record: AudioEffectRecord
#var audio_effect_capture: AudioEffectCapture
#var playback: AudioStreamGeneratorPlayback
#var audio_stream_generator: AudioStreamGenerator
#
## Voice activity detection
#var silence_counter = 0
#var is_speaking = false
#
## Voice management
#var muted_players: Array[int] = []  # List of muted player IDs
#var speaking_players: Dictionary = {}  # player_id: bool (is speaking)
#var player_volumes: Dictionary = {}  # player_id: float (volume multiplier)
#
#signal player_speaking_changed(player_id: int, is_speaking: bool)
#signal player_muted_changed(player_id: int, is_muted: bool)
#
#func _ready():
	## Create AudioStreamPlayer for playback
	#voice_player = AudioStreamPlayer.new()
	#add_child(voice_player)
	#
	## Debug info
	#print("=== VOICE CHAT SYSTEM ===")
	#var devices = AudioServer.get_input_device_list()
	#print("Available input devices:")
	#for i in range(devices.size()):
		#print("  [", i, "] ", devices[i])
	#
	## Setup but DON'T start yet
	#setup_voice_playback()
	#
	#print("Voice chat ready (disabled by default)")
	#print("Call VoiceChat.enable_voice() to start")
#
#func setup_microphone():
	#print("\n🎤 Starting microphone capture...")
	#
	## Get or create Record bus
	#var record_bus_idx = AudioServer.get_bus_index("Record")
	#if record_bus_idx == -1:
		#AudioServer.add_bus(1)
		#record_bus_idx = 1
		#AudioServer.set_bus_name(record_bus_idx, "Record")
	#
	## Set input device
	#var input_devices = AudioServer.get_input_device_list()
	#if input_devices.size() == 0:
		#print("❌ ERROR: No input devices found!")
		#return false
	#
	#var selected_device = input_devices[0]
	#for device in input_devices:
		#if "analog" in device.to_lower() or "input" in device.to_lower():
			#selected_device = device
			#break
	#
	#print("Using device: ", selected_device)
	#AudioServer.input_device = selected_device
	#
	## Add AudioEffectRecord
	#audio_effect_record = AudioEffectRecord.new()
	#audio_effect_record.format = AudioStreamWAV.FORMAT_16_BITS
	#AudioServer.add_bus_effect(record_bus_idx, audio_effect_record, 0)
	#
	## Add AudioEffectCapture
	#audio_effect_capture = AudioEffectCapture.new()
	#audio_effect_capture.buffer_length = 0.5
	#AudioServer.add_bus_effect(record_bus_idx, audio_effect_capture, 1)
	#
	## Unmute and boost
	#AudioServer.set_bus_mute(record_bus_idx, false)
	#AudioServer.set_bus_volume_db(record_bus_idx, 24.0)
	#
	## Create microphone player
	#mic_player = AudioStreamPlayer.new()
	#mic_player.name = "MicrophoneInput"
	#mic_player.bus = "Record"
	#add_child(mic_player)
	#
	#var mic_stream = AudioStreamMicrophone.new()
	#mic_player.stream = mic_stream
	#mic_player.play()
	#
	## Start recording
	#audio_effect_record.set_recording_active(true)
	#
	#print("✅ Microphone started")
	#return true
#
#func stop_microphone():
	#print("🔇 Stopping microphone...")
	#
	#if audio_effect_record != null:
		#audio_effect_record.set_recording_active(false)
	#
	#if mic_player != null:
		#mic_player.stop()
		#mic_player.queue_free()
		#mic_player = null
	#
	## Clear effects from bus
	#var record_bus_idx = AudioServer.get_bus_index("Record")
	#if record_bus_idx != -1:
		#AudioServer.set_bus_mute(record_bus_idx, true)
	#
	#audio_effect_capture = null
	#audio_effect_record = null
	#
	#print("✅ Microphone stopped")
#
#func setup_voice_playback():
	#audio_stream_generator = AudioStreamGenerator.new()
	#audio_stream_generator.mix_rate = SAMPLE_RATE
	#audio_stream_generator.buffer_length = 0.5
	#
	#voice_player.stream = audio_stream_generator
	#voice_player.play()
	#
	#playback = voice_player.get_stream_playback()
#
#func _process(_delta):
	## Always handle incoming audio, even if mic is off
	#if audio_effect_capture == null:
		#return
	#
	#if not voice_enabled:
		#return  # skip capturing mic but allow receive_voice_data() RPCs
	#
	#var available_frames = audio_effect_capture.get_frames_available()
	#
	#if available_frames >= BUFFER_SIZE:
		#var stereo_data = audio_effect_capture.get_buffer(BUFFER_SIZE)
		#
		#if stereo_data.size() == 0:
			#return
		#
		#var mono_data = convert_to_mono(stereo_data)
		#var volume = calculate_volume(mono_data)
		#
		## Voice Activity Detection
		#if volume > VOICE_THRESHOLD:
			#silence_counter = 0
			#if not is_speaking:
				#is_speaking = true
				#print("🎤 Started speaking")
				#notify_speaking_state(true)
			#
			## Send audio to other players
			#var compressed = compress_audio(mono_data)
			#rpc("receive_voice_data", multiplayer.get_unique_id(), compressed)
		#else:
			#silence_counter += 1
			#if silence_counter > SILENCE_FRAMES and is_speaking:
				#is_speaking = false
				#print("🔇 Stopped speaking")
				#notify_speaking_state(false)
#
#func notify_speaking_state(speaking: bool):
	#var my_id = multiplayer.get_unique_id()
	#speaking_players[my_id] = speaking
	#player_speaking_changed.emit(my_id, speaking)
	#
	## Notify other players
	#rpc("update_speaking_state", my_id, speaking)
#
#@rpc("any_peer", "reliable", "call_remote")
#func update_speaking_state(player_id: int, speaking: bool):
	#speaking_players[player_id] = speaking
	#player_speaking_changed.emit(player_id, speaking)
#
#func convert_to_mono(stereo_data: PackedVector2Array) -> PackedFloat32Array:
	#var mono_data = PackedFloat32Array()
	#mono_data.resize(stereo_data.size())
	#
	#for i in range(stereo_data.size()):
		#mono_data[i] = (stereo_data[i].x + stereo_data[i].y) / 2.0
	#
	#return mono_data
#
#func calculate_volume(audio_data: PackedFloat32Array) -> float:
	#var sum = 0.0
	#for sample in audio_data:
		#sum += abs(sample)
	#return sum / audio_data.size()
#
#func compress_audio(audio_data: PackedFloat32Array) -> PackedByteArray:
	#var compressed = PackedByteArray()
	#compressed.resize(audio_data.size() * 2)
	#
	#for i in range(audio_data.size()):
		#var sample = clamp(audio_data[i], -1.0, 1.0)
		#var int_sample = int(sample * 32767.0)
		#
		#compressed[i * 2] = int_sample & 0xFF
		#compressed[i * 2 + 1] = (int_sample >> 8) & 0xFF
	#
	#return compressed
#
#func decompress_audio(compressed: PackedByteArray) -> PackedFloat32Array:
	#var audio_data = PackedFloat32Array()
	#audio_data.resize(compressed.size() / 2)
	#
	#for i in range(audio_data.size()):
		#var int_sample = compressed[i * 2] | (compressed[i * 2 + 1] << 8)
		#
		#if int_sample > 32767:
			#int_sample -= 65536
		#
		#audio_data[i] = float(int_sample) / 32767.0
	#
	#return audio_data
#
#@rpc("any_peer", "unreliable", "call_remote")
#func receive_voice_data(sender_id: int, compressed_audio: PackedByteArray):
	## Skip if muted locally
	#if sender_id in muted_players:
		## print("Muted sender ", sender_id, " -> skipping audio")
		#return
	#
	#if playback == null:
		#return
	#
	#var audio_data = decompress_audio(compressed_audio)
	#var volume_multiplier = player_volumes.get(sender_id, 1.0)
	#
	#for sample in audio_data:
		#if playback.get_frames_available() > 0:
			#var adjusted_sample = sample * volume_multiplier
			#playback.push_frame(Vector2(adjusted_sample, adjusted_sample))
#
## ========== PUBLIC API ==========
#
#func enable_voice():
	#if voice_enabled:
		#return
	#
	#var success = setup_microphone()
	#if success:
		#voice_enabled = true
		#print("✅ Voice chat ENABLED")
		#if Chatbox:
			#Chatbox.add_message("System", "Voice chat enabled", Color.GREEN)
	#else:
		#print("❌ Failed to enable voice chat")
		#if Chatbox:
			#Chatbox.add_message("System", "Failed to enable microphone", Color.RED)
#
#func disable_voice():
	#if not voice_enabled:
		#return
	#
	#voice_enabled = false
	#is_speaking = false
	#stop_microphone()
	#
	#print("✅ Voice chat DISABLED")
	#if Chatbox:
		#Chatbox.add_message("System", "Voice chat disabled", Color.YELLOW)
	#
	## Notify you stopped speaking
	#notify_speaking_state(false)
#
#func toggle_voice():
	#if voice_enabled:
		#disable_voice()
	#else:
		#enable_voice()
#
#func mute_player(player_id: int):
	#if player_id not in muted_players:
		#muted_players.append(player_id)
		#print("🔇 Muted player ", player_id, " (local only)")
		#player_muted_changed.emit(player_id, true)
#
#func unmute_player(player_id: int):
	#if player_id in muted_players:
		#muted_players.erase(player_id)
		#print("🔊 Unmuted player ", player_id, " (local only)")
		#player_muted_changed.emit(player_id, false)
#
#
#func toggle_mute_player(player_id: int):
	#if player_id in muted_players:
		#unmute_player(player_id)
	#else:
		#mute_player(player_id)
#
#func is_player_muted(player_id: int) -> bool:
	#return player_id in muted_players
#
#func is_player_speaking(player_id: int) -> bool:
	#return speaking_players.get(player_id, false)
#
#func get_speaking_players() -> Array:
	#var result = []
	#for player_id in speaking_players:
		#if speaking_players[player_id]:
			#result.append(player_id)
	#return result
#
#func set_player_volume(player_id: int, volume: float):
	## volume: 0.0 to 2.0 (0% to 200%)
	#player_volumes[player_id] = clamp(volume, 0.0, 2.0)
	#print("Set player ", player_id, " volume to ", volume)
#
#func get_player_volume(player_id: int) -> float:
	#return player_volumes.get(player_id, 1.0)
#
#func is_voice_enabled() -> bool:
	#return voice_enabled
#
## Push-to-talk mode
#func set_push_to_talk(enabled: bool):
	#push_to_talk = enabled
	#if enabled:
		#disable_voice()
		#print("Push-to-talk mode enabled")
		#if Chatbox:
			#Chatbox.add_message("System", "Push-to-talk: Hold V to speak", Color.CYAN)
#
#func _input(event):
	#if not push_to_talk:
		#return
	#
	#if event.is_action_pressed("voice_talk"):
		#enable_voice()
	#elif event.is_action_released("voice_talk"):
		#disable_voice()
