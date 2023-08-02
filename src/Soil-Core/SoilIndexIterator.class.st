Class {
	#name : #SoilIndexIterator,
	#superclass : #Object,
	#instVars : [
		'index',
		'currentPage',
		'currentKey',
		'nextKey'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #testing }
SoilIndexIterator class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilIndexIterator
]

{ #category : #'instance creation' }
SoilIndexIterator class >> on: aSoilIndex [
	^ self new 
		index: aSoilIndex 
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject ifAbsent: aBlock [ 
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject put: anObject [
	| key |
	key := (aKeyObject asSkipListKeyOfSize: index keySize) asInteger.
	^ self 
		basicAt: key 
		put: anObject
]

{ #category : #accessing }
SoilIndexIterator >> currentPage [

	^ currentPage
]

{ #category : #accessing }
SoilIndexIterator >> currentPage: anObject [

	currentPage := anObject
]

{ #category : #enumerating }
SoilIndexIterator >> do: aBlock [
	| item |
	[ (item := self next) isNil ] whileFalse: [ 
		item isRemoved ifFalse: [  
			aBlock value: item ] ]
]

{ #category : #private }
SoilIndexIterator >> find: key [ 
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndexIterator >> first [
	^ self firstAssociation value
]

{ #category : #accessing }
SoilIndexIterator >> firstAssociation [ 
	| item |
	currentPage := index store headerPage.
	item := currentPage firstItem.
	"if we get back a key that has been marked removed 
	we iterate until we find one that hasn't been 
	removed"
	[ item notNil and: [ item value isRemoved ] ] whileTrue: [ 
		item := self nextAssociation ].
	currentKey := item 
		ifNotNil: [ item key ].
	^ item
]

{ #category : #accessing }
SoilIndexIterator >> index: anIndex [ 
	index := anIndex
]

{ #category : #accessing }
SoilIndexIterator >> last [
	^ self lastAssociation value
]

{ #category : #accessing }
SoilIndexIterator >> lastAssociation [
	| lastPage item |
	lastPage := self lastPage.
	item := lastPage lastItem.  "sets currentPage"
	
	"if the last value is removed, take the one before"
	[item notNil and: [ item value isRemoved ]] whileTrue: [  
		item := lastPage itemBefore: item key].
	
	self flag: #TODO.
	"if we did not find it in the last page, we need to check the page before"
	item ifNil: [ ^nil ].	
	currentKey := item key.
	^ item 
	
]

{ #category : #accessing }
SoilIndexIterator >> lastPage [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndexIterator >> next [
	^ self nextAssociation value
]

{ #category : #accessing }
SoilIndexIterator >> next: anInteger [
	| result |
	result := OrderedCollection new: anInteger.
	anInteger timesRepeat: [
		| next |
		next := self next ifNil: [ ^ result].
		result add: next ].
	^ result
]

{ #category : #accessing }
SoilIndexIterator >> nextAssociation [
	| item |
	"preliminary support for nextKey. This is useful when iterating via #next 
	in order not jump over the first search key. nextKey implies the currentPage
	is on the right spot"
	nextKey ifNotNil: [ 
		item := currentPage 
			itemAt: nextKey 
			ifAbsent: [ Error signal: 'shoulndt be possible' ].
		nextKey := nil.
		^ item ].
	currentPage ifNil: [ 
		currentPage := index store headerPage.
		currentKey := nil ].
	[ currentPage isNil ] whileFalse: [  
		item := currentKey 
			ifNotNil: [  
				(currentPage itemAfter: currentKey)
					ifNotNil: [ :i | 
						currentKey := i key. 
						^ i ]
					ifNil: [ 
						(currentPage next = 0) ifTrue: [ ^ nil ].
						currentPage := index store pageAt: currentPage next.
						currentKey := nil ] ]
			ifNil: [
				currentPage isEmpty ifTrue: [ ^ nil ].
				^ currentPage firstItem ifNotNil: [ :item2 | currentKey := item2 key. item2 ] ] ].
	Error signal: 'shouldnt happen'
]

{ #category : #accessing }
SoilIndexIterator >> nextAssociationWithPresentValue [
	| next |
	next := self nextAssociation.
	[ next notNil and: [ next value isRemoved ] ] whileTrue: [ 
		next := self nextAssociation ].
	^ next 
]

{ #category : #'as yet unclassified' }
SoilIndexIterator >> nextPresent [ 
	^ self nextAssociationWithPresentValue value
]

{ #category : #accessing }
SoilIndexIterator >> nextPresentAssociation [
	| assoc |
	"lookup next association by leaving out the removed keys"
	assoc := self nextAssociation.
	[ assoc notNil and: [ assoc value isRemoved ] ] whileTrue: [ 
		assoc := self nextAssociation ].
	^ assoc
]

{ #category : #accessing }
SoilIndexIterator >> pageAt: anInteger [
	^ index store pageAt: anInteger
]

{ #category : #accessing }
SoilIndexIterator >> size [
	"We iterate over all elements to get the size. Slow!"
	| sum |
	sum := 0.
	self do: [ :each | sum := sum + 1 ].
	^ sum
]

{ #category : #transactions }
SoilIndexIterator >> updateCurrentTransaction: anInteger [ 
	currentPage lastTransaction: anInteger
]
