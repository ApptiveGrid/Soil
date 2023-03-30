Class {
	#name : #SoilModifiableSkipList,
	#superclass : #SoilSkipList,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #accessing }
SoilModifiableSkipList >> at: aKeyObject put: anObject [
	| key iterator page index newPage |
	key := (aKeyObject asSkipListKeyOfSize: self keySize) asInteger.
	iterator := self iterator.
	iterator find: key.
	page := iterator page.
	index := page indexOfKey: key.
	(index > 0)
		ifTrue: [ page asModifiable itemAt: key put: anObject ] 
		ifFalse: [ 
			page hasRoom 
				ifTrue: [ iterator page asModifiable addItem: (key -> anObject) ]
				ifFalse: [ 
					newPage := self pageRegistry splitPage: iterator.
					((page biggestKey < key)
						ifTrue: [ newPage ]
						ifFalse: [ page ])
							addItem: (key -> anObject) ] ].
	^ anObject
]

{ #category : #accessing }
SoilModifiableSkipList >> newPageRegistry [ 
	^ super newPageRegistry asModifiableRegistry
]

{ #category : #initialization }
SoilModifiableSkipList >> pageClass [ 
	^ SoilWritableSkipListPage 
]
