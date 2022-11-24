Class {
	#name : #SOClassDescription,
	#superclass : #Object,
	#instVars : [
		'class',
		'name',
		'instVarNames',
		'classIdentifier',
		'versionIdentifier'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
SOClassDescription class >> for: aClass [ 
	^ self new 
		initializeFromClass: aClass
]

{ #category : #'as yet unclassified' }
SOClassDescription >> classIdentifier [ 
	^ classIdentifier ifNil: [ 
		classIdentifier := class soilClassIdentifier  ]
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
	^ (Smalltalk at: classIdentifier asSymbol) allInstVarNames collect: [ :n | (Smalltalk at: classIdentifier asSymbol) allInstVarNames indexOf: n ]
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
	class := Smalltalk at: name asSymbol 
]

{ #category : #accessing }
SOClassDescription >> objectClass [
	^ Smalltalk at: classIdentifier asSymbol
]

{ #category : #'as yet unclassified' }
SOClassDescription >> versionIdentifier [ 
	^ versionIdentifier ifNil: [ 
		versionIdentifier := class soilVersionIdentifier  ]
]

{ #category : #accessing }
SOClassDescription >> versionIdentifier: anObject [

	versionIdentifier := anObject
]
