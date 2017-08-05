tool
extends AcceptDialog

func warn(title, text):
	set_title(title)
	set_text(text)
	popup_centered()
	
	# Probably this should be placed at get_base_control()
