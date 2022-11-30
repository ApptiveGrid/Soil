Class {
	#name : #SkipNode,
	#superclass : #Object,
	#instVars : [
		'key',
		'value',
		'right',
		'below',
		'levels'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SkipNode >> hasRightAt: anInteger [ 
	^ (levels at: anInteger) notNil 
]

{ #category : #accessing }
SkipNode >> key [
	^ key
]

{ #category : #accessing }
SkipNode >> key: aString [ 
	key := aString
]

{ #category : #'as yet unclassified' }
SkipNode >> keyIsSmallerThan: aString [ 
	^ (key compare: aString) <= 2
]

{ #category : #accessing }
SkipNode >> level: anInteger [
	levels := Array new: anInteger 
]

{ #category : #enumerating }
SkipNode >> linearDo: aBlock [ 
	aBlock value: self.
	(self rightAt: 1) ifNotNil: [:node | node linearDo: aBlock ]
]

{ #category : #printing }
SkipNode >> printOn: aStream [ 
	aStream << 'key: ' << key asString 
]

{ #category : #accessing }
SkipNode >> right: aSkipNode [ 
	1 to: levels size do: [ :n |
		levels at: n put: aSkipNode  ]
]

{ #category : #accessing }
SkipNode >> rightAt: anInteger [ 
	^ levels at: anInteger 
]

{ #category : #accessing }
SkipNode >> rightAt: anInteger put: aSkipNode [ 
	levels at: anInteger put: aSkipNode
]

{ #category : #accessing }
SkipNode >> value [
	^ value 
]

{ #category : #accessing }
SkipNode >> value: aString [ 
	value := aString
]
