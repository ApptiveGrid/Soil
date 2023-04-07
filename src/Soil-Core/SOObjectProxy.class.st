Class {
	#name : #SOObjectProxy,
	#superclass : #ProtoObject,
	#instVars : [
		'transaction',
		'objectId',
		'object'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'as yet unclassified' }
SOObjectProxy class >> forId: objectId transaction: transaction [
	^ self new
		objectId: objectId;
		transaction: transaction
		"do not call #yourself as this would return the proxied object"
]

{ #category : #'reflective operations' }
SOObjectProxy >> doesNotUnderstand: aMessage [ 
	^ aMessage sendTo: self object
]

{ #category : #inspector }
SOObjectProxy >> inspectionObject [
	<inspectorPresentationOrder: 30 title: 'object'>
	^ StRawInspection on: self object

]

{ #category : #testing }
SOObjectProxy >> isSoilProxy [ 
	^ true
]

{ #category : #'reflective operations' }
SOObjectProxy >> object [
	^ object ifNil: [  
		object := transaction objectWithId: objectId ]
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
SOObjectProxy >> objectIsNotLoaded [ 
	^ object isNil
]

{ #category : #printing }
SOObjectProxy >> printOn: aStream [ 
	aStream << 'proxy ' << objectId asString.
	object ifNotNil: [ 
		aStream <<  ': '.
		object printOn: aStream ]
]

{ #category : #printing }
SOObjectProxy >> printString [ 
	^ String streamContents: [ :s | self printOn: s ] limitedTo: 1000 
]

{ #category : #'as yet unclassified' }
SOObjectProxy >> soilLoadedIn: aTransaction [ 
	transaction := aTransaction  
]

{ #category : #'as yet unclassified' }
SOObjectProxy >> soilSerialize: aSerializer [ 
	^ self object soilSerialize: aSerializer 
]

{ #category : #'as yet unclassified' }
SOObjectProxy >> theNonSoilProxy [ 
	^ self object
]

{ #category : #accessing }
SOObjectProxy >> transaction: aTransaction [ 
	transaction := aTransaction 
]
