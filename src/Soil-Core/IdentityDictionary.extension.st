Extension { #name : #IdentityDictionary }

{ #category : #'*Soil-Core' }
IdentityDictionary >> soilBasicSerialize: serializer [
	self class == IdentityDictionary ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutIdentityDictionary: self
]
