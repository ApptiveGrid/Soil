"
A view of the object graph of a walk with what was found in it - the client that shows what SoilGraphTracker collected and what the consistency trackers of the same walk found, each finding on the node it is about (SoilFinding>>nodeIn:). It is a picture for a person in the development image: the Roassal canvas it draws needs Roassal, which BaselineOfSoil does not load.

#of: walks a database once for all three. What used to be SoilConsistencyInspectorVisitor is this: the checks are the consistency trackers', the graph is the graph tracker's, and only the drawing is left here.
"
Class {
	#name : #SoilGraphView,
	#superclass : #Object,
	#instVars : [
		'graph',
		'findings'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #'instance creation' }
SoilGraphView class >> graph: aSoilGraphTracker findings: aCollectionOfFindings [
	^ self new
		graph: aSoilGraphTracker findings: aCollectionOfFindings;
		yourself
]

{ #category : #'instance creation' }
SoilGraphView class >> of: aSoil [
	"one walk: the graph, and the findings of both levels, read at one version"
	| visitor graph database application |
	visitor := SoilTrackingVisitor new.
	graph := visitor addTracker: SoilGraphTracker new.
	database := visitor addTracker: SoilDatabaseConsistencyTracker new.
	application := visitor addTracker: SoilApplicationConsistencyTracker new.
	visitor track: aSoil.
	^ self graph: graph findings: database findings , application findings
]

{ #category : #accessing }
SoilGraphView >> findings [
	^ findings
]

{ #category : #accessing }
SoilGraphView >> graph [
	^ graph
]

{ #category : #initialization }
SoilGraphView >> graph: aSoilGraphTracker findings: aCollectionOfFindings [
	graph := aSoilGraphTracker.
	findings := aCollectionOfFindings.
	findings do: [ :each |
		(each nodeIn: graph) ifNotNil: [ :node | node addFinding: each ] ]
]

{ #category : #inspector }
SoilGraphView >> inspectionGraph [
	<inspectorPresentationOrder: 1800 title: 'graph'>

	^ SpRoassalPresenter new canvas: self roassalCanvas
]

{ #category : #accessing }
SoilGraphView >> nodesWithFindings [
	^ graph nodes select: [ :each | each hasFindings ]
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
