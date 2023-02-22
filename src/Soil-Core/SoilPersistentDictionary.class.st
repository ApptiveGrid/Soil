Class {
	#name : #SoilPersistentDictionary,
	#superclass : #Object,
	#instVars : [
		'transaction',
		'dict'
	],
	#category : #'Soil-Core-Collections'
}

{ #category : #'instance creation' }
SoilPersistentDictionary class >> new: size [
	^self new
]

{ #category : #materializing }
SoilPersistentDictionary class >> soilMaterialize: materializer [
	^ materializer nextPersistentDictionary: self
]

{ #category : #accessing }
SoilPersistentDictionary class >> soilTransientInstVars [
	^#(transaction)
]

{ #category : #forwarded }
SoilPersistentDictionary >> add: anAssociation [
	| return |
	transaction makeRoot: anAssociation value.
	return := dict add: anAssociation.
	transaction markDirty: dict.
	^return
]

{ #category : #forwarded }
SoilPersistentDictionary >> at: key [
	^ dict at: key
]

{ #category : #forwarded }
SoilPersistentDictionary >> at: key ifAbsent: aBlock [ 
	^ dict at: key ifAbsent: aBlock
]

{ #category : #forwarded }
SoilPersistentDictionary >> at: key ifAbsentPut: aBlock [
	^ dict 
		at: key 
		ifAbsent: [ self at: key put: aBlock value ]
]

{ #category : #forwarded }
SoilPersistentDictionary >> at: key put: value [
	| return |
	transaction ifNotNil: [:tr | tr makeRoot:  value].
	return := dict at: key put: value.
	transaction ifNotNil: [:tr | tr markDirty: dict].
	^return

]

{ #category : #forwarded }
SoilPersistentDictionary >> collect: aBlock [ 
	^ dict collect: aBlock
]

{ #category : #forwarded }
SoilPersistentDictionary >> includesKey: key [
	^dict includesKey: key
]

{ #category : #initialization }
SoilPersistentDictionary >> initialize [
	dict := Dictionary new
]

{ #category : #forwarded }
SoilPersistentDictionary >> keysAndValuesDo: aBlock [
	^ dict keysAndValuesDo: aBlock
]

{ #category : #forwarded }
SoilPersistentDictionary >> removeKey: anObject [
	| return |
	return := dict removeKey: anObject.
	transaction markDirty: dict.
	^return
]

{ #category : #forwarded }
SoilPersistentDictionary >> size [
	^ dict size
]

{ #category : #'as yet unclassified' }
SoilPersistentDictionary >> soilBasicSerialize: serializer [
	self class == SoilPersistentDictionary ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutPersistentDictionary: self
]

{ #category : #initialization }
SoilPersistentDictionary >> soilMakePersistentIn: aTransaction [
	transaction ifNotNil: [self error: 'Object is already persistent in another transaction'].
	transaction := aTransaction.
	dict do: [:each | each isImmediateObject ifFalse: [transaction makeRoot: each]].
	transaction makeRoot: dict
]
