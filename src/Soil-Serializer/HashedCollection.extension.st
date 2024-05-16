Extension { #name : 'HashedCollection' }

{ #category : '*Soil-Serializer' }
HashedCollection >> soilMaterialized: materialized [
	super soilMaterialized: materialized.
	"We have to re-hash, as the elements are newly de-serialized objects.
	If the #hash is using #identityHash, we might not find it anymore"
	^ self rehash 
]
