Class {
	#name : #SOProxy,
	#superclass : #Object,
	#instVars : [
		'id',
		'transaction'
	],
	#category : #'Soil-Core'
}

{ #category : #'reflective operations' }
SOProxy >> doesNotUnderstand: aMessage [ 
	| realObject |
	realObject := transaction 
		objectWithId: id 
		ifNone: [ Error signal: 'cannot load' ].
	^ aMessage sendTo: realObject
]

{ #category : #accessing }
SOProxy >> id: anInteger [ 
	id := anInteger
]

{ #category : #'as yet unclassified' }
SOProxy >> soilLoadedIn: aTransaction [ 
	transaction := aTransaction  
]
