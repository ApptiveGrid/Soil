Class {
	#name : #SoilVisitor,
	#superclass : #Object,
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilVisitor >> visit: anObject [ 
	^ anObject acceptSoil: self 
	
]

{ #category : #visiting }
SoilVisitor >> visitAll: aCollection [ 
	^ aCollection collect: [ :each |
		self visit: each ]
]

{ #category : #visiting }
SoilVisitor >> visitIndexManager: aSoilIndexManager [ 
	^ aSoilIndexManager 
]

{ #category : #visiting }
SoilVisitor >> visitJournal: aSoilJournal [ 
	self visitAll: aSoilJournal transactionJournals.
	^ aSoilJournal 
]

{ #category : #'as yet unclassified' }
SoilVisitor >> visitMetaSegment: aSoilMetaSegment [ 
	self visit: aSoilMetaSegment indexManager.
	^ aSoilMetaSegment 
]

{ #category : #visiting }
SoilVisitor >> visitObjectRepository: aSoilObjectRepository [ 
	self visitAll: aSoilObjectRepository allSegments.
	^ aSoilObjectRepository 
]

{ #category : #visiting }
SoilVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	self visit: aSoilObjectSegment indexManager.

	^ aSoilObjectSegment 
]

{ #category : #visiting }
SoilVisitor >> visitParameters: aSoilParameterFile [ 

]

{ #category : #visiting }
SoilVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	^ aSoilPersistentClusterVersion 
]

{ #category : #visiting }
SoilVisitor >> visitSoil: aSoil [ 
	self visit: aSoil settings.
	self visit: aSoil objectRepository.
	self visit: aSoil journal.
	^ aSoil
]

{ #category : #visiting }
SoilVisitor >> visitTransactionJournal: aSoilTransactionJournal [ 
	^ aSoilTransactionJournal 
]
