"
What a SoilQuery asks of the value of its property, as data: equal to a value, between two values
(each end included or not, nil for an open end), or starting with some bytes. Because it is data
and not a block a planner can turn it into the range of an index, see #rangeIn:, and a read without
an index can check it with #matches:encoding:.

Equality and order are those of a SoilKeyEncoding, not of the values.
"
Class {
	#name : #SoilQueryComparison,
	#superclass : #Object,
	#instVars : [
		'kind',
		'low',
		'high',
		'includesFirst',
		'includesLast'
	],
	#category : #'Soil-Core-Query'
}

{ #category : #'instance creation' }
SoilQueryComparison class >> equalTo: aValue [
	^ self new
		setKind: #equal low: aValue high: aValue includeFirst: true includeLast: true;
		yourself
]

{ #category : #'instance creation' }
SoilQueryComparison class >> from: aLowValue to: aHighValue [
	"both ends included, nil for an open end"
	^ self from: aLowValue to: aHighValue includeFirst: true includeLast: true
]

{ #category : #'instance creation' }
SoilQueryComparison class >> from: aLowValue to: aHighValue includeFirst: firstBoolean includeLast: lastBoolean [
	^ self new
		setKind: #between low: aLowValue high: aHighValue includeFirst: firstBoolean includeLast: lastBoolean;
		yourself
]

{ #category : #'instance creation' }
SoilQueryComparison class >> startingWith: someBytes [
	"the property starts with someBytes, a string or a byte array. Only for values that are stored
	left aligned: strings and byte arrays"
	^ self new
		setKind: #startingWith low: someBytes high: nil includeFirst: true includeLast: true;
		yourself
]

{ #category : #accessing }
SoilQueryComparison >> high [
	^ high
]

{ #category : #accessing }
SoilQueryComparison >> includesFirst [
	^ includesFirst
]

{ #category : #accessing }
SoilQueryComparison >> includesLast [
	^ includesLast
]

{ #category : #testing }
SoilQueryComparison >> isEqual [
	^ kind == #equal
]

{ #category : #accessing }
SoilQueryComparison >> kind [
	^ kind
]

{ #category : #accessing }
SoilQueryComparison >> low [
	^ low
]

{ #category : #testing }
SoilQueryComparison >> matches: aValue encoding: anEncoding [
	"whether aValue satisfies the comparison, as the encoding orders values. A value the
	encoding refuses is an error, as it is when it is put into an index"
	| order |
	kind == #equal ifTrue: [ ^ (anEncoding compare: aValue with: low) = 0 ].
	kind == #startingWith ifTrue: [ ^ anEncoding isValue: aValue startingWith: low ].
	low ifNotNil: [
		order := anEncoding compare: aValue with: low.
		(includesFirst ifTrue: [ order >= 0 ] ifFalse: [ order > 0 ]) ifFalse: [ ^ false ] ].
	high ifNotNil: [
		order := anEncoding compare: aValue with: high.
		(includesLast ifTrue: [ order <= 0 ] ifFalse: [ order < 0 ]) ifFalse: [ ^ false ] ].
	^ true
]

{ #category : #printing }
SoilQueryComparison >> printOn: aStream [
	super printOn: aStream.
	aStream << ' ' << kind << ' ' << low printString.
	kind == #between ifTrue: [ aStream << ' to ' << high printString ]
]

{ #category : #converting }
SoilQueryComparison >> rangeIn: aLayout [
	"the range of keys of an index with aLayout that holds the values this comparison lets through"
	kind == #equal ifTrue: [ ^ aLayout rangeFor: low ].
	kind == #startingWith ifTrue: [ ^ aLayout rangeStartingWith: low ].
	^ aLayout rangeFrom: low to: high includeFirst: includesFirst includeLast: includesLast
]

{ #category : #initialization }
SoilQueryComparison >> setKind: aSymbol low: aLowValue high: aHighValue includeFirst: firstBoolean includeLast: lastBoolean [
	kind := aSymbol.
	low := aLowValue.
	high := aHighValue.
	includesFirst := firstBoolean.
	includesLast := lastBoolean
]
