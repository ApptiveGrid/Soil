Class {
	#name : #SOTestClassWithTransient,
	#superclass : #Object,
	#instVars : [
		'one',
		'two'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SOTestClassWithTransient class >> soilTransientInstVars [

	^ #(two)
]

{ #category : #accessing }
SOTestClassWithTransient >> one [

	^ one
]

{ #category : #accessing }
SOTestClassWithTransient >> one: anObject [

	one := anObject
]

{ #category : #accessing }
SOTestClassWithTransient >> two [

	^ two
]

{ #category : #accessing }
SOTestClassWithTransient >> two: anObject [

	two := anObject
]
