extends Node

# --- Scenes ---
@export var scene_lowerpipe = preload("res://pipe_lower.tscn")
@export var scene_upperpipe = preload("res://pipe_upper.tscn")

# --- Nodes ---
@onready var bird = $Player
@onready var pipe_spawner = $PipeSpawner
@onready var parallax_background = $ParallaxBackground
@onready var score_label = $UI/ScoreLabel
@onready var message_label = $UI/MessageLabel
@onready var audio_player = $AudioStreamPlayer2D

# --- Game Variables ---
var scroll_speed = 150.0
var score = 0
var site_data = [["Year", "start", "end", "frost_free"], ["1958", "136", "277", "142"], ["1959", "139", "258", "120"], ["1960", "112", "275", "164"], ["1961", "152", "277", "126"], ["1962", "130", "262", "133"], ["1963", "145", "256", "112"], ["1964", "143", "274", "132"], ["1965", "135", "269", "135"], ["1966", "132", "284", "153"], ["1967", "135", "278", "144"], ["1968", "130", "279", "150"], ["1969", "148", "287", "140"], ["1970", "128", "288", "161"], ["1971", "109", "310", "202"], ["1972", "120", "286", "167"], ["1973", "106", "291", "186"], ["1974", "123", "266", "144"], ["1975", "121", "275", "155"], ["1976", "142", "272", "131"], ["1977", "130", "280", "151"], ["1978", "125", "287", "163"], ["1979", "127", "262", "136"], ["1980", "114", "271", "158"], ["1981", "139", "272", "134"], ["1982", "121", "282", "162"], ["1983", "139", "282", "144"], ["1984", "139", "259", "121"], ["1985", "130", "284", "155"], ["1986", "125", "278", "154"], ["1987", "137", "284", "148"], ["1988", "115", "287", "173"], ["1989", "120", "282", "163"], ["1990", "110", "291", "182"], ["1991", "111", "271", "161"], ["1992", "147", "267", "121"], ["1993", "119", "272", "154"], ["1994", "135", "284", "150"], ["1995", "129", "266", "138"], ["1996", "136", "276", "141"], ["1997", "128", "290", "163"], ["1998", "119", "278", "160"], ["1999", "116", "278", "163"], ["2000", "123", "271", "149"], ["2001", "120", "280", "161"], ["2002", "141", "281", "141"], ["2003", "138", "275", "138"], ["2004", "130", "278", "149"], ["2005", "134", "292", "159"], ["2006", "120", "286", "167"], ["2007", "127", "301", "175"], ["2008", "124", "291", "168"], ["2009", "107", "284", "178"], ["2010", "132", "289", "158"], ["2011", "127", "278", "152"], ["2012", "122", "286", "165"], ["2013", "114", "258", "145"], ["2014", "115", "305", "191"], ["2015", "116", "289", "174"], ["2016", "138", "288", "151"], ["2017", "130", "289", "160"], ["2018", "114", "290", "177"], ["2019", "120", "276", "157"], ["2020", "135", "282", "148"], ["2021", "117", "305", "189"], ["2022", "121", "292", "172"], ["2023", "139", "303", "165"], ["2024", "118", "300", "183"]]


# A simple state machine to manage the game's flow.
enum GameState { READY, PLAYING, WIN, GAME_OVER }
var current_state

func load_csv(path: String) -> Array:
	var result: Array = []
	var file := FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		push_error("Failed to open file: %s" % path)
		return result
	
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue  # Skip empty lines
		var columns := line.split(",", false)  # false = keep empty string
		result.append(columns)

	file.close()
	return result

func _ready():
	# When the game starts, set the state to READY.
	#site_data = load_csv('res://data/data_to_use.csv')
	set_state(GameState.READY)
	audio_player.play()

func _process(delta):
	# The parallax background is moved by updating its scroll_offset.
	# This is only done when the game is actively playing.
	if current_state == GameState.PLAYING:
		parallax_background.scroll_offset.x -= scroll_speed * delta

func _unhandled_input(event):
	# This function handles player input based on the current game state.
	if event.is_action_pressed("flap"):
		if current_state == GameState.READY:
			set_state(GameState.PLAYING)
		elif current_state == GameState.GAME_OVER:
			# Reload the entire scene to restart the game.
			get_tree().reload_current_scene()

func set_state(new_state):
	current_state = new_state
	match current_state:
		GameState.READY:
			# Prepare for a new game.
			message_label.text = "Flap to Start"
			message_label.show()     
			pipe_spawner.stop()
			score = 1
			score_label.text = str(site_data[score][0])
			bird.position = Vector2(120, 360)
			bird.set_physics_process(false) # Keep bird from falling
			
		GameState.PLAYING:
			# Start the game.
			message_label.hide()
			pipe_spawner.start()
			bird.set_physics_process(true) # Bird can now move
			
		GameState.GAME_OVER:
			# End the game.
			message_label.text = "Game Over\nFlap to Retry"
			message_label.show()
			pipe_spawner.stop()
			bird.stop()
			
		GameState.WIN:
			# Play Win sequence
			message_label.text = "You Survived\nto Adulthood!"
			message_label.show()
			pipe_spawner.stop()
			bird.end()

func _on_pipe_spawner_timeout():
	# This function is called every time the PipeSpawner timer finishes.
	var pipe_lower = scene_lowerpipe.instantiate()
	var pipe_upper = scene_upperpipe.instantiate()
	
	# Set vertical position based on the data from HBF.
	pipe_lower.position = Vector2(550, 2*int(site_data[score][2]))
	pipe_lower.scroll_speed = scroll_speed
	
	pipe_upper.position = Vector2(550, 2*int(site_data[score][1]))
	pipe_upper.scroll_speed = scroll_speed
	
	# Connect to the pipe's custom signals.
	pipe_lower.hit.connect(_on_pipe_hit)
	pipe_lower.scored.connect(_on_pipe_scored)
	
	pipe_upper.hit.connect(_on_pipe_hit)
	pipe_upper.scored.connect(_on_pipe_scored)
	
	add_child(pipe_lower)
	add_child(pipe_upper)

func _on_pipe_hit():
	# If a pipe's "hit" signal is received, end the game.
	# Disable movement input
	bird.velocity.x = 0
	# Let gravity pull the player down
	bird.velocity.y += 1200
	await get_tree().create_timer(1.0).timeout
	set_state(GameState.GAME_OVER)

func _on_pipe_scored():
	# If a pipe's "scored" signal is received, update the score.
	score += 1
	score_label.text = str(site_data[score][0])
	bird.increase_size()
	
	if score == 67:
		set_state(GameState.WIN) #Set win state - end game

	# Difficulty Scaling: Every 5 points, increase the speed.
	if score % 5 == 0:
		scroll_speed += 10.0

func _on_bird_hit():
	# This is connected to the bird's "hit" signal.
	# Disable movement input
	bird.velocity.x = 0
	# Let gravity pull the player down
	bird.velocity.y += 1200
	await get_tree().create_timer(2.0).timeout
	# If the bird hits anything (like the ground), end the game.
	set_state(GameState.GAME_OVER)
