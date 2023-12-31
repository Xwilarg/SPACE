extends Control;

class_name CardUI;

var _curr_card: Card;

func _ready():
	GameManager.subscribe_button(self);

func _on_pressed():
	GameManager.load_item(self, _curr_card);

func set_card(c: Card):
	_curr_card = c;
	$CardBG/MarginContainer/VBoxContainer/HBoxContainer2/NamePanel/MarginContainer/RichTextLabel.text = c.name;
	$CardBG/MarginContainer/VBoxContainer/DescPanel/MarginContainer/RichTextLabel.text = c.description
	$CardBG/MarginContainer/VBoxContainer/HBoxContainer2/EnergyPanel/MarginContainer/RichTextLabel.text = tr("COST") + tr("COLON") + " " + str(c.energyCost)

	$CardBG/MarginContainer/VBoxContainer/HBoxContainer/IconPanel/TextureRect.texture = c.icon

	var effects_text = ""
	var effect_text = ""
	
	for eff in c.effects:
		effect_text = tr("EFF_" + eff).replace("%1", str(c.effects[eff]))
		
		effects_text += effect_text + "\n"
	
	$CardBG/MarginContainer/VBoxContainer/StatsPanel/MarginContainer/RichTextLabel.text = effects_text


func _on_delete_pressed():
	GameManager.update_button(self, true);
