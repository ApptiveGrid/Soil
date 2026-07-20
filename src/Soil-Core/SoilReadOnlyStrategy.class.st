Class {
	#name : #SoilReadOnlyStrategy,
	#superclass : #SoilCommitStrategy,
	#instVars : [
		'ignoreWriteAttempts'
	],
	#category : #'Soil-Core'
}

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
