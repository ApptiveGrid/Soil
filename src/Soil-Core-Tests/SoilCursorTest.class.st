"
Tests for SoilCursor, run against both index backends because a position has to mean the same
on a skip list as on a BTree.

The holder is a plain Dictionary as the database root, with the indexed dictionary under #entries
and the cursor under #cursor - the shape a using module has: it holds the reference, the store
holds the progress.
"
Class {
	#name : #SoilCursorTest,
	#superclass : #ParametrizedTestCase,
	#instVars : [
		'soil',
		'dict',
		'backend'
	],
	#category : #'Soil-Core-Tests-Index'
}

{ #category : #'building suites' }
SoilCursorTest class >> testParameters [
	^ ParametrizedTestMatrix new
		addCase: { #backend -> SoilSkipList };
		addCase: { #backend -> SoilBTree };
		yourself
]

{ #category : #accessing }
SoilCursorTest >> backend [

	^ backend
]

{ #category : #accessing }
SoilCursorTest >> backend: anObject [

	backend := anObject
]

{ #category : #accessing }
SoilCursorTest >> indexKeyFor: aString [
	"The key an iterator answers is an index key, and so is the key a cursor carries."
	^ aString asIndexKeyOfSize: self keySize
]

{ #category : #accessing }
SoilCursorTest >> keySize [
	^ 10
]

{ #category : #accessing }
SoilCursorTest >> path [ 
	^ 'soil-tests'
]

{ #category : #running }
SoilCursorTest >> setUp [ 
	super setUp.
	soil := Soil path: self path.
	soil 
		destroy;
		initializeFilesystem.
	dict := (SoilIndexedDictionary newWithBackend: backend)
		keySize: self keySize;
		maxLevel: 8; "ignored for BTree"
		yourself
]

{ #category : #running }
SoilCursorTest >> storeEntries: aCollection [
	"Commit a root holding the indexed dictionary under #entries, one entry per name."
	| tx |
	tx := soil newTransaction.
	tx root: Dictionary new.
	tx makeRoot: dict.
	tx root at: #entries put: dict.
	aCollection do: [ :each | dict at: each put: (OrderedCollection with: each) ].
	tx commit
]

{ #category : #running }
SoilCursorTest >> tearDown [ 
	soil ifNotNil: [ 
		soil close ].
	super tearDown.
]

{ #category : #tests }
SoilCursorTest >> testCursorWithoutKeyStartsAtTheBeginning [
	"No key is the position before the first entry, not a missing value to guard against."
	| tx |
	self storeEntries: #( 'key1' 'key2' 'key3' ).

	tx := soil newTransaction.
	self 
		assert: (SoilCursor on: (tx root at: #entries)) asIterator nextAssociation key 
		equals: (self indexKeyFor: 'key1').
	tx abort
]

{ #category : #tests }
SoilCursorTest >> testKeyGoneKeepsReadingForward [
	"A cursor addresses a place that was reached, not an entry that has to still be there.
	Committing a removal takes the key off the page, and the cursor still positions and
	keeps reading forward from there.

	Which entry comes back then is the iterator's business, not the cursor's: positioning
	lands on the closest key that is still there - key4 - and reading goes on behind it, so
	key5 is the answer. Pinned here because a change to that in the iterator changes what
	every cursor reads."
	| tx |
	self storeEntries: #( 'key1' 'key2' 'key3' 'key4' 'key5' 'key6' ).

	tx := soil newTransaction.
	(tx root at: #entries) 
		removeKey: 'key2';
		removeKey: 'key3'.
	tx commit.

	tx := soil newTransaction.
	self 
		assert: ((SoilCursor on: (tx root at: #entries) key: (self indexKeyFor: 'key2')) 
			asIterator nextAssociation key)
		equals: (self indexKeyFor: 'key5').
	tx abort
]

{ #category : #tests }
SoilCursorTest >> testNothingBehindTheCursorReadsNilAndStaysThere [
	"Reading behind the last entry answers nil, and asking again answers nil again rather
	than running on that entry forever."
	| tx iterator |
	self storeEntries: #( 'key1' 'key2' 'key3' ).

	tx := soil newTransaction.
	iterator := (SoilCursor on: (tx root at: #entries) key: (self indexKeyFor: 'key3')) 
		asIterator.
	self assert: iterator nextAssociation isNil.
	self assert: iterator nextAssociation isNil.
	tx abort
]

{ #category : #tests }
SoilCursorTest >> testPositionSurvivesACommit [
	"What a cursor is for: it is a value, not an open iterator. Stored and read back in a
	later transaction it still answers the entry behind the one that was read last."
	| tx cursor |
	self storeEntries: #( 'key1' 'key2' 'key3' ).

	tx := soil newTransaction.
	cursor := SoilCursor on: (tx root at: #entries).
	cursor := cursor advancedTo: cursor asIterator nextAssociation key.
	tx root at: #cursor put: cursor.
	tx markDirty: tx root.
	tx commit.

	tx := soil newTransaction.
	self 
		assert: (tx root at: #cursor) asIterator nextAssociation key 
		equals: (self indexKeyFor: 'key2').
	tx abort
]

{ #category : #tests }
SoilCursorTest >> testReadsExcludingItsOwnKey [
	"Reading starts after the cursor, not at it: the entry that was read last must not be
	handed out a second time."
	| tx |
	self storeEntries: #( 'key1' 'key2' 'key3' ).

	tx := soil newTransaction.
	self 
		assert: ((SoilCursor on: (tx root at: #entries) key: (self indexKeyFor: 'key1')) 
			asIterator nextAssociation key)
		equals: (self indexKeyFor: 'key2').
	tx abort
]
