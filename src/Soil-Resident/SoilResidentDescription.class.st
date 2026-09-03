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
		'workspace'
	],
	#category : #'Soil-Resident'
}

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
	and resolves me in whichever one is running"
	^ self instanceClass new
		descriptionId: (aTransaction objectIdOf: self);
		yourself
]

{ #category : #accessing }
SoilResidentDescription >> workspace [
	"the object under which everything hangs that the resident needs persistently.
	A frequent pattern, not a requirement -- a description with several references
	is just as valid"
	^ workspace
]

{ #category : #accessing }
SoilResidentDescription >> workspace: anObject [
	workspace := anObject
]
