Class {
	#name : #SOClassDescription,
	#superclass : #Object,
	#instVars : [
		'name',
		'instVarNames',
		'classIdentifier',
		'objectId'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
SOClassDescription class >> for: aClass [ 
	^ self new 
		initializeFromClass: aClass
]

{ #category : #'as yet unclassified' }
SOClassDescription class >> soilTransientInstVars [ 
	^ #( objectId ) 
]

{ #category : #'as yet unclassified' }
SOClassDescription >> classIdentifier [ 
	^ classIdentifier 
]

{ #category : #initialization }
SOClassDescription >> initializeFromClass: aClass [ 
	"class := aClass."
	classIdentifier := aClass soilClassIdentifier.
	
	instVarNames := aClass instVarNames
]

{ #category : #public }
SOClassDescription >> instVarIndexes [
	| class |
	class := Smalltalk at: classIdentifier asSymbol. 
	^ (class allInstVarNames difference: class soilTransientInstVars) 
		collect: [ :n | class allInstVarNames indexOf: n ]
]

{ #category : #accessing }
SOClassDescription >> instVarNames [

	^ instVarNames
]

{ #category : #accessing }
SOClassDescription >> name [

	^ name
]

{ #category : #accessing }
SOClassDescription >> name: anObject [

	name := anObject.
]

{ #category : #accessing }
SOClassDescription >> objectClass [
	^ Smalltalk at: classIdentifier asSymbol
]

{ #category : #accessing }
SOClassDescription >> objectId [
	^ objectId
]

{ #category : #accessing }
SOClassDescription >> objectId: aSOObjectId [ 
	objectId := aSOObjectId
]
