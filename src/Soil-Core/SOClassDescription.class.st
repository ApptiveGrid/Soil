Class {
	#name : #SOClassDescription,
	#superclass : #Object,
	#instVars : [
		'class',
		'name',
		'instVarNames'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
SOClassDescription class >> for: aClass [ 
	^ self new 
		initializeFromClass: aClass
]

{ #category : #'as yet unclassified' }
SOClassDescription >> classId [
	^ 1
]

{ #category : #initialization }
SOClassDescription >> initializeFromClass: aClass [ 
	class := aClass.
	name := aClass name.
	instVarNames := aClass instVarNames
]

{ #category : #public }
SOClassDescription >> instVarIndexes [
	^ class allInstVarNames collect: [ :n | class allInstVarNames indexOf: n ]
]

{ #category : #testing }
SOClassDescription >> isBits [
	^ class isBits 
]

{ #category : #testing }
SOClassDescription >> isBytes [
	^ class isBytes 
]

{ #category : #testing }
SOClassDescription >> isVariable [
	^ class isVariable 
]

{ #category : #accessing }
SOClassDescription >> name [

	^ name
]

{ #category : #accessing }
SOClassDescription >> name: anObject [

	name := anObject
]
