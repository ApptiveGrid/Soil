Class {
	#name : #SoilAutomaticTrackingStrategy,
	#superclass : #SoilReadWriteStrategy,
	#category : #'Soil-Core'
}

{ #category : #public }
SoilAutomaticTrackingStrategy >> markDirty: anObject [ 
	"do nothing"
]

{ #category : #strategy }
SoilAutomaticTrackingStrategy >> prepareCommit [ 
	transaction objectMap do: [ :each | 
		each hasChanged ifTrue: [ 
			self addRecord: each ] ].
	self serializeObjects 
]

{ #category : #strategy }
SoilAutomaticTrackingStrategy >> recordMaterialized: record materializer: materializer [
	super recordMaterialized: record materializer: materializer.
	record ensureFingerprint 
]
