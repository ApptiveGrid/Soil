Class {
	#name : #SoilSkipListIterator,
	#superclass : #Object,
	#instVars : [
		'skipList',
		'page',
		'key',
		'levels'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'instance creation' }
SoilSkipListIterator class >> on: aSoilSkipList [ 
	^ self new 
		skipList: aSoilSkipList 
]

{ #category : #accessing }
SoilSkipListIterator >> atLevel: key put: anObject [
	levels at: key put: anObject 
]

{ #category : #enumerating }
SoilSkipListIterator >> do: aBlock [
	| item |
	[ (item := self next) isNil ] whileFalse: [ 
		aBlock value: item ]
]

{ #category : #accessing }
SoilSkipListIterator >> first [
	^ self firstAssociation ifNotNil: [ :assoc | assoc value ]
]

{ #category : #accessing }
SoilSkipListIterator >> firstAssociation [ 
	^ skipList pageRegistry startPage firstItem
]

{ #category : #accessing }
SoilSkipListIterator >> levelAt: anInteger [ 
	^ levels at: anInteger 
]

{ #category : #accessing }
SoilSkipListIterator >> next [
	^ self nextAssociation ifNotNil: [ :assoc | assoc value ]
]

{ #category : #accessing }
SoilSkipListIterator >> nextAssociation [
	| item i2 |
	page ifNil: [ 
		page := skipList pageRegistry startPage.
		key := nil ].
	[ page isNil ] whileFalse: [  
		item := key 
			ifNotNil: [  
				(page itemAfter: key)
					ifNotNil: [ :i | 
						key := i key. 
						^ i ]
					ifNil: [ 
						((page right at: 1) = 0) ifTrue: [ ^ nil ].
						page := skipList pageRegistry pageAt: (page rightAt: 1).
						key := nil ] ]
			ifNil: [
				i2 := page firstItem.
				key := i2 key.
				^ i2 ]].
	Error signal: 'shouldnt happen'
]

{ #category : #accessing }
SoilSkipListIterator >> page [

	^ page
]

{ #category : #accessing }
SoilSkipListIterator >> page: anObject [

	page := anObject
]

{ #category : #printing }
SoilSkipListIterator >> printOn: aStream [ 
	aStream << 'path: ' << levels asString
]

{ #category : #accessing }
SoilSkipListIterator >> skipList: aSoilSkipList [ 
	skipList := aSoilSkipList.
	levels := Array new: skipList maxLevel 
]
