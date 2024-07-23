Class {
	#name : #SoilGlobals,
	#superclass : #SoilFileWithLayout,
	#category : #'Soil-Core'
}

{ #category : #formatting }
SoilGlobals class >> fileLayout [ 
	^ { 
		SoilFileField name: #lastOpened size: 16 initialBlock: [ DateAndTime epoch ] .
		SoilFileField name: #lastModified size: 16 initialBlock: [ DateAndTime epoch ] .
		SoilFileField name: #lastGarbageCollect size: 16 initialBlock: [ DateAndTime epoch ] .
		SoilFileField name: #lastBackup size: 16 initialBlock: [ DateAndTime epoch ] .
		 }
]

{ #category : #'as yet unclassified' }
SoilGlobals >> inspectionFields [
	<inspectorPresentationOrder: 1000 title: 'fields'>

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
SoilGlobals >> lastModified [
	^ self fieldAt: #lastModified
]

{ #category : #accessing }
SoilGlobals >> lastModified: aDateAndTime [ 
	self fieldAt: #lastModified put: aDateAndTime 
]

{ #category : #accessing }
SoilGlobals >> lastOpened [
	^ self fieldAt: #lastOpened
]

{ #category : #accessing }
SoilGlobals >> lastOpened: aDateAndTime [ 
	self protectedFieldAt: #lastOpened put: aDateAndTime 
]

{ #category : #utilities }
SoilGlobals >> prefix [
	^ 'SOIL GLOBALS'
]

{ #category : #counting }
SoilGlobals >> transactionCommitted: aSoilTransaction [ 
	aSoilTransaction hasModifications ifTrue: [ 
		self lastModified: DateAndTime now  ]
]
