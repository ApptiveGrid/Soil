Class {
	#name : #SOObjectId,
	#superclass : #Object,
	#instVars : [
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
