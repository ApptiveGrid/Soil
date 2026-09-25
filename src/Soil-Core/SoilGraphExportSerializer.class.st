"
I serialize a cluster for SoilGraphExporter, with the objects its migrations replace written in their place.

A migration hands back another object, typically a shallow copy, while what the cluster points at is still the original. I leave the original where it is in my object table and write its replacement at that position. Whatever points at the original later becomes an internal reference to that position, and the import finds the replacement there. That is how a back pointer at a migrated cluster root arrives at the root, and how two references to one migrated object arrive at one replacement.

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
	^ super 
		registerObject: anObject 
		ifAbsent: [
			(self replacementFor: anObject)
				ifNil: [ aBlock value ]
				ifNotNil: [ :replacement | replacement soilBasicSerialize: self ] ]
]

{ #category : #accessing }
SoilGraphExportSerializer >> replace: anObject with: aReplacement [
	replacements at: anObject put: aReplacement
]

{ #category : #private }
SoilGraphExportSerializer >> replacementFor: anObject [
	^ replacements 
		at: anObject 
		ifAbsent: [ 
			(migrations at: anObject class ifAbsent: [ ^ nil ]) value: anObject ]
]
