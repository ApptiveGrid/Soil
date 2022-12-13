Class {
	#name : #SoilBehaviorRegistry,
	#superclass : #Object,
	#instVars : [
		'soil',
		'index'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #adding }
SoilBehaviorRegistry >> addSpecialObjects [
	self 
		nameAt: SOBehaviorDescription name 
		put: (SOObjectId segment: 1 index: 2)
]

{ #category : #accessing }
SoilBehaviorRegistry >> index [
	^ index ifNil: [ 
		index := self readIndex ]
]

{ #category : #initialization }
SoilBehaviorRegistry >> initializeFilesystem [
	self open.
	index initializeList
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier ifAbsent: aBlock [
	^ self index 
		at: classIdentifier 
		ifAbsent: aBlock
	
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier ifPresent: aBlock [
	^ self index 
		at: classIdentifier 
		ifPresent: aBlock
	
]

{ #category : #accessing }
SoilBehaviorRegistry >> nameAt: classIdentifier put: objectId [
	| dict |
	(objectId index = 0) ifTrue: [ Error signal: 'cannot add non-initialized object id' ].
	dict := self index 
		at: classIdentifier put: objectId;
		yourself.
	index writePages 
]

{ #category : #'instance creation' }
SoilBehaviorRegistry >> open [ 
	index ifNotNil: [ index close ].
	index :=  SOPersistentSkipList new 
		maxLevel: 16;
		path: self path
]

{ #category : #accessing }
SoilBehaviorRegistry >> path [
	^ soil path / #'behavior.registry'
]

{ #category : #accessing }
SoilBehaviorRegistry >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #writing }
SoilBehaviorRegistry >> writeIndex: dictionary [
	| stream serializer |
	stream := ByteArray new writeStream.
	serializer := soil newSerializer 
		stream: stream.
	serializer nextPutLengthEncodedInteger: dictionary size.
	dictionary keysAndValuesDo: [ :key :value |
		serializer basicNextPutSymbol: key.
		value soilRawSerialize: serializer ].  

	((self path / #index) ensureDelete; binaryWriteStream)
		nextPutAll: (stream flush; contents);
		flush;
		close
]
