Class {
	#name : #SoilVisualNode,
	#superclass : #Object,
	#instVars : [
		'objectId',
		'errors',
		'outgoing',
		'incoming'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #adding }
SoilVisualNode >> addError: anError [ 
	errors add: anError 
]

{ #category : #adding }
SoilVisualNode >> addIncoming: aSoilObjectId [ 
	incoming add: aSoilObjectId  
]

{ #category : #adding }
SoilVisualNode >> addOutgoing: aSoilObjectId [ 
	outgoing add: aSoilObjectId 
]

{ #category : #adding }
SoilVisualNode >> addReference: aSoilObjectId [ 
	outgoing add: aSoilObjectId 
]

{ #category : #accessing }
SoilVisualNode >> extent [
	^ self hasErrors 
		ifTrue: [ 100 ]
		ifFalse: [ 1 ]
]

{ #category : #'as yet unclassified' }
SoilVisualNode >> findRoot: path seen: seen [
	(seen includes: objectId) ifTrue: [ ^ nil ].
	seen add: objectId.
	path add: objectId.
	incoming do: [ :node | 
		(node objectId index = 1) ifTrue: [ 
			path add: node objectId.
			^ path ].
		(node findRoot: path copy seen: seen) ifNotNil: [ :p2 | ^ p2 ] ].
	^ nil 
]

{ #category : #'as yet unclassified' }
SoilVisualNode >> findRootPath [
	^ self 
		findRoot: OrderedCollection new
		seen: Set new
]

{ #category : #'as yet unclassified' }
SoilVisualNode >> graphColor [
	^ self hasErrors 
		ifTrue: [  Color lightRed ] 
		ifFalse: [ Color lightBlue ] 
]

{ #category : #'as yet unclassified' }
SoilVisualNode >> hasErrors [ 
	^ errors notEmpty 
]

{ #category : #initialization }
SoilVisualNode >> initialize [ 
	super initialize.
	outgoing := Set new.
	incoming := Set new.
	errors := OrderedCollection new 
]

{ #category : #accessing }
SoilVisualNode >> objectId [
	^ objectId
]

{ #category : #accessing }
SoilVisualNode >> objectId: aSoilObjectId [ 
	objectId := aSoilObjectId 
]

{ #category : #accessing }
SoilVisualNode >> outgoing [
	^ outgoing
]

{ #category : #printing }
SoilVisualNode >> printOn: aStream [ 
	aStream << 'node: ' << objectId asString 
]

{ #category : #accessing }
SoilVisualNode >> references [
	^ outgoing
]

{ #category : #'as yet unclassified' }
SoilVisualNode >> resolveObjectIdsIn: anObject [ 
	outgoing := outgoing collect: [ :each |
		anObject nodeAt: each  ]
]
