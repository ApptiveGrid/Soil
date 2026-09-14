"
I mark off a section of an index: where it starts, where it ends, and whether a key
still falls inside it.

I am for reading only. Inserting, removing and moving a key stay on the
SoilIndexIterator, so the writing side lives in one place instead of two. What that
means for a caller is that whoever puts an entry into a shared index has to know its own
section -- I am asked, I never write.

I do not enforce anything either. An index has no idea that it is shared, and nothing
stops a scan from reading straight on into the next section. What I supply is the stop
condition, #includesKey:, and a loop that forgets to ask it is a programming error that
a test catches -- the same line the suite takes everywhere: the constraint is carried by
the reader.

My subclasses answer only where I begin and where I end, as keys of the index's full key
size. Membership follows from those two, because an index orders its keys as numbers of
fixed width and a section is therefore always a contiguous stretch of them.
"
Class {
	#name : #SoilIndexRange,
	#superclass : #Object,
	#instVars : [
		'keySize'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilIndexRange class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilIndexRange
]

{ #category : #accessing }
SoilIndexRange >> firstIndexKey [
	"my lower bound in the form the index compares in: one number of the index's key size"

	^ self firstKey asIndexKeyOfSize: keySize
]

{ #category : #accessing }
SoilIndexRange >> firstKey [
	"the key my section starts at, whether or not an entry sits there. A scan positions
	itself here with #nextCloseTo:, which answers the next existing key at or after it"

	^ self subclassResponsibility
]

{ #category : #testing }
SoilIndexRange >> includesKey: aKey [
	"the stop condition a reader carries. Takes a key in any of the forms an index accepts,
	including the index key an iterator hands back from an association"

	| key |
	key := aKey asIndexKeyOfSize: keySize.
	^ key >= self firstIndexKey and: [ key <= self lastIndexKey ]
]

{ #category : #accessing }
SoilIndexRange >> keySize [

	^ keySize
]

{ #category : #accessing }
SoilIndexRange >> lastIndexKey [
	"my upper bound in the form the index compares in"

	^ self lastKey asIndexKeyOfSize: keySize
]

{ #category : #accessing }
SoilIndexRange >> lastKey [
	"the last key that is still mine, whether or not an entry sits there"

	^ self subclassResponsibility
]
