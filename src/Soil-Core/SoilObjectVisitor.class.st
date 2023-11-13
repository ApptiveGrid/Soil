Class {
	#name : #SoilObjectVisitor,
	#superclass : #SoilTransactionalVisitor,
	#category : #'Soil-Core-Model'
}

{ #category : #private }
SoilObjectVisitor >> processObject: anObject [

]

{ #category : #visiting }
SoilObjectVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
]

{ #category : #visiting }
SoilObjectVisitor >> visitPersistentClusterVersion: aPersistentClusterVersion [ 
	self processObject: (aPersistentClusterVersion
			transaction: transaction;
			materializeObject).
	super visitPersistentClusterVersion: aPersistentClusterVersion.
]
