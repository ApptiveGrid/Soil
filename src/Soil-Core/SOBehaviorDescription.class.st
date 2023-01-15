Class {
	#name : #SOBehaviorDescription,
	#superclass : #Object,
	#instVars : [
		'name',
		'instVarNames',
		'behaviorIdentifier',
		'objectId',
		'classLayout'
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

{ #category : #combining }
SOBehaviorDescription class >> metaId [
	"the id of the class is alway 2 and pre-initialized to break recursion"
	^ SOObjectId segment: 0 index: 2
]

{ #category : #'as yet unclassified' }
SOBehaviorDescription class >> soilTransientInstVars [ 
	^ #( objectId ) 
]

{ #category : #accessing }
SOBehaviorDescription >> behaviorIdentifier [ 
	^ behaviorIdentifier 
]

{ #category : #accessing }
SOBehaviorDescription >> classLayout [
	^ classLayout
]

{ #category : #initialization }
SOBehaviorDescription >> initializeFromBehavior: aClass [
	behaviorIdentifier := aClass soilBehaviorIdentifier.
	"we record only the persistent ivar names, in order"
	instVarNames := aClass soilPersistentInstVars.
	"we record the Layout to be able to detect if the layout changed"
	classLayout := aClass classLayout class name
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
		ifFalse: [ | currentClass |
			currentClass := Smalltalk globals at: behaviorIdentifier.
			classLayout == currentClass classLayout class name and: [ self matchesBehavior: currentClass ] ]
]

{ #category : #testing }
SOBehaviorDescription >> isFixedLayout [
	^ classLayout == #FixedLayout
]

{ #category : #testing }
SOBehaviorDescription >> isMeta [
	^ behaviorIdentifier = self class name
]

{ #category : #testing }
SOBehaviorDescription >> isVariableLayout [
	^ classLayout == #VariableLayout
]

{ #category : #testing }
SOBehaviorDescription >> matchesBehavior: aBehavior [
	^ self matchesDescription: (self class for: aBehavior)
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

	name := anObject
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

{ #category : #references }
SOBehaviorDescription >> referenceIndexWithSerializer: aSerializer [

	^ self isMeta
		  ifTrue: [ 0 ]
		  ifFalse: [ aSerializer referenceIndexOf: self ]
]
