"
What recovery says about the way it went.

#recover has six ways out and used to take all of them in silence, which is how a
day of hunting a Windows problem could go by without the log ever naming which
one had happened. These tests stage the three that can be staged and hold each to
its own line.

Staging them means putting a database into the state a crash would leave. Every
commit that changed something checkpoints - SoilTransactionManager does it - so
after a clean close there is never anything past the last checkpoint. Winding the
control file's checkpoint back is what makes the difference, and it is the same
handle SoilJournalConverter reaches for.

The three not staged here: a database on read-only media, a fragment file missing
for the last checkpoint (unreachable through #open, which recreates one and
checkpoints before recovery looks), and a checkpoint that ends the journal
(#isNeeded appears to rule it out before #recover is entered).
"
Class {
	#name : #SoilRecoveryReportingTest,
	#superclass : #TestCase,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Tests'
}

{ #category : #helpers }
SoilRecoveryReportingTest >> commit: anInteger [
	"a committing transaction, so that the journal gets an entry to replay"
	| txn |
	txn := soil newTransaction.
	txn root: (SoilPersistentDictionary new
		at: #n put: anInteger;
		yourself).
	txn commit
]

{ #category : #helpers }
SoilRecoveryReportingTest >> path [
	^ 'soil-recovery-reporting-tests'
]

{ #category : #helpers }
SoilRecoveryReportingTest >> reopen [
	"close and open again, which is where recovery runs"
	soil close.
	soil := SoilReportingTestDatabase path: self path.
	soil open
]

{ #category : #running }
SoilRecoveryReportingTest >> setUp [
	super setUp.
	soil := SoilReportingTestDatabase path: self path.
	soil
		destroy;
		initializeFilesystem
]

{ #category : #running }
SoilRecoveryReportingTest >> tearDown [
	soil ifNotNil: [
		soil isOpen ifTrue: [ soil close ].
		soil destroy ].
	super tearDown
]

{ #category : #tests }
SoilRecoveryReportingTest >> testABogusCheckpointPositionIsNamedWithItsError [
	"the position does not read back as an entry, so recovery quietly starts a fresh
	fragment file. Quietly was the problem: the line carries the read error, which
	is the only thing that says what was wrong with the file"
	self commit: 1.
	soil control checkpoint: (SoilLogSequenceNumber fileNumber: 0 offset: 0).
	self reopen.
	self assert: (soil reportedMatching: 'does not read back') size equals: 1
]

{ #category : #tests }
SoilRecoveryReportingTest >> testACleanDatabaseSaysThereIsNothingToDo [
	"the common case, and it has to say something - otherwise silence still means
	either 'clean' or 'recovery never ran'"
	self commit: 1.
	self reopen.
	self assert: (soil reportedMatching: 'nothing past the last checkpoint') size equals: 1
]

{ #category : #tests }
SoilRecoveryReportingTest >> testAReplayCountsWhatItReplayed [
	"the count is the point: a line saying only that recovery ran leaves open
	whether it found one transaction or a thousand"
	| checkpoint |
	self commit: 1.
	checkpoint := soil control lastCheckpoint.
	self commit: 2.
	self commit: 3.
	"back to a checkpoint that is real but no longer the last - what a crash after
	those two commits would have left"
	soil control checkpoint: checkpoint.
	self reopen.
	self assert: (soil reportedMatching: 'replaying the journal from the last checkpoint') size equals: 1.
	self assert: (soil reportedMatching: 'replayed 2 transactions from 1 fragment file') size equals: 1
]

{ #category : #tests }
SoilRecoveryReportingTest >> testCommittingStaysSilent [
	"the hot path is out of scope, and it is easy to slip into: every commit that
	changed something checkpoints, so a line in Soil>>checkpoint would be one per
	commit"
	self commit: 1.
	self commit: 2.
	self commit: 3.
	self assert: (soil reportedMatching: 'checkpoint') isEmpty
]
