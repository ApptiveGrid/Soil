"
A position on an object that holds an index and is itself held in the store, a
SoilIndexedDictionary for example. This is the ordinary case, and it has the plain name for
that reason.

The holder is what makes it work: it knows its transaction and answers an iterator that is
already wired with proxy strategy, journal and read version, so this cursor only has to
position that iterator.

	cursor := SoilCursor on: aSoilIndexedDictionary.
	iterator := cursor asIterator.
	[ (association := iterator nextAssociation) notNil ] whileTrue: [
		self handle: association value.
		cursor := cursor advancedTo: association key ]

Whoever ran that loop then stores the last cursor where it keeps its progress, in the
transaction it opened itself - a cursor never commits.

The counterpart for a raw index addressed by segment and index id - positioning outside a
transaction, where none of that wiring is available - is not built. It is a second class and not
a second kind of holder, because the two cannot answer #newIterator under the same contract.
"
Class {
	#name : #SoilCursor,
	#superclass : #SoilBasicCursor,
	#instVars : [
		'holder'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #'instance creation' }
SoilCursor class >> on: aHolder [
	"A cursor at the beginning of aHolder: no key means the position before the first entry."
	^ self new
		holder: aHolder;
		yourself
]

{ #category : #'instance creation' }
SoilCursor class >> on: aHolder key: aKey [
	^ self new
		holder: aHolder;
		key: aKey;
		yourself
]

{ #category : #converting }
SoilCursor >> asIterator [
	"Answer an iterator on the holder, positioned here and nothing more - reading is the
	iterator's job. Without a key the iterator stays at the beginning.

	The answer of #nextKeyCloseTo: is dropped on purpose: a position comes from an
	association that was read, not from a key we merely looked for, see
	SoilBasicCursor>>#advancedTo:."
	| iterator |
	iterator := holder newIterator.
	key ifNotNil: [ iterator nextKeyCloseTo: key ].
	^ iterator
]

{ #category : #accessing }
SoilCursor >> holder [
	^ holder
]

{ #category : #initialization }
SoilCursor >> holder: anObject [
	holder := anObject
]
