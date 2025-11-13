Class {
	#name : 'WinOverlapped',
	#superclass : 'FFIStructure',
	#classVars : [
		'OFFSET_HEVENT',
		'OFFSET_INTERNAL',
		'OFFSET_INTERNALHIGH',
		'OFFSET_OFFSET',
		'OFFSET_OFFSETHIGH'
	],
	#category : 'Soil-File',
	#package : 'Soil-File'
}

{ #category : 'field definition' }
WinOverlapped class >> fieldsDesc [
	"self rebuildFieldAccessors"

	^ #(
	uint64 internal;
	uint64 internalHigh;
	uint offset;
	uint offsetHigh;
	void* hEvent;
	)
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> hEvent [
	"This method was automatically generated"
	^ExternalData fromHandle: (handle pointerAt: OFFSET_HEVENT) type: ExternalType void asPointerType
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> hEvent: anObject [
	"This method was automatically generated"
	handle pointerAt: OFFSET_HEVENT put: anObject getHandle.
]

{ #category : 'initialization' }
WinOverlapped >> initialize [
	super initialize
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> internal [
	"This method was automatically generated"
	^handle unsignedLongLongAt: OFFSET_INTERNAL
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> internal: anObject [
	"This method was automatically generated"
	handle unsignedLongLongAt: OFFSET_INTERNAL put: anObject
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> internalHigh [
	"This method was automatically generated"
	^handle unsignedLongLongAt: OFFSET_INTERNALHIGH
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> internalHigh: anObject [
	"This method was automatically generated"
	handle unsignedLongLongAt: OFFSET_INTERNALHIGH put: anObject
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> offset [
	"This method was automatically generated"
	^handle unsignedLongAt: OFFSET_OFFSET
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> offset: anObject [
	"This method was automatically generated"
	handle unsignedLongAt: OFFSET_OFFSET put: anObject
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> offsetHigh [
	"This method was automatically generated"
	^handle unsignedLongAt: OFFSET_OFFSETHIGH
]

{ #category : 'accessing - structure variables' }
WinOverlapped >> offsetHigh: anObject [
	"This method was automatically generated"
	handle unsignedLongAt: OFFSET_OFFSETHIGH put: anObject
]

{ #category : 'printing' }
WinOverlapped >> printOn: aStream [
	"Append to the argument, aStream, the names and values of all the record's variables."

	aStream nextPutAll: self class name; nextPutAll: ' ( '; cr.
	self class fieldSpec fieldNames do: [ :field |
		aStream nextPutAll: field; nextPut: $:; space; tab.
			(self perform: field ) printOn: aStream.
			] separatedBy: [ aStream cr ].
	aStream cr; nextPut: $)
]
