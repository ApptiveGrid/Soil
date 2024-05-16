Extension { #name : #IdentityDictionary }

{ #category : #'*Soil-Serializer' }
IdentityDictionary >> soilBasicSerialize: serializer [
	self class == IdentityDictionary ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutIdentityDictionary: self
]
