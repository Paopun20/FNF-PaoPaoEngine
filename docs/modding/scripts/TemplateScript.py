# python stuff

def onCreate():
	# Triggered when the lua file is started, some variables weren't created yet
	pass


def onCreatePost():
	# End of "create"
	pass


def onDestroy():
	# Triggered when the lua file is ended
	pass



# Gameplay/Song interactions
def onSectionHit():
	# Triggered after it goes to the next section
	pass


def onBeatHit():
	# Triggered 4 times per section
	pass


def onStepHit():
	# Triggered 16 times per section
	pass


def onUpdate(elapsed):
	# Start of "update", some variables weren't updated yet
	# Also gets called while in the game over screen
	pass


def onUpdatePost(elapsed):
	# End of "update"
	# Also gets called while in the game over screen
	pass


def onStartCountdown():
	# Countdown started, duh
	# return Function_Stop if you want to stop the countdown from happening (Can be used to trigger dialogues and stuff! You can trigger the countdown with startCountdown())
	return Function_Continue;


def onCountdownStarted():
	# Called AFTER countdown started, if you want to stop it from starting, refer to the previous def (onStartCountdown)
	pass


def onCountdownTick(counter):
	# counter = 0 -> "Three"
	# counter = 1 -> "Two"
	# counter = 2 -> "One"
	# counter = 3 -> "Go!"
	# counter = 4 -> Nothing happens lol, tho it is triggered at the same time as onSongStart i think
	pass


def onSpawnNote(id, data, type, isSustainNote, strumTime):
	#You can use id to get other properties from notes, for example:
	#getPropertyFromGroup('notes', id, 'texture'):
	pass


def onSongStart():
	# Inst and Vocals start playing, songPosition = 0
	pass


def onEndSong():
	# Song ended/starting transition (Will be delayed if you're unlocking an achievement):
	# return Function_Stop to stop the song from ending for playing a cutscene or something.
	return Function_Continue;



# Substate interactions
def onPause():
	# Called when you press Pause while not on a cutscene/etc
	# return Function_Stop if you want to stop the player from pausing the game
	return Function_Continue;


def onResume():
	# Called after the game has been resumed from a pause (WARNING: Not necessarily from the pause screen, but most likely is!!!):
	pass


def onGameOver():
	# You died! Called every single frame your health is lower (or equal to): zero
	# return Function_Stop if you want to stop the player from going into the game over screen
	return Function_Continue;


def onGameOverStart():
	# Called when you have entered the game over screen and "onGameOver" wasn't stopped
	pass


def onGameOverConfirm(retry):
	# Called when you Press Enter/Esc on Game Over
	# If you've pressed Esc, value "retry" will be false
	pass



# Dialogue (When a dialogue is finished, it calls startCountdown again):
def onNextDialogue(line):
	# triggered when the next dialogue line starts, dialogue line starts at 0 (first line):, although it won't be triggered on line 0
	pass


def onSkipDialogue(line):
	# triggered when you press Enter and skip a dialogue line that was still being typed, dialogue line starts at 0 (first line):
	pass



# Key Press/Release
def onKeyPressPre(key):
	# Called before the note key press calculations
	# "key" can be: 0 - left, 1 - down, 2 - up, 3 - right
	pass


def onKeyReleasePre(key):
	# Called before the note key release calculations
	# "key" can be: 0 - left, 1 - down, 2 - up, 3 - right
	pass


def onKeyPress(key):
	# Called after the note key press calculations
	# "key" can be: 0 - left, 1 - down, 2 - up, 3 - right
	pass


def onKeyRelease(key):
	# Called after the note key release calculations
	# "key" can be: 0 - left, 1 - down, 2 - up, 3 - right
	pass


def onGhostTap(key):
	# Player pressed a button, but there was no note to hit and "Ghost Tapping" is enabled (ghost tap):
	# "key" can be: 0 - left, 1 - down, 2 - up, 3 - right
	pass



# Note miss/hit
## PRE
def goodNoteHitPre(id, noteData, noteType, isSustainNote):
	# def called when you hit a note (***before*** note hit calculations):
	# id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime'):"
	# noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	# noteType: The note type string
	# isSustainNote: If it's a hold note, can be either true or false
	pass

def opponentNoteHitPre(id, noteData, noteType, isSustainNote):
	# def called when the opponent hits a note (***before*** note hit calculations):
	# id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime'):"
	# noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	# noteType: The note type string
	# isSustainNote: If it's a hold note, can be either true or false
	pass


## POST
def goodNoteHit(id, noteData, noteType, isSustainNote):
	# def called when you hit a note (***after*** note hit calculations):
	# id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime'):"
	# noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	# noteType: The note type string
	# isSustainNote: If it's a hold note, can be either true or false
	pass

def opponentNoteHit(id, noteData, noteType, isSustainNote):
	# def called when the opponent hits a note (***after*** note hit calculations):
	# id: The note member id, you can get whatever variable you want from this note, example: "getPropertyFromGroup('notes', id, 'strumTime'):"
	# noteData: 0 = Left, 1 = Down, 2 = Up, 3 = Right
	# noteType: The note type string
	# isSustainNote: If it's a hold note, can be either true or false
	pass


def noteMissPress(direction):
	# Called after the note press miss calculations
	# Player pressed a button, but there was no note to hit (ghost miss):


def noteMiss(id, direction, noteType, isSustainNote):
	# Called after the note miss calculations
	# Player missed a note by letting it go offscreen
	pass



# Other def hooks
def preUpdateScore(miss):
	# Called before the score text updates
	# "miss" will be true if you missed
	# return Function_Stop if you want to stop the score text from updating
	return Function_Continue


def onUpdateScore(miss):
	# Called after the score text updates
	# "miss" will be true if you missed
	pass


def onRecalculateRating():
	# return Function_Stop if you want to do your own rating calculation,
	# use setRatingPercent(): to set the number on the calculation and setRatingString(): to set the funny rating name
	# NOTE: THIS IS CALLED BEFORE THE CALCULATION!!!
	return Function_Continue;
	pass


def onMoveCamera(focus):
	#Called when the camera focuses to a character

	if focus == 'boyfriend':
		# Called when the camera focuses on boyfriend
		pass
	elif focus == 'dad':
		# Called when the camera focuses on dad
		pass
	elif focus == 'gf':
		# Called when the camera focuses on girlfriend
		pass
	



# Event notes hooks
def onEvent(name, value1, value2, strumTime):
	# Event note triggered

	# print('Event triggered: ', name, value1, value2, strumTime):;
	pass


def onEventPushed(name, value1, value2, strumTime):
	# Called for every event note, recommended to precache assets
	pass


def eventEarlyTrigger(name, value1, value2, strumTime):
	#   Here's a port of the Kill Henchmen early trigger but on Lua instead of Haxe:
	#   
	#   if name == 'Kill Henchmen':
	#   	return 280;
	#   
	#   
	#   This makes the "Kill Henchmen" event be triggered 280 miliseconds earlier so that the kill sound is perfectly timed with the song

	# write your shit under this line, the new return value will override the ones hardcoded on the engine
	pass



# Custom Substates
def onCustomSubstateCreate(name):
	# "name" is defined on "openCustomSubstate(name)"
	pass


def onCustomSubstateCreatePost(name):
	# "name" is defined on "openCustomSubstate(name)"
	pass


def onCustomSubstateUpdate(name, elapsed):
	# "name" is defined on "openCustomSubstate(name)"
	pass


def onCustomSubstateUpdatePost(name, elapsed):
	# "name" is defined on "openCustomSubstate(name)"
	pass


def onCustomSubstateDestroy(name):
	# "name" is defined on "openCustomSubstate(name)"
	# Called when you use "closeCustomSubstate()"
	pass



# Tween/Timer/Sound hooks
def onTweenCompleted(tag, vars):
	# A tween you called has been completed, value "tag" is it's tag
	# vars = the tag of the sprite that was tweened
	pass


def onTimerCompleted(tag, loops, loopsLeft):
	# A loop from a timer you called has been completed, value "tag" is it's tag
	# loops = how many loops it will have done when it ends completely
	# loopsLeft = how many are remaining
	pass


def onSoundFinished(tag):
	# Only called if you use playSound() with a tag
	pass

