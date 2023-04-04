Class {
	#name : #SoilWritablePageRegistry,
	#superclass : #SoilPageRegistry,
	#category : #'Soil-Core-Index-SkipList'
}

{ #category : #'as yet unclassified' }
SoilWritablePageRegistry >> clonePages [ 
	pages := pages copy
]

{ #category : #accessing }
SoilWritablePageRegistry >> pageAt: anInteger [ 
	^ pages 
		at: anInteger 
		ifAbsentPut: [ 
			stream 
				ifNotNil: [ self pageFaultAt: anInteger ]
				ifNil: [ 
					(anInteger = 1) 
						ifTrue: [  
							skipList newPage
								registry: self;
								beFirstPage;
								yourself ]
						ifFalse: [ 
							 skipList newPage
								registry: self;
								index: anInteger;
								yourself ] ] ]
]
