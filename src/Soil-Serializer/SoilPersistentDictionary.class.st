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
	transaction markDirty: self.
	^return
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
SoilPersistentDictionary >> at: key put: value [
	| return |
	transaction ifNotNil: [:tr | tr makeRoot: value].
	return := dict at: key put: value.
	transaction ifNotNil: [:tr | tr markDirty: self].
	^return

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

{ #category : #forwarded }
SoilPersistentDictionary >> includesKey: key [
	^dict includesKey: key
]

{ #category : #initialization }
SoilPersistentDictionary >> initialize [
	dict := Dictionary new
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
	| return |
	return := dict removeKey: anObject ifAbsent: aBlock.
	transaction markDirty: self.
	^return
]

{ #category : #forwarded }
SoilPersistentDictionary >> size [
	^ dict size
]

{ #category : #serialization }
SoilPersistentDictionary >> soilBasicSerialize: serializer [
	self class == SoilPersistentDictionary ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutPersistentDictionary: self
]

{ #category : #initialization }
SoilPersistentDictionary >> soilClusterRootIn: aTransaction [
	(transaction isNil or: [ transaction == aTransaction ])
		ifFalse: [self error: 'Object is already persistent in another transaction'].
	transaction := aTransaction.
	dict do: [:each | each isImmediateObject ifFalse: [transaction makeRoot: each]].

]

{ #category : #serialization }
SoilPersistentDictionary >> soilLoadedIn: aSOTransaction [
	transaction := aSOTransaction 
]

{ #category : #forwarded }
SoilPersistentDictionary >> values [
	^ dict values
]
