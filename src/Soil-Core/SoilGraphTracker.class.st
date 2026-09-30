"
Collects the object graph of a walk: a node (SoilModelGraphNode) for every cluster the walk reads, with what it points to - its references and the values of its indexes - and what points to it. It collects, it does not judge; the consistency trackers of the same walk say what is wrong, and a client shows both (the graph view of the development image).

A target that is pointed at but never read stays as a node of its own (#unreadNodes): an object id that leads nowhere, with the nodes that lead to it. Needs no transaction and no classes of the application.
"
Class {
	#name : #SoilGraphTracker,
	#superclass : #SoilTracker,
	#instVars : [
		'nodes',
		'indexOwners'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #adding }
SoilGraphTracker >> from: aNode to: aSoilObjectId [
	aNode addOutgoing: aSoilObjectId.
	(self nodeAt: aSoilObjectId) addIncoming: aNode
]

{ #category : #initialization }
SoilGraphTracker >> initialize [
	super initialize.
	nodes := Dictionary new.
	indexOwners := Dictionary new
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
SoilGraphTracker >> ownerOfIndex: anIndexId segment: anInteger [
	"the node of the cluster that holds the index, nil where none of the walk does -
	how a finding about an index is put on the graph"
	^ indexOwners at: anInteger -> anIndexId ifAbsent: [ nil ]
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
