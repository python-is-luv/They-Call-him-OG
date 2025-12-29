extends Control

@onready var text_label: Label = $DialogueText
var dialogue_index := 0

var dialogues = [
"???: Hey Orochi, its Rob. Your old friend from
AKARI space station. You might've heard the news, the
Earth is in danger from a demon called
SantriK and we need a strong crew to defeat him.
<Click to Continue>",
"OG: After all that happened with my daughter during
the mission to find about the strange behaviour of
OVERGLADE galaxy in the milkyway,I don't want to
be responsible for any more lives.
<Click to Continue>",
"Rob: Look, OG. Listen...
<Click to Continue>",
"Rob: I totally understand what's going through you.
I know the patch is still wet. But the world needs you!
<Click to Continue>",
"Rob: You are the most trained astronaut we have OG. Most
of our crew barely left the simulator. All other skilled
ones have been killed by that evil creature!
<Click to Continue>",
"Rob: But you OG, you're are only hope now, you are a very
skilled astronaut, you even know swordfighting and martial
arts. The world needs you OG. You remember what your
daughter told you before dying?
<Click to Continue>",
"Rob: (plays OG's daughter's audio clip from the 1977 mission)
{Dad, the fuel is low, mass distribution and shuttle weight
depends a lot. *sighh* *a deep pause*. You gotta leave me here.
*What are you talkinh about? are you mad?* No dad",
"if we both go we'll both die. I want you to live. You're the greatest father dad.
Remember we love the world and we'll do anything for our mother Earth.
*pushes OG into the shuttle and locks him inside*}
<Click to Continue>",
"OG: *sobs* you blackmailed me emotionally didn't you Rob?
<Click to Continue>",
"Rob: Had to. But please, help us
<Click to Continue>",
"OG: Okay but I don't need rookies to be with me. I need maverick,
Caleb and Radek with me in the mission.
<Click to Continue>",
"Rob: Good ol' team huh OG? Consider it done Sir!"
]

func _ready():
	await show_text(dialogues[dialogue_index])
	
func _on_texture_rect_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		next_dialogue()

func show_text(line: String):
	text_label.text = ""
	for c in line:
		text_label.text += c
		await get_tree().create_timer(0.03).timeout	

func next_dialogue():
	dialogue_index += 1
	
	if dialogue_index >= dialogues.size():
		end_dialogue()
		return
		
	await show_text(dialogues[dialogue_index])
	
func end_dialogue():
	get_tree().change_scene_to_file("res://scenes/TUT/tut.tscn")
