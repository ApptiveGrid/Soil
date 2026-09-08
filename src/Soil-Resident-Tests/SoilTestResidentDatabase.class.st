"
A Soil database for the resident tests: it keeps its resident registry under
its own key in the root dictionary and thereby fills the overridable lookup
Soil>>residentRegistryIn:. That is exactly the freedom the stage-one lookup is
meant to leave the embedder -- Soil prescribes no structure, the way to the
registry is overridden here.

I also fill the other overridable seam, Soil>>emit:, by collecting what is
reported instead of signalling it. A test can then read the lines straight off
me - no logger to start, no Beacon in the way, and nothing that depends on
another test having stopped its logger. What the default seam does is a
question of its own and is asked in its own test.
"
Class {
	#name : #SoilTestResidentDatabase,
	#superclass : #Soil,
	#instVars : [
		'reported'
	],
	#category : #'Soil-Resident-Tests'
}

{ #category : #residents }
SoilTestResidentDatabase >> addResidentDescription: aDescription [
	"what an embedder does when a resident is added: put the description into the
	registry, make it a cluster root and let it create the objects it works on.
	Answers the description"
	| txn |
	txn := self newTransaction.
	[ | registry |
	registry := self ensureResidentRegistryIn: txn.
	registry addDescription: aDescription.
	txn makeRoot: aDescription.
	aDescription initializeFrom: txn.
	txn commit ]
		ensure: [ txn isAborted ifFalse: [ txn abort ] ].
	^ aDescription
]

{ #category : #residents }
SoilTestResidentDatabase >> ensureResidentRegistryIn: aTransaction [
	"the registry is a cluster root of its own from the start, so named roots
	later only add a name -> object id entry instead of moving data"
	^ aTransaction root
		at: #residents
		ifAbsent: [ | registry |
			registry := SoilResidentRegistry new.
			aTransaction makeRoot: registry.
			aTransaction root at: #residents put: registry.
			registry ]
]

{ #category : #logging }
SoilTestResidentDatabase >> emit: aString [
	reported add: aString
]

{ #category : #initialization }
SoilTestResidentDatabase >> initialize [
	super initialize.
	reported := OrderedCollection new
]

{ #category : #initialization }
SoilTestResidentDatabase >> initializeRoot [
	| txn |
	txn := self newTransaction.
	txn root: SoilPersistentDictionary new.
	txn commit
]

{ #category : #logging }
SoilTestResidentDatabase >> reported [
	"the lines, in the order they were reported"
	^ reported
]

{ #category : #logging }
SoilTestResidentDatabase >> reportedMatching: aString [
	"the lines containing aString. Substring rather than equality on purpose: a
	line carries a resident's name and often a number, and a test should say which
	part of it is the point"
	^ reported select: [ :each | each includesSubstring: aString ]
]

{ #category : #residents }
SoilTestResidentDatabase >> residentRegistryIn: aTransaction [
	^ aTransaction root at: #residents ifAbsent: [ nil ]
]
