Class {
	#name : #SoilSkipListDictionary,
	#superclass : #Object,
	#instVars : [
		'id',
		'transaction',
		'index',
		'newValues'
	],
	#category : #'Soil-Core'
}

{ #category : #materializing }
SoilSkipListDictionary class >> soilMaterialize: aMaterializer [ 
	self halt.
]

{ #category : #accessing }
SoilSkipListDictionary class >> soilTransientInstVars [ 
	^ #( index transaction newValues )
]

{ #category : #accessing }
SoilSkipListDictionary >> at: key [ 
	| objectId |
	objectId := SOObjectId readFrom: (self index at: key) readStream.
	^ transaction objectWithId: objectId
]

{ #category : #accessing }
SoilSkipListDictionary >> at: key put: anObject [
"	objectId := transaction makeRoot: anObject.
"	"(transaction isPersistent: anObject) ifFalse: [ 
		transaction makeRoot: anObject ]."
	
	"newValues at: key put: objectId"
	newValues at: key put: anObject
]

{ #category : #accessing }
SoilSkipListDictionary >> first: anInteger [ 
	^ (self index first: anInteger) collect: [ :each | self objectFromKey: each ]  
]

{ #category : #accessing }
SoilSkipListDictionary >> id [
	^ id
]

{ #category : #accessing }
SoilSkipListDictionary >> index [
	^ index ifNil: [ 
		index := self lookupIndex ]
]

{ #category : #initialization }
SoilSkipListDictionary >> initialize [ 
	super initialize.
	newValues := Dictionary new.
	id := UUID new asString36.
	index := SoilSkipList new 
		valueSize: 8;
		yourself
]

{ #category : #accessing }
SoilSkipListDictionary >> keySize: anInteger [ 
	index keySize: anInteger 
]

{ #category : #private }
SoilSkipListDictionary >> loadFrom: aFileReference [ 
	^ SoilSkipList new 
		path: aFileReference;
		open
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> lookupIndex [
	^ transaction lookupIndex: self
]

{ #category : #accessing }
SoilSkipListDictionary >> maxLevel: anInteger [ 
	index maxLevel: anInteger 
]

{ #category : #accessing }
SoilSkipListDictionary >> objectFromKey: key [ 
	| objectId |
	objectId := SOObjectId readFrom: (self index at: key) readStream.
	^ transaction objectWithId: objectId
]

{ #category : #accessing }
SoilSkipListDictionary >> size [ 
	^ self index size
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> soilClusterRootIn: aTransaction [
	transaction := aTransaction 
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> soilLoadedIn: aTransaction [
	transaction := aTransaction 
]

{ #category : #'as yet unclassified' }
SoilSkipListDictionary >> soilSerialize: aSerializer [ 
	| objectId |
	super soilSerialize: aSerializer.
	index path ifNil: [  
		aSerializer registerIndexedObject: self ].
	newValues keysAndValuesDo: [ :key :object |
		objectId := transaction makeRoot: object.
		objectId initializeIndex: transaction objectRepository.
		index at: key put: objectId ].
	index writePages
]
