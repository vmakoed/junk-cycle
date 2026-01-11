extends Container


signal toggled_child_changed


var toggled_child: Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	child_entered_tree.connect(_setup_toggle_signals)


func _setup_toggle_signals(node: Node) -> void:
	var toggleable: Toggleable = node.toggleable
	toggleable.toggle_requested.connect(_on_toggle_requested.bind(node))
	toggleable.toggled.connect(node.on_toggled)
	toggleable.untoggled.connect(node.on_untoggled)


func _on_toggle_requested(node: Node) -> void:
	if node == toggled_child: return
	if toggled_child != null: toggled_child.toggleable.is_toggled = false
	
	toggled_child = node
	node.toggleable.is_toggled = true
	toggled_child_changed.emit(toggled_child)
