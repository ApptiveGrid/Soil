"
All Files that are used by Soil are modeled using a subclass
"
Class {
	#name : #SoilBinaryFile,
	#superclass : #Object,
	#instVars : [
		'stream'
	],
	#category : #'Soil-Core-Files'
}

{ #category : #testing }
SoilBinaryFile class >> isAbstract [
	<ignoreForCoverage>
	^ self == SoilBinaryFile
]

{ #category : #'open/close' }
SoilBinaryFile >> close [
	stream ifNotNil: [ 
		stream close ]
]

{ #category : #accessing }
SoilBinaryFile >> flush [
	stream flush 
]

{ #category : #utilities }
SoilBinaryFile >> headerSize [ 
	^ self prefix size
]

{ #category : #initialization }
SoilBinaryFile >> initializeFilesystem [
	self initializeHeader.
	self initializeStart.
	self stream 
		flush
]

{ #category : #initialization }
SoilBinaryFile >> initializeHeader [
	self stream 
		position: 0;
		nextPutAll: self prefix asByteArray
]

{ #category : #initialization }
SoilBinaryFile >> initializeStart [

]

{ #category : #testing }
SoilBinaryFile >> isOpen [
	^stream notNil and: [stream isOpen]
]

{ #category : #locking }
SoilBinaryFile >> lockAppendingFor: lockContext [
	^ stream lockAppendingFor: lockContext 
]

{ #category : #'open/close' }
SoilBinaryFile >> open [
	self isOpen ifTrue: [ self error: 'File already open' ].
	stream := self soil lockableStream initializePath: self path
]

{ #category : #accessing }
SoilBinaryFile >> path [
	self subclassResponsibility 
]

{ #category : #utilities }
SoilBinaryFile >> prefix [
	self subclassResponsibility 
]

{ #category : #'private - decoding' }
SoilBinaryFile >> readHeader [
	| prefix |
	stream position: 0.
	prefix := stream next: self prefix size.
	(prefix = self prefix asByteArray) ifFalse: [ 
		Error signal: 'read incorrect prefix: ', prefix asString ]
]

{ #category : #accessing }
SoilBinaryFile >> soil [ 
	self subclassResponsibility
]

{ #category : #accessing }
SoilBinaryFile >> stream [
	^ stream ifNil: [ 
		stream := SoilLockableStream path: self path ]
]

{ #category : #accessing }
SoilBinaryFile >> stream: anObject [
	stream := anObject
]

{ #category : #writing }
SoilBinaryFile >> writeContentsToDisk [
	stream fileStream fdatasync
]
