Class {
	#name : #SOMapper,
	#superclass : #FLLightGeneralMapper,
	#category : #'Soil-Core'
}

{ #category : #testing }
SOMapper >> isRoot: anObject [
	^ anObject class name endsWith: 'B'
]

{ #category : #mapping }
SOMapper >> mapAndTrace: anObject [
	((anObject = (analysis instVarNamed: #root)) not and: [ self isRoot: anObject ])
		ifTrue: [ self visitSubstitution: anObject by: (self proxyFor: self)  ]
		ifFalse: [ anObject fuelAccept: self ]
]

{ #category : #'as yet unclassified' }
SOMapper >> proxyFor: anObject [ 
	^ SOProxy new name: anObject class name 
]
