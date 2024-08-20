local config = {}






config.restrictActions = true 
config.disabledActions = {
    "loadHome", 
    "saveHome",
    "reset_physics",
    "reset_all_physics",
    "recover_vehicle", 
    "reload_vehicle", 
    "reload_all_vehicles", 
    "recover_vehicle_alt",
    "recover_to_last_road", 
    "nodegrabberRender", 
    "slower_motion", 
    "faster_motion", 
    "toggle_slow_motion",
    "dropPlayerAtCamera",
    "dropPlayerAtCameraNoReset",
   "dropCameraAtPlayer", 
   "editorPlacePlayerAtCamera",
    "editorToggle",
    "couplersToggle",          
    "couplersLock",   
    "couplersUnlock",
    "menu_item_radial_x",
     "menu_item_radial_y",
	 "menu_item_radial_right_x",
	"menu_item_radial_right_y",
	"toggleConsoleNG",
	"toggleConsole",
	"cefdev_console_toggle",
	"cycleTimeOfDay",
	"toggleWalkingMode",
	"menu_item_select",
	"toggleBigMap",
	"bigMapMouseClick",
	"bigMapControllerSelect",
	"bigMapNextFilter",
	"bigMapPreviousFilter",	
	"fuelVehicle",
	"forceField",
	"toggle_minimap",
	"menu_item_select"
}

 --"parts_selector"

return config
