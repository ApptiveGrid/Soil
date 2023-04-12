"
Example class where one ivar is tagged as transient, see class side method #soilTransientInstVars
"
Class {
	#name : #SoilTestClassWithTransient,
	#superclass : #Object,
	#instVars : [
		'one',
		'two',
		'three'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #accessing }
SoilTestClassWithTransient class >> soilTransientInstVars [

	^ #(two)
]

{ #category : #accessing }
SoilTestClassWithTransient >> one [

	^ one
]

{ #category : #accessing }
SoilTestClassWithTransient >> one: anObject [

	one := anObject
]

{ #category : #accessing }
SoilTestClassWithTransient >> three [

	^ three
]

{ #category : #accessing }
SoilTestClassWithTransient >> three: anObject [

	three := anObject
]

{ #category : #accessing }
SoilTestClassWithTransient >> two [

	^ two
]

{ #category : #accessing }
SoilTestClassWithTransient >> two: anObject [

	two := anObject
]
