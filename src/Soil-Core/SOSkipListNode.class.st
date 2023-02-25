Class {
	#name : #SOSkipListNode,
	#superclass : #Object,
	#instVars : [
		'key',
		'value',
		'levels',
		'page'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SOSkipListNode >> hasRightAt: anInteger [ 
	^ (levels at: anInteger) notNil 
]

{ #category : #accessing }
SOSkipListNode >> key [
	^ key
]

{ #category : #accessing }
SOSkipListNode >> key: aString [ 
	key := aString
]

{ #category : #'as yet unclassified' }
SOSkipListNode >> keyIsSmallerThan: aString [ 
	^ key asInteger <= aString asInteger
]

{ #category : #accessing }
SOSkipListNode >> level: anInteger [
	levels := Array new: anInteger 
]

{ #category : #accessing }
SOSkipListNode >> levels [
	^ levels
]

{ #category : #enumerating }
SOSkipListNode >> linearDo: aBlock [ 
	aBlock value: self.
	(self rightAt: 1) ifNotNil: [:node | node linearDo: aBlock ]
]

{ #category : #accessing }
SOSkipListNode >> page: aSkipFilePage [ 
	page := aSkipFilePage 
]

{ #category : #accessing }
SOSkipListNode >> pageIndex [
	^ page itemIndexOf: self 
]

{ #category : #accessing }
SOSkipListNode >> pageNumber [
	^ page pageNumber
]

{ #category : #printing }
SOSkipListNode >> printOn: aStream [ 
	aStream << 'key: ' << key asString 
]

{ #category : #'as yet unclassified' }
SOSkipListNode >> realNodeIn: aPersistedSkipList [ 
	^ self
]

{ #category : #accessing }
SOSkipListNode >> right: aSkipNode [ 
self halt.
	1 to: levels size do: [ :n |
		levels at: n put: aSkipNode  ]
]

{ #category : #accessing }
SOSkipListNode >> rightAt: anInteger [ 
	^ levels at: anInteger 
]

{ #category : #accessing }
SOSkipListNode >> rightAt: anInteger put: aSkipNode [ 
	(aSkipNode isKindOf: SOSkipListNodeProxy) ifTrue: [ self halt ].
	levels at: anInteger put: aSkipNode
]

{ #category : #accessing }
SOSkipListNode >> value [
	^ value 
]

{ #category : #accessing }
SOSkipListNode >> value: aString [ 
	value := aString
]

{ #category : #writing }
SOSkipListNode >> writeOn: aStream [ 
self halt.
	aStream  
		nextPutAll: (key asByteArrayOfSize: 8);
		nextPutAll: (value asByteArrayOfSize: 8).
	levels do: [ :level |
		aStream nextPut: 1 ]
]
