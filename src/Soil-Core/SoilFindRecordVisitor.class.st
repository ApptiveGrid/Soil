Class {
	#name : #SoilFindRecordVisitor,
	#superclass : #SoilTransactionalVisitor,
	#instVars : [
		'condition',
		'object'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #api }
SoilFindRecordVisitor >> find: aBlock in: aSoilTransaction [ 
	transaction := aSoilTransaction. 
	soil := aSoilTransaction soil.
	condition := aBlock.
	self visit: soil
]

{ #category : #accessing }
SoilFindRecordVisitor >> object [
	^ object
]

{ #category : #visiting }
SoilFindRecordVisitor >> visitObjectId: aSoilObjectId [ 
	object ifNotNil: [ ^ self ].
	^ super visitObjectId: aSoilObjectId 
]

{ #category : #visiting }
SoilFindRecordVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	object ifNotNil: [ ^ self ].
	aSoilPersistentClusterVersion transaction: transaction.
	(condition value: aSoilPersistentClusterVersion) ifTrue: [ 
		object := aSoilPersistentClusterVersion  ].
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion.
	^ aSoilPersistentClusterVersion 

]
