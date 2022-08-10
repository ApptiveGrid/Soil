Class {
	#name : #SOMapper,
	#superclass : #FLLightGeneralMapper,
	#instVars : [
		'transaction'
	],
	#category : #'Soil-Core'
}

{ #category : #testing }
SOMapper >> isRoot: anObject [
	^ transaction isRoot: anObject
]

{ #category : #mapping }
SOMapper >> mapAndTrace: anObject [
	((anObject = (analysis instVarNamed: #root)) not and: [ self isRoot: anObject ])
		ifTrue: [ self visitSubstitution: anObject by: (self proxyFor: anObject)  ]
		ifFalse: [ anObject fuelAccept: self ]
]

{ #category : #'as yet unclassified' }
SOMapper >> proxyFor: anObject [ 
	^ SOProxy new id: (transaction idOf: anObject) 
]

{ #category : #accessing }
SOMapper >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]
