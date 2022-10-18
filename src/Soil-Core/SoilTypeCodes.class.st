Class {
	#name : #SoilTypeCodes,
	#superclass : #SharedPool,
	#classVars : [
		'ArrayCode',
		'LargeNegativeIntegerCode',
		'LargePositiveIntegerCode',
		'NewObjectCode',
		'TypeCodeMapping',
		'UndefinedCode'
	],
	#category : #'Soil-Core'
}

{ #category : #initialization }
SoilTypeCodes class >> initialize [ 
	self initializeTypeCodes.
	self initializeTypeCodeMapping 
]

{ #category : #initialization }
SoilTypeCodes class >> initializeTypeCodeMapping [
	<script>

	TypeCodeMapping := Array new: 255.
	TypeCodeMapping
		at: NewObjectCode              put: nil;
		at: UndefinedCode 					put: UndefinedObject;
		at: LargePositiveIntegerCode 	put: [ :materializer | materializer nextLargePositiveInteger ];
		at: LargeNegativeIntegerCode 	put: #bar;
		at: ArrayCode 						put: Array.

]

{ #category : #initialization }
SoilTypeCodes class >> initializeTypeCodes [ 
	<script>
	NewObjectCode := 1.
	UndefinedCode := 2.
	LargePositiveIntegerCode := 3.
	LargeNegativeIntegerCode := 4.
	ArrayCode := 5.
]
