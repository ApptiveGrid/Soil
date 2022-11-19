Class {
	#name : #SOClassDescription,
	#superclass : #Object,
	#instVars : [
		'class',
		'name',
		'instVarNames'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
SOClassDescription class >> for: aClass [ 
	^ self new 
		initializeFromClass: aClass
]

{ #category : #'as yet unclassified' }
SOClassDescription class >> soilMaterialize: materializer [ 
	| classDescription names |
	classDescription := SOClassDescription new.
	classDescription 
		name: materializer basicNextString.
	names := Array new: materializer nextLengthEncodedInteger.
	1  to: names size do: [:index |
		names at: index put: materializer basicNextString ].
	classDescription instVarNames: names.
	^ classDescription 
]

{ #category : #'as yet unclassified' }
SOClassDescription >> classId [
	^ 1
]

{ #category : #'as yet unclassified' }
SOClassDescription >> classIndex [
	^ class soilClassIndex 
]

{ #category : #initialization }
SOClassDescription >> initializeFromClass: aClass [ 
	class := aClass.
	name := aClass name.
	instVarNames := aClass instVarNames
]

{ #category : #public }
SOClassDescription >> instVarIndexes [
	^ class allInstVarNames collect: [ :n | class allInstVarNames indexOf: n ]
]

{ #category : #accessing }
SOClassDescription >> instVarNames [

	^ instVarNames
]

{ #category : #accessing }
SOClassDescription >> instVarNames: anObject [

	instVarNames := anObject
]

{ #category : #accessing }
SOClassDescription >> name [

	^ name
]

{ #category : #accessing }
SOClassDescription >> name: anObject [

	name := anObject.
	class := Smalltalk at: name asSymbol 
]

{ #category : #'as yet unclassified' }
SOClassDescription >> soilBasicSerialize: serializer [ 
	serializer 
		basicNextPutString: class name;
		nextPutLengthEncodedInteger: instVarNames size.
	instVarNames do: [ :n |
		serializer basicNextPutString: n ]
]
