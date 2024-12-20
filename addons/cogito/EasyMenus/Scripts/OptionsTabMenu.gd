class_name OptionsTabMenu
extends Control
signal options_updated

# Grabbing TabContainer node for gamepad navigation
@onready var tab_container: CogitoTabMenu = $VBoxContainer/TabContainer

const HSliderWLabel = preload("res://addons/cogito/EasyMenus/Scripts/slider_w_labels.gd")
var config = ConfigFile.new()

var have_options_changed: bool = false

# GAMEPLAY
@onready var invert_y_check_button: CheckButton = %InvertYAxisCheckButton
@onready var toggle_crouching_check_button: CheckButton = %ToggleCrouchingCheckButton
@onready var headbob_option_button: OptionButton = %HeadbobOptionButton
@onready var mouse_sens_slider: HSlider = %MouseSensSlider
@onready var mouse_sens_value_label: Label = %MouseSensValueLabel
@onready var gp_look_sens_value_label: Label = %GPLookSensValueLabel
@onready var gp_look_sens_slider: HSlider = %GPLookSensSlider


var gp_looksens : float
var mouse_sens : float
var headbob_strength : int

# AUDIO
@onready var sfx_volume_slider : HSliderWLabel = $%SFXVolumeSlider
@onready var music_volume_slider: HSliderWLabel = $%MusicVolumeSlider

var sfx_bus_index
var music_bus_index

# GRAPHICS
@onready var render_scale_current_value_label: Label = %RenderScaleCurrentValueLabel
@onready var render_scale_slider: HSlider = %RenderScaleSlider
@onready var gui_scale_current_value_label: Label = %GUIScaleCurrentValueLabel
@onready var gui_scale_slider: HSlider = %GUIScaleSlider
@onready var vsync_check_button: CheckButton = %VSyncCheckButton
@onready var anti_aliasing_2d_option_button: OptionButton = $%AntiAliasing2DOptionButton
@onready var anti_aliasing_3d_option_button: OptionButton = $%AntiAliasing3DOptionButton
@onready var window_mode_option_button: OptionButton = %WindowModeOptionButton
@onready var resolution_option_button: OptionButton = %ResolutionOptionButton

var render_resolution : Vector2i
var prev_resolution : Vector2i
var render_scale_val : float

const HEADBOB_DICTIONARY : Dictionary = {
	"Minimal" : 1,
	"Average" : 3,
	"Full" : 7,
}

# Array to set window modes.
const WINDOW_MODE_ARRAY : Array[String] = [
	"Exclusive full screen",
	"Full screen",
	"Windowed",
	"Borderless windowed",	
]

const RESOLUTION_DICTIONARY : Dictionary = {
	"1280x720 (16:9)" : Vector2i(1280,720),
	"1280x800 (16:10)" : Vector2i(1280,800),
	"1366x768 (16:9)" : Vector2i(1366,768),
	"1440x900 (16:10)" : Vector2i(1440,900),
	"1600x900 (16:9)" : Vector2i(1600,900),
	"1920x1080 (16:9)" : Vector2i(1920,1080),
	"2560x1440 (16:9)" : Vector2i(2560,1440),
	"3840x2160 (16:9)" : Vector2i(3840,2160),
}


func _ready() -> void:
	add_headbob_items()
	headbob_option_button.item_selected.connect(on_headbob_selected)
	mouse_sens_slider.value_changed.connect(_on_mouse_sens_slider_value_changed)
	gp_look_sens_slider.value_changed.connect(_on_gp_looksens_slider_value_changed)
	add_window_mode_items()
	add_resolution_items()
	window_mode_option_button.item_selected.connect(on_window_mode_selected)
	resolution_option_button.item_selected.connect(on_resolution_selected)
	
	sfx_bus_index = AudioServer.get_bus_index(OptionsConstants.sfx_bus_name)
	music_bus_index = AudioServer.get_bus_index(OptionsConstants.music_bus_name)
	sfx_volume_slider.hslider.value_changed.connect(_on_sfx_volume_slider_value_changed)
	music_volume_slider.hslider.value_changed.connect(_on_music_volume_slider_value_changed)
	
	load_options()


# Called from outside initializes the options menu
func on_open():
	pass


# Adding headbob options to the button
func add_headbob_items() -> void:
	for headbob_option in HEADBOB_DICTIONARY:
		headbob_option_button.add_item(headbob_option)


func on_headbob_selected(index:int) -> void:
	headbob_strength = HEADBOB_DICTIONARY.values()[index]

func _on_mouse_sens_slider_value_changed(value):
	mouse_sens = value
	mouse_sens_value_label.text = str(value)
	

func _on_gp_looksens_slider_value_changed(value):
	gp_looksens = value
	gp_look_sens_value_label.text = str(value)


# Adding window modes to the window mode button.
func add_window_mode_items() -> void:
	for mode in WINDOW_MODE_ARRAY:
		window_mode_option_button.add_item(mode)


# Adding resolutions to the resolution button.
func add_resolution_items() -> void:
	for resolution_text in RESOLUTION_DICTIONARY:
		resolution_option_button.add_item(resolution_text)


# Function to change window modes. Hooked up to the window_mode_option_button.
func on_window_mode_selected(index: int) -> void:
	match index:
		0: #Exclusive full screen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		1: #Full screen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2: #Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		3: #Borderless windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)


func refresh_render():
	get_window().size = render_resolution
	get_window().content_scale_size = render_resolution
	get_window().scaling_3d_scale = render_scale_val


# Function to change resolution. Hooked up to the resolution_option_button.
func on_resolution_selected(index:int) -> void:
	prev_resolution = render_resolution
	render_resolution = RESOLUTION_DICTIONARY.values()[index]
	if prev_resolution != render_resolution:
		have_options_changed = true


func _on_sfx_volume_slider_value_changed(value):
	set_volume(sfx_bus_index, value)


func _on_music_volume_slider_value_changed(value):
	set_volume(music_bus_index, value)


# Sets the volume for the given audio bus
func set_volume(bus_index, value):
	print("Setting volume on bus_index ", bus_index, " to ", value)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


# Saves the options
func save_options():
	config.set_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, invert_y_check_button.button_pressed)
	config.set_value(OptionsConstants.section_name, OptionsConstants.toggle_crouching_key, toggle_crouching_check_button.button_pressed)
	config.set_value(OptionsConstants.section_name, OptionsConstants.head_bobble_key, headbob_strength)
	config.set_value(OptionsConstants.section_name, OptionsConstants.mouse_sens_key, mouse_sens)
	config.set_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, gp_looksens)
	config.set_value(OptionsConstants.section_name, OptionsConstants.windowmode_key_name, window_mode_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.resolution_index_key_name, resolution_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.render_scale_key, render_scale_slider.value);
	config.set_value(OptionsConstants.section_name, OptionsConstants.gui_scale_key, gui_scale_slider.value);
	config.set_value(OptionsConstants.section_name, OptionsConstants.vsync_key, vsync_check_button.button_pressed)
	config.set_value(OptionsConstants.section_name, OptionsConstants.msaa_2d_key, anti_aliasing_2d_option_button.get_selected_id())
	config.set_value(OptionsConstants.section_name, OptionsConstants.msaa_3d_key, anti_aliasing_3d_option_button.get_selected_id())
	
	config.set_value(OptionsConstants.section_name, OptionsConstants.sfx_volume_key_name, sfx_volume_slider.hslider.value)
	config.set_value(OptionsConstants.section_name, OptionsConstants.music_volume_key_name, music_volume_slider.hslider.value)
	
	config.save(OptionsConstants.config_file_name)


# Loads options and sets the controls values to loaded values. Uses default values if config file does not exist
func load_options(skip_applying:bool = false):
	var err = config.load(OptionsConstants.config_file_name)
	if err != 0:
		print("Loading options config failed. Assuming and saving defaults.")
	
	var invert_y = config.get_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, true)
	var toggle_crouching = config.get_value(OptionsConstants.section_name, OptionsConstants.toggle_crouching_key, true)
	mouse_sens = config.get_value(OptionsConstants.section_name, OptionsConstants.mouse_sens_key, 0.25)
	gp_looksens = config.get_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, 2)
	headbob_strength = config.get_value(OptionsConstants.section_name, OptionsConstants.head_bobble_key, 2)
	
	var window_mode = config.get_value(OptionsConstants.section_name, OptionsConstants.windowmode_key_name, 0)
	var resolution_index = config.get_value(OptionsConstants.section_name, OptionsConstants.resolution_index_key_name, 0)
	var render_scale = config.get_value(OptionsConstants.section_name, OptionsConstants.render_scale_key, 1)
	var gui_scale = config.get_value(OptionsConstants.section_name, OptionsConstants.gui_scale_key, 1)
	var vsync = config.get_value(OptionsConstants.section_name, OptionsConstants.vsync_key, true)

	var msaa_2d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_2d_key, 0)
	var msaa_3d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_3d_key, 0)

	var sfx_volume = config.get_value(OptionsConstants.section_name, OptionsConstants.sfx_volume_key_name, 1)
	var music_volume = config.get_value(OptionsConstants.section_name, OptionsConstants.music_volume_key_name, 1)

	# LOADING GAMEPLAY CFG
	invert_y_check_button.set_pressed_no_signal(invert_y)
	toggle_crouching_check_button.set_pressed(toggle_crouching)
	
	if !skip_applying:
		invert_y_check_button.toggled.emit()
		toggle_crouching_check_button.toggled.emit()
	
	match headbob_strength:
		1: headbob_option_button.selected = 0
		3: headbob_option_button.selected = 1
		7: headbob_option_button.selected = 2
	if !skip_applying:
		headbob_option_button.item_selected.emit(headbob_option_button.selected)

	mouse_sens_slider.value = mouse_sens
	mouse_sens_value_label.text = str(mouse_sens)

	gp_look_sens_slider.value = gp_looksens
	gp_look_sens_value_label.text = str(gp_looksens)

	# LOADING AUDIO CFG
	sfx_volume_slider.hslider.value = sfx_volume
	music_volume_slider.hslider.value = music_volume
	
	# LOADING GRAPHICS CFG
	render_scale_slider.value = render_scale
	render_scale_val = render_scale
	
	gui_scale_slider.value = gui_scale
	gui_scale_current_value_label.text = str(gui_scale)
	if !skip_applying:
		apply_gui_scale_value()
	
	# Need to set it like that to guarantee signal to be triggered
	vsync_check_button.set_pressed_no_signal(vsync)
	vsync_check_button.toggled.emit()
	
	anti_aliasing_2d_option_button.selected = msaa_2d
	anti_aliasing_3d_option_button.selected = msaa_3d
	
	window_mode_option_button.selected = window_mode
	resolution_option_button.selected = resolution_index
	
	if !skip_applying:
		anti_aliasing_2d_option_button.emit_signal("item_selected", msaa_2d)
		anti_aliasing_3d_option_button.emit_signal("item_selected", msaa_3d)
		window_mode_option_button.item_selected.emit(window_mode)
		resolution_option_button.item_selected.emit(resolution_index)
		refresh_render()
		window_mode_option_button.item_selected.emit(window_mode_option_button.selected)


func _on_render_scale_slider_value_changed(value):
	render_scale_val = value
	render_scale_current_value_label.text = str(value)
	have_options_changed = true


func _on_gui_scale_slider_value_changed(value):
	gui_scale_current_value_label.text = str(value)

	
func _on_gui_scale_slider_drag_ended(_value_changed):
	apply_gui_scale_value()


# TODO: Apply changes if the slider is clicked but not dragged
func apply_gui_scale_value():
	get_viewport().content_scale_factor = gui_scale_slider.value
	gui_scale_current_value_label.text = str(gui_scale_slider.value)
	have_options_changed = true


func _on_v_sync_check_button_toggled(button_pressed):
	# There are multiple V-Sync Methods supported by Godot 
	# For now we just use the simple ones could be worth a consideration to add the others
	# Just sets V-Sync for the first window. So no support for multi window games
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_anti_aliasing_2d_option_button_item_selected(index):
	set_msaa("msaa_2d", index)


func _on_anti_aliasing_3d_option_button_item_selected(index):
	set_msaa("msaa_3d", index)


func set_msaa(mode, index):
	match index:
		0:
			get_viewport().set(mode,Viewport.MSAA_DISABLED)
		1:
			get_viewport().set(mode,Viewport.MSAA_2X)
		2:
			get_viewport().set(mode,Viewport.MSAA_4X)
		3:
			get_viewport().set(mode,Viewport.MSAA_8X)


func _on_apply_changes_pressed() -> void:
	window_mode_option_button.item_selected.emit(window_mode_option_button.selected)
	if have_options_changed:
		refresh_render()
	save_options()
	options_updated.emit()

func _on_tab_menu_resume():
	# reload options
	load_options.call_deferred()
