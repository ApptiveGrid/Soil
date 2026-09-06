"
Wait for a signal -- and do not wait at all while the resident still has work.

The second half is what turns a signal into a drain. A tracker that is woken
once works through what is there without needing a signal per item, and blocks
again only when the flag has gone down. That is why the question is put to the
resident's flag and not to the semaphore: signals count up, so n signals would
otherwise become n runs, and a queue that filled up while a step ran would need
exactly as many wake-ups as it has items.
"
Class {
	#name : #SoilSignalRunStrategy,
	#superclass : #SoilResidentRunStrategy,
	#category : #'Soil-Resident'
}

{ #category : #waiting }
SoilSignalRunStrategy >> awaitDue [
	resident hasPendingWork ifTrue: [ ^ self ].
	resident waitForWork
]
