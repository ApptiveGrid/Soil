Class {
	#name : #SoilClusterRecord,
	#superclass : #Object,
	#instVars : [
		'object',
		'transaction',
		'objectId',
		'references',
		'bytes',
		'committed',
		'previousVersionPosition',
		'version',
		'behaviorDescriptions'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SoilClusterRecord class >> readFrom: aStream [
	^ self new 
		readFrom: aStream
]

{ #category : #'instance creation' }
SoilClusterRecord >> addReference: reference [
	references detect: [ :each | each = reference ] ifFound: [ Error signal: 'reference already there' ].
	references add: reference 
]

{ #category : #accessing }
SoilClusterRecord >> behaviorDescriptionAt: anInteger [ 
	^ behaviorDescriptions at: anInteger 
]

{ #category : #accessing }
SoilClusterRecord >> bytes [
	^ bytes
]

{ #category : #accessing }
SoilClusterRecord >> bytes: anObject [

	bytes := anObject
]

{ #category : #asserting }
SoilClusterRecord >> committed [ 
	committed := true
]

{ #category : #testing }
SoilClusterRecord >> hasPreviousVersion [
	^ previousVersionPosition > 0 
]

{ #category : #initialization }
SoilClusterRecord >> initialize [ 
	super initialize.
	behaviorDescriptions := OrderedCollection new.
	references := OrderedCollection new.
	committed := false.
	previousVersionPosition := 0.

]

{ #category : #accessing }
SoilClusterRecord >> object [
	^ object
]

{ #category : #accessing }
SoilClusterRecord >> object: anObject [
	object := anObject
]

{ #category : #accessing }
SoilClusterRecord >> objectId [
	^ objectId
]

{ #category : #accessing }
SoilClusterRecord >> objectId: aSOObjectId [ 
	
	objectId := aSOObjectId 
]

{ #category : #accessing }
SoilClusterRecord >> previousVersionPosition [

	^ previousVersionPosition
]

{ #category : #accessing }
SoilClusterRecord >> previousVersionPosition: anInteger [ 
	previousVersionPosition := anInteger 
]

{ #category : #printing }
SoilClusterRecord >> printOn: aStream [ 
	self subclassResponsibility 
]

{ #category : #accessing }
SoilClusterRecord >> referenceAt: anInteger [
	(references at: anInteger) ifNil: [ Error signal: 'reference at ', anInteger ,' not found' ].
	^ SoilObjectProxy 
		forId: (references at: anInteger) 
		transaction: transaction
]

{ #category : #accessing }
SoilClusterRecord >> references [
	^ references
]

{ #category : #accessing }
SoilClusterRecord >> transaction [
	^ transaction
]

{ #category : #accessing }
SoilClusterRecord >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]

{ #category : #accessing }
SoilClusterRecord >> version [

	^ version
]

{ #category : #accessing }
SoilClusterRecord >> version: anInteger [ 
	version := anInteger 
]
