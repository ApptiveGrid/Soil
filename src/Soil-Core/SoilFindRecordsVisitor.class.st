Class {
	#name : #SoilFindRecordsVisitor,
	#superclass : #SoilTransactionalVisitor,
	#instVars : [
		'condition',
		'records',
		'numberOfRecords'
	],
	#category : #'Soil-Core-Model'
}

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
]

{ #category : #accessing }
SoilFindRecordsVisitor >> numberOfRecords: anObject [

	numberOfRecords := anObject
]

{ #category : #accessing }
SoilFindRecordsVisitor >> records [

	^ records
]

{ #category : #accessing }
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
		on: Error do: [ :e | ] 
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
