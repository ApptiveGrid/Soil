Class {
	#name : #SoilMetrics,
	#superclass : #SoilNotificationHandler,
	#instVars : [
		'transactionsCreated',
		'objectsSerialized',
		'clustersWritten',
		'clustersRead',
		'objectsMaterialized',
		'transactionsCommittedReadOnly',
		'transactionsCommittedWrite',
		'transactionsAborted'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #counting }
SoilMetrics >> clusterRead: aSoilPersistentClusterVersion [ 
	clustersRead := clustersRead + 1
]

{ #category : #counting }
SoilMetrics >> clusterWritten: aCollection [ 
	clustersWritten := clustersWritten + 1
]

{ #category : #accessing }
SoilMetrics >> clustersRead [

	^ clustersRead
]

{ #category : #accessing }
SoilMetrics >> clustersWritten [

	^ clustersWritten
]

{ #category : #initialization }
SoilMetrics >> initialize [ 
	super initialize.
	transactionsCreated := 0.
	transactionsCommittedReadOnly := 0.
	transactionsCommittedWrite := 0.
	transactionsAborted := 0.
	clustersRead := 0.
	clustersWritten := 0.
	objectsSerialized := 0.
	objectsMaterialized := 0
]

{ #category : #counting }
SoilMetrics >> objectMaterialized: aSoilBehaviorDescription [ 
	objectsMaterialized := objectsMaterialized + 1
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
SoilMetrics >> transactionCommitted: aSoilTransaction [ 
	aSoilTransaction hasModifications 
		ifTrue: [ transactionsCommittedWrite := transactionsCommittedWrite + 1 ]
		ifFalse: [ transactionsCommittedReadOnly := transactionsCommittedReadOnly + 1 ]
]

{ #category : #'as yet unclassified' }
SoilMetrics >> transactionCommittedWrite [
	self shouldBeImplemented.
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
