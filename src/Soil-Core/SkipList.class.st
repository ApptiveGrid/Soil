Class {
	#name : #SkipList,
	#superclass : #Object,
	#instVars : [
		'levels',
		'maxLevel',
		'nodes'
	],
	#category : #'Soil-Core'
}

{ #category : #helpers }
SkipList >> allNodes [
	| n |
	n := OrderedCollection new.
	nodes first linearDo: [ :each | n add: each ].
	^ n
]

{ #category : #accessing }
SkipList >> at: key put: anObject [
		| current levelNodes raise level newNode random |
	current := nodes first.
	levelNodes := Array new: maxLevel.
	random := Random seed: Time microsecondClockValue.
	
	maxLevel to: 1 by: -1 do: [ :lvl |
		[ (current hasRightAt: lvl) and: [ (current rightAt: lvl) keyIsSmallerThan: key ] ]
			whileTrue: [ current := current rightAt: lvl ] .
		levelNodes at: lvl put: current
	].
	raise := true.
	level := 1.
	newNode := self newNode.
	newNode 
		key: key;
		value: anObject.
	[ (level <= maxLevel) & (raise = true) ] whileTrue: [ 
		newNode rightAt: level  put: ((levelNodes at: level) rightAt: level).
		(levelNodes at: level) rightAt: level put: newNode.
		level := level + 1.
		raise := random next > 0.5 ].
	 ^ nil
]

{ #category : #private }
SkipList >> find: aString [ 
	^ (self findNode: aString)
		ifNotNil: [ :node | node value ]
]

{ #category : #private }
SkipList >> findNode: aString [ 
	| current |
	current := nodes first.
	
	maxLevel to: 1 by: -1 do: [ :level |
		[ (current hasRightAt: level) and: [ (current rightAt: level) keyIsSmallerThan: aString ] ]
			whileTrue: [ current := current rightAt: level ] .
		(current key = aString) ifTrue: [ ^ current ]. 

	].
	^ nil
]

{ #category : #initialization }
SkipList >> initialize [ 
	super initialize.
	nodes := OrderedCollection new.

]

{ #category : #initialization }
SkipList >> initializeNodes [
	| lower upper |
	lower := self newSentinelNode beLower.
	nodes addFirst: lower.
	upper := self newSentinelNode beUpper.
	nodes addLast: upper.
	lower right: upper
]

{ #category : #accessing }
SkipList >> maxLevel [
	^ maxLevel
]

{ #category : #accessing }
SkipList >> maxLevel: anInteger [ 
	maxLevel := anInteger 
]

{ #category : #'instance creation' }
SkipList >> newNode [ 
	^ SkipNode new 
		level: self maxLevel 
]

{ #category : #'instance creation' }
SkipList >> newSentinelNode [ 
	^ SkipSentinelNode new 
		level: self maxLevel 
]
