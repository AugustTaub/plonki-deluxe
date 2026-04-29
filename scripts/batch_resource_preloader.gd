@tool
extends ResourcePreloader

# Toggle this in the inspector to refresh the list
@export var refresh_folder: bool = false:
	set(value):
		_populate_from_folder()

@export_dir var folder_path: String = "res://custom_res/upgrades"

func _ready():
	SignalBus.upgrade_preloader_loaded.emit(self)


func _populate_from_folder() -> void:
	if folder_path == "":
		return
	
	for res_name in get_resource_list():
		remove_resource(res_name)
	
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if !dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
				var full_path = folder_path.path_join(file_name)
				var resource = load(full_path)
				
				if resource is UpgradeData:
					var key = file_name.get_basename()
					add_resource(key, resource)
					print("Preloaded: ", key)
			
			file_name = dir.get_next()
		dir.list_dir_end()
		print("Preload complete. Total: ", get_resource_list().size())
		notify_property_list_changed()
	else:
		printerr("Failed to open folder: ", folder_path)
