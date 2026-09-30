"
Collects the object graph of a walk: a node (SoilModelGraphNode) for every cluster the walk reads, with what it points to - its references and the values of its indexes - and what points to it. It collects, it does not judge; the consistency trackers of the same walk say what is wrong, and a client shows both (the graph view of the development image).

A target that is pointed at but never read stays as a node of its own (#unreadNodes): an object id that leads nowhere, with the nodes that lead to it. Needs no transaction and no classes of the application.

#of: walks a database once with the graph tracker and both consistency trackers and puts each finding on the node it is about (#placeFindings:, SoilFinding>>nodeIn:). The drawing of the result is SoilGraphView's. Both live in Soil-Roassal, outside the core and outside BaselineOfSoil - the view needs Roassal - until the tracker is split off on its own.
"
Class {
	#name : #SoilGraphTracker,
	#superclass : #SoilTracker,
	#instVars : [
		'nodes',
		'indexOwners',
		'findings'
	],
	#category : #'Soil-Roassal'
}

{ #category : #'instance creation' }
SoilGraphTracker class >> of: aSoil [
	"one walk: the graph, and the findings of both levels, read at one version and put
	on their nodes"
	| visitor graph database application |
	visitor := SoilTrackingVisitor new.
	graph := visitor addTracker: self new.
	database := visitor addTracker: SoilDatabaseConsistencyTracker new.
	application := visitor addTracker: SoilApplicationConsistencyTracker new.
	visitor track: aSoil.
	^ graph
		placeFindings: database findings , application findings;
		yourself
]

{ #category : #accessing }
SoilGraphTracker >> findings [
	^ findings
]

{ #category : #adding }
SoilGraphTracker >> from: aNode to: aSoilObjectId [
	aNode addOutgoing: aSoilObjectId.
	(self nodeAt: aSoilObjectId) addIncoming: aNode
]

{ #category : #initialization }
SoilGraphTracker >> initialize [
	super initialize.
	nodes := Dictionary new.
	indexOwners := Dictionary new.
	findings := OrderedCollection new
]

{ #category : #accessing }
SoilGraphTracker >> nodeAt: aSoilObjectId [
	^ nodes
		at: aSoilObjectId
		ifAbsentPut: [ SoilModelGraphNode new
			objectId: aSoilObjectId;
			yourself ]
]

{ #category : #accessing }
SoilGraphTracker >> nodeAt: aSoilObjectId ifAbsent: aBlock [
	^ nodes at: aSoilObjectId ifAbsent: aBlock
]

{ #category : #accessing }
SoilGraphTracker >> nodes [
	^ nodes values
]

{ #category : #accessing }
SoilGraphTracker >> nodesWithFindings [
	^ self nodes select: [ :each | each hasFindings ]
]

{ #category : #accessing }
SoilGraphTracker >> ownerOfIndex: anIndexId segment: anInteger [
	"the node of the cluster that holds the index, nil where none of the walk does -
	how a finding about an index is put on the graph"
	^ indexOwners at: anInteger -> anIndexId ifAbsent: [ nil ]
]

{ #category : #adding }
SoilGraphTracker >> placeFindings: aCollectionOfFindings [
	"the findings of the consistency trackers of the same walk, each on the node it is
	about; one that names no node is kept all the same"
	aCollectionOfFindings do: [ :each |
		findings add: each.
		(each nodeIn: self) ifNotNil: [ :node | node addFinding: each ] ]
]

{ #category : #tracking }
SoilGraphTracker >> trackCluster: aSoilPersistentClusterVersion in: aVisitor [
	| node |
	node := self nodeAt: aSoilPersistentClusterVersion objectId.
	node beRead.
	aSoilPersistentClusterVersion references do: [ :each | self from: node to: each ].
	aSoilPersistentClusterVersion indexIds do: [ :each |
		indexOwners at: aSoilPersistentClusterVersion segment -> each put: node ]
]

{ #category : #tracking }
SoilGraphTracker >> trackValue: aSoilObjectId ofIndex: anIndex segment: aSoilObjectSegment in: aVisitor [
	(self ownerOfIndex: anIndex id segment: aSoilObjectSegment id)
		ifNotNil: [ :owner | self from: owner to: aSoilObjectId ]
]

{ #category : #accessing }
SoilGraphTracker >> unreadNodes [
	"object ids something points to and the walk never read a cluster under"
	^ self nodes reject: [ :each | each isRead ]
]
