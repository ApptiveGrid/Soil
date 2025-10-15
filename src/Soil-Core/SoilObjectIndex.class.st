Class {
	#name : #SoilObjectIndex,
	#superclass : #Object,
	#instVars : [
		'selector',
		'index',
		'id',
		'transaction'
	],
	#category : #'Soil-Core-Index-Common'
}

{ #category : #accessing }
SoilObjectIndex class >> soilTransientInstVars [ 
	^ #( index transaction )
]

{ #category : #adding }
SoilObjectIndex >> add: anObject [
	index 
		at: (anObject perform: selector asSymbol)
		add: anObject 
]

{ #category : #adding }
SoilObjectIndex >> add: anObject objectId: objectId [
	| key oldValue |
	key := anObject perform: selector asSymbol.
	oldValue := index 
		at: key
		add: objectId.
		
	transaction addJournalEntry: (SoilAddKeyEntry new
			 segment: 1;
			 id: id;
			 key: (index indexKey: key);
			 value: objectId;
			 oldValue: oldValue).
]

{ #category : #accessing }
SoilObjectIndex >> indexClass: aClass [ 
	index := aClass new 
		keySize: 16;
		valueSize: 8;
		maxLevel: 16;
		uniqueKeys: false
]

{ #category : #initialization }
SoilObjectIndex >> initialize [ 
	super initialize.
	id :=  UUID new asString36
]

{ #category : #initialization }
SoilObjectIndex >> initializeIndex: aTransaction [ 
	index isRegistered ifFalse: [ 
		aTransaction addJournalEntry: (index newIndexEntry 
			id: id;
			segment: 1 )]
]

{ #category : #'instance creation' }
SoilObjectIndex >> newIterator [
	^ index newIterator
		returnProxyForTransaction: transaction;
		journal: transaction soil journal;
		readVersion: transaction readVersion 

]

{ #category : #accessing }
SoilObjectIndex >> selector: aString [ 
	selector := aString 
]

{ #category : #serialization }
SoilObjectIndex >> soilBasicSerialize: aSerializer [
	super soilBasicSerialize: aSerializer.
	aSerializer registerIndexId: id
]

{ #category : #initialization }
SoilObjectIndex >> soilClusterRootIn: aTransaction [
	transaction := aTransaction.
	index isRegistered ifFalse: [ 
		aTransaction addJournalEntry: (index newIndexEntry 
			id: id;
			segment: 1 )]
]

{ #category : #serialization }
SoilObjectIndex >> soilLoadedIn: aTransaction [
	transaction := aTransaction.

]

{ #category : #serializing }
SoilObjectIndex >> soilMaterialized: aMaterializer [
	"connect the global index at materialization time when we
	know the cluster root which defines the location of the index.
	Store a copy-on-write version so all changes are per transaction"
	index := (aMaterializer indexAt: id) asCopyOnWrite
]

{ #category : #accessing }
SoilObjectIndex >> values [
	^ index values 
]
