Class {
	#name : #SOTransaction,
	#superclass : #Object,
	#instVars : [
		'soil',
		'objects'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SOTransaction >> commit [
	| stream |
	objects keysAndValuesDo: [ :id :object | | file |
		stream := (soil path / id asString) binaryWriteStream.
		FLSerializer newDefault 
			analyzer: (SOAnalyzer new transaction: self);
			serialize: object on: stream.
			stream 
				flush;
				close ]
]

{ #category : #'as yet unclassified' }
SOTransaction >> idOf: anObject [ 
	^ objects keyAtValue: anObject
]

{ #category : #initialization }
SOTransaction >> initialize [ 
	super initialize.
	objects := Dictionary new
]

{ #category : #testing }
SOTransaction >> isRoot: anObject [
	^ objects includes: anObject
]

{ #category : #'as yet unclassified' }
SOTransaction >> makeRoot: anObject [ 
	objects at: 2 put: anObject
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
	m := (soil materializationWithId: 1 ifNone: [ nil ]).
	m objects do: [ :each | each soilLoadedIn: self ].
	^ m root
]

{ #category : #accessing }
SOTransaction >> root: anObject [
	objects at: 1 put: anObject
]

{ #category : #accessing }
SOTransaction >> soil: aSoil [ 
	soil := aSoil
]
