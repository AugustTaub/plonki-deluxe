extends TextEdit

@export var console_feed: TextEdit

@export var full_save: SaveGame

var known_commands: Dictionary[String, Callable] = {
	"hello": say_hello,
	"add coins": add_money,
	"add balls": add_balls,
	"load full save": load_full_save,
	"reset progress": reset_progress,
	"list commands": list_commands,
}

var commands_with_variables: Array[String] = ["add coins","add balls"]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("send_console_command") and has_focus():
		try_command(text.strip_edges())
		clear()

func try_command(content: String):
	for key: String in known_commands.keys():
		if content.contains(key):
			if commands_with_variables.has(key):
				var nr_chain: String = get_first_number_chain(content)
				if nr_chain != "":
					var nr_chain_i: int = int(nr_chain)
					known_commands[key].call(nr_chain_i)
				
			else:
				known_commands[key].call()
			
			return

func get_first_number_chain(gtext: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\d+")
	
	var result := regex.search(gtext)
	if result:
		return result.get_string()
		
	return "" 


func push_notification(content: String):
	if console_feed:
		console_feed.text = content
		await get_tree().create_timer(60.0).timeout
		console_feed.text = ""

func say_hello():
	push_notification("Hello!")

func add_money(amount: int):
	SaveManager.change_money_with_vis_nr(amount, get_global_mouse_position())
	push_notification("Added " + str(amount)  + " coins")

func add_balls(amount: int):
	SaveManager.set_ball_amount(amount)
	push_notification("Added " + str(amount)  + " balls")

func load_full_save():
	if full_save:
		SaveManager.load_save_game(full_save)
		SignalBus.enable_piercing_button.emit()
		push_notification("Loaded complete save game with all Unlocks")

func reset_progress():
	SaveManager.reset_save_game()
	push_notification("Progress was reset. Savegame overwritten")

func list_commands():
	var string: String = ""
	for key in known_commands.keys():
		string += "\n" + key
	
	push_notification(string)
