extends Node
class_name Toggleable


signal toggle_requested
signal toggled
signal untoggled


var is_toggled := false: set = _set_toggled


func _set_toggled(new_value: bool) -> void:
    is_toggled = new_value
    
    if is_toggled:
        toggled.emit()
    else:
        untoggled.emit()
