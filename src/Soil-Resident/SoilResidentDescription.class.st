"
I am the persisted half of a resident: everything needed to run it, and the
references to the objects it works on.

Subclasses add their own operating data (intervals, limits, switches) and their
own references. Operating data is configuration, not runtime state -- how far a
resident has got belongs under the referenced objects, otherwise I get written
on every work unit although I never change.

I create my own instance so the mapping description -> resident lives in one
place and a new resident type needs no registration.
"
Class {
	#name : #SoilResidentDescription,
	#superclass : #Object,
	#instVars : [
		'workspace',
		'disabled'
	],
	#category : #'Soil-Resident'
}

{ #category : #accessing }
SoilResidentDescription >> disable [
	"switch me off and keep me off. Whoever calls me is inside a transaction and
	commits it -- the flag is persisted precisely so that it outlives the image,
	which is what tells it apart from a #requestStop: a stop is a runtime fact and
	is gone with the process.

	Taking effect on a resident that is already running is a second step, and it is
	SoilResident>>restartIn: -- the one place a description is read anyway."
	disabled := true
]

{ #category : #accessing }
SoilResidentDescription >> enable [
	"the way back. Also a second step to take effect, and the same one"
	disabled := false
]

{ #category : #testing }
SoilResidentDescription >> isDisabled [
	"Compared against true rather than answered straight: every description that
	already sits in a database gets the new field as nil when Soil migrates it,
	and nil means 'was never switched off'."
	^ disabled == true
]

{ #category : #testing }
SoilResidentDescription >> hasWorkspace [
	^ workspace notNil
]

{ #category : #initialization }
SoilResidentDescription >> initializeFrom: aTransaction [
	"called once when I am added to a database, and from the embedder's migration
	path when I am added to a database that already exists. Create the objects I
	work on here and make them cluster roots"
]

{ #category : #'instance creation' }
SoilResidentDescription >> instanceClass [
	self subclassResponsibility
]

{ #category : #accessing }
SoilResidentDescription >> name [
	"my symbolic name, the registry key. An internal symbol, deliberately not
	part of any URI, so it stays changeable"
	self subclassResponsibility
]

{ #category : #'instance creation' }
SoilResidentDescription >> newInstanceIn: aTransaction [
	"the resident remembers my object id, not me: it outlives many transactions
	and resolves me in whichever one is running. It remembers my workspace's id as
	well, so that it reaches the objects it works on directly -- I am read to create
	and configure it, not on every work unit"
	^ self instanceClass new
		descriptionId: (aTransaction objectIdOf: self);
		workspaceId: self workspaceId;
		yourself
]

{ #category : #accessing }
SoilResidentDescription >> workspace [
	"the object under which everything hangs that the resident needs persistently.
	The rule rather than a pattern (Norbert, 2026-09-25): most residents have state
	to keep, and further references hang under the workspace. A resident that needs
	none leaves it nil and ignores it"
	^ workspace
]

{ #category : #accessing }
SoilResidentDescription >> workspace: anObject [
	workspace := anObject
]

{ #category : #accessing }
SoilResidentDescription >> workspaceId [
	"the object id of my workspace, for the resident to reach it without reading me.
	Only a workspace that is a cluster root of its own has one -- read in a
	transaction, it sits in me as a proxy that knows its id without being loaded.
	nil when I have no workspace, or when it lives inside my own cluster; the resident
	then goes through me as it always did"
	^ (workspace notNil and: [ workspace isSoilProxy ])
		ifTrue: [ workspace objectId ]
		ifFalse: [ nil ]
]
