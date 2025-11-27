Class {
	#name : #SoilBasicVisitor,
	#superclass : #Object,
	#category : #'Soil-Core-Visitor'
}

{ #category : #testing }
SoilBasicVisitor class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilBasicVisitor
]

{ #category : #processing }
SoilBasicVisitor >> processBehaviorDescription: aSoilObjectId [ 
	self processObjectId: aSoilObjectId 
]

{ #category : #visiting }
SoilBasicVisitor >> processIndexId: indexId segment: aSegment [  
	self visit: (aSegment indexAt: indexId)
]

{ #category : #visiting }
SoilBasicVisitor >> processIndexValue: objectId [
	self processObjectId: objectId 
]

{ #category : #visiting }
SoilBasicVisitor >> processObjectId: aSoilObjectId [ 
	^ aSoilObjectId 
]

{ #category : #processing }
SoilBasicVisitor >> processReference: aSoilObjectId [ 
	self processObjectId: aSoilObjectId 
]

{ #category : #visiting }
SoilBasicVisitor >> visit: anObject [ 
	^ anObject acceptSoil: self 
	
]

{ #category : #visiting }
SoilBasicVisitor >> visitAll: aCollection [ 
	^ aCollection collect: [ :each |
		self visit: each ]
]

{ #category : #visiting }
SoilBasicVisitor >> visitControl: aSoilControlFile [ 

]

{ #category : #visiting }
SoilBasicVisitor >> visitDatabaseJournal: aSoilJournal [ 
	self visitAll: aSoilJournal fragmentFiles.
	^ aSoilJournal 
]

{ #category : #visiting }
SoilBasicVisitor >> visitFirstSegment: aSoilObjectSegment [ 
	self visit: (aSoilObjectSegment at: 1).
	self visitObjectSegment: aSoilObjectSegment
]

{ #category : #visiting }
SoilBasicVisitor >> visitIndex: anIndex [ 
	| iterator assoc objectId |
	iterator := anIndex newIterator.
	[ (assoc := iterator nextAssociation) isNil ] whileFalse: [ 
		objectId := assoc value asSoilObjectId.
		self processIndexValue: objectId. ]
]

{ #category : #visiting }
SoilBasicVisitor >> visitIndexManager: aSoilIndexManager [ 
	^ aSoilIndexManager 
]

{ #category : #visiting }
SoilBasicVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
	aSoilJournalFragmentFile open.
	[ self visitAll: aSoilJournalFragmentFile transactionJournals ]
		ensure: [ aSoilJournalFragmentFile close ].
	^ aSoilJournalFragmentFile 
]

{ #category : #visiting }
SoilBasicVisitor >> visitMetaSegment: aSoilMetaSegment [ 
	self visitObjectSegment: aSoilMetaSegment

]

{ #category : #visiting }
SoilBasicVisitor >> visitObjectId: aSoilObjectId [ 
	^ self processObjectId: aSoilObjectId 
]

{ #category : #visiting }
SoilBasicVisitor >> visitObjectRepository: aSoilObjectRepository [ 
	self visitAll: aSoilObjectRepository allSegments.
	^ aSoilObjectRepository 
]

{ #category : #visiting }
SoilBasicVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	self visit: aSoilObjectSegment indexManager.

	^ aSoilObjectSegment 
]

{ #category : #visiting }
SoilBasicVisitor >> visitPagedFileIndexStore: aSoilPagedFileIndexStore [ 
	| pageOffset page |
	pageOffset := 1.
	[ pageOffset == 0 ] whileFalse: [  
		page := aSoilPagedFileIndexStore pageAt: pageOffset.
		page items do: [ :item |
			item value isRemoved ifFalse: [ 
				self processIndexValue: item value asSoilObjectId ] ].
		pageOffset := page next ].
	^ aSoilPagedFileIndexStore 
]

{ #category : #visiting }
SoilBasicVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	aSoilPersistentClusterVersion references 
		do: [ :reference | self processReference: reference ].
	aSoilPersistentClusterVersion behaviorDescriptions 
		do: [ :description | self processBehaviorDescription: description ].
	^ aSoilPersistentClusterVersion 
]

{ #category : #visiting }
SoilBasicVisitor >> visitSkipList: aSkiplist [ 
	self visitIndex: aSkiplist
]

{ #category : #visiting }
SoilBasicVisitor >> visitSkipListDictionary: aSkipListDictionary [ 
	
]

{ #category : #visiting }
SoilBasicVisitor >> visitSoil: aSoil [ 
	self visit: aSoil control.
	self visit: aSoil objectRepository.
	self visit: aSoil journal.
	^ aSoil
]

{ #category : #visiting }
SoilBasicVisitor >> visitTransactionJournal: aSoilTransactionJournal [ 
	^ aSoilTransactionJournal 
]
