Class {
	#name : #SoilFindRecordsVisitor,
	#superclass : #SoilTransactionalVisitor,
	#instVars : [
		'condition',
		'records',
		'numberOfRecords',
		'errors'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #accessing }
SoilFindRecordsVisitor >> errors [
	^ errors
]

{ #category : #api }
SoilFindRecordsVisitor >> find: aBlock in: aSoilTransaction [ 
	transaction := aSoilTransaction. 
	soil := aSoilTransaction soil.
	condition := aBlock.
	self visit: soil
]

{ #category : #initialization }
SoilFindRecordsVisitor >> initialize [
	super initialize.
	records := OrderedCollection new.
	numberOfRecords := nil.
	errors := OrderedCollection new
]

{ #category : #accessing }
SoilFindRecordsVisitor >> numberOfRecords: anObject [

	numberOfRecords := anObject
]

{ #category : #api }
SoilFindRecordsVisitor >> processLoop [
	"Overridden from SoilVisitor: a materialize error for one object must not
	abort the whole scan - collect it in errors and continue with the next
	queued object instead of letting it propagate out of find:in:."
	| objectId record |
	[ toBeProcessed isEmpty ] whileFalse: [ 
		(numberOfRecords notNil and: [ records size >= numberOfRecords ]) ifTrue: [ ^ self ].
		objectId := toBeProcessed removeFirst.
		[ record := (soil objectRepository segmentAt: objectId segment) 
			basicAt: objectId index version: self databaseVersion.
		self visit: (record objectId: objectId) ]
			on: Error
			do: [ :e | errors add: objectId -> e messageText ] ]
]

{ #category : #accessing }
SoilFindRecordsVisitor >> records [

	^ records
]

{ #category : #api }
SoilFindRecordsVisitor >> returnFirst [

	numberOfRecords := 1
]

{ #category : #visiting }
SoilFindRecordsVisitor >> visitJournalFragmentFile: aJournalFragmentFile [ 
	^ aJournalFragmentFile 
]

{ #category : #visiting }
SoilFindRecordsVisitor >> visitObjectId: aSoilObjectId [ 
	(numberOfRecords notNil and: [ records size >= numberOfRecords ]) ifTrue: [ ^ self ].
	^ [ super visitObjectId: aSoilObjectId ]
		on: Error 
		do: [ :e | errors add: aSoilObjectId -> e messageText ]
]

{ #category : #visiting }
SoilFindRecordsVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	(numberOfRecords notNil and: [ records size >= numberOfRecords ]) ifTrue: [ ^ self ].
	aSoilPersistentClusterVersion transaction: transaction.
	(condition value: aSoilPersistentClusterVersion) ifTrue: [ 
		records add: aSoilPersistentClusterVersion  ].
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion.
	^ aSoilPersistentClusterVersion 

]
