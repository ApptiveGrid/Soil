"
A Soil database for the resident tests: it keeps its resident registry under
its own key in the root dictionary and thereby fills the overridable lookup
Soil>>residentRegistryIn:. That is exactly the freedom the stage-one lookup is
meant to leave the embedder -- Soil prescribes no structure, the way to the
registry is overridden here.
"
Class {
	#name : #SoilTestResidentDatabase,
	#superclass : #Soil,
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

{ #category : #initialization }
SoilTestResidentDatabase >> initializeRoot [
	| txn |
	txn := self newTransaction.
	txn root: SoilPersistentDictionary new.
	txn commit
]

{ #category : #residents }
SoilTestResidentDatabase >> residentRegistryIn: aTransaction [
	^ aTransaction root at: #residents ifAbsent: [ nil ]
]
