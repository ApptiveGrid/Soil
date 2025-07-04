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
		'indexIds',
		'position'
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

{ #category : #testing }
SoilClusterRecord >> asNewClusterVersion [
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
SoilClusterRecord >> basicAddReference: reference [
	references add: reference 
]

{ #category : #api }
SoilClusterRecord >> beChanged [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilClusterRecord >> behaviorDescriptionAt: anInteger [ 
	(anInteger = 0) ifTrue: [ ^ SoilBehaviorDescription meta ].
	^ behaviorDescriptions at: anInteger 
]

{ #category : #'queries - behaviors' }
SoilClusterRecord >> behaviorDescriptionWithObjectId: aSoilObjectId andVersion: anInteger [ 
	^ transaction behaviorDescriptionWithObjectId: aSoilObjectId andVersion: anInteger 
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

{ #category : #accessing }
SoilClusterRecord >> committed [ 
	committed := true
]

{ #category : #api }
SoilClusterRecord >> findReferencesTo [
	^ SoilReferenceFinder new
		soil: transaction database;
		find: objectId;
		records
]

{ #category : #testing }
SoilClusterRecord >> hasChanged [
	^ self subclassResponsibility
]

{ #category : #testing }
SoilClusterRecord >> hasPreviousVersion [
	^ previousVersionPosition > 0 
]

{ #category : #testing }
SoilClusterRecord >> includesReference: aSoilObjectId [ 
	^ references includes: aSoilObjectId 
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
SoilClusterRecord >> position: anInteger [ 
	position := anInteger
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

{ #category : #serializing }
SoilClusterRecord >> serializeOn: stream [
	bytes ifNil: [ self serializeObject ].
	stream 
		nextPutLengthEncodedInteger: version;
		nextPutLengthEncodedInteger: previousVersionPosition.
	"behavior description"
	stream nextPutLengthEncodedInteger: behaviorDescriptions size.
	behaviorDescriptions do: [ :behavior |
		stream 
			nextPutLengthEncodedInteger: behavior objectId index;
			nextPutLengthEncodedInteger: behavior version ].
	stream
		nextPutLengthEncodedInteger: references size.
	"references"
	references do: [ :ref |
		"do not write zero index, try to allocate a new index before"
		(ref index = 0) ifTrue: [ 
			Error signal: 'there should be no uninitialized reference' ].
		ref writeOn: stream ].
	"indexes"
	stream nextPutLengthEncodedInteger: indexIds size.
	indexIds do: [ :indexId |	
		stream 
			nextPut: indexId size;
			nextPutAll: indexId asByteArray].
	"objects in bytes"
	stream 
		nextPutLengthEncodedInteger: bytes size;
		nextPutAll: bytes .
]

{ #category : #testing }
SoilClusterRecord >> shouldBeCommitted [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilClusterRecord >> transaction [
	^ transaction
]

{ #category : #accessing }
SoilClusterRecord >> transaction: aSOTransaction [ 
	transaction := aSOTransaction 
]

{ #category : #testing }
SoilClusterRecord >> usesIndexId: aString [ 
	^ indexIds includes: aString
]

{ #category : #accessing }
SoilClusterRecord >> version [

	^ version
]

{ #category : #accessing }
SoilClusterRecord >> version: anInteger [ 
	version := anInteger 
]
