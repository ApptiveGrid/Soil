Class {
	#name : #SoilMetadata,
	#superclass : #SoilFileWithLayout,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core-Metadata'
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

{ #category : #'open/close' }
SoilMetadata >> ensurePresent [ 
	"this is a legacy method to create for older databases that do not
	have the metadata file already"
	self path exists ifFalse: [ 
		self initializeFilesystem ]
]

{ #category : #inspector }
SoilMetadata >> inspectionMetadata: aBuilder [
	<inspectorPresentationOrder: 1000 title: 'metadata'>

	^ aBuilder newTable
		items: self fields keys;
		addColumn: (SpCompositeTableColumn new
			title: 'key';
			addColumn: (SpStringTableColumn evaluated: [:each | each printString ]));
		addColumn: (SpCompositeTableColumn new
			title: 'value';
			addColumn: (SpStringTableColumn evaluated: [:each | self fieldAt: each asSymbol ]))
]

{ #category : #accessing }
SoilMetadata >> lastBackup [
	^ self fieldAt: #lastBackup
]

{ #category : #accessing }
SoilMetadata >> lastBackup: aDateAndTime [
	^ self fieldAt: #lastBackup put: aDateAndTime 
]

{ #category : #accessing }
SoilMetadata >> lastGarbageCollect [
	^ self fieldAt: #lastGarbageCollect
]

{ #category : #accessing }
SoilMetadata >> lastGarbageCollect: aDateAndTime [ 
	^ self fieldAt: #lastGarbageCollect put: aDateAndTime 
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
	self fieldAt: #lastOpened put: aDateAndTime 
]

{ #category : #accessing }
SoilMetadata >> path [ 
	^ soil path / #metadata
]

{ #category : #utilities }
SoilMetadata >> prefix [
	^ 'SOIL METADATA'
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

{ #category : #accessing }
SoilMetadata >> updateLastBackup [ 
	self lastBackup: DateAndTime now
]

{ #category : #accessing }
SoilMetadata >> updateLastGarbageCollect [ 
	self lastGarbageCollect: DateAndTime now
]

{ #category : #accessing }
SoilMetadata >> updateLastModified [
	self lastModified: DateAndTime now
]

{ #category : #accessing }
SoilMetadata >> updateLastOpened [ 
	self lastOpened: DateAndTime now
]
