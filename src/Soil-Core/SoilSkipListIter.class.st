Class {
	#name : #SoilSkipListIter,
	#superclass : #Object,
	#instVars : [
		'skipList',
		'page',
		'key'
	],
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'instance creation' }
SoilSkipListIter class >> on: aSoilSkipList [ 
	^ self new 
		skipList: aSoilSkipList 
]

{ #category : #enumerating }
SoilSkipListIter >> do: aBlock [
	| item |
	[ (item := self next) isNil ] whileFalse: [ 
		aBlock value: item ]
]

{ #category : #accessing }
SoilSkipListIter >> first [
	^ self firstAssociation ifNotNil: [ :assoc | assoc value ]
]

{ #category : #accessing }
SoilSkipListIter >> firstAssociation [ 
	^ skipList pageRegistry startPage firstItem
]

{ #category : #accessing }
SoilSkipListIter >> next [
	^ self nextAssociation ifNotNil: [ :assoc | assoc value ]
]

{ #category : #accessing }
SoilSkipListIter >> nextAssociation [
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
SoilSkipListIter >> skipList: aSoilSkipList [ 
	skipList := aSoilSkipList 
]
