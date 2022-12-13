Class {
	#name : #SOSimpleBox,
	#superclass : #SOBlockElement,
	#category : #'Soil-Roassal'
}

{ #category : #converting }
SOSimpleBox >> asShape [
	^ super asShape
		border: self border;
		color: Color white;
		yourself
]
