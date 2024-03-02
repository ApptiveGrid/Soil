Class {
	#name : #SoilFrame,
	#superclass : #SoilBinaryFile,
	#instVars : [
		'path',
		'fields'
	],
	#category : #'Soil-Core'
}

{ #category : #'as yet unclassified' }
SoilFrame >> buildFields [
	| dict offset end |
	dict := Dictionary new.
	offset := self dataPosition.
	self format do: [ :format |
		end  := offset + format third + 1.
		dict 
			at: format first
			put: { format second . offset . end }.
		offset := end  ].
	^ dict
]

{ #category : #accessing }
SoilFrame >> dataPosition [
	^ self headerSize 
]

{ #category : #accessing }
SoilFrame >> fieldAt: aString [ 
	| field materializer |
	field := self fields at: aString.
	self stream position: field second.
	materializer := SoilMaterializer new
		stream: self stream.
	^ materializer nextSoilObject 
]

{ #category : #accessing }
SoilFrame >> fieldAt: aString put: anObject [
	| field serializer |
	field := self fields at: aString.
	self stream position: field second.
	serializer := SoilSerializer new
		stream: self stream.
	anObject soilBasicSerialize: serializer.
	stream flush
]

{ #category : #accessing }
SoilFrame >> fields [
	^ fields ifNil: [ 
		fields := self buildFields ]
]

{ #category : #accessing }
SoilFrame >> foo [
	^  self fieldAt: #foo
]

{ #category : #inline }
SoilFrame >> foo: anInteger [ 
	self fieldAt: #foo put: anInteger
]

{ #category : #formatting }
SoilFrame >> format [ 
	^ { 
		{ #lastOpened . [ DateAndTime now ] . 33  } .
		{ #lastModified . [ DateAndTime now ] . 33  } .
		{ #foo . [ 0 ] . 9 } }
]

{ #category : #initialization }
SoilFrame >> initializeFields [
	self fields keysAndValuesDo: [ :field :spec |
		self fieldAt: field put: spec first value ]
]

{ #category : #'as yet unclassified' }
SoilFrame >> inspectionMetadata [
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
SoilFrame >> lastModified: aDateAndTime [ 
	self fieldAt: #lastModified put: aDateAndTime 
]

{ #category : #accessing }
SoilFrame >> lastOpened [
	^ self fieldAt: #lastOpened
]

{ #category : #accessing }
SoilFrame >> lastOpened: aDateAndTime [ 
	self fieldAt: #lastOpened put: aDateAndTime 
]

{ #category : #'open/close' }
SoilFrame >> open [ 
	| create |
	create := self path exists.
	stream := self path binaryReadWriteStream.
	create ifFalse: [
		stream
			position: 0; 
			nextPutAll: self prefix.
		self initializeFields.
		stream flush  ]
]

{ #category : #accessing }
SoilFrame >> path [
	^ path 
]

{ #category : #accessing }
SoilFrame >> path: anObject [

	path := anObject
]

{ #category : #utilities }
SoilFrame >> prefix [
	^ 'SOIL FRAME'
]
