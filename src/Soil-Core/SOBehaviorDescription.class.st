Class {
	#name : #SOBehaviorDescription,
	#superclass : #Object,
	#instVars : [
		'name',
		'instVarNames',
		'behaviorIdentifier',
		'objectId'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SOBehaviorDescription class >> for: aClass [ 
	^ self new 
		initializeFromBehavior: aClass
]

{ #category : #'instance creation' }
SOBehaviorDescription class >> isSoilClusterRoot [ 
	^ true
]

{ #category : #combining }
SOBehaviorDescription class >> meta [ 
	^ self for: self
]

{ #category : #'as yet unclassified' }
SOBehaviorDescription class >> soilTransientInstVars [ 
	^ #( objectId ) 
]

{ #category : #'as yet unclassified' }
SOBehaviorDescription >> behaviorIdentifier [ 
	^ behaviorIdentifier 
]

{ #category : #initialization }
SOBehaviorDescription >> initializeFromBehavior: aClass [ 
	"class := aClass."
	behaviorIdentifier := aClass soilBehaviorIdentifier.
	
	instVarNames := aClass instVarNames
]

{ #category : #public }
SOBehaviorDescription >> instVarIndexes [
	| class |
	class := Smalltalk at: behaviorIdentifier asSymbol. 
	^ (class allInstVarNames difference: class soilTransientInstVars) 
		collect: [ :n | class allInstVarNames indexOf: n ]
]

{ #category : #accessing }
SOBehaviorDescription >> instVarNames [

	^ instVarNames
]

{ #category : #testing }
SOBehaviorDescription >> isCurrent [
	^ self isMeta 
		ifTrue: [ 
			self flag: #todo.
			"this assumption is only valid until SOBehaviorDescription changes 
			shape itselt. But this is unlikely to be handled automatically"
			true ]
		ifFalse: [ 
			self matchesBehavior: (Smalltalk at: behaviorIdentifier) ]
]

{ #category : #testing }
SOBehaviorDescription >> isMeta [ 
	^ behaviorIdentifier = self class name
]

{ #category : #testing }
SOBehaviorDescription >> matchesBehavior: aBehavior [
	^ self matchesDescription: (SOBehaviorDescription for: aBehavior)
]

{ #category : #testing }
SOBehaviorDescription >> matchesDescription: description [ 
	(behaviorIdentifier = description behaviorIdentifier) ifFalse: [ ^ false ].
	(instVarNames = description instVarNames) ifFalse: [ ^ false ].
	^ true
]

{ #category : #accessing }
SOBehaviorDescription >> name [

	^ name
]

{ #category : #accessing }
SOBehaviorDescription >> name: anObject [

	name := anObject.
]

{ #category : #accessing }
SOBehaviorDescription >> objectClass [
	^ Smalltalk at: behaviorIdentifier asSymbol
]

{ #category : #accessing }
SOBehaviorDescription >> objectId [
	^ objectId
]

{ #category : #accessing }
SOBehaviorDescription >> objectId: aSOObjectId [ 
	objectId := aSOObjectId
]
