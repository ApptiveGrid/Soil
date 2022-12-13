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

{ #category : #initialization }
SOSkipListSentinelNode >> initializeKeyOfSize: anInteger [ 
	key := lowerBound 
		ifTrue: [ 0 asByteArrayOfSize: anInteger ]
		ifFalse: [ ((2 raisedTo: (anInteger * 8)) - 1) asByteArrayOfSize: anInteger  ]
]

{ #category : #'as yet unclassified' }
SOSkipListSentinelNode >> keyIsSmallerThan: aString [ 
	^ lowerBound 
]

{ #category : #printing }
SOSkipListSentinelNode >> printOn: aStream [ 
	aStream << (lowerBound ifTrue: [ 'lower bound' ] ifFalse: [ 'upper bound' ] )
]

{ #category : #accessing }
SOSkipListSentinelNode >> value [ 
	^ 0 
]
