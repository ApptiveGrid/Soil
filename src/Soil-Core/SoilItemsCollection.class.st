Class {
	#name : #SoilItemsCollection,
	#superclass : #Object,
	#instVars : [
		'items'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #adding }
SoilItemsCollection >> add: anAssociation [ 
	self shouldBeImplemented.
]

{ #category : #initialization }
SoilItemsCollection >> initialize [ 
	super initialize.
	items := OrderedCollection new
]
