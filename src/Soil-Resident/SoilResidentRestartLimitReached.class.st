"
Kept as a failed resident's error after its process has been brought back as
often as that resident tolerates. Not signalled, and that is deliberate: the
tick that notices runs in the supervisor's own process, and there is nobody
there to catch anything. A resident's answer to the embedder is its state plus
its error, the same way a failed start is kept rather than raised.
"
Class {
	#name : #SoilResidentRestartLimitReached,
	#superclass : #SoilResidentError,
	#instVars : [
		'restartCount'
	],
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResidentRestartLimitReached >> messageText [
	^ 'gave up restarting ', name asString, ' after ', self restartCount printString,
		(self restartCount = 1 ifTrue: [ ' restart' ] ifFalse: [ ' restarts' ])
]

{ #category : #accessing }
SoilResidentRestartLimitReached >> restartCount [
	"how many revivals had happened when I was made. The number is the diagnosis:
	read together with the resident's name it says whether this was a slow decay or
	a crash loop"
	^ restartCount
]

{ #category : #accessing }
SoilResidentRestartLimitReached >> restartCount: anInteger [
	restartCount := anInteger
]
