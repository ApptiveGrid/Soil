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

{ #category : #serialization }
SOProxy >> fuelAfterMaterialization [ 
	| record |
	record := SOCurrentRecord value.
	id := record references at: id.
	transaction := record transaction.

]

{ #category : #serialization }
SOProxy >> fuelAfterMaterialization: aMaterialization [
	| record |
	record := aMaterialization record.
	id := record references at: id.
	transaction := record transaction.

]

{ #category : #accessing }
SOProxy >> id: anInteger [ 
	id := anInteger
]

{ #category : #'as yet unclassified' }
SOProxy >> soilLoadedIn: aTransaction [ 
	transaction := aTransaction  
]
