Class {
	#name : #SOBlockElement,
	#superclass : #Object,
	#instVars : [
		'name'
	],
	#category : #'Soil-Roassal'
}

{ #category : #'instance creation' }
SOBlockElement class >> on: aString [
	^ self new
		name: aString;
		yourself
]

{ #category : #converting }
SOBlockElement >> asShape [
	^ { self label } asShape
		height: 150;
		padding: 5;
		model: self;
		yourself
]

{ #category : #accessing }
SOBlockElement >> border [
	^ RSBorder new color: Color black; joinMiter
]

{ #category : #converting }
SOBlockElement >> label [
	^ RSLabel new
		text: name;
		color: Color black;
		yourself
]

{ #category : #accessing }
SOBlockElement >> name [

	^ name
]

{ #category : #accessing }
SOBlockElement >> name: anObject [

	name := anObject
]
