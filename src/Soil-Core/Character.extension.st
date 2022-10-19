Extension { #name : #Character }

{ #category : #'*Soil-Core' }
Character >> soilBasicSerialize: serializer [ 
	self class == Character ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutCharacter: self
]

{ #category : #'*Soil-Core' }
Character class >> soilMaterialize: materializer [ 
	^ materializer nextCharacter
]

{ #category : #'*Soil-Core' }
Character >> soilSerialize: serializer [ 
	"Immediate object, no registration needed"
	self soilBasicSerialize: serializer
]
