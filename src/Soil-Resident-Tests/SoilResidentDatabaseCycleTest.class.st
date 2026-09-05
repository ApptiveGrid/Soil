"
The embedder's cycle, which SoilResidentTest deliberately leaves out: it proves
the generic base ""without any embedder's registry of open databases"", so every
one of its tests lives inside a single freshly created database.

What is missing there is what an embedder actually does over time. A database is
opened, worked in, closed, opened again -- and residents are added to it after it
already exists. Two contracts only become visible across that boundary:

 - a resident is *not* what survives. The registry and the workspace are
   persistent, the SoilResident is not; on reopening, the description mints a
   fresh instance, and the work it did before has to be found in the workspace,
   not in the instance.
 - SoilResidentDescription>>initializeFrom: says it is called ""once when I am
   added to a database, and from the embedder's migration path when I am added to
   a database that already exists"". Only the first half is exercised by the
   existing tests, because their database is always brand new.

I subclass SoilResidentTest for its fixture and helpers (#setUp, #addResident:,
#startedSupervisor, #stop:within:, #waitUntil:within:). Its own tests are *not*
inherited -- the superclass is concrete, so shouldInheritSelectors is false --
and that is intended here: they run once, in their own class.
"
Class {
	#name : #SoilResidentDatabaseCycleTest,
	#superclass : #SoilResidentTest,
	#category : #'Soil-Resident-Tests'
}

{ #category : #accessing }
SoilResidentDatabaseCycleTest >> path [
	"my own directory, so a run of mine and a run of SoilResidentTest cannot meet
	on disk"
	^ 'soil-resident-cycle-tests'
]

{ #category : #helpers }
SoilResidentDatabaseCycleTest >> reopen [
	"what an embedder does between two runs of the image: close the database and
	open the same files again. Leaves #soil pointing at the open database, so the
	inherited tearDown still finds one"
	soil close.
	soil := SoilTestResidentDatabase path: self path.
	soil open.
	^ soil
]

{ #category : #helpers }
SoilResidentDatabaseCycleTest >> stepsOf: aName [
	"the persistent side of a resident: what its workspace holds, read without
	going through any instance"
	| txn |
	txn := soil newTransaction.
	^ [ ((soil residentRegistryIn: txn) descriptionNamed: aName) workspace at: #steps ]
		ensure: [ txn abort ]
]

{ #category : #helpers }
SoilResidentDatabaseCycleTest >> workOnce: aSupervisor [
	"one completed work unit of the dummy, so there is something in the workspace
	that a later reopening can find"
	| resident |
	resident := aSupervisor residentNamed: #dummy.
	resident triggerWork.
	self waitUntil: [ resident stepCount = 1 ] within: 5 seconds.
	^ resident
]

{ #category : #tests }
SoilResidentDatabaseCycleTest >> testAddingAResidentLeavesTheOnesAlreadyThereUntouched [
	"the maintenance path must not disturb what is already in the database: the
	dummy's counted step is still there afterwards, and its description is still
	the one it worked through"
	| supervisor |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	self workOnce: supervisor.
	self stop: supervisor within: 5 seconds.
	self reopen.

	self addResident: SoilTestPassiveResidentDescription new.

	self assert: (self stepsOf: #dummy) equals: 1.
	supervisor := self startedSupervisor.
	self assert: (supervisor residentNamed: #dummy) stepCount equals: 0.
	self assert: (supervisor residentNamed: #passive) notNil.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentDatabaseCycleTest >> testClosingAfterTheStopLeavesNoResidentProcess [
	"the reason the stop handshake exists at all: nothing may still be running
	into a database that is being closed"
	| supervisor resident |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	resident := self workOnce: supervisor.
	self assert: resident hasRunningProcess.

	self assert: (self stop: supervisor within: 5 seconds) isEmpty.

	self deny: resident hasRunningProcess.
	self reopen
]

{ #category : #tests }
SoilResidentDatabaseCycleTest >> testReopeningBringsBackEveryRegisteredResident [
	"the registry is the persistent half: after reopening, loadFrom: has to find
	every description again, by name, without anybody re-adding them"
	| supervisor |
	self addResident: SoilTestResidentDescription new.
	self addResident: SoilTestPassiveResidentDescription new.
	supervisor := self startedSupervisor.
	self stop: supervisor within: 5 seconds.

	self reopen.

	supervisor := self startedSupervisor.
	self assert: supervisor residents size equals: 2.
	self assert: (supervisor residentNamed: #dummy) name equals: #dummy.
	self assert: (supervisor residentNamed: #passive) name equals: #passive.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentDatabaseCycleTest >> testResidentAddedToAnExistingDatabaseGetsItsWorkspace [
	"the migration half of initializeFrom:, which the existing tests cannot reach
	because their database is always brand new: the resident is added to a
	database that already exists, and has to arrive with its objects created"
	| supervisor |
	self reopen.

	self addResident: SoilTestResidentDescription new.

	self assert: (self stepsOf: #dummy) equals: 0.
	supervisor := self startedSupervisor.
	self workOnce: supervisor.
	self assert: (self stepsOf: #dummy) equals: 1.
	self stop: supervisor within: 5 seconds
]

{ #category : #tests }
SoilResidentDatabaseCycleTest >> testWorkSurvivesCloseAndReopenInTheWorkspaceNotTheInstance [
	"what persists is the workspace, not the resident. After reopening, the
	description mints a fresh instance -- its own counter starts at zero again,
	while the step it did before is still in the database"
	| supervisor resident registryId |
	self addResident: SoilTestResidentDescription new.
	supervisor := self startedSupervisor.
	resident := self workOnce: supervisor.
	self assert: resident stepCount equals: 1.
	self assert: (self stepsOf: #dummy) equals: 1.
	registryId := self residentRegistryObjectId.
	self stop: supervisor within: 5 seconds.

	self reopen.
	supervisor := self startedSupervisor.

	"the persistent half is the same object across the reopen -- this is what
	depends on the database having been closed and read back, unlike the identity
	of the resident below, which a fresh supervisor would give us anyway"
	self assert: self residentRegistryObjectId equals: registryId.
	self assert: (self stepsOf: #dummy) equals: 1.
	self deny: (supervisor residentNamed: #dummy) == resident.
	self assert: (supervisor residentNamed: #dummy) stepCount equals: 0.

	self workOnce: supervisor.
	self assert: (self stepsOf: #dummy) equals: 2.
	self stop: supervisor within: 5 seconds
]
