Class {
	#name : #SoilClassRegistry,
	#superclass : #Object,
	#instVars : [
		'soil',
		'index'
	],
	#category : #'Soil-Core'
}

{ #category : #adding }
SoilClassRegistry >> addSpecialObjects [
	self 
		nameAt: SOClassDescription name 
		put: (SOObjectId segment: 1 index: 2)
]

{ #category : #accessing }
SoilClassRegistry >> index [
	^ index ifNil: [ 
		index := self readIndex ]
]

{ #category : #initialization }
SoilClassRegistry >> initializeFilesystem [
	self path ensureCreateDirectory.
	(self path / #index) binaryWriteStream 
		nextPutAll: #[ 0 ];
		flush;
		close
]

{ #category : #accessing }
SoilClassRegistry >> nameAt: classIdentifier ifAbsent: aBlock [
	^ self index 
		at: classIdentifier 
		ifAbsent: aBlock
	
]

{ #category : #accessing }
SoilClassRegistry >> nameAt: classIdentifier ifPresent: aBlock [
	^ self index 
		at: classIdentifier 
		ifPresent: aBlock
	
]

{ #category : #accessing }
SoilClassRegistry >> nameAt: classIdentifier put: objectId [
	| dict |
	(objectId index = 0) ifTrue: [ Error signal: 'cannot add non-initialized object id' ].
	dict := self index 
		at: classIdentifier put: objectId;
		yourself.
	self writeIndex: dict		
]

{ #category : #accessing }
SoilClassRegistry >> path [
	^ soil path / #'class-registry'
]

{ #category : #accessing }
SoilClassRegistry >> readIndex [
	| indexFile dictionary  materializer size |
	indexFile := self path / #index.
	dictionary := Dictionary new.
	materializer := soil newMaterializer 
		stream: indexFile binaryReadStream.
	size := materializer nextLengthEncodedInteger.
	1 to: size do: [ :n | 
		dictionary 
			at: materializer nextSymbol
			put: (SOObjectId soilRawMaterialize: materializer) ].
	^ dictionary
]

{ #category : #accessing }
SoilClassRegistry >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #writing }
SoilClassRegistry >> writeIndex: dictionary [
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
