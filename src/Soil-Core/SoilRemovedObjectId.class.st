"
This is a special ID used for indexes (0:0).

To allow us to use one index from multiple transactions, we restore the state of the last commited transaction via analysing the transaction log.
For removals, this means we can not remove a key (or key->value) for real until the transaction commits. In addition, indexes do not allow empty pages.

Soil therefore never removes an entry when doing a removeKey:, but instead it overrides the value with a Removed ID. 
In multi-key mode, we need to be able to distinguish difference removes of the same key (but different values) to restore the correct transaction log entry.

We create removed IDs alwasy as instances of SoilRemovedObjectId with the ID of the removed value as state.
When stored to disk, it will be loaded back as an instance of SoilObjectID (0:0), a non-restorable removed ID as in this case, there will be no restore done (the removed IDs will be cleaned up eventually when a whole page is empty this recycled) 
"
Class {
	#name : #SoilRemovedObjectId,
	#superclass : #SoilObjectId,
	#instVars : [
		'removedId'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SoilRemovedObjectId class >> for: aSoilObjectId [

	^self new
		removedId: aSoilObjectId;
		yourself 
]

{ #category : #'instance creation' }
SoilRemovedObjectId class >> new [

	^self basicNew 
		segment: 0; index: 0;
		yourself 
]

{ #category : #testing }
SoilRemovedObjectId >> isRestorable [
	^ true
]

{ #category : #accessing }
SoilRemovedObjectId >> removedId [

	^ removedId
]

{ #category : #accessing }
SoilRemovedObjectId >> removedId: anObject [

	removedId := anObject
]
