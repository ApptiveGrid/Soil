Class {
	#name : #SoilMetadata,
	#superclass : #SoilFileWithLayout,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core'
}

{ #category : #formatting }
SoilMetadata class >> fileLayout [ 
	^ { 
		SoilFileField name: #lastOpened size: 16 initialBlock: [ DateAndTime epoch ] .
		SoilFileField name: #lastModified size: 16 initialBlock: [ DateAndTime epoch ] .
		SoilFileField name: #lastGarbageCollect size: 16 initialBlock: [ DateAndTime epoch ] .
		SoilFileField name: #lastBackup size: 16 initialBlock: [ DateAndTime epoch ] .
		 }
]

{ #category : #'as yet unclassified' }
SoilMetadata >> inspectionMetadata [
	<inspectorPresentationOrder: 1000 title: 'metadata'>

	^ SpTablePresenter new
		items: self fields keys;
		addColumn: (SpCompositeTableColumn new
			title: 'key';
			addColumn: (SpStringTableColumn evaluated: [:each | each printString ]));
		addColumn: (SpCompositeTableColumn new
			title: 'value';
			addColumn: (SpStringTableColumn evaluated: [:each | self fieldAt: each asSymbol ]))
]

{ #category : #accessing }
SoilMetadata >> lastModified [
	^ self fieldAt: #lastModified
]

{ #category : #accessing }
SoilMetadata >> lastModified: aDateAndTime [ 
	self fieldAt: #lastModified put: aDateAndTime 
]

{ #category : #accessing }
SoilMetadata >> lastOpened [
	^ self fieldAt: #lastOpened
]

{ #category : #accessing }
SoilMetadata >> lastOpened: aDateAndTime [ 
	self protectedFieldAt: #lastOpened put: aDateAndTime 
]

{ #category : #accessing }
SoilMetadata >> path [ 
	^ soil path / #globals
]

{ #category : #utilities }
SoilMetadata >> prefix [
	^ 'SOIL GLOBALS'
]

{ #category : #accessing }
SoilMetadata >> soil [ 
	^ soil
]

{ #category : #accessing }
SoilMetadata >> soil: aSoil [ 
	soil := aSoil
]

{ #category : #counting }
SoilMetadata >> transactionCommitted: aSoilTransaction [ 
	aSoilTransaction hasModifications ifTrue: [ 
		self lastModified: DateAndTime now  ]
]
