Class {
	#name : #SoilFileWithLayoutTest,
	#superclass : #TestCase,
	#instVars : [
		'metadata'
	],
	#category : #'Soil-Core-Tests-Metadata'
}

{ #category : #accessing }
SoilFileWithLayoutTest >> aMoment [
	"whole microseconds: that is what a field keeps"
	^ DateAndTime year: 2026 month: 10 day: 6 hour: 8 minute: 30 second: 15 offset: 0 hours
]

{ #category : #accessing }
SoilFileWithLayoutTest >> path [
	^ FileLocator temp / 'soil-file-with-layout-test'
]

{ #category : #running }
SoilFileWithLayoutTest >> setUp [
	super setUp.
	SoilFileLockRegistry reset.
	self path ensureDeleteAll.
	self path ensureCreateDirectory.
	metadata := SoilMetadata new
		soil: (Soil new path: self path; yourself);
		yourself.
	metadata open
]

{ #category : #running }
SoilFileWithLayoutTest >> tearDown [
	"guarded: a test that did not get as far as opening must not bury its own failure"
	metadata ifNotNil: [ metadata stream ifNotNil: [ :each | each close ] ].
	self path ensureDeleteAll.
	super tearDown
]

{ #category : #tests }
SoilFileWithLayoutTest >> testAFieldIsWrittenUnderALockThatIsLetGoOfAfterwards [
	| written |
	written := self aMoment.
	metadata lastBackup: written.
	self assert: metadata lastBackup equals: written.
	self assert: metadata stream locks isEmpty
]

{ #category : #tests }
SoilFileWithLayoutTest >> testAFieldIsWrittenWhenWhoeverHoldsItLetsGoWithinAMoment [
	"two writers of different fields are not two writers of one field: a lock that is
	held for as long as a write takes is waited for"
	| field foreign written |
	"only in the image: locks of the file itself do not conflict within one process"
	metadata stream lockOnlyInImage.
	field := metadata fields at: #lastBackup.
	foreign := metadata stream lockFrom: field start length: field size for: Object new.
	[ (Delay forMilliseconds: 50) wait.
	foreign release ] fork.
	written := self aMoment.
	metadata lastBackup: written.
	self assert: metadata lastBackup equals: written
]

{ #category : #tests }
SoilFileWithLayoutTest >> testAFieldThatStaysHeldIsAnErrorAfterTheWait [
	| field foreign |
	metadata stream lockOnlyInImage.
	field := metadata fields at: #lastBackup.
	foreign := metadata stream lockFrom: field start length: field size for: Object new.
	[ self
		should: [ metadata lastBackup: self aMoment ]
		raise: SoilAlreadyLocked ]
		ensure: [ foreign release ].
	self assert: (SoilFileLockRegistry forPath: metadata path) numberOfLocks equals: 0
]

{ #category : #tests }
SoilFileWithLayoutTest >> testAnotherFieldIsNotHeldByTheLockOnOne [
	| field foreign written |
	metadata stream lockOnlyInImage.
	field := metadata fields at: #lastBackup.
	foreign := metadata stream lockFrom: field start length: field size for: Object new.
	[ written := self aMoment.
	metadata lastModified: written.
	self assert: metadata lastModified equals: written ]
		ensure: [ foreign release ]
]
