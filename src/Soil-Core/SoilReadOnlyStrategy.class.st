Class {
	#name : #SoilReadOnlyStrategy,
	#superclass : #SoilCommitStrategy,
	#instVars : [
		'ignoreWriteAttempts'
	],
	#category : #'Soil-Core'
}

{ #category : #public }
SoilReadOnlyStrategy >> addRecord: record [
	"the last door into this strategy that was not named. #markDirty: and #prepareCommit
	both answer a write attempt by the same rule, and this one answered with a
	doesNotUnderstand - the caller learned the name of a missing method rather than that
	it had written to a read-only transaction.

	Three callers reach it: #addObjectToBeCommited:, #makeNewVersion: and
	#atObjectId:putObject:asVersion:, plus auto-migration when a materialized cluster
	could be migrated. None of them can do anything here - nothing this strategy holds is
	ever committed."
	ignoreWriteAttempts ifFalse: [
		SoilWriteOnReadOnlyTransaction new
			object: record object;
			signal ]
]

{ #category : #accessing }
SoilReadOnlyStrategy >> errorOnWriteAttempts [
	ignoreWriteAttempts := false
]

{ #category : #testing }
SoilReadOnlyStrategy >> hasChanges [ 
	^ false 
]

{ #category : #accessing }
SoilReadOnlyStrategy >> ignoreWriteAttempts [ 
	ignoreWriteAttempts := true
]

{ #category : #initialization }
SoilReadOnlyStrategy >> initialize [
	super initialize.
	ignoreWriteAttempts := true
]

{ #category : #testing }
SoilReadOnlyStrategy >> isWritable [
	^ false
]

{ #category : #public }
SoilReadOnlyStrategy >> markDirty: anObject [ 
	ignoreWriteAttempts ifFalse: [  
		SoilWriteOnReadOnlyTransaction new 
			object: anObject;
			signal ]
]

{ #category : #strategy }
SoilReadOnlyStrategy >> prepareCommit [
	"iterate over a snapshot, not the live objectMap - see
	SoilAutomaticTrackingStrategy>>prepareCommit for why"
	ignoreWriteAttempts ifFalse: [
		transaction objectMap values do: [ :each |
			each hasChanged ifTrue: [
				 ^ SoilWriteOnReadOnlyTransaction new
					object: each object;
					signal ] ] ]
]

{ #category : #strategy }
SoilReadOnlyStrategy >> recordMaterialized: record materializer: materializer [
	super recordMaterialized: record materializer: materializer.
	"if we want to find out what has changed we need to make a 
	fingerprint even in read-only mode"
	ignoreWriteAttempts ifFalse: [ 
		record ensureFingerprint ].
]
