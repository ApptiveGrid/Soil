"
I am the persisted side of the resident registry: a map from symbolic name to
SoilResidentDescription. The registry that holds the live residents is
transient and rebuilt on every open; I survive.

I am a cluster root with an object id of my own, deliberately so even while the
way to me is still an overridable lookup: once named roots exist in Soil, that
step is then a single name -> object id entry pointing at me, instead of a data
migration through databases in production.

Being a map rather than a list is the second reason I exist: named access does
not have to search linearly, and two descriptions under the same name cannot
happen.
"
Class {
	#name : #SoilResidentRegistry,
	#superclass : #Object,
	#instVars : [
		'descriptions'
	],
	#category : #'Soil-Resident'
}

{ #category : #adding }
SoilResidentRegistry >> addDescription: aDescription [
	"answers the description, so a caller can go on to initialize it"
	(descriptions includesKey: aDescription name) ifTrue: [
		SoilResidentAlreadyPresent signalForName: aDescription name ].
	descriptions at: aDescription name put: aDescription.
	^ aDescription
]

{ #category : #accessing }
SoilResidentRegistry >> descriptionNamed: aSymbol [
	^ self descriptionNamed: aSymbol ifAbsent: [ SoilResidentNotFound signalForName: aSymbol ]
]

{ #category : #accessing }
SoilResidentRegistry >> descriptionNamed: aSymbol ifAbsent: aBlock [
	^ descriptions at: aSymbol ifAbsent: aBlock
]

{ #category : #enumerating }
SoilResidentRegistry >> descriptions [
	^ descriptions values asArray
]

{ #category : #enumerating }
SoilResidentRegistry >> descriptionsDo: aBlock [
	descriptions valuesDo: aBlock
]

{ #category : #testing }
SoilResidentRegistry >> includesName: aSymbol [
	^ descriptions includesKey: aSymbol
]

{ #category : #initialization }
SoilResidentRegistry >> initialize [
	super initialize.
	descriptions := Dictionary new
]

{ #category : #testing }
SoilResidentRegistry >> isEmpty [
	^ descriptions isEmpty
]

{ #category : #accessing }
SoilResidentRegistry >> names [
	^ descriptions keys asArray
]

{ #category : #removing }
SoilResidentRegistry >> removeDescriptionNamed: aSymbol [
	^ descriptions removeKey: aSymbol ifAbsent: [ nil ]
]

{ #category : #accessing }
SoilResidentRegistry >> size [
	^ descriptions size
]
