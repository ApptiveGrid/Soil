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

{ #category : #metrics }
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

{ #category : #metrics }
SoilMetrics >> metaRecordCacheHitRatio [
	| metaSegment |
	metaSegment := soil objectRepository metaSegment.
	^ (metaSegment isKindOf: SoilCachedObjectSegment)
		ifTrue: [ metaSegment cache hitRatio ] 
		ifFalse: [ 0 ]
	
]

{ #category : #metrics }
SoilMetrics >> metaRecordCacheHits [ 
	| metaSegment |
	metaSegment := soil objectRepository metaSegment.
	^ (metaSegment isKindOf: SoilCachedObjectSegment)
		ifTrue: [ metaSegment cache hits ]
		ifFalse: [ 0 ]
]

{ #category : #metrics }
SoilMetrics >> metaRecordCacheMaximumSize [
	| metaSegment |
	metaSegment := soil objectRepository metaSegment.
	^ (metaSegment isKindOf: SoilCachedObjectSegment)
		ifTrue: [ (metaSegment cache instVarNamed: #weight) maximum ]
		ifFalse: [ 0 ]
]

{ #category : #metrics }
SoilMetrics >> metaRecordCacheMisses [
	| metaSegment |
	metaSegment := soil objectRepository metaSegment.
	^ (metaSegment isKindOf: SoilCachedObjectSegment)
		ifTrue: [ metaSegment cache misses ]
		ifFalse: [ 0 ]
]

{ #category : #metrics }
SoilMetrics >> metaRecordCacheSize [
	| metaSegment |
	metaSegment := soil objectRepository metaSegment.
	^ (metaSegment isKindOf: SoilCachedObjectSegment)
		ifTrue: [ metaSegment cache size ]
		ifFalse: [ 0 ]
]

{ #category : #metrics }
SoilMetrics >> metaRecordsRead [
	^ metaRecordsRead
]

{ #category : #metrics }
SoilMetrics >> metaRecordsWritten [
	^ metaRecordsWritten
]

{ #category : #counting }
SoilMetrics >> objectMaterialized: anObject [
	objectsMaterialized := objectsMaterialized + 1
]

{ #category : #metrics }
SoilMetrics >> objectRecordCacheHitRatio [
	^ self cachedSegments 
		ifNotEmpty: [:segments | (segments collect: [ :each | each cache hitRatio ]) average ]
		ifEmpty: 0
	
]

{ #category : #metrics }
SoilMetrics >> objectRecordCacheHits [ 
	^ self cachedSegments 
		ifNotEmpty: [:segments | segments sum: [ :each | each cache hits ] ]
		ifEmpty: 0
]

{ #category : #metrics }
SoilMetrics >> objectRecordCacheMaximumSize [
	^ self cachedSegments 
		ifNotEmpty: [:segments | (segments collect: [ :each | (each cache instVarNamed: #weight) maximum ]) average ]
		ifEmpty: 0
	
]

{ #category : #metrics }
SoilMetrics >> objectRecordCacheMisses [
	^ self cachedSegments 
		ifNotEmpty: [:segments | segments sum: [ :each | each cache misses ] ]
		ifEmpty: 0
]

{ #category : #metrics }
SoilMetrics >> objectRecordCacheSize [
	^ self cachedSegments 
		ifNotEmpty: [:segments | (segments collect: [ :each | each cache size ]) average ]
		ifEmpty: 0
	
]

{ #category : #metrics }
SoilMetrics >> objectRecordsRead [
	^ objectRecordsRead
]

{ #category : #metrics }
SoilMetrics >> objectRecordsWritten [
	^ objectRecordsWritten
]

{ #category : #counting }
SoilMetrics >> objectSerialized: aString [ 
	objectsSerialized := objectsSerialized + 1
]

{ #category : #metrics }
SoilMetrics >> objectsMaterialized [

	^ objectsMaterialized
]

{ #category : #metrics }
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

{ #category : #counting }
SoilMetrics >> transactionAborted: aSoilTransaction [ 
	transactionsAborted := transactionsAborted + 1
]

{ #category : #counting }
SoilMetrics >> transactionCommitted: aSoilTransaction [ 
	aSoilTransaction hasModifications 
		ifTrue: [ transactionsCommittedWrite := transactionsCommittedWrite + 1 ]
		ifFalse: [ transactionsCommittedReadOnly := transactionsCommittedReadOnly + 1 ]
]

{ #category : #counting }
SoilMetrics >> transactionCreated: aSoilTransaction [ 
	transactionsCreated := transactionsCreated + 1
]

{ #category : #metrics }
SoilMetrics >> transactionsAborted [

	^ transactionsAborted
]

{ #category : #metrics }
SoilMetrics >> transactionsCommittedReadOnly [

	^ transactionsCommittedReadOnly
]

{ #category : #metrics }
SoilMetrics >> transactionsCommittedWrite [
	^ transactionsCommittedWrite
]

{ #category : #metrics }
SoilMetrics >> transactionsCreated [
	^ transactionsCreated
]
