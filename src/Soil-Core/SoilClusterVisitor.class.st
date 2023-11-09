Class {
	#name : #SoilClusterVisitor,
	#superclass : #SoilTransactionalVisitor,
	#category : #'Soil-Core-Model'
}

{ #category : #private }
SoilClusterVisitor >> processObject: anObject( [
anObject isKindOf: AGGrid) ifTrue: [ self halt ].
	Transcript show: 'processing: ', anObject printString; cr
]

{ #category : #visiting }
SoilClusterVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
]

{ #category : #visiting }
SoilClusterVisitor >> visitPersistentClusterVersion: aPersistentClusterVersion [ 
	| object |
	
	[ object := aPersistentClusterVersion
		transaction: transaction;
		materializeObject.
	self processObject: object ]
		on: Error 
		do: [ :err | Transcript show: 'error', aPersistentClusterVersion printString; cr ].
	super visitPersistentClusterVersion: aPersistentClusterVersion.
]
