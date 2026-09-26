Class {
	#name : #SoilReadWriteStrategy,
	#superclass : #SoilCommitStrategy,
	#instVars : [
		'records',
		'recordSet'
	],
	#category : #'Soil-Core'
}

{ #category : #testing }
SoilReadWriteStrategy class >> isAbstract [ 
	^ self == SoilReadWriteStrategy 
]

{ #category : #adding }
SoilReadWriteStrategy >> addRecord: record [ 
	"asked through a set, not the list: the list keeps the order the records are written
	in, and looking a record up in it made every add go through all the ones before -
	a commit of ten thousand records spent a quarter of its time here"
	(recordSet includes: record) ifFalse: [  
		recordSet add: record.
		records add: record ]
]

{ #category : #accessing }
SoilReadWriteStrategy >> errorOnWriteAttempts [ 
	self error: 'a read-write transaction does not error on write attempts'
]

{ #category : #testing }
SoilReadWriteStrategy >> hasChanges [ 
	^ records notNil and: [ records notEmpty ]
]

{ #category : #testing }
SoilReadWriteStrategy >> hasRecords [ 
	^ records notEmpty
]

{ #category : #accessing }
SoilReadWriteStrategy >> ignoreWriteAttempts [
	self error: 'a read-write transaction does not ignore write attempts'
]

{ #category : #initialization }
SoilReadWriteStrategy >> initialize [ 
	super initialize.
	self reset
]

{ #category : #testing }
SoilReadWriteStrategy >> isWritable [
	^ true
]

{ #category : #accessing }
SoilReadWriteStrategy >> records [
	^ records
]

{ #category : #public }
SoilReadWriteStrategy >> reset [ 
	records := OrderedCollection new.
	recordSet := Set new
]

{ #category : #accessing }
SoilReadWriteStrategy >> serializeObjects [ 
	| index |
	"serialize initial records. While serializing there can be new records 
	popping up (an object not registered yet in the transaction but is a
	cluster root"

	index := 1.
	"process the loop in a way new records that appear while serializing
	are taken into account"
	[ index <= records size ] whileTrue: [ | record |
		record := (records at: index) asNewClusterVersion.
		recordSet
			remove: (records at: index);
			add: record.
		records at: index put: record.
		record serializeObject.
		index := index + 1 ]
]
