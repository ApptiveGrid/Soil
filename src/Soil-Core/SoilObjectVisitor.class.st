Class {
	#name : #SoilObjectVisitor,
	#superclass : #SoilTransactionalVisitor,
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilObjectVisitor >> processClusterVersion: aPersistentClusterVersion [ 
	"materialize object in cluster version and process it"
	self processObject: (aPersistentClusterVersion
			transaction: transaction;
			materializeObject)
]

{ #category : #private }
SoilObjectVisitor >> processObject: anObject [

]

{ #category : #visiting }
SoilObjectVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
]

{ #category : #visiting }
SoilObjectVisitor >> visitPersistentClusterVersion: aPersistentClusterVersion [ 
	super visitPersistentClusterVersion: aPersistentClusterVersion.
	self processClusterVersion: aPersistentClusterVersion.

]
