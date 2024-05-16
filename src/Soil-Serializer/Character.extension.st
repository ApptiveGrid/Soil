Extension { #name : #Character }

{ #category : #'*Soil-Serializer' }
Character >> soilBasicSerialize: serializer [ 
	self class == Character ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutCharacter: self
]

{ #category : #'*Soil-Serializer' }
Character class >> soilMaterialize: materializer [ 
	^ materializer nextCharacter
]

{ #category : #'*Soil-Serializer' }
Character >> soilSerialize: serializer [ 
	"Immediate object, no registration needed"
	self soilBasicSerialize: serializer
]
