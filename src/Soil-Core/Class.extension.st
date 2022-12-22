Extension { #name : #Class }

{ #category : #'*Soil-Core' }
Class >> isSoilClusterRoot [ 
	^ false
]

{ #category : #'*Soil-Core' }
Class >> soilBasicSerialize: serializer [

	serializer nextPutClass: self
]

{ #category : #'*Soil-Core' }
Class >> soilBehaviorIdentifier [
	^ name
]

{ #category : #'*Soil-Core' }
Class class >> soilMaterialize: materializer [

	^ materializer nextClass
]

{ #category : #'*Soil-Core' }
Class >> soilSerialize: serializer [
	"registration not needed, as we always return the current class on read"
	self soilBasicSerialize: serializer
]

{ #category : #'*Soil-Core' }
Class >> soilTransientInstVars [
	^ #()
]
