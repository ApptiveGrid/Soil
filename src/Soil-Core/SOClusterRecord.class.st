Class {
	#name : #SOClusterRecord,
	#superclass : #Object,
	#instVars : [
		'object',
		'transaction',
		'objectId',
		'references',
		'bytes',
		'committed',
		'previousVersionPosition'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SOClusterRecord class >> readFrom: aStream [
	^ self new 
		readFrom: aStream
]

{ #category : #'instance creation' }
SOClusterRecord >> addReference: reference [
	references detect: [ :each | each = reference ] ifFound: [ self halt ].
	references add: reference 
]

{ #category : #'as yet unclassified' }
SOClusterRecord >> assignObjectIds: aSOObjectRepository [ 
	references do: [ :reference |
		reference initializeIndex: aSOObjectRepository ]
]

{ #category : #accessing }
SOClusterRecord >> bytes [
	^ bytes
]

{ #category : #accessing }
SOClusterRecord >> bytes: anObject [

	bytes := anObject
]

{ #category : #asserting }
SOClusterRecord >> committed [ 
	committed := true
]

{ #category : #initialization }
SOClusterRecord >> initialize [ 
	super initialize.
	references := OrderedCollection new.
	committed := false.
	previousVersionPosition := 0.

]

{ #category : #accessing }
SOClusterRecord >> object [
	^ object
]

{ #category : #accessing }
SOClusterRecord >> object: anObject [
	object := anObject
]

{ #category : #accessing }
SOClusterRecord >> objectId [
	^ objectId
]

{ #category : #accessing }
SOClusterRecord >> objectId: aSOObjectId [ 
	
	objectId := aSOObjectId 
]

{ #category : #accessing }
SOClusterRecord >> previousVersionPosition: anInteger [ 
	previousVersionPosition := anInteger 
]

{ #category : #printing }
SOClusterRecord >> printOn: aStream [ 
	self subclassResponsibility 
]

{ #category : #accessing }
SOClusterRecord >> referenceAt: anInteger [ 
	(references at: anInteger) ifNil: [ self halt ]. 
	^ SOObjectProxy new 
		objectId: (references at: anInteger);
		transaction: transaction;
		yourself 
]

{ #category : #accessing }
SOClusterRecord >> references [
	^ references
]

{ #category : #accessing }
SOClusterRecord >> transaction [
	^ transaction
]

{ #category : #accessing }
SOClusterRecord >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]
