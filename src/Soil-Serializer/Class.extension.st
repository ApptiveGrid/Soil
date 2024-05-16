Extension { #name : #Class }

{ #category : #'*Soil-Serializer' }
Class >> soilBasicSerialize: serializer [

	serializer nextPutClass: self
]

{ #category : #'*Soil-Serializer' }
Class >> soilBehaviorIdentifier [
	^ name 
]

{ #category : #'*Soil-Serializer' }
Class class >> soilMaterialize: materializer [

	^ materializer nextClass
]

{ #category : #'*Soil-Serializer' }
Class >> soilSerialize: serializer [
	"registration not needed, as we always return the current class on read"
	self soilBasicSerialize: serializer
]

{ #category : #'*Soil-Serializer' }
Class >> soilTransientInstVars [
	^ #()
]
