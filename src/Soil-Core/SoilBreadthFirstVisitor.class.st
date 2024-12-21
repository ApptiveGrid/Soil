Class {
	#name : #SoilBreadthFirstVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'toBeProcessed',
		'seen'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #initialization }
SoilBreadthFirstVisitor >> initialize [ 
	super initialize.
	seen := Set new.
	toBeProcessed := OrderedCollection new
]

{ #category : #accessing }
SoilBreadthFirstVisitor >> processObjectId: aSoilObjectId [ 
	((aSoilObjectId segment = 0) and: [ aSoilObjectId index = 2 ]) ifTrue: [ ^ self ].
	(seen includes: aSoilObjectId) ifTrue: [ ^ self ].
	seen add: aSoilObjectId.
	toBeProcessed add: aSoilObjectId  
]

{ #category : #'as yet unclassified' }
SoilBreadthFirstVisitor >> processReference: aSoilObjectId [ 
	self processObjectId: aSoilObjectId 
]

{ #category : #visiting }
SoilBreadthFirstVisitor >> visitObjectId: anObjectId [ 
	self halt.
]

{ #category : #visiting }
SoilBreadthFirstVisitor >> visitSoil: aSoil [ 
	super visitSoil: aSoil.
	self traverseGraph 
]
