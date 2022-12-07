Class {
	#name : #SOObjectProxy,
	#superclass : #Object,
	#instVars : [
		'transaction',
		'objectId'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'reflective operations' }
SOObjectProxy >> doesNotUnderstand: aMessage [ 
	| realObject |
	realObject := transaction 
		objectWithId: objectId 
		ifNone: [ Error signal: 'cannot load' ].
	^ aMessage sendTo: realObject
]

{ #category : #accessing }
SOObjectProxy >> objectId [

	^ objectId
]

{ #category : #accessing }
SOObjectProxy >> objectId: anObject [

	objectId := anObject
]

{ #category : #'as yet unclassified' }
SOObjectProxy >> soilLoadedIn: aTransaction [ 
	transaction := aTransaction  
]

{ #category : #accessing }
SOObjectProxy >> transaction: aTransaction [ 
	transaction := aTransaction 
]
