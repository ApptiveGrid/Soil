Extension { #name : #ByteArray }

{ #category : #'*Soil-Core' }
ByteArray >> asSkipListKeyOfSize: anInteger [ 
	^ self asByteArrayOfSize: anInteger 
]

{ #category : #'*Soil-Core' }
ByteArray >> soilBasicSerialize: serializer [
	self class == ByteArray ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutByteArray: self
]

{ #category : #'*Soil-Core' }
ByteArray class >> soilMaterialize: deserializer [

	^ deserializer nextByteArray: self
]
