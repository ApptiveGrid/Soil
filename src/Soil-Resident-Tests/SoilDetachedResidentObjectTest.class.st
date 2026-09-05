"
The wire between a detached object and a resident: a change to the object has to
reach the resident, so that it -- not the object -- decides when the write
happens.
"
Class {
	#name : #SoilDetachedResidentObjectTest,
	#superclass : #SoilResidentTest,
	#category : #'Soil-Resident-Tests'
}

{ #category : #accessing }
SoilDetachedResidentObjectTest >> path [
	^ 'soil-detached-resident-tests'
]

{ #category : #tests }
SoilDetachedResidentObjectTest >> testChangedReachesTheResidentAndBecomesWork [
	"end to end: somebody changes the object, the resident is the one who notices,
	and the work it then does is its own -- in its own transaction, on its own
	schedule"
	| supervisor resident detached txn |
	self addResident: (SoilTestResidentDescription new workDuration: 10 milliSeconds).
	supervisor := self startedSupervisor.
	resident := supervisor residentNamed: #dummy.

	txn := soil newTransaction.
	detached := SoilDetachedResidentObject
		on: ((soil residentRegistryIn: txn) descriptionNamed: #dummy) workspace
		in: txn.
	detached resident: resident.
	txn abort.

	self assert: resident stepCount equals: 0.
	detached changed.
	self waitUntil: [ resident stepCount = 1 ] within: 5 seconds.

	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilDetachedResidentObjectTest >> testForwardsWithoutAResidentAndStaysSilent [
	"a detached object without a wire is still a usable detached object -- it just
	tells nobody"
	| supervisor detached txn |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.

	txn := soil newTransaction.
	detached := SoilDetachedResidentObject
		on: ((soil residentRegistryIn: txn) descriptionNamed: #dummy) workspace
		in: txn.
	txn abort.

	detached changed.
	self assert: detached resident isNil.

	self stop: supervisor within: 5 seconds
]
