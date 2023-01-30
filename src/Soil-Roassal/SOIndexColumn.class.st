Class {
	#name : #SOIndexColumn,
	#superclass : #SOBlockElement,
	#instVars : [
		'children'
	],
	#category : #'Soil-Roassal'
}

{ #category : #adding }
SOIndexColumn >> add: anObject [
	children add: anObject
]

{ #category : #adding }
SOIndexColumn >> addAll: aCollection [
	children addAll: aCollection
]

{ #category : #converting }
SOIndexColumn >> asShape [
	| shapes shape label |
	shapes := children collect: [ :child | child asShape ] as: RSGroup.
	self normalizeWidth: shapes.
	RSVerticalLineLayout on: shapes.
	shape := shapes asShape
		model: self;
		border: self border;
		color: Color veryVeryLightGray;
		padding: 3;
		draggable;
		yourself.
	label := self label.
	shape add: label.
	label position: 0@ (shape height / -2 - label height).
	^ shape
]

{ #category : #initialization }
SOIndexColumn >> initialize [
	super initialize.
	children := OrderedCollection new
]

{ #category : #converting }
SOIndexColumn >> normalizeWidth: shapes [
	| maxWidth |
	maxWidth := shapes inject: 0 into: [ :max :each | max max: each width ].
	shapes do: [ :each | each width: maxWidth ]
]
