Class {
	#name : #SoilSignal,
	#superclass : #WrapperSignal,
	#instVars : [
		'message',
		'id'
	],
	#classVars : [
		'IdCounter'
	],
	#category : #'Soil-Core'
}

{ #category : #initialization }
SoilSignal class >> initialize [
	IdCounter := 0.
	self environment 
		at: #SessionManager 
		ifPresent: [ :manager | manager default registerUserClassNamed: self name ]
		ifAbsent: [ Smalltalk addToStartUpList: self ]
]

{ #category : #'system startup' }
SoilSignal class >> nextId [
	^ IdCounter := IdCounter + 1
]

{ #category : #'system startup' }
SoilSignal class >> startUp [
	IdCounter := 0
]

{ #category : #'as yet unclassified' }
SoilSignal >> emit: aString [ 
	message := aString.
	self emit
]

{ #category : #initialization }
SoilSignal >> initialize [ 
	super initialize.
	id := self nextId
]

{ #category : #accessing }
SoilSignal >> message [
	^ message
]

{ #category : #accessing }
SoilSignal >> message: anObject [
	message := anObject
]

{ #category : #initialization }
SoilSignal >> nextId [
	^ self class nextId
]

{ #category : #printing }
SoilSignal >> printOneLineOn: stream [
	self timestamp printYMDOn: stream.
	stream space.
	self timestamp rounded printHMSOn: stream.
	stream space.
	id \\ 1000 printOn: stream base: 10 length: 3 padded: true.
	stream space.
	self processId printOn: stream base: 10 length: 6 padded: true.
	stream space.
	message ifNotNil: [  
		message printOn: stream.
		stream space ].
	self printOneLineContentsOn: stream
]

{ #category : #printing }
SoilSignal >> processId [
	^ Processor activeProcess hash \\ 999999
]
