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
	
	"if we did not find it in the last page, it does not exist"
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
SoilIndexIterator >> nextAssociation [
	^ self subclassResponsibility
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
