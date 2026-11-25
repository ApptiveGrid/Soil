Class {
	#name : #SoilJournalEntriesByKeyTest,
	#superclass : #TestCase,
	#category : #'Soil-Core-Tests-Journal'
}

{ #category : #tests }
SoilJournalEntriesByKeyTest >> testAnIdAndKeyHaveTheirEntriesInTheOrderTheyWereAdded [
	| entries first second |
	first := SoilAddKeyEntry new id: 'idx'; key: 1; yourself.
	second := SoilAddKeyEntry new id: 'idx'; key: 1; yourself.
	entries := SoilJournalEntriesByKey new.
	entries
		add: first;
		add: second.
	self assert: (entries entriesFor: first) asArray equals: { first. second }
]

{ #category : #tests }
SoilJournalEntriesByKeyTest >> testEntriesOfAnotherIdOrKeyAreNotFound [
	| entries entry |
	entry := SoilAddKeyEntry new id: 'idx'; key: 1; yourself.
	entries := SoilJournalEntriesByKey new.
	entries add: entry.
	self assert: (entries entriesFor: (SoilRemoveKeyEntry new id: 'other'; key: 1; yourself)) isEmpty.
	self assert: (entries entriesFor: (SoilRemoveKeyEntry new id: 'idx'; key: 2; yourself)) isEmpty.
	self assert: (entries entriesFor: (SoilRemoveKeyEntry new id: 'idx'; key: 1; yourself)) asArray equals: { entry }
]

{ #category : #tests }
SoilJournalEntriesByKeyTest >> testKnowsAnIndexIdOnceItHasEntries [
	| entries |
	entries := SoilJournalEntriesByKey new.
	self assert: entries isEmpty.
	entries add: (SoilAddKeyEntry new id: 'idx'; key: 1; yourself).
	self deny: entries isEmpty.
	self assert: entries anyIndexId equals: 'idx'
]
