Class {
	#name : #SoilJournalEntries,
	#superclass : #Object,
	#instVars : [
		'entries'
	],
	#category : #'Soil-Core-Model'
}

{ #category : #accessing }
SoilJournalEntries >> entries [

	^ entries
]

{ #category : #accessing }
SoilJournalEntries >> entries: anObject [

	entries := anObject
]

{ #category : #'as yet unclassified' }
SoilJournalEntries >> inspectionEntries [
	<inspectorPresentationOrder: 0 title: 'journal entries'>

	^ SpTablePresenter new
		items: entries;
		addColumn: (SpCompositeTableColumn new
			title: '#';
			width: 30;
			addColumn: (SpStringTableColumn evaluated: [:each | entries indexOf: each ]));
		addColumn: (SpCompositeTableColumn new
			title: 'Tx id';
			width: 30;
			addColumn: (SpStringTableColumn evaluated: [:each | each transactionId ]));
		addColumn: (SpCompositeTableColumn new
			title: 'Name';
			addColumn: (SpStringTableColumn evaluated: [:each | each class name ]));
		addColumn: (SpCompositeTableColumn new
			title: 'container';
			addColumn: (SpStringTableColumn evaluated: [:each | each container ]));
		addColumn: (SpCompositeTableColumn new
			title: 'address';
			addColumn: (SpStringTableColumn evaluated: [:each | each address ]));
		addColumn: (SpCompositeTableColumn new
			title: 'value';
			addColumn: (SpStringTableColumn evaluated: [:each | each value ]));
		addColumn: (SpCompositeTableColumn new
			title: 'oldValue';
			addColumn: (SpStringTableColumn evaluated: [:each | each oldValue ]))
]
