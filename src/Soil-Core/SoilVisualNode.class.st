Class {
	#name : #SoilVisualNode,
	#superclass : #Object,
	#instVars : [
		'objectId',
		'errors',
		'outgoing'
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
