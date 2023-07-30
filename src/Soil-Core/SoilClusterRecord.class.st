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
		'behaviorDescriptions',
		'indexIds'
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
	self basicAddReference: reference 
]

{ #category : #'instance creation' }
SoilClusterRecord >> basicAddReference: reference [
	references add: reference 
]

{ #category : #accessing }
SoilClusterRecord >> behaviorDescriptionAt: anInteger [ 
	(anInteger = 0) ifTrue: [ ^ SoilBehaviorDescription meta ].
	^ behaviorDescriptions at: anInteger 
]

{ #category : #accessing }
SoilClusterRecord >> behaviorDescriptions [
	^ behaviorDescriptions
]

{ #category : #accessing }
SoilClusterRecord >> behaviorDescriptions: aCollection [ 
	behaviorDescriptions := aCollection
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

{ #category : #accessing }
SoilClusterRecord >> indexAt: indexId [ 
	"resolve the index in the segment of the cluster root"
	^ (transaction segmentAt: objectId segment)
		indexAt: indexId
]

{ #category : #accessing }
SoilClusterRecord >> indexIds [
	^ indexIds
]

{ #category : #initialization }
SoilClusterRecord >> initialize [ 
	super initialize.
	behaviorDescriptions := OrderedCollection new.
	references := OrderedCollection new.
	indexIds := OrderedCollection new.
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
	^ references at: anInteger
]

{ #category : #accessing }
SoilClusterRecord >> references [
	^ references
]

{ #category : #accessing }
SoilClusterRecord >> references: aCollection [ 
	references := aCollection
]

{ #category : #accessing }
SoilClusterRecord >> registerIndexId: aString [ 
	(indexIds includes: aString) ifFalse: [ 
		indexIds add: aString ]
]

{ #category : #accessing }
SoilClusterRecord >> resetPreviousVersion [
	previousVersionPosition := 0

]

{ #category : #accessing }
SoilClusterRecord >> segment [
	^ objectId segment
]

{ #category : #serializing }
SoilClusterRecord >> serialize [
	^ ByteArray streamContents: [ :stream |
		self serializeOn: stream ]
				
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
