"
Raised when an imported behavior description has a shape that this database neither
knows from the chain of that class nor recognizes as the shape the class has in this
image.

That combination means the exporting image runs different code: SoilGraphExporter>>
updateCluster: raises everything it exports to the state of *its* software, so a shape
that is not ours came from a different one. Migrating it would mean guessing which
instance variable became which, and that guess belongs to whoever changed the class,
not here.

The two shapes are carried in the error so that the difference can be read without
re-running the import.
"
Class {
	#name : #SoilBehaviorShapeConflict,
	#superclass : #SoilError,
	#instVars : [
		'behaviorIdentifier',
		'importedInstVarNames',
		'presentInstVarNames'
	],
	#category : #'Soil-Core-Error'
}

{ #category : #accessing }
SoilBehaviorShapeConflict >> behaviorIdentifier [
	^ behaviorIdentifier
]

{ #category : #accessing }
SoilBehaviorShapeConflict >> behaviorIdentifier: anObject [
	behaviorIdentifier := anObject
]

{ #category : #accessing }
SoilBehaviorShapeConflict >> importedInstVarNames [
	^ importedInstVarNames
]

{ #category : #accessing }
SoilBehaviorShapeConflict >> importedInstVarNames: anObject [
	importedInstVarNames := anObject
]

{ #category : #accessing }
SoilBehaviorShapeConflict >> messageText [
	^ messageText ifNil: [
		  messageText := String streamContents: [ :stream |
				             stream
					             << 'the imported shape of ';
					             << behaviorIdentifier asString;
					             << ' is neither a version this database knows nor the shape the class has here. imported: ';
					             print: importedInstVarNames;
					             << ', present: ';
					             print: presentInstVarNames ] ]
]

{ #category : #accessing }
SoilBehaviorShapeConflict >> presentInstVarNames [
	^ presentInstVarNames
]

{ #category : #accessing }
SoilBehaviorShapeConflict >> presentInstVarNames: anObject [
	presentInstVarNames := anObject
]
