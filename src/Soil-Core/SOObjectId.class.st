Class {
	#name : #SOObjectId,
	#superclass : #Object,
	#instVars : [
		'segment',
		'index'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
SOObjectId class >> segment: segmentId index: index [
	^ self new 
		segment: segmentId index: index
]

{ #category : #accessing }
SOObjectId >> index [
	^ index
]

{ #category : #initialization }
SOObjectId >> initialize [ 
	super initialize.
	segment := 1
]

{ #category : #printing }
SOObjectId >> printOn: aStream [ 
	aStream << 'ObjectId(' << segment asString << ':' << index asString << ')'
]

{ #category : #accessing }
SOObjectId >> segment [
	self flag: #todo.
	"There should ne no default segment. This is a shortcut"
	^ segment ifNil: [ 1 ]
]

{ #category : #accessing }
SOObjectId >> segment: segmentNo index: segmentIndex [ 
	segment := segmentNo.
	index := segmentIndex 
]

{ #category : #accessing }
SOObjectId >> setIndex: anInteger [ 
	index := anInteger 
]
