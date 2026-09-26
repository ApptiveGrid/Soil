Class {
	#name : #SoilReadWriteStrategy,
	#superclass : #SoilCommitStrategy,
	#instVars : [
		'records'
	],
	#category : #'Soil-Core'
}

{ #category : #testing }
SoilReadWriteStrategy class >> isAbstract [ 
	^ self == SoilReadWriteStrategy 
]

{ #category : #adding }
SoilReadWriteStrategy >> addRecord: record [ 
	"looked up by hash: a list asked with #includes: made a commit of n records go
	through n*n/2 of them - 37 seconds for forty thousand"
	records at: record ifAbsentPut: [ record ]
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
	"in the order they were added, each as its newest version - see #serializeObjects"
	^ records values
]

{ #category : #public }
SoilReadWriteStrategy >> reset [ 
	"each record as it was added, mapped to the version of it that is written"
	records := OrderedDictionary new
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
	[ index <= records size ] whileTrue: [ | key record |
		key := records keyAtIndex: index.
		record := (records at: key) asNewClusterVersion.
		records at: key put: record.
		record serializeObject.
		index := index + 1 ]
]
