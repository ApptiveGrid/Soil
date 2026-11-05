"
Writes nil as the object of a record that holds none (SoilEmptyRecord). nil is the one object Soil can write without knowing what the object was, and nothing is given up: the record held nothing. The record is written again with the version and the previous version it had, so every reader that met the empty record meets nil now; the index points at the new one, and the empty record is left where it is for the garbage collection to take.

It is not a default. The record reads afterwards, but whether the application can do with nil where it had an object is for a person to say: the links of a space that turn nil fail the next delete of a flow just the same, only in the application and no longer in Soil.

Never in the meta segment (SoilRepairVisitor>>visitWriteNil:): a behavior description that is nil is no description, and every object of its class depends on it.
"
Class {
	#name : #SoilWriteNil,
	#superclass : #SoilRepairAction,
	#instVars : [
		'segment',
		'index',
		'position'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #accessing }
SoilWriteNil class >> actionName [
	^ #writeNil
]

{ #category : #'instance creation' }
SoilWriteNil class >> newFromDictionary: aDictionary [
	^ self
		segment: (aDictionary at: #segment)
		index: (aDictionary at: #index)
		position: (aDictionary at: #position)
]

{ #category : #'instance creation' }
SoilWriteNil class >> segment: anInteger index: anIndex position: aPosition [
	^ self new
		segment: anInteger index: anIndex position: aPosition;
		yourself
]

{ #category : #visiting }
SoilWriteNil >> acceptSoil: aSoilVisitor [
	^ aSoilVisitor visitWriteNil: self
]

{ #category : #accessing }
SoilWriteNil >> asDictionary [
	^ super asDictionary
		at: #segment put: segment;
		at: #index put: index;
		at: #position put: position;
		yourself
]

{ #category : #accessing }
SoilWriteNil >> description [
	^ 'write nil as the object of object ', index printString, ' of segment ', segment printString, ' in place of the empty record at position ', position printString
]

{ #category : #accessing }
SoilWriteNil >> index [
	^ index
]

{ #category : #accessing }
SoilWriteNil >> position [
	^ position
]

{ #category : #accessing }
SoilWriteNil >> segment [
	^ segment
]

{ #category : #initialization }
SoilWriteNil >> segment: anInteger index: anIndex position: aPosition [
	segment := anInteger.
	index := anIndex.
	position := aPosition
]
