"
A tracker that checks what it is shown and collects what fails as findings (SoilFinding) - it reports, it does not repair. Checking and repairing are two calls; each finding offers its repair actions, and SoilRepairVisitor carries out the ones a person chose.

Two levels, one subclass each: SoilDatabaseConsistencyTracker checks the structure on disk and needs no transaction, SoilApplicationConsistencyTracker checks that the stored objects fit the classes of this image and needs one.
"
Class {
	#name : #SoilConsistencyTracker,
	#superclass : #SoilTracker,
	#instVars : [
		'findings'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #checking }
SoilConsistencyTracker >> check: anObject using: aBlock [
	"a check that fails in a way no finding names is kept as one all the same"
	aBlock 
		on: Error 
		do: [ :error | self report: (SoilUnexpectedFinding subject: anObject error: error) ]
]

{ #category : #checking }
SoilConsistencyTracker >> versionsOf: aCluster in: aVisitor onFault: aBlock do: eachBlock [
	"aCluster and every version before it, newest first, each without its payload, handed
	to eachBlock as the chain is followed and not kept: what is held is the set of
	positions the walk has been at, and nothing else.
	Where the chain cannot be followed on - a previous version that cannot be read, one
	that runs into the record after it, a version that does not come before the one after
	it, a position it has already been at - the fault is handed to aBlock with the
	position of the last record that is fine - the one whose link to its previous version
	cannot be followed - and the walk ends there.
	Without the guard on positions a loop never ends.
	A record is written behind the ones before it, so a previous version ends where the
	record after it starts at the latest. One that starts before it and runs on into it
	is not a record but bytes that read as one - a link into the middle of a record, say -
	and what such a head names, its descriptions above all, is noise"
	| segment current positions |
	segment := aVisitor soil objectRepository segmentAt: aCluster segment.
	positions := Set with: aCluster position.
	current := aCluster.
	eachBlock value: current.
	[ current hasPreviousVersion ] whileTrue: [ | position previous |
		position := current previousVersionPosition.
		(positions includes: position) ifTrue: [ 
			^ aBlock value: current position value: 'previous version leads back to position ', position printString ].
		positions add: position.
		previous := [ 
			self 
				countsOfHeadAt: position 
				in: segment 
				fitBefore: (position < current position ifTrue: [ current position ] ifFalse: [ nil ]).
			(segment headAtPosition: position) objectId: aCluster objectId; yourself ]
			on: Error 
			do: [ :error | 
				^ aBlock value: current position value: 'previous version at position ', position printString, ' cannot be read: ', error messageText asString ].
		(position < current position and: [ position + previous length > current position ]) ifTrue: [ 
			^ aBlock value: current position value: 'previous version ', previous version printString, ' at position ', position printString, ' overlaps the record at ', current position printString ].
		previous version < current version ifFalse: [ 
			^ aBlock value: current position value: 'previous version ', previous version printString, ' at position ', position printString, ' does not come before version ', current version printString ].
		eachBlock value: previous.
		current := previous ]
]

{ #category : #checking }
SoilConsistencyTracker >> chainOf: aCluster in: aVisitor onFault: aBlock [
	"aCluster and every version before it, newest first, each without its payload, as a
	collection. Holds the whole chain: an object that is written at every commit has a
	chain of a million records and the collection is more than a gigabyte - what
	#versionsOf:in:onFault:do: is for. This one stays for the checks that need the
	chain as a whole"
	| versions |
	versions := OrderedCollection new.
	self 
		versionsOf: aCluster 
		in: aVisitor 
		onFault: aBlock 
		do: [ :each | versions add: each ].
	^ versions
]

{ #category : #checking }
SoilConsistencyTracker >> count: anInteger of: aSize names: aString fitsIn: aNumberOfBytes [
	anInteger * aSize > aNumberOfBytes ifTrue: [ 
		Error signal: anInteger printString, ' ', aString, ' cannot be in the ', (aNumberOfBytes max: 0) printString, ' bytes that are left' ]
]

{ #category : #checking }
SoilConsistencyTracker >> countsOfHeadAt: aPosition in: aSegment fitBefore: anEndOrNil [
	"signal when the counts the bytes at aPosition name as a head cannot be in the bytes
	before anEndOrNil, or before the end of the file. Read from the bytes themselves,
	before #headAtPosition: allocates what they name: the check of 62398e23 followed a
	previous version into the bytes of another record, read 530 million behavior
	descriptions there and asked for a collection of four gigabytes, which killed the
	scheduler. A real head always fits.

	The layout is SoilPersistentClusterVersion>>readHeadFrom:'s: version, previous
	version, the behavior descriptions as pairs of numbers, references of eight bytes,
	index ids of one byte at least"
	| objectFile end offset bytes count |
	objectFile := aSegment instVarNamed: #objectFile.
	end := anEndOrNil ifNil: [ objectFile size ] ifNotNil: [ anEndOrNil min: objectFile size ].
	bytes := (objectFile basicAtPosition: aPosition length: (end - aPosition min: 30)) readStream.
	self readCountFrom: bytes; readCountFrom: bytes.
	count := self readCountFrom: bytes.
	offset := aPosition + bytes position.
	self count: count of: 2 names: 'behavior descriptions' fitsIn: end - offset.
	bytes := (objectFile basicAtPosition: offset length: (end - offset min: count * 20 + 10)) readStream.
	count timesRepeat: [ self readCountFrom: bytes; readCountFrom: bytes ].
	count := self readCountFrom: bytes.
	offset := offset + bytes position.
	self count: count of: 8 names: 'references' fitsIn: end - offset.
	offset := offset + (count * 8).
	bytes := (objectFile basicAtPosition: offset length: (end - offset min: 10)) readStream.
	count := self readCountFrom: bytes.
	self count: count of: 1 names: 'index ids' fitsIn: end - offset - bytes position
]

{ #category : #accessing }
SoilConsistencyTracker >> findings [
	^ findings
]

{ #category : #initialization }
SoilConsistencyTracker >> initialize [ 
	super initialize.
	findings := OrderedCollection new
]

{ #category : #checking }
SoilConsistencyTracker >> readCountFrom: aStream [
	"a number as #nextLengthEncodedInteger writes it, seven bits a byte, the lowest
	first; bytes that end before it are a head that does not fit"
	| value shift byte |
	value := 0.
	shift := 0.
	[ byte := aStream next ifNil: [ ^ Error signal: 'the head ends before its counts' ].
	value := value + ((byte bitAnd: 127) bitShift: shift).
	shift := shift + 7.
	byte >= 128 ] whileTrue.
	^ value
]

{ #category : #checking }
SoilConsistencyTracker >> report: aSoilFinding [
	findings add: aSoilFinding
]
