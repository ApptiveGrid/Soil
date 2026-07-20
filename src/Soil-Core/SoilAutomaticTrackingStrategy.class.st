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
	"iterate over a snapshot, not the live objectMap: resolving a reference while
	checking #hasChanged can register further objects into objectMap, and growing
	a Dictionary while it is being #do:-iterated can silently skip entries that were
	already there, dropping a changed record from the commit without any error"
	transaction objectMap values do: [ :each |
		each hasChanged ifTrue: [
			self addRecord: each ] ].
	self serializeObjects
]

{ #category : #strategy }
SoilAutomaticTrackingStrategy >> recordMaterialized: record materializer: materializer [
	super recordMaterialized: record materializer: materializer.
	record ensureFingerprint 
]
