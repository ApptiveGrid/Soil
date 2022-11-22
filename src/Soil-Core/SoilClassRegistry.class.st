Class {
	#name : #SoilClassRegistry,
	#superclass : #Object,
	#instVars : [
		'soil'
	],
	#category : #'Soil-Core'
}

{ #category : #public }
SoilClassRegistry >> classDescriptionFor: aClass [ 
	| descriptionFile stream serializer classDescription |
	descriptionFile := self path / aClass soilClassIndex.
	^ descriptionFile exists 
		ifTrue: [ self readClassDescriptionFrom: descriptionFile ]
		ifFalse: [ 
			stream := descriptionFile binaryWriteStream.
			serializer := SoilSerializer new stream: stream.
			classDescription := SOClassDescription for: aClass.
			classDescription soilBasicSerialize: serializer.
			stream 
				flush;
				close.
			classDescription 
			 ] 
]

{ #category : #'as yet unclassified' }
SoilClassRegistry >> loadIndex: aString [ 
	^ self readClassDescriptionFrom: self path / aString
]

{ #category : #accessing }
SoilClassRegistry >> path [
	^ (soil path / #'class-registry') ensureCreateDirectory  
]

{ #category : #'as yet unclassified' }
SoilClassRegistry >> readClassDescriptionFrom: aFileReference [ 
	| stream materializer |
	stream := aFileReference binaryReadStream.
	materializer := soil newMaterializer stream: stream.
	^ SOClassDescription soilMaterialize: materializer.

]

{ #category : #accessing }
SoilClassRegistry >> soil: aSoil [ 
	soil := aSoil
]
