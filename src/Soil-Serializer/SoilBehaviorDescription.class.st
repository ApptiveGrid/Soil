"
A SoilBehaviorDescription is a flat, versioned view of classes

- Flat, this means that it models the class with all instance variables of the superclasses (what #allInstVarNames returns)
- Names, not offsets. Soil reads and writes by name, it does not care about the offset of the instance Variable

Together, this allows us to read data from disk even though the code was changed (e.g. instance variable order, variables moved in the hierachy)


"
Class {
	#name : #SoilBehaviorDescription,
	#superclass : #Object,
	#instVars : [
		'instVarNames',
		'behaviorIdentifier',
		'objectId',
		'classLayout',
		'version',
		'objectClass'
	],
	#category : #'Soil-Serializer-Base'
}

{ #category : #'instance creation' }
SoilBehaviorDescription class >> for: aClass [ 
	^ self basicNew 
		initializeFromBehavior: aClass
]

{ #category : #'instance creation' }
SoilBehaviorDescription class >> isSoilClusterRoot [ 
	^ true
]

{ #category : #combining }
SoilBehaviorDescription class >> meta [
	^ (self for: self) 
		beFirstVersion;
		objectId: self metaId
]

{ #category : #accessing }
SoilBehaviorDescription class >> soilTransientInstVars [ 
	^ #( objectId objectClass ) 
]

{ #category : #converting }
SoilBehaviorDescription >> asSoilObjectId [
	^ objectId 
]

{ #category : #'object creation' }
SoilBehaviorDescription >> basicNew [
	^ self compatibilityCheckObject: self objectClass basicNew
]

{ #category : #'object creation' }
SoilBehaviorDescription >> basicNew: size [
	^ self compatibilityCheckObject: (self objectClass basicNew: size)
]

{ #category : #accessing }
SoilBehaviorDescription >> beFirstVersion [
	version := 1
]

{ #category : #accessing }
SoilBehaviorDescription >> behaviorIdentifier [ 
	^ behaviorIdentifier 
]

{ #category : #accessing }
SoilBehaviorDescription >> classLayout [
	^ classLayout
]

{ #category : #testing }
SoilBehaviorDescription >> compatibilityCheck: aClassLayout [

	"we can read if the layout is the same"
	classLayout == aClassLayout class name ifTrue: [ ^true ].
	"we support turning variable objects into fixed onces (and vice versa)"
	(self isVariableLayout and: [ aClassLayout isFixedLayout]) ifTrue: [ ^true ].
	(aClassLayout isVariable and: [ aClassLayout isBits not and: [self isFixedLayout]]) ifTrue: [ ^true ].
	"for now we raise errors for the others. We could instead create and empty object and log a warning"
	SoilLayoutMigrationError signal: 'Incompatible layout detected: trying to read a ', classLayout , ' current code uses ', aClassLayout class name asString
]

{ #category : #testing }
SoilBehaviorDescription >> compatibilityCheckObject: anObject [

	self compatibilityCheck: anObject class classLayout.
	^anObject
]

{ #category : #api }
SoilBehaviorDescription >> incrementVersion [ 
	version := version + 1
]

{ #category : #initialization }
SoilBehaviorDescription >> initializeFromBehavior: aClass [
	behaviorIdentifier := aClass soilBehaviorIdentifier.
	"we record only the persistent ivar names, in order"
	instVarNames := aClass soilPersistentInstVars.
	"we record the Layout to be able to detect if the layout changed"
	classLayout := aClass classLayout class name
]

{ #category : #accessing }
SoilBehaviorDescription >> instVarNames [

	^ instVarNames
]

{ #category : #testing }
SoilBehaviorDescription >> isCurrent [
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
SoilBehaviorDescription >> isFixedLayout [
	^ classLayout == #FixedLayout
]

{ #category : #testing }
SoilBehaviorDescription >> isMeta [
	^ behaviorIdentifier = self class name
]

{ #category : #testing }
SoilBehaviorDescription >> isVariableLayout [
	"WeakLayout and EphemeronLayout answer implement isVariable, too"

	^ classLayout == #VariableLayout or: [
		  classLayout == #WeakLayout or: [ classLayout == #EphemeronLayout ] ]
]

{ #category : #testing }
SoilBehaviorDescription >> matchesBehavior: aBehavior [
	^ self matchesDescription: (self class for: aBehavior)
]

{ #category : #testing }
SoilBehaviorDescription >> matchesDescription: description [
	(behaviorIdentifier = description behaviorIdentifier) ifFalse: [ ^ false ].
	(instVarNames = description instVarNames) ifFalse: [ ^ false ].
	^ true
]

{ #category : #'object creation' }
SoilBehaviorDescription >> newObjectWith: aSerializer [
	^ self objectClass classLayout soilBasicMaterialize: self with: aSerializer
]

{ #category : #accessing }
SoilBehaviorDescription >> objectClass [
	^ objectClass ifNil: [ 
		objectClass := Smalltalk at: behaviorIdentifier asSymbol ]
]

{ #category : #accessing }
SoilBehaviorDescription >> objectId [
	^ objectId
]

{ #category : #accessing }
SoilBehaviorDescription >> objectId: aSOObjectId [
	objectId := aSOObjectId
]

{ #category : #printing }
SoilBehaviorDescription >> printOn: aStream [ 
	aStream << 'behavior: ' << behaviorIdentifier asString
]

{ #category : #accessing }
SoilBehaviorDescription >> version [
	^ version
]

{ #category : #accessing }
SoilBehaviorDescription >> version: anObject [

	version := anObject
]
