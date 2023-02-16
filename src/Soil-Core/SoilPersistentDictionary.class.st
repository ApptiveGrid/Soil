Class {
	#name : #SoilPersistentDictionary,
	#superclass : #Object,
	#instVars : [
		'transaction',
		'dict'
	],
	#category : #'Soil-Core-Collections'
}

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
SoilPersistentDictionary >> at: key put: value [
	| return |
	transaction makeRoot:  value.
	return := dict at: key put: value.
	transaction markDirty: dict.
	^return

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
SoilPersistentDictionary >> removeKey: anObject [
	| return |
	return := dict removeKey: anObject.
	transaction markDirty: dict.
	^return
]

{ #category : #initialization }
SoilPersistentDictionary >> soilMakePersistentIn: aTransaction [
	transaction ifNotNil: [self error: 'Object is already persistent in another transaction'].
	transaction := aTransaction.
	dict do: [:each | each isImmediateObject ifFalse: [transaction makeRoot: each]].
	transaction makeRoot: dict
]
