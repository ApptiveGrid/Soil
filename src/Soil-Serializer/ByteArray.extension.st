Extension { #name : 'ByteArray' }

{ #category : '*Soil-Serializer' }
ByteArray >> soilBasicSerialize: serializer [
	self class == ByteArray ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutByteArray: self
]

{ #category : '*Soil-Serializer' }
ByteArray >> soilMaterialize [
	| stream registry a |
	stream := self readStream.
	registry := SoilStandaloneObjectRegistry readFrom: stream.
	^ SoilMaterializer new 
		externalObjectRegistry: registry;
		materializeFromBytes: stream upToEnd
]

{ #category : '*Soil-Serializer' }
ByteArray class >> soilMaterialize: deserializer [

	^ deserializer nextByteArray: self
]
