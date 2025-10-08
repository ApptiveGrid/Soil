Class {
	#name : #SoilFileWithLayout,
	#superclass : #SoilBinaryFile,
	#instVars : [
		'path',
		'fields',
		'semaphore'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #formatting }
SoilFileWithLayout class >> fileLayout [ 
	self subclassResponsibility 
]

{ #category : #formatting }
SoilFileWithLayout >> buildFields [
	| position layoutDict |
	position := self dataPosition.
	layoutDict := OrderedDictionary new.
	self class fileLayout do: [ :each | 
		layoutDict 
			at: each name 
			put: (each start: position).
		position := position + each size ].
	^ layoutDict 
]

{ #category : #accessing }
SoilFileWithLayout >> dataPosition [
	^ self headerSize 
]

{ #category : #testing }
SoilFileWithLayout >> fieldAt: aString [ 
	| field |
	^ semaphore critical: [
		field :=  self fields 
			at: aString 
			ifAbsent: [ self error: 'no such field: ', aString ].
		stream position: field start.
		SoilBasicMaterializer new 
			stream: stream;
			nextSoilObject ]
]

{ #category : #accessing }
SoilFileWithLayout >> fieldAt: aString put: anObject [
	| field bytes |
	semaphore critical: [  
		field := self fields 
			at: aString 
			ifAbsent: [ self error: 'no such field: ', aString ].
		bytes := ByteArray streamContents: [ :str |
			anObject soilBasicSerialize: (SoilBasicSerializer new
				stream: str) ].
		(bytes size > field size) ifTrue: [ 
			self error: 'content for field ', field name, ' too large' ].
		self stream 
			position: field start;
			nextPutAll: bytes;
			flush ]
]

{ #category : #formatting }
SoilFileWithLayout >> fields [ 
	^ fields ifNil: [ 
		fields := self buildFields ]
]

{ #category : #initialization }
SoilFileWithLayout >> initialize [ 
	super initialize.
	semaphore := Semaphore forMutualExclusion 
]

{ #category : #initialization }
SoilFileWithLayout >> initializeFields [
	self fields keysAndValuesDo: [ :name :field |
		self 
			fieldAt: name 
			put: field initialValue ]
]

{ #category : #'open/close' }
SoilFileWithLayout >> initializeFilesystem [  
	self stream
			position: 0; 
			nextPutAll: self prefix.
	self initializeFields.
	stream flush
]

{ #category : #'open/close' }
SoilFileWithLayout >> open [ 
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
SoilFileWithLayout >> path [
	^ path 
]

{ #category : #accessing }
SoilFileWithLayout >> path: anObject [

	path := anObject asFileReference 
]
