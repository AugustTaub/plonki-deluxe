@tool
extends Node

@export_dir var folder_path: String = ""

@export var run_importer: bool = false:
	set(value):
		if value:
			_populate_parent_array()

func _populate_parent_array() -> void:
	var parent = get_parent()
	
	if not parent:
		push_error("Importer: Parent node not found.")
		return

	if not "state_script_arr" in parent:
		push_error("Importer: Parent node does not have a 'state_script_arr' variable.")
		return

	if folder_path.is_empty() or not DirAccess.dir_exists_absolute(folder_path):
		push_error("Importer: Target directory path is invalid or empty.")
		return

	var found_scripts: Array[Script] = []
	var file_names = DirAccess.get_files_at(folder_path)

	for file_name in file_names:
		if file_name.ends_with(".gd"):
			var full_path = folder_path.path_join(file_name)
			var script_res = load(full_path) as Script
			
			if script_res:
				found_scripts.append(script_res)

	parent.state_script_arr = found_scripts
	
	if parent.has_method("notify_property_list_changed"):
		parent.notify_property_list_changed()
		
	print("Importer: Successfully added %d script(s) to parent state_script_arr." % found_scripts.size())
