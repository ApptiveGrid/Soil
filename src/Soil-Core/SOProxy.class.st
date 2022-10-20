Class {
	#name : #SOProxy,
	#superclass : #Object,
	#instVars : [
		'transaction',
		'objectId'
	],
	#category : #'Soil-Core'
}

{ #category : #'reflective operations' }
SOProxy >> doesNotUnderstand: aMessage [ 
	| realObject |
	realObject := transaction 
		objectWithId: objectId 
		ifNone: [ Error signal: 'cannot load' ].
	^ aMessage sendTo: realObject
]

{ #category : #accessing }
SOProxy >> objectId [

	^ objectId
]

{ #category : #accessing }
SOProxy >> objectId: anObject [

	objectId := anObject
]

{ #category : #'as yet unclassified' }
SOProxy >> soilLoadedIn: aTransaction [ 
	transaction := aTransaction  
]

{ #category : #accessing }
SOProxy >> transaction: aTransaction [ 
	transaction := aTransaction 
]
