Class {
	#name : #SoilMemoryIndexStoreTest,
	#superclass : #TestCase,
	#instVars : [
		'index'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #running }
SoilMemoryIndexStoreTest >> setUp [
	super setUp.
	index := SoilSkipList new
		beMemoryStore;
		initializeFilesystem;
		initializeHeaderPage;
		maxLevel: 4;
		keySize: 8;
		valueSize: 8;
		uniqueKeys: true;
		yourself
]

{ #category : #tests }
SoilMemoryIndexStoreTest >> testHasNoFileBehindIt [
	self assert: index path isNil.
	self deny: index isPresentOnDisk
]

{ #category : #tests }
SoilMemoryIndexStoreTest >> testPageFaultOnUnallocatedPageIsAnError [
	self
		should: [ index pageAt: 4711 ]
		raise: Error
]

{ #category : #tests }
SoilMemoryIndexStoreTest >> testStoresAndReadsBackItemsAcrossSeveralPages [
	| capacity |
	capacity := index firstPage itemCapacity.
	1 to: capacity + 10 do: [ :n |
		index at: n add: (n asByteArrayOfSize: 8) ].
	self assert: index pages size > 1.
	self assert: index size equals: capacity + 10.
	self assert: (index at: 42) asInteger equals: 42
]
