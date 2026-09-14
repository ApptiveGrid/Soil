"
A cursor is a position on a key-ordered structure: the key that was read last. It is immutable
and persistent, and it is what an iterator's current key distills to - the iterator works and is
bound to a transaction, the cursor outlives it. Keeping an iterator over several commits instead
would hold a long read transaction open, and under MVCC that stops old versions from being
cleaned up.

Reading starts after that key, excluding it. A cursor without a key is the position before the
first entry, so reading starts at the beginning of the structure.

A cursor does not move: #advancedTo: answers a new one. What changes is the holder, which
replaces its cursor with the answer. A cursor does not commit either - it advances inside the
transaction its caller opened.

What a cursor deliberately does not know: handlers, patterns, wakeup, retention. With any of
those it would be a subscription and would only fit the one case it was built for.

Subclasses say how to reach an iterator for their target. SoilCursor is the ordinary case, a
position on an object held in the store.
"
Class {
	#name : #SoilBasicCursor,
	#superclass : #Object,
	#instVars : [
		'key'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilBasicCursor class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilBasicCursor
]

{ #category : #accessing }
SoilBasicCursor >> advancedTo: aKey [
	"Answer a new cursor at aKey. A cursor is a position and does not move; the holder is
	what changes, by replacing its cursor with this answer.

	Advance to the key of an association that was actually read. The answer of a
	positioning call is not a position - see SoilCursor>>#asIterator."
	^ self copy
		key: aKey;
		yourself
]

{ #category : #converting }
SoilBasicCursor >> asIterator [
	"Answer an iterator on the target, positioned at this cursor and nothing more."
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilBasicCursor >> key [
	"The key read last, or nil for the position before the first entry."
	^ key
]

{ #category : #initialization }
SoilBasicCursor >> key: aKey [
	"For construction and #advancedTo: only - a cursor that is already in use does not move."
	key := aKey
]

{ #category : #printing }
SoilBasicCursor >> printOn: aStream [
	super printOn: aStream.
	aStream << ' key=' << key printString
]
