extends TextEdit

@export var notification_label: RichTextLabel

var known_commands: Dictionary[String, Callable] = {
	"hello": say_hello,
	"add1000": add_money,
}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("send_console_command") and has_focus():
		try_command(text.strip_edges())
		clear()

func try_command(content: String):
	for key: String in known_commands.keys():
		if content.contains(key):
			known_commands[key].call()
			return

func push_notification(content: String):
	if notification_label:
		notification_label.text = content
		await get_tree().create_timer(5.0).timeout
		notification_label.text = ""

func say_hello():
	push_notification("Hello!")

func add_money():
	SaveManager.change_money_with_vis_nr(1000, get_global_mouse_position())
	push_notification("Added 1000 coins")
