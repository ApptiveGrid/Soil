Class {
	#name : #SoilMemoryDatabaseJournal,
	#superclass : #SoilDatabaseJournal,
	#category : #'Soil-Core-Journal'
}

{ #category : #initialization }
SoilMemoryDatabaseJournal >> initialize [ 
	super initialize.
	transactionJournals := Dictionary new
]

{ #category : #inspector }
SoilMemoryDatabaseJournal >> inspectionTransactionJournals: aBuilder [ 
	<inspectorPresentationOrder: 0 title: 'transaction journals'>

	^ aBuilder newTable 
		items: transactionJournals;
		addColumn: (SpCompositeTableColumn new
			title: '#';
			width: 30;
			addColumn: (SpStringTableColumn evaluated: [:each | each index ]));
		addColumn: (SpStringTableColumn new 
			title: #read;
			evaluated: #readVersion;
			width: 50);
		addColumn: (SpStringTableColumn new 
			title: #duration;
			evaluated: #duration;
			width: 50);
		addColumn: (SpStringTableColumn new 
			title: #created;
			evaluated: #createdAt);
		addColumn: (SpStringTableColumn new
			title: #commit;
			evaluated: #committedAt)
]

{ #category : #accessing }
SoilMemoryDatabaseJournal >> transactionJournalsStartingAt: index do: aBlock [ 
	^ (transactionJournals select: [ :each | each index >= index ])	
		do: aBlock

]
