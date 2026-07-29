extends TextEdit

@export var notification_label: RichTextLabel

@export var full_save: SaveGame

var known_commands: Dictionary[String, Callable] = {
	"hello": say_hello,
	"add coins": add_money,
	"add balls": add_balls,
	"load full save": load_full_save,
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

func get_first_number_chain(text: String) -> String:
	var regex := RegEx.new()
	regex.compile("\\d+")
	
	var result := regex.search(text)
	if result:
		return result.get_string()
		
	return "" 


func push_notification(content: String):
	if notification_label:
		notification_label.text = content
		await get_tree().create_timer(5.0).timeout
		notification_label.text = ""

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
		push_notification("Loaded complete save game with all Unlocks")
