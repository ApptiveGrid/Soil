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

{ #category : #accessing }
SOBehaviorDescription >> behaviorIdentifier [ 
	^ behaviorIdentifier 
]

{ #category : #initialization }
SOBehaviorDescription >> initializeFromBehavior: aClass [
	behaviorIdentifier := aClass soilBehaviorIdentifier.
	"we record only the persistent ivar names, in order"
	instVarNames := aClass soilPersistentInstVars
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
