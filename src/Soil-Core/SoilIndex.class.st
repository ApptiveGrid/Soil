Class {
	#name : #SoilIndex,
	#superclass : #Object,
	#instVars : [
		'store'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #private }
SoilIndex >> at: key [ 
	^ self 
		at: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #accessing }
SoilIndex >> at: anObject ifAbsent: aBlock [
	^ (self find: anObject) 
		ifNotNil: [:node | node value ]
		ifNil: [ aBlock value ] 
]

{ #category : #accessing }
SoilIndex >> at: aKeyObject put: anObject [
	self newIterator 
		at: aKeyObject 
		put: anObject
]

{ #category : #accessing }
SoilIndex >> atIndex: anInteger [
	^ self newIterator atIndex: anInteger 
]

{ #category : #accessing }
SoilIndex >> basicAt: key put: anObject [
	^ self newIterator 
		basicAt: key 
		put: anObject 
]

{ #category : #'open/close' }
SoilIndex >> close [
	self store close
]

{ #category : #enumerating }
SoilIndex >> do: aBlock [
	self newIterator do: aBlock
]

{ #category : #private }
SoilIndex >> find: aString [ 
	^ self newIterator 
		find: (aString asSkipListKeyOfSize: self keySize) asInteger
]

{ #category : #accessing }
SoilIndex >> first [
	^ self newIterator first
]

{ #category : #accessing }
SoilIndex >> first: anInteger [
	^ self newIterator first: anInteger
]

{ #category : #accessing }
SoilIndex >> flushCachedPages [
	store flushCachedPages
]

{ #category : #accessing }
SoilIndex >> headerPage [
	^ self store headerPage
]

{ #category : #testing }
SoilIndex >> isEmpty [
	^ self store headerPage isEmpty
]

{ #category : #testing }
SoilIndex >> isRegistered [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndex >> keySize [
	^ self headerPage keySize
]

{ #category : #accessing }
SoilIndex >> last [
	^ self newIterator last
]

{ #category : #accessing }
SoilIndex >> lastPage [
	^ self newIterator lastPage
]

{ #category : #'instance creation' }
SoilIndex >> newFileStore [
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
SoilIndex >> newIterator [
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
SoilIndex >> newPage [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndex >> pageAt: anInteger [ 
	^ self store pageAt: anInteger 
]

{ #category : #accessing }
SoilIndex >> pageSize [
	^ 4 * 1024
]

{ #category : #removing }
SoilIndex >> removeKey: key [ 
	^ self
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #'instance creation' }
SoilIndex >> removeKey: aString ifAbsent: aBlock [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndex >> size [
	"We iterate over all elements to get the size. Slow!"
	^ self newIterator size 
]

{ #category : #accessing }
SoilIndex >> store [
	^ store ifNil: [ 
		store := self newFileStore ]
]

{ #category : #accessing }
SoilIndex >> store: anObject [
	anObject index: self.
	store := anObject
]

{ #category : #converting }
SoilIndex >> thePersistentInstance [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndex >> valueSize [
	^ self headerPage valueSize
]

{ #category : #accessing }
SoilIndex >> valueSize: anInteger [
	self headerPage valueSize: anInteger
]

{ #category : #enumerating }
SoilIndex >> values [ 
	^ self newIterator values
]
