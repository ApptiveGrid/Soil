Class {
	#name : #SoilFindRecordVisitor,
	#superclass : #SoilTransactionalVisitor,
	#instVars : [
		'seen',
		'condition',
		'object'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #api }
SoilFindRecordVisitor >> find: aBlock in: aSoilTransaction [ 
	transaction := aSoilTransaction. 
	soil := aSoilTransaction soil.
	condition := aBlock.
	self visit: soil
]

{ #category : #initialization }
SoilFindRecordVisitor >> initialize [ 
	super initialize.
	seen := Set new.
]

{ #category : #accessing }
SoilFindRecordVisitor >> object [
	^ object
]

{ #category : #visiting }
SoilFindRecordVisitor >> visitObjectId: aSoilObjectId [ 
	object ifNotNil: [ ^ self ].
	(seen includes: aSoilObjectId) ifTrue: [ ^ aSoilObjectId ].
	seen add: aSoilObjectId.
	self visit: (soil objectRepository at: aSoilObjectId).
	^ aSoilObjectId 
]

{ #category : #visiting }
SoilFindRecordVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	object ifNotNil: [ ^ self ].
	aSoilPersistentClusterVersion transaction: transaction.
	(condition value: aSoilPersistentClusterVersion) ifTrue: [ 
		object := aSoilPersistentClusterVersion  ].
	aSoilPersistentClusterVersion references do: [ :reference |
		self visit: reference ].
	aSoilPersistentClusterVersion indexIds do:[ :indexId |
		self visit: ((soil objectRepository segmentAt: aSoilPersistentClusterVersion  segment) indexAt: indexId)  ].

]
