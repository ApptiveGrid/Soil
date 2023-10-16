Class {
	#name : #SoilMetrics,
	#superclass : #SoilNotificationHandler,
	#instVars : [
		'transactionsCreated',
		'objectsSerialized',
		'objectsMaterialized',
		'transactionsCommittedReadOnly',
		'transactionsCommittedWrite',
		'transactionsAborted',
		'metaRecordsRead',
		'metaRecordsWritten',
		'objectRecordsRead',
		'objectRecordsWritten'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'as yet unclassified' }
SoilMetrics >> cachedSegments [
	^ soil objectRepository segments select: [ :each | each isKindOf: SoilCachedObjectSegment  ]
]

{ #category : #initialization }
SoilMetrics >> initialize [ 
	super initialize.
	transactionsCreated := 0.
	transactionsCommittedReadOnly := 0.
	transactionsCommittedWrite := 0.
	transactionsAborted := 0.
	metaRecordsRead := 0.
	metaRecordsWritten := 0. 
	objectRecordsRead := 0.
	objectRecordsWritten := 0.
	objectsSerialized := 0.
	objectsMaterialized := 0
]

{ #category : #'as yet unclassified' }
SoilMetrics >> metaRecordCacheHitRatio [
	| metaSegment |
	metaSegment := soil objectRepository metaSegment.
	^ (metaSegment isKindOf: SoilCachedObjectSegment)
		ifTrue: [ metaSegment cache hitRatio ] 
		ifFalse: 0
	
]

{ #category : #'as yet unclassified' }
SoilMetrics >> metaRecordCacheHits [ 
	| metaSegment |
	metaSegment := soil objectRepository metaSegment.
	^ (metaSegment isKindOf: SoilCachedObjectSegment)
		ifTrue: [ metaSegment cache hits ]
		ifFalse: 0
]

{ #category : #'as yet unclassified' }
SoilMetrics >> metaRecordCacheMisses [
	| metaSegment |
	metaSegment := soil objectRepository metaSegment.
	^ (metaSegment isKindOf: SoilCachedObjectSegment)
		ifTrue: [ metaSegment cache misses ]
		ifFalse: 0
]

{ #category : #accessing }
SoilMetrics >> metaRecordsRead [
	^ metaRecordsRead
]

{ #category : #accessing }
SoilMetrics >> metaRecordsWritten [
	^ metaRecordsWritten
]

{ #category : #counting }
SoilMetrics >> objectMaterialized: anObject [
	objectsMaterialized := objectsMaterialized + 1
]

{ #category : #'as yet unclassified' }
SoilMetrics >> objectRecordCacheHitRatio [
	^ self cachedSegments 
		ifNotEmpty: [:segments | (segments collect: [ :each | each cache hitRatio ]) average ]
		ifEmpty: 0
	
]

{ #category : #'as yet unclassified' }
SoilMetrics >> objectRecordCacheHits [ 
	^ self cachedSegments 
		ifNotEmpty: [:segments | segments sum: [ :each | each cache hits ] ]
		ifEmpty: 0
]

{ #category : #'as yet unclassified' }
SoilMetrics >> objectRecordCacheMisses [
	^ self cachedSegments 
		ifNotEmpty: [:segments | segments sum: [ :each | each cache misses ] ]
		ifEmpty: 0
]

{ #category : #accessing }
SoilMetrics >> objectRecordsRead [
	^ objectRecordsRead
]

{ #category : #accessing }
SoilMetrics >> objectRecordsWritten [
	^ objectRecordsWritten
]

{ #category : #counting }
SoilMetrics >> objectSerialized: aString [ 
	objectsSerialized := objectsSerialized + 1
]

{ #category : #accessing }
SoilMetrics >> objectsMaterialized [

	^ objectsMaterialized
]

{ #category : #accessing }
SoilMetrics >> objectsSerialized [

	^ objectsSerialized
]

{ #category : #counting }
SoilMetrics >> recordRead: aSoilPersistentClusterVersion [ 
	(aSoilPersistentClusterVersion objectId isMeta)
		ifTrue: [ metaRecordsRead := metaRecordsRead + 1 ]
		ifFalse: [ objectRecordsRead := objectRecordsRead + 1 ]
]

{ #category : #counting }
SoilMetrics >> recordWritten: anObjectId [
	anObjectId isMeta 
		ifTrue: [ metaRecordsWritten := metaRecordsWritten + 1 ]
		ifFalse: [ objectRecordsWritten := objectRecordsWritten + 1 ]
]

{ #category : #'as yet unclassified' }
SoilMetrics >> transactionAborted: aSoilTransaction [ 
	transactionsAborted := transactionsAborted + 1
]

{ #category : #counting }
SoilMetrics >> transactionCommitted: aSoilTransaction [ 
	aSoilTransaction hasModifications 
		ifTrue: [ transactionsCommittedWrite := transactionsCommittedWrite + 1 ]
		ifFalse: [ transactionsCommittedReadOnly := transactionsCommittedReadOnly + 1 ]
]

{ #category : #'as yet unclassified' }
SoilMetrics >> transactionCreated: aSoilTransaction [ 
	transactionsCreated := transactionsCreated + 1
]

{ #category : #accessing }
SoilMetrics >> transactionsAborted [

	^ transactionsAborted
]

{ #category : #accessing }
SoilMetrics >> transactionsCommittedReadOnly [

	^ transactionsCommittedReadOnly
]

{ #category : #accessing }
SoilMetrics >> transactionsCommittedWrite [
	^ transactionsCommittedWrite
]

{ #category : #accessing }
SoilMetrics >> transactionsCreated [
	^ transactionsCreated
]
