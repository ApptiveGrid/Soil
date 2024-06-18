Class {
	#name : #SoilCloneVisitor,
	#superclass : #SoilVisitor,
	#instVars : [
		'soil',
		'seen',
		'toBeProcessed'
	],
	#category : #'Soil-Core-Visitor'
}

{ #category : #initialization }
SoilCloneVisitor >> initialize [ 
	super initialize.
	seen := Set new.
	toBeProcessed := OrderedCollection new
]

{ #category : #accessing }
SoilCloneVisitor >> processObjectId: aSoilObjectId [ 
	"don't continue if the objectId is the behavior description meta object"
	((aSoilObjectId segment = 0) and: [ aSoilObjectId index = 2 ]) ifTrue: [ ^ self ].
	(seen includes: aSoilObjectId) ifTrue: [ ^ self ].
	seen add: aSoilObjectId.
	toBeProcessed add: aSoilObjectId  
]

{ #category : #accessing }
SoilCloneVisitor >> soil [

	^ soil
]

{ #category : #accessing }
SoilCloneVisitor >> soil: anObject [

	soil := anObject
]

{ #category : #api }
SoilCloneVisitor >> traverseGraph [ 
	| objectId |
	[ toBeProcessed isEmpty ] whileFalse: [  
		objectId := toBeProcessed  removeFirst.
		(objectId segment <= 1) ifTrue: [  
			self visit: (soil objectRepository at: objectId) ]] 
]
