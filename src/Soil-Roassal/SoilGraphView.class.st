"
Draws the object graph a SoilGraphTracker collected, with the nodes the findings of the same walk are on in red and larger. A client of the graph and nothing else: the checks are the consistency trackers', the graph is SoilGraphTracker's. Needs Roassal, which BaselineOfSoil does not load - this package is for the development image.

SoilGraphView of: aSoil walks the database (SoilGraphTracker class>>of:) and is ready to inspect.
"
Class {
	#name : #SoilGraphView,
	#superclass : #Object,
	#instVars : [
		'graph'
	],
	#category : #'Soil-Roassal'
}

{ #category : #'instance creation' }
SoilGraphView class >> of: aSoil [
	^ self on: (SoilGraphTracker of: aSoil)
]

{ #category : #'instance creation' }
SoilGraphView class >> on: aSoilGraphTracker [
	^ self new
		graph: aSoilGraphTracker;
		yourself
]

{ #category : #accessing }
SoilGraphView >> graph [
	^ graph
]

{ #category : #accessing }
SoilGraphView >> graph: aSoilGraphTracker [
	graph := aSoilGraphTracker
]

{ #category : #inspector }
SoilGraphView >> inspectionGraph [
	<inspectorPresentationOrder: 1800 title: 'graph'>

	^ SpRoassalPresenter new canvas: self roassalCanvas
]

{ #category : #drawing }
SoilGraphView >> roassalCanvas [
	"the first thousand nodes by object id, the ones with findings red and larger"
	| canvas sorted shapes |
	canvas := RSCanvas new.
	sorted := graph nodes sorted: [ :a :b | a objectId index < b objectId index ].
	shapes := (sorted first: (sorted size min: 1000)) collect: [ :node | | box lbl |
		lbl := RSLabel new
			text: node asString;
			color: Color darkGray;
			yourself.
		box := RSBox new
			withBorder;
			color: node graphColor;
			cornerRadius: (RSCornerRadius new right: 20; left: 20);
			extent: lbl extent + 10 + node extent.
		RSComposite new
			draggable;
			model: node;
			shapes: (RSGroup with: box with: lbl);
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
		connectToAll: [ :node | node outgoing collect: [ :each | graph nodeAt: each ] ].
	RSForceBasedLayout new
		doNotUseProgressBar;
		charge: -3500;
		on: canvas nodes.
	^ canvas
]
