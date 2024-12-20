Class {
	#name : #SoilVisitor,
	#superclass : #Object,
	#category : #'Soil-Core-Visitor'
}

{ #category : #testing }
SoilVisitor class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilVisitor
]

{ #category : #'as yet unclassified' }
SoilVisitor >> inspectionGraph [
	<inspectorPresentationOrder: 800 title: 'graph'>

	^ SpRoassalPresenter new canvas: self roassalCanvas 
]

{ #category : #'as yet unclassified' }
SoilVisitor >> roassalCanvas [ 
	| canvas allNodes shapes nodes |
	canvas := RSCanvas new.
	allNodes := self allNodes.
	shapes := nodes values collect: [ :node | | box lbl |
		lbl := RSLabel new
			text: node asString;
			yourself.
		box := RSBox new
			withBorder;
			color: node graphColor;
			cornerRadius: (RSCornerRadius new right: 20; left: 20);
			extent: lbl extent + 10.
		RSComposite new
			draggable;
			model: node;
			shapes: (RSGroup with: box with: lbl );
			yourself ].
	canvas addAll: shapes.
	canvas @ RSCanvasController.
	RSLineBuilder orthoVertical   
		markerEnd: (RSMarker new
			offset: 3;
			shape: (RSShapeFactory triangle
				color: Color black;
				size: 6;
				yourself));
		attachPoint: RSVerticalAttachPoint new;
		canvas: canvas;
		shapes: canvas nodes;
		connectFrom: #parent.
	RSTreeLayout new 
		"verticallyReverse;"
		on: canvas nodes.
	^ canvas
]

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
SoilVisitor >> visitControl: aSoilControlFile [ 

]

{ #category : #visiting }
SoilVisitor >> visitDatabaseJournal: aSoilJournal [ 
	self visitAll: aSoilJournal fragmentFiles.
	^ aSoilJournal 
]

{ #category : #visiting }
SoilVisitor >> visitIndexManager: aSoilIndexManager [ 
	^ aSoilIndexManager 
]

{ #category : #visiting }
SoilVisitor >> visitJournalFragmentFile: aSoilJournalFragmentFile [ 
	aSoilJournalFragmentFile open.
	[ self visitAll: aSoilJournalFragmentFile transactionJournals ]
		ensure: [ aSoilJournalFragmentFile close ].
	^ aSoilJournalFragmentFile 
]

{ #category : #visiting }
SoilVisitor >> visitMetaSegment: aSoilMetaSegment [ 
	self visit: aSoilMetaSegment indexManager.
	^ aSoilMetaSegment 
]

{ #category : #visiting }
SoilVisitor >> visitObjectId: aSoilObjectId [ 
	^ aSoilObjectId 
]

{ #category : #visiting }
SoilVisitor >> visitObjectRepository: aSoilObjectRepository [ 
	self visitAll: aSoilObjectRepository allSegments.
	^ aSoilObjectRepository 
]

{ #category : #visiting }
SoilVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	(aSoilObjectSegment id = 1) ifTrue: [ 
		self visit: (aSoilObjectSegment at: 1) ].
	self visit: aSoilObjectSegment indexManager.

	^ aSoilObjectSegment 
]

{ #category : #visiting }
SoilVisitor >> visitPagedFileIndexStore: aSoilPagedFileIndexStore [ 
	
]

{ #category : #visiting }
SoilVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	aSoilPersistentClusterVersion references 
		do: [ :reference | self processReference: reference ].
	^ aSoilPersistentClusterVersion 
]

{ #category : #visiting }
SoilVisitor >> visitSkipList: aSoilSkipList [ 
	self visit: aSoilSkipList store
]

{ #category : #visiting }
SoilVisitor >> visitSoil: aSoil [ 
	self visit: aSoil control.
	self visit: aSoil objectRepository.
	self visit: aSoil journal.
	^ aSoil
]

{ #category : #visiting }
SoilVisitor >> visitTransactionJournal: aSoilTransactionJournal [ 
	^ aSoilTransactionJournal 
]
