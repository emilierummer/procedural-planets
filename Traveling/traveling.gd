extends Control

@onready var timer:Timer = $Timer
@onready var TimeRemainingLabel:Label = $VBoxContainer/TimeRemaining


func _process(_delta):
    var time_left = round(timer.time_left)
    TimeRemainingLabel.text = str(time_left) + "s remaining"


func _on_timer_timeout():
    print("Timer timeout!")
