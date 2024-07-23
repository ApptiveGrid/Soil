Class {
	#name : #SoilIndexIterator,
	#superclass : #Object,
	#instVars : [
		'index',
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
	foundValue := self find: aKeyObject ifAbsent: [^ aBlock value].
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

{ #category : #accessing }
SoilIndexIterator >> basicPreviousAssociation [
	| item |
	"Find the association before"
	currentKey ifNil: [ ^ self error: 'you need to navigate first using find: or last, for example'].
	currentPage ifNil: [ self findPageFor: currentKey].
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
	currentKey := nil.
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
	currentPage := self lastNonEmptyPage ifNil: [ ^nil ]. 
	lastAssociation := currentPage lastItem.
	currentKey := lastAssociation key.
	[restoredItem := self restoreItem: lastAssociation] whileNil: [   
			"if the last entry is deleted, we need to take the one before"
			lastAssociation := self basicPreviousAssociation ifNil: [ ^nil ]].
	^ restoredItem key -> (self convertValue: restoredItem value)
]

{ #category : #accessing }
SoilIndexIterator >> lastNonEmptyPage [
	currentPage := self lastPage.
	[currentPage isEmpty] whileTrue: [ 
		"if the page is empty, go to the previous page, if that returns nil all pages are empty"
		currentPage := self previousPage ifNil: [^nil]].
	^ currentPage
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
	indexKey := index indexKey: key.
	"We search for the data page for the key to update the value with a removed ID
	and return the prior value just like #at: would do"
	self findPageFor: indexKey.
	item :=  self restoreItem: (currentPage itemAt: indexKey ifAbsent: [^ aBlock value]).
	oldValue := item
		ifNotNil: [ 
			(self convertValue: item value) 
				ifNil: [ aBlock value ] ]
		ifNil: [ aBlock value ].
	"We replace the value with the removed ID. As the key stays, we do not need to do a full insert 
	(e.g no need to update index pages for the BTree"
	currentPage 
		itemAt: indexKey 
		put: SoilObjectId removed.
	^ oldValue
]

{ #category : #initialization }
SoilIndexIterator >> resetCurrentKey [ 	
	currentKey := nil
]

{ #category : #private }
SoilIndexIterator >> restoreItem: anItem [ 
	^ anItem 
]

{ #category : #enumerating }
SoilIndexIterator >> reverseDo: aBlock [ 
	| item |
	aBlock value: self lastAssociation value.
	
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
