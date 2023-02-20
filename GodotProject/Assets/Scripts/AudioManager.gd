extends Node

# Expose to the editor an array of AudioStream to place the game audios
export(Array, AudioStream) var m_AudioDB: Array

# Keys to all the audios
enum { ACTION_MISC_2, COLLECT_4, FLYING, LONG_SLIDE_DOWN, YOU_BEAST }


# Start playing the given sound without spacial positioning
func makeSound(audioKey):
	# Create the AudioStreamPlayer
	var audioSP = AudioStreamPlayer.new()

	# Add it to the scene
	add_child(audioSP)

	# Assign the given audio to the stream
	audioSP.set_stream(m_AudioDB[audioKey])

	# Connect the audio's finished signal to the Manager's onEnd method
	audioSP.connect("finished", self, "onEnd")

	# Play the audio
	audioSP.play()


# Start playing the given sound with a given spacial position
func makeSoundAtPlace(audioKey, position):
	# Create the AudioStreamPlayer
	var audioSP = AudioStreamPlayer3D.new()

	# Set the audio's position
	audioSP.transform.position = position
	
	# Add it to the scene
	add_child(audioSP)

	# Assign the given audio to the stream
	audioSP.set_stream(m_AudioDB[audioKey])

	# Connect the audio's finished signal to the Manager's onEnd method
	audioSP.connect("finished", self, "onEnd")

	# Play the audio
	audioSP.play()


# Called when a given audio ends
func onEnd():
	# Get every currently created audio
	var children = get_children()

	# Loop through the audios
	for child in children:

		# Check if the audio isn't playing
		if not child.is_playing():

			# Remove the audio and innerhit all of its children
			child.remove_and_skip()

			# Destroy the audio node
			child.queue_free()
