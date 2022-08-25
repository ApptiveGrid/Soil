Class {
	#name : #SOTransaction,
	#superclass : #Object,
	#instVars : [
		'soil',
		'objects',
		'newObjects',
		'objectIndex'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SOTransaction >> commit [
	| stream lastId |
	lastId := 1.
	"iterate over all object ids to assign numbers before they get serialized"
	objects keys do: [ :id  |
		(id index = 0) ifTrue: [ lastId := lastId + 1. id index: lastId ] ].
	objects keysAndValuesDo: [ :id :object | | file |
		stream := (soil path / id index asString) binaryWriteStream.
		FLSerializer new 
			analyzer: (SOAnalyzer new transaction: self);
			serialize: object on: stream.
			stream 
				flush;
				close ]
]

{ #category : #'as yet unclassified' }
SOTransaction >> idOf: anObject [ 
	| id |
	id := objectIndex at: anObject.
	(id index = 0) ifTrue: [ Error signal: 'index of object id is not initialized' ].
	^ id
]

{ #category : #initialization }
SOTransaction >> initialize [ 
	super initialize.
	objects := Dictionary new.
	objectIndex := Dictionary new.
]

{ #category : #testing }
SOTransaction >> isRoot: anObject [
	^ objects includes: anObject
]

{ #category : #'as yet unclassified' }
SOTransaction >> makeRoot: anObject [ 
	| objectId |
	objectId := self newObjectId.
	objectIndex at: anObject put: objectId.
	objects at: objectId put: anObject 
]

{ #category : #'instance creation' }
SOTransaction >> newObjectId [ 
	^ SOObjectId new 
		index: 0
]

{ #category : #'as yet unclassified' }
SOTransaction >> objectWithId: anInteger ifNone: aBlock [
	| m |
	m := soil materializationWithId: anInteger ifNone: aBlock.
	m objects do: [ :each | each soilLoadedIn: self ].
	^ m root
]

{ #category : #accessing }
SOTransaction >> root [
	| m |
	m := (soil materializationWithId: (SOObjectId new index: 1) ifNone: [ nil ]).
	m objects do: [ :each | each soilLoadedIn: self ].
	^ m root
]

{ #category : #accessing }
SOTransaction >> root: anObject [
	objects at: (SOObjectId new index: 1) put: anObject
]

{ #category : #accessing }
SOTransaction >> soil: aSoil [ 
	soil := aSoil
]
