"
A SoilCollectionRecordCheck is run when a transaction commits that has added, removed or updated an element of a
SoilIndexedCollection. It checks that the record of the collection is still the one the transaction read.

The collection is changed by #primary:, #addIndex: and #removeIndex:, and by nothing else. An element is added
without writing the collection, so two writers that add different elements do not disturb each other. But a
transaction that read the collection before another one added an index does not know that index, and what it
adds would be missing from it. The check fails the commit with a SoilObjectHasConcurrentChange for the collection.
It does not write the record. A record that is new in the transaction has nothing to check, and a record the
transaction writes is checked like any record that is written.
"
Class {
	#name : #SoilCollectionRecordCheck,
	#superclass : #Object,
	#instVars : [
		'collection'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilCollectionRecordCheck class >> on: aSoilIndexedCollection [
	^ self new
		collection: aSoilIndexedCollection;
		yourself
]

{ #category : #comparing }
SoilCollectionRecordCheck >> = anotherCheck [
	^ self class == anotherCheck class and: [ collection == anotherCheck collection ]
]

{ #category : #accessing }
SoilCollectionRecordCheck >> collection [
	^ collection
]

{ #category : #accessing }
SoilCollectionRecordCheck >> collection: aSoilIndexedCollection [
	collection := aSoilIndexedCollection
]

{ #category : #comparing }
SoilCollectionRecordCheck >> hash [
	^ collection identityHash
]

{ #category : #validating }
SoilCollectionRecordCheck >> validateIn: aTransaction [
	| record |
	record := aTransaction objectIndex at: collection ifAbsent: [ ^ self ].
	(record isKindOf: SoilPersistentClusterVersion) ifFalse: [ ^ self ].
	record position = (aTransaction objectRepository heapPositionOf: record objectId) ifFalse: [
		SoilObjectHasConcurrentChange new
			objectId: record objectId;
			signal ]
]
