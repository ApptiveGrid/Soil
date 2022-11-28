Class {
	#name : #SOClassDescription,
	#superclass : #Object,
	#instVars : [
		'name',
		'instVarNames',
		'classIdentifier',
		'versionIdentifier',
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
SOClassDescription class >> soilPersistentInstVars [
	^ self instVarNames difference: self soilTransientInstVars 
]

{ #category : #'as yet unclassified' }
SOClassDescription class >> soilTransientInstVars [ 
	^ #( objectId ) 
]

{ #category : #'as yet unclassified' }
SOClassDescription >> classIdentifier [ 
	^ classIdentifier 
]

{ #category : #accessing }
SOClassDescription >> classIdentifier: anObject [

	classIdentifier := anObject
]

{ #category : #initialization }
SOClassDescription >> initializeFromClass: aClass [ 
	"class := aClass."
	classIdentifier := aClass soilClassIdentifier.
	versionIdentifier := aClass soilVersionIdentifier.
	
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
SOClassDescription >> instVarNames: anObject [

	instVarNames := anObject
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

{ #category : #'as yet unclassified' }
SOClassDescription >> versionIdentifier [ 
	^ versionIdentifier
]

{ #category : #accessing }
SOClassDescription >> versionIdentifier: anObject [

	versionIdentifier := anObject
]
