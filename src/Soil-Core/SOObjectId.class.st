Class {
	#name : #SOObjectId,
	#superclass : #Object,
	#instVars : [
		'segment',
		'index'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SOObjectId >> index [
	^ index
]

{ #category : #accessing }
SOObjectId >> index: anInteger [ 
	index := anInteger
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
SOObjectId >> segment: anObject [

	segment := anObject
]
