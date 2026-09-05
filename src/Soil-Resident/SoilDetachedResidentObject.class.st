"
A detached object whose changes reach a resident.

This is where the three parts meet. The resident holds no materialized object of
its own -- it outlives many transactions, and a held object would be a snapshot
growing staler with every foreign change. The detached object is where that
object may live. And I am the wire between them: when something changes, I tell
the resident, and it decides what happens next.

What it usually does is wait. A limit that is used a hundred times in a minute
should not cause a hundred writes; the resident lets the changes pile up for its
grace period and then writes once. That is why #changed reports rather than
writes, even though my superclass could write itself: the resident is the one
that knows when.
"
Class {
	#name : #SoilDetachedResidentObject,
	#superclass : #SoilDetachedObject,
	#instVars : [
		'resident'
	],
	#category : #'Soil-Resident'
}

{ #category : #notifying }
SoilDetachedResidentObject >> changed [
	"the whole point of me"
	resident ifNotNil: [ resident noteChanged ]
]

{ #category : #accessing }
SoilDetachedResidentObject >> resident [
	^ resident
]

{ #category : #accessing }
SoilDetachedResidentObject >> resident: aResident [
	resident := aResident
]
