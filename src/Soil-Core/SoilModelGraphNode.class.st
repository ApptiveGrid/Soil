Class {
	#name : #SoilModelGraphNode,
	#superclass : #Object,
	#instVars : [
		'objectId',
		'errors',
		'outgoing',
		'incoming',
		'isRead'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #adding }
SoilModelGraphNode >> addError: anError [ 
	errors add: anError 
]

{ #category : #adding }
SoilModelGraphNode >> addIncoming: aSoilObjectId [ 
	incoming add: aSoilObjectId  
]

{ #category : #adding }
SoilModelGraphNode >> addOutgoing: aSoilObjectId [ 
	outgoing add: aSoilObjectId 
]

{ #category : #adding }
SoilModelGraphNode >> addReference: aSoilObjectId [ 
	outgoing add: aSoilObjectId 
]

{ #category : #accessing }
SoilModelGraphNode >> extent [
	^ self hasErrors 
		ifTrue: [ 100 ]
		ifFalse: [ 1 ]
]

{ #category : #private }
SoilModelGraphNode >> findRoot: path seen: seen [
	(seen includes: objectId) ifTrue: [ ^ nil ].
	seen add: objectId.
	path add: objectId.
	incoming do: [ :node | 
		(node objectId index == 1) ifTrue: [ 
			path add: node objectId.
			^ path ].
		(node findRoot: path copy seen: seen) ifNotNil: [ :p2 | ^ p2 ] ].
	^ nil 
]

{ #category : #api }
SoilModelGraphNode >> findRootPath [
	^ self 
		findRoot: OrderedCollection new
		seen: Set new
]

{ #category : #api }
SoilModelGraphNode >> graphColor [
	^ self hasErrors 
		ifTrue: [  Color lightRed ] 
		ifFalse: [ Color lightBlue ] 
]

{ #category : #private }
SoilModelGraphNode >> hasErrors [ 
	^ errors notEmpty 
]

{ #category : #accessing }
SoilModelGraphNode >> beRead [
	isRead := true
]

{ #category : #accessing }
SoilModelGraphNode >> incoming [
	^ incoming
]

{ #category : #initialization }
SoilModelGraphNode >> initialize [ 
	super initialize.
	isRead := false.
	outgoing := Set new.
	incoming := Set new.
	errors := OrderedCollection new 
]

{ #category : #testing }
SoilModelGraphNode >> isRead [
	"whether the walk read a cluster under my object id. A node that is only pointed
	at was never read - the object id leads nowhere"
	^ isRead
]

{ #category : #accessing }
SoilModelGraphNode >> objectId [
	^ objectId
]

{ #category : #accessing }
SoilModelGraphNode >> objectId: aSoilObjectId [ 
	objectId := aSoilObjectId 
]

{ #category : #accessing }
SoilModelGraphNode >> outgoing [
	^ outgoing
]

{ #category : #printing }
SoilModelGraphNode >> printOn: aStream [ 
	aStream << 'node: ' << objectId asString 
]

{ #category : #accessing }
SoilModelGraphNode >> references [
	^ outgoing
]

{ #category : #private }
SoilModelGraphNode >> resolveObjectIdsIn: anObject [ 
	outgoing := outgoing collect: [ :each |
		anObject nodeAt: each  ]
]
