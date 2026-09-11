"
The SoilPersistenDictionary is a Soil specific Dictionary
- all values are roots 
- markDirty: is called on at:put:

This means that on materialize, it loads all keys in memory, but values are loaded lazyly only when accessed.


"
Class {
	#name : #SoilPersistentDictionary,
	#superclass : #Object,
	#instVars : [
		'transaction',
		'dict'
	],
	#category : #'Soil-Serializer-Base'
}

{ #category : #'instance creation' }
SoilPersistentDictionary class >> new [
	^ self basicNew
		initialize: 5;
		yourself
]

{ #category : #'instance creation' }
SoilPersistentDictionary class >> new: size [
	^ self basicNew initialize: size
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
	self 
		at: anAssociation key 
		put: anAssociation value.
	^ anAssociation 
]

{ #category : #forwarded }
SoilPersistentDictionary >> anyOne [ 
	^ dict anyOne
]

{ #category : #forwarded }
SoilPersistentDictionary >> at: key [
	^ dict at: key ifAbsent: [ 
		KeyNotFound signal: ('cannot find key ', key printString,' in dict with keys: ', dict keys printString)  ]
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
SoilPersistentDictionary >> at: key ifPresent: aPresentBlock ifAbsent: anAbsentBlock [

	^ aPresentBlock cull: (self 
		at: key 
		ifAbsent: [ ^ anAbsentBlock value ])
]

{ #category : #forwarded }
SoilPersistentDictionary >> at: key put: value [
	transaction ifNotNil: [:tr | tr makeRoot: value].
	dict at: key put: value.
	^value

]

{ #category : #forwarded }
SoilPersistentDictionary >> collect: aBlock [ 
	^ dict collect: aBlock
]

{ #category : #enumerating }
SoilPersistentDictionary >> detect: detectBlock ifNone: noneBlock [ 
	^ dict values
		detect: detectBlock 
		ifNone: noneBlock 
]

{ #category : #accessing }
SoilPersistentDictionary >> dict [
	^dict
]

{ #category : #initialization }
SoilPersistentDictionary >> ensureValuesAreRoot [
	dict do: [:each | 
		each isImmediateObject ifFalse: [
			transaction makeRoot: each ] ]

]

{ #category : #forwarded }
SoilPersistentDictionary >> includesKey: key [
	^dict includesKey: key
]

{ #category : #initialization }
SoilPersistentDictionary >> initialize: size [
	dict := Dictionary new: size
]

{ #category : #testing }
SoilPersistentDictionary >> isCollection [ 
	^ true
]

{ #category : #testing }
SoilPersistentDictionary >> isEmpty [
	^ dict isEmpty
]

{ #category : #forwarded }
SoilPersistentDictionary >> keys [
	^ dict keys
]

{ #category : #forwarded }
SoilPersistentDictionary >> keysAndValuesDo: aBlock [
	^ dict keysAndValuesDo: aBlock
]

{ #category : #copying }
SoilPersistentDictionary >> postCopy [ 
	dict := dict copy
]

{ #category : #forwarded }
SoilPersistentDictionary >> removeKey: key [
	^ self 
		removeKey: key 
		ifAbsent: [ KeyNotFound signalFor: key in: self ]
]

{ #category : #forwarded }
SoilPersistentDictionary >> removeKey: anObject ifAbsent: aBlock [
	^ dict 
		removeKey: anObject 
		ifAbsent: aBlock.

]

{ #category : #forwarded }
SoilPersistentDictionary >> size [
	^ dict size
]

{ #category : #serialization }
SoilPersistentDictionary >> soilBasicSerialize: aSerializer [ 
	transaction ifNil: [
		transaction := aSerializer transaction.
		self ensureValuesAreRoot ].
	aSerializer nextPutPersistentDictionary: self
]

{ #category : #initialization }
SoilPersistentDictionary >> soilClusterRootIn: aTransaction [
	(transaction isNil or: [ transaction == aTransaction ])
		ifFalse: [self error: 'Object is already persistent in another transaction'].
	transaction := aTransaction.
	self ensureValuesAreRoot
]

{ #category : #serialization }
SoilPersistentDictionary >> soilLoadedIn: aTransaction [
	transaction := aTransaction 
]

{ #category : #accessing }
SoilPersistentDictionary >> transaction: aTransaction [ 
	
	transaction := aTransaction 
]

{ #category : #forwarded }
SoilPersistentDictionary >> values [
	^ dict values
]
