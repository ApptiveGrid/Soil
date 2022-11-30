Class {
	#name : #SkipSentinelNode,
	#superclass : #SkipNode,
	#instVars : [
		'lowerBound'
	],
	#category : #'Soil-Core'
}

{ #category : #'as yet unclassified' }
SkipSentinelNode >> beLower [ 
	lowerBound := true
]

{ #category : #'as yet unclassified' }
SkipSentinelNode >> beUpper [
	lowerBound := false
]

{ #category : #'as yet unclassified' }
SkipSentinelNode >> keyIsGreaterThan: aString [ 
	^ lowerBound not
]

{ #category : #'as yet unclassified' }
SkipSentinelNode >> keyIsSmallerThan: aString [ 
	^ lowerBound 
]

{ #category : #printing }
SkipSentinelNode >> printOn: aStream [ 
	aStream << (lowerBound ifTrue: [ 'lower bound' ] ifFalse: [ 'upper bound' ] )
]
