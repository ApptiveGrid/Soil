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

{ #category : #forwarded }
SOObjectProxy >> at: anObject [
 	^self object at: anObject
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
SOObjectProxy >> soilLoadedIn: aTransaction [ 
	transaction := aTransaction  
]

{ #category : #accessing }
SOObjectProxy >> transaction: aTransaction [ 
	transaction := aTransaction 
]
