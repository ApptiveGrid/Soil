"
A database consistency tracker for tests whose index sizes are given, one pair per read (stored -> counted), to stand in for a database in use, where a commit can land between reading the header and counting.
"
Class {
	#name : #SoilTestSettlingSizeTracker,
	#superclass : #SoilDatabaseConsistencyTracker,
	#instVars : [
		'reads'
	],
	#category : #'Soil-Core-Tests-Visitor'
}

{ #category : #accessing }
SoilTestSettlingSizeTracker >> reads: aCollectionOfAssociations [
	reads := aCollectionOfAssociations asOrderedCollection
]

{ #category : #checking }
SoilTestSettlingSizeTracker >> sizesOf: anIndex [
	^ reads removeFirst
]
