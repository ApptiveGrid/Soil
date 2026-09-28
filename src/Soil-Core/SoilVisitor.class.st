Class {
	#name : #SoilVisitor,
	#superclass : #SoilBasicVisitor,
	#instVars : [
		'toBeProcessed',
		'seen',
		'depthFirst',
		'databaseVersion',
		'soil',
		'transaction'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #api }
SoilVisitor >> beBreadthFirst [ 
	depthFirst := false.
	seen := Set new.
	toBeProcessed := OrderedCollection new
]

{ #category : #api }
SoilVisitor >> beDepthFirst [
	depthFirst := true.
	seen := Set new.
	toBeProcessed := nil
]

{ #category : #accessing }
SoilVisitor >> databaseVersion [
	^ databaseVersion ifNil: [ 
		databaseVersion := soil control databaseVersion  ]
]

{ #category : #initialization }
SoilVisitor >> initialize [ 
	super initialize.
	self beBreadthFirst 
]

{ #category : #api }
SoilVisitor >> processLoop [ 
	| objectId |
	[ toBeProcessed isEmpty ] whileFalse: [  
		objectId := toBeProcessed  removeFirst.
		self visit: (self recordAt: objectId) ]
]

{ #category : #accessing }
SoilVisitor >> processObjectId: aSoilObjectId [ 
	((aSoilObjectId segment == 0) and: [ aSoilObjectId index == 2 ]) ifTrue: [ ^ self ].
	(seen includes: aSoilObjectId) ifTrue: [ ^ aSoilObjectId ].
	seen add: aSoilObjectId.
	^ depthFirst 
		ifTrue: [
			self visit: (self recordAt: aSoilObjectId).
			aSoilObjectId ]
		ifFalse: [  
			toBeProcessed add: aSoilObjectId ]
]

{ #category : #accessing }
SoilVisitor >> recordAt: aSoilObjectId [
	"Every record is read at the databaseVersion, in whichever order the graph is
	walked. The depth-first walk used to read the current version, past the cache and
	past any transaction the visitor had been handed"
	^ ((soil objectRepository segmentAt: aSoilObjectId segment)
		basicAt: aSoilObjectId index
		version: self databaseVersion) objectId: aSoilObjectId
]

{ #category : #accessing }
SoilVisitor >> soil [

	^ soil
]

{ #category : #accessing }
SoilVisitor >> soil: anObject [

	soil := anObject
]

{ #category : #accessing }
SoilVisitor >> transaction [

	^ transaction
]

{ #category : #accessing }
SoilVisitor >> transaction: aTransaction [
	"A visitor does not need a transaction to read - its databaseVersion is enough. It
	may be handed one, or open one itself, when something it checks has to go through
	one. Then the records it reads have to be those the transaction sees, so taking
	the transaction takes its read version as well"
	transaction := aTransaction.
	databaseVersion := aTransaction readVersion
]

{ #category : #visiting }
SoilVisitor >> visitFirstSegment: aSoilObjectSegment [ 
	depthFirst 
		ifTrue: [ self visit: (self recordAt: SoilObjectId root) ] 
		ifFalse: [ self processObjectId: SoilObjectId root ].			
	self visitObjectSegment: aSoilObjectSegment 
]

{ #category : #visiting }
SoilVisitor >> visitIndex: anIndex [
	"An index is read at the databaseVersion, like the records. Read as it is now, it
	hands out entries committed after that version, which point to objects that do not
	exist at it - see SoilBackupVisitor>>copyIndexAt:segment:, which learned it first.
	The behavior registry is the exception: its entries are not journaled, so it can
	only be read as it is now"
	| iterator assoc |
	iterator := anIndex newIterator.
	anIndex == soil behaviorRegistry index ifFalse: [
		iterator
			journal: soil journal;
			readVersion: self databaseVersion ].
	[ (assoc := iterator nextAssociation) isNil ] whileFalse: [
		assoc value isRemoved ifFalse: [
			self processIndexValue: assoc value asSoilObjectId ] ]
]

{ #category : #visiting }
SoilVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	super visitPersistentClusterVersion: aSoilPersistentClusterVersion.
	aSoilPersistentClusterVersion indexIds do:[ :indexId |
		self 
			processIndexId: indexId 
			segment: (soil objectRepository segmentAt: aSoilPersistentClusterVersion segment) ].
	^ aSoilPersistentClusterVersion 
]

{ #category : #visiting }
SoilVisitor >> visitSoil: aSoil [ 
	super visitSoil: aSoil.
	depthFirst ifFalse: [  
		self processLoop ]
]

{ #category : #visiting }
SoilVisitor >> visitWithTransaction: aSoil [
	self transaction: aSoil newTransaction.
	[ self visit: aSoil ]
		ensure: [ transaction abort ]
]
