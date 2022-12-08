Class {
	#name : #SOSkipList,
	#superclass : #Object,
	#instVars : [
		'maxLevel'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #private }
SOSkipList >> find: aString [ 
	^ (self findNode: aString)
		ifNotNil: [ :node | node value ]
]

{ #category : #private }
SOSkipList >> findNode: aString [ 
	| current right |
	current := self firstPage firstItem.
	
	maxLevel to: 1 by: -1 do: [ :level |
		[ (current hasRightAt: level) and: [ (right := (current rightAt: level) realNodeIn: self) keyIsSmallerThan: aString ] ]
			whileTrue: [ current := right ] .
		(current key = aString) ifTrue: [ ^ current ]. 

	].
	^ nil
]

{ #category : #initialization }
SOSkipList >> initialize [ 
	super initialize.

]

{ #category : #accessing }
SOSkipList >> maxLevel [
	^ maxLevel
]

{ #category : #accessing }
SOSkipList >> maxLevel: anInteger [ 
	maxLevel := anInteger 
]

{ #category : #'instance creation' }
SOSkipList >> newNode [ 
	^ SOSkipListNode new 
		level: self maxLevel 
]

{ #category : #'instance creation' }
SOSkipList >> newSentinelNode [ 
	^ SOSkipListSentinelNode new 
		level: self maxLevel 
]
