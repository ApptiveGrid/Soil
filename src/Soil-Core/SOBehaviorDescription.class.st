Class {
	#name : #SOBehaviorDescription,
	#superclass : #Object,
	#instVars : [
		'name',
		'instVarNames',
		'classIdentifier',
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
	^ classIdentifier 
]

{ #category : #initialization }
SOBehaviorDescription >> initializeFromBehavior: aClass [ 
	"class := aClass."
	classIdentifier := aClass soilClassIdentifier.
	
	instVarNames := aClass instVarNames
]

{ #category : #public }
SOBehaviorDescription >> instVarIndexes [
	| class |
	class := Smalltalk at: classIdentifier asSymbol. 
	^ (class allInstVarNames difference: class soilTransientInstVars) 
		collect: [ :n | class allInstVarNames indexOf: n ]
]

{ #category : #accessing }
SOBehaviorDescription >> instVarNames [

	^ instVarNames
]

{ #category : #testing }
SOBehaviorDescription >> isMeta [ 
	^ classIdentifier = self class name
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
	^ Smalltalk at: classIdentifier asSymbol
]

{ #category : #accessing }
SOBehaviorDescription >> objectId [
	^ objectId
]

{ #category : #accessing }
SOBehaviorDescription >> objectId: aSOObjectId [ 
	objectId := aSOObjectId
]