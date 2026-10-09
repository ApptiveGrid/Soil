"
A name in the behavior registry that points at no behavior description: its object id lies outside the meta segment, or there is no record at it. Found at 65bba342, where 16 names had four zero bytes too many and an id shifted by as many - each class had its right entry besides, so lookups by name were not affected, but the backup, which copies every entry, ended on them.

Not SoilObjectIdOutsideSegment: that one is repaired by raising the index of the segment, which for an id like 0:68719476736 would hand out indexes nobody can use. The repair is to remove the name (SoilRemoveRegistryEntry), its default.
"
Class {
	#name : #SoilBrokenRegistryEntry,
	#superclass : #SoilFinding,
	#instVars : [
		'key',
		'objectId'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #testing }
SoilBrokenRegistryEntry class >> isBroken: aSoilObjectId in: aSoil [
	"whether aSoilObjectId, a value of the behavior registry, points at no description.
	The meta description has no record: it is pre-initialized"
	| segment |
	aSoilObjectId = SoilBehaviorDescription metaId ifTrue: [ ^ false ].
	aSoilObjectId segment = 0 ifFalse: [ ^ true ].
	segment := aSoil objectRepository metaSegment.
	(aSoilObjectId index between: 1 and: segment lastObjectIndex) ifFalse: [ ^ true ].
	^ (segment heapPositionAt: aSoilObjectId index) = 0
]

{ #category : #'instance creation' }
SoilBrokenRegistryEntry class >> key: anInteger objectId: aSoilObjectId [
	^ self new
		key: anInteger objectId: aSoilObjectId;
		yourself
]

{ #category : #accessing }
SoilBrokenRegistryEntry >> asDictionary [
	^ super asDictionary
		at: #key put: (SoilRemoveRegistryEntry stringFromKey: key);
		at: #objectId put: objectId printString;
		yourself
]

{ #category : #accessing }
SoilBrokenRegistryEntry >> description [
	^ 'behavior registry entry ', (SoilRemoveRegistryEntry stringFromKey: key), ' points at no description: ', objectId printString
]

{ #category : #accessing }
SoilBrokenRegistryEntry >> key [
	^ key
]

{ #category : #initialization }
SoilBrokenRegistryEntry >> key: anInteger objectId: aSoilObjectId [
	key := anInteger.
	objectId := aSoilObjectId
]

{ #category : #accessing }
SoilBrokenRegistryEntry >> kind [
	^ #brokenRegistryEntry
]

{ #category : #accessing }
SoilBrokenRegistryEntry >> objectId [
	^ objectId
]

{ #category : #repairing }
SoilBrokenRegistryEntry >> repairActions [
	^ { SoilRemoveRegistryEntry key: key objectId: objectId }
]
