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
	(records includes: record) ifFalse: [  
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
	records := OrderedCollection new
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
		records at: index put: record.
		record serializeObject.
		index := index + 1 ]
]
