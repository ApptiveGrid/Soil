"
I serialize a cluster for SoilGraphExporter, with the objects its migrations replace written in their place.

A migration hands back another object, typically a shallow copy, while what the cluster points at is still the original. I leave the original where it is in my object table and write its replacement at that position. Whatever points at the original later becomes an internal reference to that position, and the import finds the replacement there. That is how a back pointer at a migrated cluster root arrives at the root, and how two references to one migrated object arrive at one replacement. A migration that answers nil drops the object: nil is written in its place, and every reference to it is nil.

Whether an object is embedded or referenced stays with my superclass. My replacements only take the place of what would be embedded; an object of a migrated class that is the root of another cluster remains a reference to it.
"
Class {
	#name : #SoilGraphExportSerializer,
	#superclass : #SoilSerializer,
	#instVars : [
		'migrations',
		'replacements'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #testing }
SoilGraphExportSerializer >> hasReplacementFor: anObject [
	^ (replacements includesKey: anObject) or: [ migrations includesKey: anObject class ]
]

{ #category : #initialization }
SoilGraphExportSerializer >> initialize [
	super initialize.
	migrations := Dictionary new.
	replacements := IdentityDictionary new
]

{ #category : #accessing }
SoilGraphExportSerializer >> migrations: aDictionary [
	"blocks by class, each answering what an object of that class is written as"
	migrations := aDictionary
]

{ #category : #registry }
SoilGraphExportSerializer >> registerObject: anObject ifAbsent: aBlock [
	"the block runs for what is embedded, after anObject took its place in the object table"
	(self hasReplacementFor: anObject)
		ifFalse: [ ^ super registerObject: anObject ifAbsent: aBlock ].
	(self replacementFor: anObject) ifNil: [
		"a migration dropped it: nil takes its place and nothing is registered, so every
		later reference to it is nil as well. Registering it would not do - the
		materializer does not count a nil, and every internal reference after it would
		point one object too far"
		^ nil soilSerialize: self ].
	^ super
		registerObject: anObject
		ifAbsent: [ (self replacementFor: anObject) soilBasicSerialize: self ]
]

{ #category : #accessing }
SoilGraphExportSerializer >> replace: anObject with: aReplacement [
	replacements at: anObject put: aReplacement
]

{ #category : #private }
SoilGraphExportSerializer >> replacementFor: anObject [
	"what anObject is written as. The block of its class runs once per object, so that
	each reference to it arrives at the same replacement"
	^ replacements
		at: anObject
		ifAbsentPut: [ (migrations at: anObject class) value: anObject ]
]
