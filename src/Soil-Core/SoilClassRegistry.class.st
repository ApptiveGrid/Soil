Class {
	#name : #SoilClassRegistry,
	#superclass : #Object,
	#instVars : [
		'soil',
		'index'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SoilClassRegistry >> at: identifier put: objectId [
	| dict |
	(objectId index = 0) ifTrue: [ Error signal: 'cannot add non-initialized object id' ].
	dict := self index 
		at: identifier put: objectId;
		yourself.
	self writeIndex: dict
]

{ #category : #accessing }
SoilClassRegistry >> atClass: classIdentifier ifPresent: aBlock [
	^ self index 
		at: classIdentifier 
		ifPresent: aBlock
]

{ #category : #'as yet unclassified' }
SoilClassRegistry >> class: classIdentifier version: versionIdentifier transaction: transaction [ 
	| objectId |
	objectId := index at: classIdentifier.
	^ transaction objectWithId: objectId ifNone: [ self halt ]. 
			
]

{ #category : #public }
SoilClassRegistry >> classDescriptionFor: aClass [
	|  classDescription |
	self halt.
	index := self index.
	index
		at: aClass soilClassIdentifier
		ifPresent: [ :pos | ^ pos ].
	classDescription := SOClassDescription for: aClass.
	index 
		at: aClass soilClassIdentifier 
		put: classDescription.
	^ classDescription
]

{ #category : #accessing }
SoilClassRegistry >> index [
	| indexFile dictionary  materializer size |
	indexFile := self path / #index.
	indexFile exists
		ifTrue: [ 
			dictionary := Dictionary new.
			materializer := soil newMaterializer 
				stream: indexFile binaryReadStream.
			size := materializer nextLengthEncodedInteger.
			1 to: size do: [ :n | 
				dictionary 
					at: materializer nextSymbol
					put: (SOObjectId soilRawMaterialize: materializer) ] ]
		ifFalse: [ 
			dictionary := Dictionary new.
			self writeIndex: dictionary ].
	^ dictionary
]

{ #category : #accessing }
SoilClassRegistry >> path [
	^ (soil path / #'class-registry') ensureCreateDirectory  
]

{ #category : #accessing }
SoilClassRegistry >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #writing }
SoilClassRegistry >> writeIndex: dictionary [
	| stream serializer |
	stream := ByteArray new writeStream.
	serializer := SoilSerializer new 
		soil: soil;
		stream: stream.
	serializer nextPutLengthEncodedInteger: dictionary size.
	dictionary keysAndValuesDo: [ :key :value |
		serializer basicNextPutSymbol: key.
		value soilRawSerialize: serializer ].  

	((self path / #index) ensureDelete; binaryWriteStream)
		truncate;
		nextPutAll: (stream flush; contents);
		flush;
		close
]
