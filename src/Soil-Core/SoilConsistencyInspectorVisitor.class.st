Class {
	#name : #SoilConsistencyInspectorVisitor,
	#superclass : #SoilConsistencyVisitor,
	#instVars : [
		'nodes',
		'currentNode'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #adding }
SoilConsistencyInspectorVisitor >> addCluster: aSoilPersistentClusterVersion [ 
	nodes at: aSoilPersistentClusterVersion objectId ifPresent: [ Error signal ].
	^ nodes 
		at: aSoilPersistentClusterVersion objectId 
		ifAbsentPut: [
			SoilModelGraphNode new 
				objectId: aSoilPersistentClusterVersion objectId;
				yourself ]
]

{ #category : #checking }
SoilConsistencyInspectorVisitor >> check: anObject using: aBlock [
	aBlock 
		on: Error 
		do: [ :error | 
			errors at: anObject put: (error -> currentNode) ]
]

{ #category : #accessing }
SoilConsistencyInspectorVisitor >> errors [
	^ errors 
]

{ #category : #initialization }
SoilConsistencyInspectorVisitor >> initialize [ 
	super initialize.
	nodes := Dictionary new 
]

{ #category : #inspector }
SoilConsistencyInspectorVisitor >> inspectionGraph [
	<inspectorPresentationOrder: 1800 title: 'graph'>

	^ SpRoassalPresenter new canvas: self roassalCanvas 
]

{ #category : #accessing }
SoilConsistencyInspectorVisitor >> nodeAt: aSoilObjectId [ 
	^ nodes at: aSoilObjectId 
]

{ #category : #visiting }
SoilConsistencyInspectorVisitor >> processIndexValue: aSoilObjectId [ 
	self processOutgoing: aSoilObjectId.
	super processIndexValue: aSoilObjectId 
]

{ #category : #private }
SoilConsistencyInspectorVisitor >> processOutgoing: aSoilObjectId [ 
	currentNode addOutgoing: aSoilObjectId.

]

{ #category : #processing }
SoilConsistencyInspectorVisitor >> processReference: aSoilObjectId [ 
	self processOutgoing: aSoilObjectId.
	super processReference: aSoilObjectId 
]

{ #category : #private }
SoilConsistencyInspectorVisitor >> resolveNodes [
	nodes valuesDo: [ :each | 
		each resolveObjectIdsIn: self ].
	nodes keysAndValuesDo: [ :objectId :node | 
		node outgoing do: [ :outgoing |
			outgoing addIncoming: node ] ]
]

{ #category : #private }
SoilConsistencyInspectorVisitor >> roassalCanvas [ 
	| canvas shapes |
	canvas := RSCanvas new.
	shapes := ((nodes values sorted: [:a :b | a objectId index < b objectId index ])first: 1000)  collect: [ :node | | box lbl |
		lbl := RSLabel new
			text: node asString;
			color: Color darkGray;
			yourself.
		box := RSBox new
			withBorder;
			color: node graphColor;
			cornerRadius: (RSCornerRadius new right: 20; left: 20);
			extent: lbl extent + 10 + node extent .
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
		connectToAll: [:node | node references collect: [:each | nodes at: each] ].
	RSForceBasedLayout new
		doNotUseProgressBar;
		charge: -3500;
		on: canvas nodes.
	"RSTreeLayout  new 
	
		on: canvas nodes."
	^ canvas
]

{ #category : #private }
SoilConsistencyInspectorVisitor >> useNode: aSoilVisualNode during: aBlock [
	| oldNode |
	oldNode := currentNode.
	[ 
		currentNode := aSoilVisualNode.
		aBlock value ]
		ensure: [ 
			currentNode := oldNode ]
]

{ #category : #visiting }
SoilConsistencyInspectorVisitor >> visit: anObject [ 
	^ [ super visit: anObject ]
		on: Error do: [ :err | 
			currentNode addError: err ]
]

{ #category : #visiting }
SoilConsistencyInspectorVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	self 
		useNode: (self addCluster: aSoilPersistentClusterVersion) 
		during: [ super visitPersistentClusterVersion: aSoilPersistentClusterVersion ]
]
