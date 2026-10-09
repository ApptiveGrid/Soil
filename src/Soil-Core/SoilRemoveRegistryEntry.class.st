"
Takes a name out of the behavior registry that points at no description (SoilBrokenRegistryEntry). It is the default there: the name finds nothing, and the class it was meant for has its own entry or is stored again under a new one.

The key is the key as the registry holds it, an integer - a name with zero bytes at its end is another key than the name without them. In a dictionary it is written in hex.
"
Class {
	#name : #SoilRemoveRegistryEntry,
	#superclass : #SoilRepairAction,
	#instVars : [
		'key',
		'segment',
		'index'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #accessing }
SoilRemoveRegistryEntry class >> actionName [
	^ #removeRegistryEntry
]

{ #category : #'instance creation' }
SoilRemoveRegistryEntry class >> key: anInteger objectId: aSoilObjectId [
	^ self new
		key: anInteger segment: aSoilObjectId segment index: aSoilObjectId index;
		yourself
]

{ #category : #converting }
SoilRemoveRegistryEntry class >> keyFromString: aString [
	^ Integer readFrom: aString base: 16
]

{ #category : #'instance creation' }
SoilRemoveRegistryEntry class >> newFromDictionary: aDictionary [
	^ self new
		key: (self keyFromString: (aDictionary at: #key))
		segment: (aDictionary at: #segment)
		index: (aDictionary at: #index);
		yourself
]

{ #category : #converting }
SoilRemoveRegistryEntry class >> stringFromKey: anInteger [
	^ anInteger printStringBase: 16
]

{ #category : #visiting }
SoilRemoveRegistryEntry >> acceptSoil: aSoilVisitor [
	^ aSoilVisitor visitRemoveRegistryEntry: self
]

{ #category : #accessing }
SoilRemoveRegistryEntry >> asDictionary [
	^ super asDictionary
		at: #key put: self keyString;
		at: #segment put: segment;
		at: #index put: index;
		yourself
]

{ #category : #accessing }
SoilRemoveRegistryEntry >> description [
	^ 'remove the behavior registry entry ', self keyString, ' that points at ', self objectId printString
]

{ #category : #testing }
SoilRemoveRegistryEntry >> isDefault [
	^ true
]

{ #category : #accessing }
SoilRemoveRegistryEntry >> key [
	^ key
]

{ #category : #initialization }
SoilRemoveRegistryEntry >> key: anInteger segment: aSegmentId index: anIndex [
	key := anInteger.
	segment := aSegmentId.
	index := anIndex
]

{ #category : #accessing }
SoilRemoveRegistryEntry >> keyString [
	^ self class stringFromKey: key
]

{ #category : #accessing }
SoilRemoveRegistryEntry >> objectId [
	^ SoilObjectId segment: segment index: index
]
