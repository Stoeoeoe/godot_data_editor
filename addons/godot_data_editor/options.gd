tool
extends AcceptDialog

var config = null

onready var serializer_label = get_node("Panel/GridContainer/SerializerLabel")
onready var serializer_option = get_node("Panel/GridContainer/SerializerOption")
onready var extension_label = get_node("Panel/GridContainer/ExtensionLabel")
onready var extension_line_edit = get_node("Panel/GridContainer/ExtensionLineEdit")
onready var encrypt_label = get_node("Panel/GridContainer/EncryptLabel")
onready var encrypt_check_box = get_node("Panel/GridContainer/EncryptCheckBox")
onready var password_label = get_node("Panel/GridContainer/PasswordLabel")
onready var password_line_edit = get_node("Panel/GridContainer/PasswordLineEdit")
onready var output_directory_label = get_node("Panel/GridContainer/OutputDirectoryLabel")
onready var output_directory_line_edit = get_node("Panel/GridContainer/OutputDirectoryHBox/OutputDirectoryLineEdit")
onready var class_directory_label = get_node("Panel/GridContainer/OutputDirectoryLabel")
onready var class_directory_line_edit = get_node("Panel/GridContainer/ClassDirectoryHBox/ClassDirectoryLineEdit")
onready var sanitize_ids_label = get_node("Panel/GridContainer/SanitizeIdsLabel")
onready var sanitize_ids_check_box = get_node("Panel/GridContainer/SanitizeIdsCheckBox")

onready var warn_dialog = get_node("WarnDialog")

var extension = ""
var serializer = ""
var encrypt = false
var password = ""
var class_directory = ""
var output_directory = ""
var sanitize_ids = true

signal extension_changed(new_extension, serializer)
signal encryption_changed(is_encrypted, password)

func _ready():
	self.set_title(tr("Options"))
	self.add_cancel(tr("Cancel"))							# TODO: Does this keep on adding cancels?
	serializer_label.set_text(tr("Serializer"))
	extension_label.set_text(tr("File Extension"))
	encrypt_label.set_text(tr("Encrypt Files"))
	class_directory_label.set_text(tr("Class Directory"))
	output_directory_label.set_text(tr("Output Directory"))
	sanitize_ids_label.set_text(tr("Sanitize IDs"))
	
	config = ConfigFile.new()
	config.load("res://addons/godot_data_editor/plugin.cfg") 
	serializer = config.get_value("custom", "serializer")
	extension = config.get_value("custom", "extension")

	class_directory = config.get_value("custom", "class_directory")
	sanitize_ids = config.get_value("custom", "sanitize_ids")
	encrypt = config.get_value("custom", "encrypt")
	password = config.get_value("custom", "password")
	output_directory = config.get_value("custom", "output_directory")
	sanitize_ids = config.get_value("custom", "sanitize_ids")
	
	serializer_option.clear()
	serializer_option.add_item("json", 0)
	serializer_option.add_item("binary", 1)
	if serializer == "json":
		serializer_option.select(0)
	elif serializer == "binary":
		serializer_option.select(1)
	else:
		serializer_option.select(0)
		serializer = "json"
		
	extension_line_edit.set_text(extension)
	
	if serializer == "binary":
		encrypt_check_box.set_disabled(false)
		password_line_edit.set_editable(true)
	else:
		encrypt = false
		password = ""
		encrypt_check_box.set_disabled(true)
		password_line_edit.set_editable(false)
	
	encrypt_check_box.set_pressed(encrypt)
	encrypt_check_box.set_text(str(encrypt))
	
	password_line_edit.set_text(str(password))
	
	class_directory_line_edit.set_text(str(class_directory))
	output_directory_line_edit.set_text(str(output_directory))
	
	sanitize_ids_check_box.set_pressed(sanitize_ids)
	sanitize_ids_check_box.set_text(str(sanitize_ids))
	
func _on_SerializerOption_item_selected(index):
	if index == 0:
		extension_line_edit.set_text("json")
		encrypt = false
		password = ""
		encrypt_check_box.set_disabled(true)
		password_line_edit.set_editable(false)
	if index == 1:
		extension_line_edit.set_text("gob")
		encrypt_check_box.set_disabled(false)
		password_line_edit.set_editable(true)



func _on_Options_confirmed():
	extract_values()
	extension = extension.strip_edges()
	if extension.begins_with("."):
		extension = extension.replace(".", "")
	
	# TODO: Validate
	var error_message = ""
#	if self.serializer != "binary" or self.serializer != "json":
#		error_message = tr("Please choose either 'json' or 'binary' as serializer.\n")
	if self.extension == "":
		error_message = tr("Please choose a valid file extension, e.g. 'gob' or 'json'.")
	if self.class_directory == "" or not self.class_directory.begins_with("res://"):
		error_message = tr("The class directory must be a resource path, e.g. 'res://classes'.")
	if self.output_directory == "" or not self.output_directory.begins_with("res://"):
		error_message = tr("The output directory must be a resource path, e.g. 'res://data'.")
	
	var extension_changed = false
	var encryption_changed = false
	if extension != config.get_value("custom", "extension") or serializer != config.get_value("custom", "serializer"):
		extension_changed = true

	if encrypt != config.get_value("custom", "encrypt") or password != config.get_value("custom", "password"):
		encryption_changed = true

	if error_message == "":
		config.set_value("custom", "extension", extension)
		config.set_value("custom", "serializer", serializer)
		config.set_value("custom", "encrypt", encrypt)
		config.set_value("custom", "password", password)
		config.set_value("custom", "class_directory", class_directory)		
		config.set_value("custom", "output_directory", output_directory)		
		config.set_value("custom", "sanitize_ids", sanitize_ids)	
		config.save("res://addons/godot_data_editor/plugin.cfg")
		hide()
	else:
		warn_dialog.set_text(error_message)
		warn_dialog.popup_centered()
	
	if extension_changed:
		emit_signal("extension_changed", extension, serializer)

	if encryption_changed:
		emit_signal("encryption_changed", encrypt, password)
# TODO: Add a tip to NOT FORGET THE PASSWORD

func extract_values():
	serializer = serializer_option.get_item_text(serializer_option.get_selected())
	extension = extension_line_edit.get_text()
	encrypt = encrypt_check_box.is_pressed()
	password = password_line_edit.get_text()
	output_directory = output_directory_line_edit.get_text()
	sanitize_ids = sanitize_ids_check_box.is_pressed()
	
func _on_ClassDirectoryButton_button_down():
	var dialog = EditorFileDialog.new()
	dialog.set_mode(EditorFileDialog.MODE_OPEN_DIR)
	dialog.connect("dir_selected", self, "set_class_directory", [])
	if not self.find_node("EditorFileDialog"):
		add_child(dialog)
	else:
		get_node("EditorFileDialog").popup_centered()
	dialog.popup_centered_ratio()


func _on_OutputDirectoryButton_button_down():
	var dialog = EditorFileDialog.new()
	dialog.set_mode(EditorFileDialog.MODE_OPEN_DIR)
	dialog.connect("dir_selected", self, "set_output_directory", [])
	if not self.find_node("EditorFileDialog"):
		add_child(dialog)
	else:
		get_node("EditorFileDialog").popup_centered()
	dialog.popup_centered_ratio()
		
func set_class_directory(selected_directory):
	class_directory = selected_directory
	class_directory_line_edit.set_text(selected_directory)

func set_output_directory(selected_directory):
	output_directory = selected_directory
	output_directory_line_edit.set_text(selected_directory)

func _on_EncryptCheckBox_button_down():
	encrypt_check_box.set_text(str(!encrypt_check_box.is_pressed()))

func _on_SanitizeIdsCheckBox_button_down():
	sanitize_ids_check_box.set_text(str(!sanitize_ids_check_box.is_pressed()))
