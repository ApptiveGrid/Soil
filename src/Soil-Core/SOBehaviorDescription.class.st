Class {
	#name : #SOBehaviorDescription,
	#superclass : #Object,
	#instVars : [
		'name',
		'instVarNames',
		'objectId',
		'behaviorIdentifier'
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
SOBehaviorDescription >> initializeFromBehavior: aBehavior [ 
	"class := aClass."
	behaviorIdentifier := aBehavior soilBehaviorIdentifier.
	
	instVarNames := aBehavior instVarNames
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
SOBehaviorDescription >> isMeta [ 
	^ behaviorIdentifier = self class name
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
