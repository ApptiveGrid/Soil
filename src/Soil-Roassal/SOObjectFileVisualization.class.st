Class {
	#name : #SOObjectFileVisualization,
	#superclass : #RSAbstractContainerBuilder,
	#instVars : [
		'objects',
		'links',
		'soil',
		'canvas'
	],
	#classInstVars : [
		'soil'
	],
	#category : #'Soil-Roassal'
}

{ #category : #examples }
SOObjectFileVisualization class >> example01 [
	| builder |
	builder := self new.
	self halt.
	builder objects: self someObjects.
	builder links: { 'root'-> 'extent index' }.
	builder asPresenter open
]

{ #category : #accessing }
SOObjectFileVisualization class >> first [
	^ (ExColumn on: 'ext4_inode')
		addAll: {
			ExSimpleText on: 'i_block'.
			ExSimpleBox on: 'eh_header'.
			ExBoxWithBody on: 'root'.
			ExSimpleText on: ''.
			 };
		yourself
]

{ #category : #'instance creation' }
SOObjectFileVisualization class >> on: aSoil [
	^ self new
		soil: aSoil
]

{ #category : #accessing }
SOObjectFileVisualization class >> second [
	^ (ExColumn on: 'index node')
		addAll: {
			ExSimpleBox on: 'node header'.
			ExBoxWithBody on: 'extent index'.
			ExBasicText on: '...'.
			ExBasicText on: '...'.
			ExBoxWithBody on: 'extent index'.
			 };
		yourself
]

{ #category : #'as yet unclassified' }
SOObjectFileVisualization class >> someObjects [
	^ {self first. self second}
]

{ #category : #'public - attach point' }
SOObjectFileVisualization >> attachPoint [
	^ RSStartEndAttachPoint new
		startAttachPoint: (RSBorderAttachPoint new);
		endAttachPoint: (RSBorderAttachPoint new endOffset: 10);
		yourself
]

{ #category : #accessing }
SOObjectFileVisualization >> canvas [
	canvas := RSCanvas new.
	self renderIn: canvas.
	^ canvas
]

{ #category : #'as yet unclassified' }
SOObjectFileVisualization >> createLineFrom: shapeFrom to: shapeTo [
	| arrow |
	arrow := RSShapeFactory arrow.
	arrow size: 10.
	^ RSLine new
		markerEnd: arrow;
		color: Color black;
		attachPoint: self attachPoint;
		from: shapeFrom;
		to: shapeTo;
		yourself
]

{ #category : #'accessing - defaults' }
SOObjectFileVisualization >> defaultContainer [
	| c |
	c := RSCanvas new @ RSCanvasController.
	c camera zoomRatio: 0.7.
	^ c
]

{ #category : #'as yet unclassified' }
SOObjectFileVisualization >> generateObjects [
	objects := {
		self indexColumn.
		self heapColumn }
]

{ #category : #'as yet unclassified' }
SOObjectFileVisualization >> heapColumn [
	| column records |
	column := SOIndexColumn on: 'segment'.
	records := soil objectRepository firstSegment objectFile allRecords.
	records size to: 1 by: -1 do: [ :n |
		column add: (SOSimpleBox on: 'object-', (records at: n) key first asString) ].
	^ column
]

{ #category : #'as yet unclassified' }
SOObjectFileVisualization >> indexColumn [
	| lastId column indexFile |
	column := SOIndexColumn on: 'index'.
	links := OrderedCollection new.
	indexFile := soil objectRepository segments first indexFile.
	lastId := indexFile lastObjectIndex.
	lastId to: 1 by: -1 do: [ :n | | position |
		position := indexFile positionAt: n.
		column add: (SOSimpleBox on: 'index-', n asString).
		(position = 0) ifFalse: [
			links add: ( ('index-', n asString) -> ('object-', position asString) ) ] ].
	^ column
]

{ #category : #'as yet unclassified' }
SOObjectFileVisualization >> inspectionSoil [
	<inspectorPresentationOrder: 0 title: 'soil'>
	^ SpRoassal3InspectorPresenter  new
		canvas: self canvas;
		yourself
]

{ #category : #accessing }
SOObjectFileVisualization >> links: aCollection [
	links := aCollection
]

{ #category : #accessing }
SOObjectFileVisualization >> objects: aCollection [
	objects := aCollection
]

{ #category : #hooks }
SOObjectFileVisualization >> renderIn: aCanvas [
	"render columns"
	aCanvas addAll: (objects collect: [ :each | each  asShape]).
	self renderLinksOn: aCanvas.
	RSHorizontalLineLayout on: aCanvas nodes
]

{ #category : #rendering }
SOObjectFileVisualization >> renderLinksOn: aRSCanvas [
	| allShapes |
	allShapes := aRSCanvas allChildren select: [:each | each model notNil ].
	aRSCanvas addAll: (links collect: [ :assoc | | from to |
		from := self shapeNamed: assoc key in: allShapes.
		to := self shapeNamed: assoc value in: allShapes.
		self createLineFrom: from to: to.
		 ])
]

{ #category : #'as yet unclassified' }
SOObjectFileVisualization >> shapeNamed: aString in: aCollection [
	^ aCollection detect: [ :each | each model name = aString ]
]

{ #category : #accessing }
SOObjectFileVisualization >> soil: aSoil [
	soil := aSoil
]
