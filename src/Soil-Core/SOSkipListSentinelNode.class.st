Class {
	#name : #SOSkipListSentinelNode,
	#superclass : #SOSkipListNode,
	#instVars : [
		'lowerBound'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'as yet unclassified' }
SOSkipListSentinelNode >> beLower [ 
	lowerBound := true
]

{ #category : #'as yet unclassified' }
SOSkipListSentinelNode >> beUpper [
	lowerBound := false
]

{ #category : #accessing }
SOSkipListSentinelNode >> key [ 
	^ lowerBound 
		ifTrue: [  0 asByteArrayOfSize: 8 ]
		ifFalse: [ ((2 raisedTo: 64) - 1) asByteArrayOfSize: 8  ]
]

{ #category : #'as yet unclassified' }
SOSkipListSentinelNode >> keyIsGreaterThan: aString [ 
	^ lowerBound not
]

{ #category : #'as yet unclassified' }
SOSkipListSentinelNode >> keyIsSmallerThan: aString [ 
	^ lowerBound 
]

{ #category : #printing }
SOSkipListSentinelNode >> printOn: aStream [ 
	aStream << (lowerBound ifTrue: [ 'lower bound' ] ifFalse: [ 'upper bound' ] )
]

{ #category : #'as yet unclassified' }
SOSkipListSentinelNode >> realNodeIn: aPersistedSkipList [ 
	^ self
]

{ #category : #accessing }
SOSkipListSentinelNode >> value [ 
	^ 0 
]
