"
A detached object that knows its database, and can therefore write itself back.

My superclass deliberately cannot: it holds an object and an objectId and reports
changes, but somebody else has to do the writing. That is right wherever an owner
already runs transactions -- a resident coalescing a burst of changes into one
write knows better than I do when the moment is.

But not every detached object has such an owner. With a database I can open a
transaction of my own, put my object back at my objectId and commit. That is one
method, #writeBack, and it is deliberately a *named* operation rather than
something that happens as a side effect of a forwarded send: a proxy cannot tell
from a message whether it changed anything, so it must not try to guess when to
commit.

Reading never opens a transaction, here as in my superclass. I answer from the
object I hold.
"
Class {
	#name : #SoilDetachedObject,
	#superclass : #SoilFullyDetachedObject,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #'instance creation' }
SoilDetachedObject class >> on: anObject in: aTransaction [
	| detached |
	detached := super on: anObject in: aTransaction.
	detached soil: aTransaction soil.
	^ detached
]

{ #category : #accessing }
SoilDetachedObject >> soil [
	^ soil
]

{ #category : #accessing }
SoilDetachedObject >> soil: aSoil [
	soil := aSoil
]

{ #category : #writing }
SoilDetachedObject >> writeBack [
	"my object, back at my objectId, in a transaction of my own - as the next version
	of what is stored there. It used to go in as a record of its own, without a
	predecessor, and a reader on an older version then found nothing at my objectId:
	the metabase backup of every database whose limits were written during the copy
	stopped on it (2026-09-26).

	A commit leaves the transaction aborted already, so the ensure does not touch it"
	| txn |
	txn := soil newTransaction.
	^ [ txn atObjectId: objectId putNewVersionOf: object.
	  txn commit ]
		ensure: [ txn isAborted ifFalse: [ txn abort ] ]
]
