"
Example class where one ivar is tagged as transient, see class side method #soilTransientInstVars
"
Class {
	#name : #SOTestClassWithTransient,
	#superclass : #Object,
	#instVars : [
		'one',
		'two',
		'three'
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
SOTestClassWithTransient >> three [

	^ three
]

{ #category : #accessing }
SOTestClassWithTransient >> three: anObject [

	three := anObject
]

{ #category : #accessing }
SOTestClassWithTransient >> two [

	^ two
]

{ #category : #accessing }
SOTestClassWithTransient >> two: anObject [

	two := anObject
]
