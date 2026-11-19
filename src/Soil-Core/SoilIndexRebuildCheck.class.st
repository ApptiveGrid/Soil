"
A SoilIndexRebuildCheck is run when a transaction commits that has built a new index of a SoilIndexedCollection from
the elements it holds. The index is only right if what it was built from is still what the primary holds, so the
check fails the commit with a SoilIndexHasConcurrentChange when a transaction committed since the one that builds
read has changed the primary, or has written one of the elements the index was built from, whatever it changed in
it. A journal that is not there any more is taken as a change, as SoilTransaction>>#detectIndexConflicts does.

The caller repeats in a new transaction. #addIndex: repeats nothing itself.
"
Class {
	#name : #SoilIndexRebuildCheck,
	#superclass : #Object,
	#instVars : [
		'primaryIndexId',
		'elementIds'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilIndexRebuildCheck class >> primaryIndexId: aString elementIds: aSet [
	^ self new
		setPrimaryIndexId: aString elementIds: aSet;
		yourself
]

{ #category : #private }
SoilIndexRebuildCheck >> isChangeIn: aJournal [
	^ aJournal entries anySatisfy: [ :each |
		(each modifiesIndex and: [ each id = primaryIndexId ]) or: [
			each providesObjectIds and: [ each objectIds anySatisfy: [ :id | elementIds includes: id ] ] ] ]
]

{ #category : #initialization }
SoilIndexRebuildCheck >> setPrimaryIndexId: aString elementIds: aSet [
	primaryIndexId := aString.
	elementIds := aSet
]

{ #category : #private }
SoilIndexRebuildCheck >> signalChange [
	^ SoilIndexHasConcurrentChange new
		indexId: primaryIndexId;
		signal
]

{ #category : #validating }
SoilIndexRebuildCheck >> validateIn: aTransaction [
	aTransaction writeVersion - 1 > aTransaction readVersion ifFalse: [ ^ self ].
	aTransaction readVersion + 1 to: aTransaction writeVersion - 1 do: [ :version | | committed |
		committed := aTransaction soil journal
			transactionJournalAt: version
			ifAbsent: [ ^ self signalChange ].
		(self isChangeIn: committed) ifTrue: [ ^ self signalChange ] ]
]
