Class {
	#name : #SoilIndexIterator,
	#superclass : #Object,
	#instVars : [
		'index',
		'currentPage',
		'currentKey',
		'itemStrategy',
		'currentPageIndex'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #enumerating }
SoilIndexIterator >> associationsDo: aBlock [
	| item |
	"set currentPage to nil to force starting at the first element"
	currentPage := nil.
	[ (item := self nextAssociation ) notNil ] 
		whileTrue: [ aBlock value: item ]
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject [
	^ self 
		at: aKeyObject 
		ifAbsent: [ KeyNotFound signalFor: aKeyObject in: self  ] 
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject add: anObject [

	^ self basicAt: (index indexKey: aKeyObject) add: anObject
]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject ifAbsent: aBlock [
	^ self find: aKeyObject ifAbsent: [^ aBlock value].

]

{ #category : #accessing }
SoilIndexIterator >> at: aKeyObject put: anObject [
	self
		deprecated: 'Please use #at:add:'
		transformWith: '`@receiver at: `@arg1 put: `@arg2' -> '`@receiver at: `@arg1 add: `@arg2'.

	^ self at: aKeyObject add: anObject
]

{ #category : #accessing }
SoilIndexIterator >> atIndex: anInteger [
	| current |
	current := self firstAssociation.
	2 to: anInteger do: [ :idx |
		current := self nextAssociation ].
	^ current value
]

{ #category : #accessing }
SoilIndexIterator >> basicAt: key add: anObject [
	self subclassResponsibility 
]

{ #category : #accessing }
SoilIndexIterator >> basicAt: indexKey put: anObject [
	self subclassResponsibility
]

{ #category : #accessing }
SoilIndexIterator >> basicNextAssociation [
	| item |
	currentPage ifNil: [ 
		currentPage := index store headerPage.
		currentKey := nil.
		currentPageIndex := 0 ].
	[ currentPage isNil ] whileFalse: [  
		"if there is a current key the item after that key is next
		if present"
		item := currentPageIndex > 0
			ifTrue: [  
				(currentPage itemAfterIndex: currentPageIndex)
					ifNotNil: [ :i | 
						currentPageIndex := currentPageIndex + 1.
						currentKey := i key. 
						^ i ]
					ifNil: [ 
						"if we did not find an element after the current key we
						need to proceed with the next page.
						For the last page there is no next page and we return nil"
						(currentPage isLastPage) ifTrue: [ ^ nil ].
						"if there is a next page we set it to current and restart"
						currentPage := self nextPage.
						currentKey := nil.
						currentPageIndex := 0 ] ]
			ifFalse: [
				"without currentKey we are looking for the first item in a page.
				If the currentPage is empty we advance the page and restart"
				currentPage isEmpty 
					ifTrue: [ 
						currentPage := self nextPage.
						currentKey := nil.
						currentPageIndex := 0. ]
					ifFalse: [
						"if the currentPage has an item we set currentKey and 
						return the found item"
						currentPage firstItem ifNotNil: [ :item2 | 
							currentKey := item2 key.
							currentPageIndex := 1. 
							^ item2 ] ] ] ].
	"if we end up here then there was no next page to continue looking for the
	next item"
	^ nil 
]

{ #category : #accessing }
SoilIndexIterator >> basicPreviousAssociation [
	| item |
	"Find the association before"
	currentKey ifNil: [ ^ self error: 'you need to navigate first using find: or last, for example'].
	currentPage ifNil: [ self findPageFor: currentKey].
	[ currentPage isNil ] whileFalse: [  
		item := currentPageIndex > 0 
			ifTrue: [  
				(currentPage itemBeforeIndex: currentPageIndex)
					ifNotNil: [ :i | 
						currentPageIndex := currentPageIndex - 1.
						currentKey := i key. 
						^ i ]
					ifNil: [ 
						"are we the first page? if yes, there is no item before"
						currentPage isHeaderPage ifTrue: [ 
							currentKey := nil.
							currentPageIndex := 0.
							^ nil ].
						currentPage := self previousPage.
						currentKey := nil.
						currentPageIndex := 0 ] ]
			ifFalse: [
				currentPage isEmpty ifTrue: [ ^ nil ].
				^ currentPage lastItem ifNotNil: [ :item2 | 
					currentKey := item2 key. 
					currentPageIndex := currentPage numberOfItems.
					item2 ] ] ].
	Error signal: 'shouldnt happen'
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
	"set currentPage to nil to force starting at the first element"
	currentPage := nil.
	"We use basicNextAssociation to avoid the creation of intermediate associations of nextAssociation"
	[ (item := self basicNextAssociation ) notNil ] whileTrue: [ 
 		(self restoreItem: item) ifNotNil: [ :notNil |
			(self convertValue: notNil value)
				ifNotNil: [ :value | aBlock value: value ] ] ]
]

{ #category : #private }
SoilIndexIterator >> find: key [
	^ self find: key ifAbsent: nil
]

{ #category : #private }
SoilIndexIterator >> find: key ifAbsent: aBlock [
	
	^ index hasUniqueKeys 
		ifTrue: [ self findOne: key ifAbsent: aBlock  ]
		ifFalse: [ self findAll: key ifAbsent: aBlock ]
	
]

{ #category : #'as yet unclassified' }
SoilIndexIterator >> findAll: key ifAbsent: aBlock [ 
	| indexKey assoc item values |
	indexKey := index indexKey: key.
	self findPageFor: indexKey.
	currentPageIndex := currentPage indexOfKey: indexKey.
	currentKey := (currentPage items at: currentPageIndex ifAbsent: [ ^ aBlock value ]) key. 
	(currentKey = indexKey ) ifFalse: [ ^ aBlock value ].
	"find first occurrence"
	assoc := self basicPreviousAssociation.
	[ assoc notNil and: [ assoc key = indexKey ] ] whileTrue: [ 
		assoc := self basicPreviousAssociation ].
	(assoc notNil and: [assoc key = indexKey]) ifFalse: [ assoc := self basicNextAssociation ] . 
	"now we are on the first item with the key"
	values := OrderedCollection with: assoc value.
	assoc := self basicNextAssociation.
	[ assoc notNil and: [ assoc key = indexKey ] ] whileTrue: [ 
		values add: assoc value.
		assoc := self basicNextAssociation ].
	^ values collect: [ :value |
		item := self restoreItem: currentKey -> value.
		item
			ifNotNil: [ 
				(self convertValue: item value) 
					ifNil: [ aBlock value ] ]
			ifNil: [ aBlock value ] ] 
]

{ #category : #private }
SoilIndexIterator >> findOne: key ifAbsent: aBlock [
	| value item |
	currentKey := index indexKey: key.
	self findPageFor: currentKey.

	currentPageIndex := currentPage indexOfKey: currentKey.
	currentPageIndex == 0 ifTrue: [ ^ aBlock value ].
	value := (currentPage itemAtIndex: currentPageIndex) value.
	item := self restoreItem: currentKey -> value.
	^ item
		ifNotNil: [ 
			(self convertValue: item value) 
				ifNil: [ aBlock value ] ]
		ifNil: [ aBlock value ]
	

]

{ #category : #private }
SoilIndexIterator >> findPageFor: indexKey [ 
	^ self subclassResponsibility
]

{ #category : #private }
SoilIndexIterator >> findPreviousPageOf: aPage [
	self subclassResponsibility
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
	currentKey := nil.
	currentPageIndex := 0.
	item := self nextAssociation.
	currentKey := item ifNotNil: [ item key ].
	^ item
]

{ #category : #accessing }
SoilIndexIterator >> firstPage [
	^ currentPage := index firstPage
]

{ #category : #accessing }
SoilIndexIterator >> goToNextPage [ 
	currentPage := self nextPage 
]

{ #category : #accessing }
SoilIndexIterator >> goToPreviousPage [ 
	currentPage := self previousPage 

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
SoilIndexIterator >> itemsAt: key [ 
	"still need to restore."
	| assoc items |
	currentKey := index indexKey: key.
	self findPageFor: currentKey.
	currentPageIndex := currentPage indexOfKey: currentKey.
	assoc := self previousAssociation.
	[ assoc notNil and: [ assoc key = key ] ] whileTrue: [ 
		assoc := self previousAssociation ].
	assoc := self nextAssociation.
	items := OrderedCollection new.
	[ assoc notNil and: [ assoc key = key ] ] whileTrue: [ 
	   items add: assoc.
	   assoc := self nextAssociation ].
	^ items 
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
	currentPage := self lastPage.
	"the index could be empty, currentPage (the headerpage) is empty in this case"
	currentPage isEmpty ifTrue: [ ^nil ]. 
	lastAssociation := currentPage lastItem.
	currentKey := lastAssociation key.
	currentPageIndex := currentPage numberOfItems.
	[restoredItem := self restoreItem: lastAssociation] whileNil: [   
			"if the last entry is deleted, we need to take the one before"
			lastAssociation := self basicPreviousAssociation ifNil: [ ^nil ]].
	^ restoredItem key -> (self convertValue: restoredItem value)
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
	^ (self find: key) ifNotNil: [ self next ]
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
	(currentPageIndex = 0) ifTrue: [ ^ nil ].
	^ self nextAssociation
]

{ #category : #private }
SoilIndexIterator >> nextCloseTo: key [
	"return the next entry after key, even if key itself is not there"
	| nextExisitingKey |
	nextExisitingKey := (self nextKeyCloseTo: key) ifNil: [ ^nil ]. 
	^ self at: nextExisitingKey
]

{ #category : #private }
SoilIndexIterator >> nextKeyCloseTo: key [
	"Note: returned key will be an index key"
	| indexKey |
	indexKey := index indexKey: key.
	self findPageFor: indexKey.
	currentKey := currentPage keyOrClosestAfter: indexKey.
	currentPageIndex := currentPage indexOfKey: currentKey.
	"if there is no close key found, we position the cursor at the end, so that asking for the next association will return nil" 
	^ currentKey
		ifNil: [ currentKey := currentPage lastKey ]
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
	"Note: key will be index key"
	| previousAssociation restoredItem |
	previousAssociation := self basicPreviousAssociation ifNil: [ ^nil ].
	restoredItem := self restoreItem: previousAssociation.
	^ restoredItem 
		ifNotNil: [ restoredItem key -> (self convertValue: restoredItem value)] 
		ifNil: [ self previousAssociation ] 
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
	| indexKey item oldValue |
	index hasUniqueKeys ifFalse: [ Error signal: 'removeKey:ifAbsent: can only be used with indexes that have unique keys' ].
	indexKey := index indexKey: key.
	"We search for the data page for the key to update the value with a removed ID
	and return the prior value just like #at: would do"
	self findPageFor: indexKey.

	self flag: #todo.
	"this is a hack to be able to find the first occurrence but in a 
	very inefficient way"
	currentPageIndex := currentPage indexOfKey: indexKey.
	currentKey := (currentPage items at: currentPageIndex ifAbsent: [ ^ aBlock value ]) key. 
	
	item :=  self restoreItem: (currentPage itemAtIndex: currentPageIndex).
	oldValue := item
		ifNotNil: [ 
			(self convertValue: item value) 
				ifNil: [ aBlock value ] ]
		ifNil: [ aBlock value ].
	"We replace the value with the removed ID. As the key stays, we do not need to do a full insert 
	(e.g no need to update index pages for the BTree"
	currentPage items at: currentPageIndex put:  indexKey -> SoilObjectId removed.
	index addDirtyPage: currentPage.

	index decreaseSize.
	^ oldValue
]

{ #category : #removing }
SoilIndexIterator >> removeKey: key value: value [
	^ self 
		removeKey: key 
		value: value
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #removing }
SoilIndexIterator >> removeKey: key value: value ifAbsent: aBlock [
	| indexKey item oldValue |
	indexKey := index indexKey: key.
	"We search for the data page for the key to update the value with a removed ID
	and return the prior value just like #at: would do"
	self findPageFor: indexKey.

	self flag: #todo.
	"this is a hack to be able to find the first occurrence but in a 
	very inefficient way"
	currentPageIndex := index hasUniqueKeys 
		ifTrue: [ currentPage itemIndexForKey: indexKey ] 
		ifFalse: [ currentPage itemIndexForKey: indexKey value: value ]. 
	currentKey := (currentPage items at: currentPageIndex ifAbsent: [ ^ aBlock value ]) key. 
	
	item :=  self restoreItem: (currentPage itemAtIndex: currentPageIndex).
	oldValue := item
		ifNotNil: [ 
			(self convertValue: item value) 
				ifNil: [ aBlock value ] ]
		ifNil: [ aBlock value ].
	"We replace the value with the removed ID. As the key stays, we do not need to do a full insert 
	(e.g no need to update index pages for the BTree"
	currentPage items at: currentPageIndex put:  indexKey -> SoilObjectId removed.
	index addDirtyPage: currentPage.

	index decreaseSize.
	^ oldValue
]

{ #category : #initialization }
SoilIndexIterator >> resetCurrentKey [ 	
	currentKey := nil.
	currentPageIndex := 0
]

{ #category : #private }
SoilIndexIterator >> restoreItem: anItem [ 
	^ anItem 
]

{ #category : #enumerating }
SoilIndexIterator >> reverseDo: aBlock [ 
	| item |
	self lastAssociation ifNotNil: [ :last |  aBlock value: last value ] ifNil: [ ^self ].
	
	"We use basicNextAssociation to avoid the creation of intermediate associations of nextAssociation"
	[ (item := self basicPreviousAssociation ) notNil ] whileTrue: [ 
 		(self restoreItem: item) ifNotNil: [ :notNil |
			(self convertValue: notNil value)
				ifNotNil: [ :value | aBlock value: value ] ] ]
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
		values add: each ].
	^ values
]

{ #category : #enumerating }
SoilIndexIterator >> valuesAt: key [
	^ (self itemsAt: key) collect: #value
]
