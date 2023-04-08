Extension { #name : #Soil }

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlClasses [

	^ {
SOBinaryFile.
SOSegmentFile.
SOObjectFile.
SOObjectIndexFile.
SoilParameterFile.
SOClusterRecord.
SONewClusterVersion.
SOPersistentClusterVersion.
SOJournal.
SOJournal.
SOJournalEntry.
SONewObjectVersionEntry.
SoilNewKeyEntry.
SOObjectId.
"SOObjectProxy."
SOObjectRepository.
SOObjectSegment.
SOMetaSegment.
SOTransaction.
SoilBehaviorRegistry.
SoilIndexManager.
Soil
}
]

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlClassesOn: aStream [

	self pumlClasses do: [ :eachClassName |
		eachClassName pumlClassOn: aStream ]
]

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlImage: layoutString [
	"
	self pumlImage: 'page 1x1'
	self pumlImage: 'scale 1880*850'
	"

	^ #PlantUMLBridge asClass imageFromUML: (self pumlSource: layoutString)
]

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlREADME [
	"
	If PlantUMLBridge is loaded (see: https://github.com/kasperosterbye/PlantUMLBridge)
	then run the example code in #pumlWebbrowser: and #pumlImage:

	Otherwise, inspect the results from the examples in #pumlSource:,
	then copy and paste the 'Full Content' from the inspector to the
	online server at https://plantuml.com/
	"
]

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlRelationshipFrom: thisSideClass to: otherSideClass type: type on: aStream [

	aStream nextPutAll: thisSideClass name asString.

	type = #'1M' ifTrue: [
		aStream nextPutAll: ' "1" *-- "many" ' ].

	type = #'11' ifTrue: [
		aStream nextPutAll: ' -- ' ].

	aStream nextPutAll: otherSideClass name asString; lf
]

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlRelationshipsOn: aStream [

	self pumlRelationshipFrom: Soil to: SOObjectRepository type: #'11' on: aStream.
	self pumlRelationshipFrom: Soil to: SoilBehaviorRegistry type: #'11' on: aStream.
	self pumlRelationshipFrom: Soil to: SoilParameterFile type: #'11' on: aStream.

	self pumlRelationshipFrom: SOObjectRepository to: SOObjectSegment type: #'1M' on: aStream.
	self pumlRelationshipFrom: SOObjectRepository to: SOMetaSegment type: #'1M' on: aStream.

	self pumlRelationshipFrom: SoilBehaviorRegistry to: SOBehaviorDescription type: #'1M' on: aStream.
	self pumlRelationshipFrom: SoilBehaviorRegistry to: SoilSkipList type: #'11' on: aStream.

	self pumlRelationshipFrom: SOTransaction to: SOJournal type: #'11' on: aStream.
	self pumlRelationshipFrom: SOTransaction to: SOObjectRepository type: #'11' on: aStream.
	self pumlRelationshipFrom: SOTransaction to: SOObjectId type: #'1M' on: aStream.
	self pumlRelationshipFrom: SOTransaction to: SONewClusterVersion type: #'1M' on: aStream.

	self pumlRelationshipFrom: SOJournal to: SOJournalEntry type: #'11' on: aStream.

	self pumlRelationshipFrom: SOObjectSegment to: SOObjectFile type: #'11' on: aStream.
	self pumlRelationshipFrom: SOObjectSegment to: SOObjectIndexFile type: #'11' on: aStream.
	self pumlRelationshipFrom: SOObjectSegment to: SoilIndexManager type: #'1M' on: aStream
]

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlSource: layoutString [
	"
	self pumlSource: 'page 1x1'
	self pumlSource: 'scale 1880*850'
	"

	^ String streamContents: [ :stream |
		stream nextPutAll: '@startuml'; lf.
		stream nextPutAll: 'title Soil'; lf.
		stream nextPutAll: 'hide methods'; lf.
		stream nextPutAll: layoutString; lf.
		self pumlClassesOn: stream.
		self pumlRelationshipsOn: stream.
		self pumlSubTypesOn: stream.
		stream nextPutAll: '@enduml'; lf ]
]

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlSubTypeFrom: thisSideClass to: otherSideClass on: aStream [

	aStream
		nextPutAll: thisSideClass name asString;
		nextPutAll: ' <|-- ';
		nextPutAll: otherSideClass name asString; lf
]

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlSubTypesOn: aStream [

	self pumlSubTypeFrom: SOClusterRecord to: SONewClusterVersion on: aStream.
	self pumlSubTypeFrom: SOClusterRecord to: SOPersistentClusterVersion on: aStream.
	self pumlSubTypeFrom: SOObjectSegment to: SOMetaSegment on: aStream.

	self pumlSubTypeFrom: SOBinaryFile to: SOSegmentFile on: aStream.
	self pumlSubTypeFrom: SOSegmentFile to: SOObjectFile on: aStream.
	self pumlSubTypeFrom: SOSegmentFile to: SOObjectIndexFile on: aStream.
	self pumlSubTypeFrom: SOBinaryFile to: SoilParameterFile on: aStream.

	self pumlSubTypeFrom: SOJournalEntry to: SONewObjectEntry on: aStream.
	self pumlSubTypeFrom: SoilNewKeyEntry to: SONewObjectVersionEntry on: aStream.
	self pumlSubTypeFrom: SOJournalEntry to: SoilNewKeyEntry on: aStream
]

{ #category : #'*Soil-PlantUml' }
Soil class >> pumlWebbrowser: layoutString [
	"
	self pumlWebbrowser: 'page 1x1'
	self pumlWebbrowser: 'scale 1920*1024'
	"

	^ #PlantUMLBridge asClass webbrowseUML: (self pumlSource: layoutString)
]
