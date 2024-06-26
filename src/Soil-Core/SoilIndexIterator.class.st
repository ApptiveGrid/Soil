Class {
	#name : #SoilIndexIterator,
	#superclass : #Object,
	#instVars : [
		'index',
		'nextKey',
		'currentPage',
		'currentKey',
		'itemStrategy'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject [
	^ self 
		at: aKeyObject 
		ifAbsent: [ KeyNotFound signalFor: aKeyObject in: self  ] 
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject ifAbsent: aBlock [
	| foundValue item |
	foundValue := self find: aKeyObject ifAbsent: aBlock.
 	item := self restoreItem: currentKey -> foundValue.
	^ item
		ifNotNil: [ 
			(self convertValue: item value) 
				ifNil: [ aBlock value ] ]
		ifNil: [ aBlock value ]
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject put: anObject [
	^ self 
		basicAt: (index indexKey: aKeyObject) 
		put: anObject
]

{ #category : #accessing }
SoilIndexIterator >> atIndex: anInteger [
	| current |
	current := self firstAssociation.
	2 to: anInteger do: [ :idx |
		current := self nextAssociation ].
	^ current value
]

{ #category : #enumerating }
SoilIndexIterator >> basicAssociationsDo: aBlock [
	| item |
	[ (item := self basicNextAssociation ) notNil ] whileTrue: [
		(self restoreItem: item) ifNotNil: [ :assoc | 
 			aBlock value: assoc key -> (self convertValue: assoc value) ] ] 
]

{ #category : #accessing }
SoilIndexIterator >> basicAt: indexKey put: anObject [
	self subclassResponsibility
]

{ #category : #accessing }
SoilIndexIterator >> basicNextAssociation [
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
		"if there is a current key the item after that key is next
		if present"
		item := currentKey 
			ifNotNil: [  
				(currentPage itemAfter: currentKey)
					ifNotNil: [ :i | 
						currentKey := i key. 
						^ i ]
					ifNil: [ 
						"if we did not find an element after the current key we
						need to proceed with the next page.
						For the last page there is no next page and we return nil"
						(currentPage isLastPage) ifTrue: [ ^ nil ].
						"if there is a next page we set it to current and restart"
						currentPage := self nextPage.
						currentKey := nil ] ]
			ifNil: [
				"without currentKey we are looking for the first item in a page.
				If the currentPage is empty we advance the page and restart"
				currentPage isEmpty 
					ifTrue: [ 
						currentPage := self nextPage.
						currentKey := nil ]
					ifFalse: [
						"if the currentPage has an item we set currentKey and 
						return the found item"
						currentPage firstItem ifNotNil: [ :item2 | 
							currentKey := item2 key. 
							^ item2 ] ] ] ].
	"if we end up here then there was no next page to continue looking for the
	next item"
	^ nil 
]

{ #category : #removing }
SoilIndexIterator >> basicRemoveKey: key [ 
	^ self 
		basicAt: key 
		put: SoilObjectId removed
]

{ #category : #private }
SoilIndexIterator >> convertValue: anObject [ 
	anObject ifNil: [ ^ nil ].
	^ itemStrategy 
		ifNotNil: [ itemStrategy convertValue: anObject ]
		ifNil: [ anObject ]
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
	"We use basicNextAssociation to avoid the creation of intermediate associations of nextAssociation"
	[ (item := self basicNextAssociation ) notNil ] whileTrue: [ 
 		(self restoreItem: item) ifNotNil: [ :notNil |
			(self convertValue: notNil value)
				ifNotNil: [ :value | aBlock value: value ] ] ]
]

{ #category : #private }
SoilIndexIterator >> find: key [
	^ self find: key ifAbsent: [ ]
]

{ #category : #private }
SoilIndexIterator >> find: key ifAbsent: aBlock [
	currentKey := index indexKey: key.
	self findPageFor: currentKey.
	^ currentPage valueAt: currentKey ifAbsent: aBlock
]

{ #category : #private }
SoilIndexIterator >> findPageFor: indexKey [ 
	^ self subclassResponsibility
]

{ #category : #private }
SoilIndexIterator >> findPreviousPageOf: aPage [
	"Slow approach that searched all pages from the first following the next pointer, only called for empty pages"

	self pagesDo: [ :page | page next == aPage index ifTrue: [ ^page ] ].
	self error: 'should not happen'
]

{ #category : #accessing }
SoilIndexIterator >> first [
	^ self firstAssociation value
]

{ #category : #accessing }
SoilIndexIterator >> first: anInteger [
	| result |
	result := OrderedCollection new: anInteger.
	anInteger timesRepeat: [
		| next |
		next := self next ifNil: [ ^ result].
		result add: next ].
	^ result
]

{ #category : #accessing }
SoilIndexIterator >> firstAssociation [ 
	"Note: key will be index key"
	| item |
	currentPage := index store headerPage.
	item := self nextAssociation.
	currentKey := item ifNotNil: [ item key ].
	^ item
]

{ #category : #accessing }
SoilIndexIterator >> firstPage [
	^ currentPage := index firstPage
]

{ #category : #accessing }
SoilIndexIterator >> index [
	^index
]

{ #category : #accessing }
SoilIndexIterator >> index: anIndex [ 
	index := anIndex
]

{ #category : #testing }
SoilIndexIterator >> isEmpty [
 
	^ index isEmpty or: [  
		self currentPage: index firstPage.
		"all items might be removed and not restorable"
 		self index firstPage items allSatisfy: [ :each |
 		  	(self restoreItem: each) isNil ]]
]

{ #category : #accessing }
SoilIndexIterator >> last [
	^ self lastAssociation value
]

{ #category : #accessing }
SoilIndexIterator >> last: anInteger [
	| result |
	result := OrderedCollection new: anInteger.
	result add: self last.
	anInteger - 1 timesRepeat: [
		| prev |
		prev := self previous ifNil: [ ^ result].
		result add: prev ].
	^ result reversed
]

{ #category : #accessing }
SoilIndexIterator >> lastAssociation [
	"Note: key will be index key"
	| lastAssociation restoredItem |
	"previousAssociation will use last page if currentPage is nil"
	lastAssociation := self previousAssociation ifNil: [ ^nil ].
	restoredItem := self restoreItem: lastAssociation.
	^ restoredItem 
		ifNotNil: [ restoredItem key -> (self convertValue: restoredItem value) ] 
		ifNil: [
			"if the last entry is deleted, we need to take the one before"
			^ self lastAssociation ] 
]

{ #category : #accessing }
SoilIndexIterator >> lastPage [
	^ self subclassResponsibility
]

{ #category : #accessing }
SoilIndexIterator >> next [
	| nextAssociation |
	nextAssociation := self basicNextAssociation ifNil: [ ^nil ].
	^ (self restoreItem: nextAssociation)
		ifNotNil: [ :restoredItem | self convertValue: restoredItem value ]
		ifNil: [ self next ]
	
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
SoilIndexIterator >> nextAfter: key [
	self find: key.
	^ self next
]

{ #category : #accessing }
SoilIndexIterator >> nextAssociation [
	"Note: key will be index key"
	| nextAssociation restoredItem |
	nextAssociation := self basicNextAssociation ifNil: [ ^nil ].
	restoredItem := self restoreItem: nextAssociation.
	^ restoredItem 
		ifNotNil: [ restoredItem key -> (self convertValue: restoredItem value)] 
		ifNil: [ self nextAssociation ] 
]

{ #category : #accessing }
SoilIndexIterator >> nextAssociationAfter: key [
	"Note: key will be index key"
	self find: key.
	^ self nextAssociation
]

{ #category : #private }
SoilIndexIterator >> nextCloseTo: key [
	"return the next entry after key, even if key itself is not there"
	^ self at: (self nextKeyCloseTo: key)
]

{ #category : #private }
SoilIndexIterator >> nextKeyCloseTo: key [
	"Note: returned key will be an index key"
	| indexKey |
	indexKey := index indexKey: key.
	self findPageFor: indexKey.
	nextKey := currentPage keyOrClosestAfter: indexKey.
	^ nextKey
		ifNil: [ "if there is no close key found, we position the cursor at the end, so that asking for the next association will return nil" 
			currentKey := currentPage lastKey ]
		ifNotNil: [ 
			"if there is a close key found, we make sure the cursor get properly positioned"
			currentKey := nextKey ]
]

{ #category : #accessing }
SoilIndexIterator >> nextPage [ 
	| nextPageIndex |
	nextPageIndex := currentPage next.
	^ (nextPageIndex > 0)
		ifTrue: [ self pageAt: nextPageIndex ]
		ifFalse: [ nil ]
]

{ #category : #accessing }
SoilIndexIterator >> pageAt: anInteger [
	^ index store pageAt: anInteger
]

{ #category : #enumerating }
SoilIndexIterator >> pagesDo: aBlock [ 
	currentPage := index store headerPage.
	[ currentPage isNil ] whileFalse: [ 
		aBlock value: currentPage.
		currentPage := self nextPage ]
]

{ #category : #accessing }
SoilIndexIterator >> previous [
	^ self previousAssociation value
]

{ #category : #accessing }
SoilIndexIterator >> previous: anInteger [
	| result |
	result := OrderedCollection new: anInteger.
	anInteger timesRepeat: [
		| previous |
		previous := self previous ifNil: [ ^ result].
		result add: previous ].
	^ result
]

{ #category : #accessing }
SoilIndexIterator >> previousAssociation [
	| item |
	"Find the association before, if currentPage is not set we return the last association"
	currentPage ifNil: [ 
		currentPage := index lastPage.
		currentKey := nil ].
	[ currentPage isNil ] whileFalse: [  
		item := currentKey 
			ifNotNil: [  
				(currentPage itemBefore: currentKey)
					ifNotNil: [ :i | 
						currentKey := i key. 
						^ i ]
					ifNil: [ 
						"are we the first page? if yes, there is no item before"
						currentPage isHeaderPage ifTrue: [ ^nil ].
						currentPage := self previousPage.
						currentKey := nil ] ]
			ifNil: [
				currentPage isEmpty ifTrue: [ ^ nil ].
				^ currentPage lastItem ifNotNil: [ :item2 | currentKey := item2 key. item2 ] ] ].
	Error signal: 'shouldnt happen'
]

{ #category : #accessing }
SoilIndexIterator >> previousPage [ 
	^ self findPreviousPageOf: currentPage
]

{ #category : #removing }
SoilIndexIterator >> removeItemsSuchThat: aBlock [ 
	self pagesDo: [ :page | page items removeAllSuchThat: aBlock ].

]

{ #category : #removing }
SoilIndexIterator >> removeKey: key [
	^ self 
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilIndexIterator >> removeKey: key ifAbsent: aBlock [
	| returnValue |
	returnValue := self at: key ifAbsent: aBlock.
	self 
		at: key 
		put: SoilObjectId removed.
	^ returnValue
]

{ #category : #private }
SoilIndexIterator >> restoreItem: anItem [ 
	^ anItem 
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

{ #category : #enumerating }
SoilIndexIterator >> values [ 
	| values |
	values := OrderedCollection new.
	self do: [ :each |
		values add: each value ].
	^ values
]
