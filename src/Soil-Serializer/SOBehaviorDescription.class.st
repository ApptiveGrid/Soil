Class {
	#name : #SOBehaviorDescription,
	#superclass : #Object,
	#instVars : [
		'instVarNames',
		'behaviorIdentifier',
		'objectId',
		'classLayout',
		'version'
	],
	#category : #'Soil-Serializer'
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
	^ (self for: self) 
		beFirstVersion;
		objectId: self metaId
]

{ #category : #'as yet unclassified' }
SOBehaviorDescription class >> soilTransientInstVars [ 
	^ #( objectId ) 
]

{ #category : #'object creation' }
SOBehaviorDescription >> basicNew [
	^ self compatibilityCheckObject: self objectClass basicNew
]

{ #category : #'object creation' }
SOBehaviorDescription >> basicNew: size [
	^ self compatibilityCheckObject: (self objectClass basicNew: size)
]

{ #category : #accessing }
SOBehaviorDescription >> beFirstVersion [
	version := 1
]

{ #category : #accessing }
SOBehaviorDescription >> behaviorIdentifier [ 
	^ behaviorIdentifier 
]

{ #category : #accessing }
SOBehaviorDescription >> classLayout [
	^ classLayout
]

{ #category : #testing }
SOBehaviorDescription >> compatibilityCheck: aClassLayout [

	"we can read if the layout is the same"
	classLayout == aClassLayout class name ifTrue: [ ^true ].
	"we support turning variable objects into fixed onces (and vice versa)"
	(self isVariableLayout and: [ aClassLayout isFixedLayout]) ifTrue: [ ^true ].
	(aClassLayout isVariable and: [ aClassLayout isBits not and: [self isFixedLayout]]) ifTrue: [ ^true ].
	"for now we raise errors for the others. We could instead create and empty object and log a warning"
	SOLayoutMigrationError signal: 'Incompatible layout detected: trying to read a ', classLayout , ' current code uses ', aClassLayout class name asString
]

{ #category : #testing }
SOBehaviorDescription >> compatibilityCheckObject: anObject [

	self compatibilityCheck: anObject class classLayout.
	^anObject
]

{ #category : #'as yet unclassified' }
SOBehaviorDescription >> incrementVersion [ 
	version := version + 1
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
	"WeakLayout and EphemeronLayout answer implement isVariable, too"

	^ classLayout == #VariableLayout or: [
		  classLayout == #WeakLayout or: [ classLayout == #EphemeronLayout ] ]
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

{ #category : #'object creation' }
SOBehaviorDescription >> newObjectWith: aSerializer [
	^ self objectClass classLayout soilBasicMaterialize: self with: aSerializer
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

{ #category : #printing }
SOBehaviorDescription >> printOn: aStream [ 
	aStream << 'behavior: ' << behaviorIdentifier asString
]

{ #category : #accessing }
SOBehaviorDescription >> version [
	^ version
]

{ #category : #accessing }
SOBehaviorDescription >> version: anObject [

	version := anObject
]
