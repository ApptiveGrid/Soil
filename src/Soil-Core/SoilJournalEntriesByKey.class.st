"
Index key entries of a journal, found again by the index id and the key they are for.

The two are kept apart on purpose: one level per index id, below it one per key. The
obvious `id -> key` association as the key of a dictionary hashes as its key only, which
here is the index id, the same for every entry of an index. All keys of an index then sit
in one chain, and every lookup compares along the whole of it: a commit with n key entries
in one index took n squared comparisons.
"
Class {
	#name : #SoilJournalEntriesByKey,
	#superclass : #Object,
	#instVars : [
		'byId'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #adding }
SoilJournalEntriesByKey >> add: anIndexJournalEntry [
	((byId at: anIndexJournalEntry id ifAbsentPut: [ Dictionary new ])
		at: anIndexJournalEntry key
		ifAbsentPut: [ OrderedCollection new ]) add: anIndexJournalEntry
]

{ #category : #accessing }
SoilJournalEntriesByKey >> anyIndexId [
	^ byId keys anyOne
]

{ #category : #accessing }
SoilJournalEntriesByKey >> entriesFor: anIndexJournalEntry [
	"the entries added so far for the index id and the key of anIndexJournalEntry, in the
	order they were added"
	^ (byId at: anIndexJournalEntry id ifAbsent: [ ^ #() ])
		at: anIndexJournalEntry key
		ifAbsent: [ #() ]
]

{ #category : #initialization }
SoilJournalEntriesByKey >> initialize [
	super initialize.
	byId := Dictionary new
]

{ #category : #testing }
SoilJournalEntriesByKey >> isEmpty [
	^ byId isEmpty
]
