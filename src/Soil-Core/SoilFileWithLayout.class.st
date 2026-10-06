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
		self writeBytes: bytes into: field ]
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
	stream := self soil streamOnPath: self path.
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

{ #category : #locking }
SoilFileWithLayout >> lockField: aField [
	"a lock over the field, or nil on a stream that cannot lock - a read-only one is
	a plain read stream, and writes nothing.

	What the lock is for: the fields of this file are written by different hosts, one
	each - the base that holds the database writes lastOpened and lastModified, the
	metabase writes lastBackup. Over NFS every client caches the file by pages, and a
	write of sixteen bytes into a page it holds is written back as the whole page,
	unless the file is locked: then the client writes what was written and nothing
	around it. Without the lock the base's next commit put the old lastBackup back,
	every night, and the metabase kept finding a database that was never backed up.
	A local file system has one cache for everybody and does not need it.

	Somebody else holding the field is a matter of a moment - another field write -
	so it is asked again before it is an error"
	| attempts |
	(self stream respondsTo: #lockFrom:length:for:) ifFalse: [ ^ nil ].
	attempts := 0.
	^ [ self stream lockFrom: aField start length: aField size for: self ]
		on: SoilAlreadyLocked
		do: [ :error |
			(attempts := attempts + 1) > self lockAttempts ifTrue: [ error pass ].
			(Delay forMilliseconds: 10) wait.
			error retry ]
]

{ #category : #locking }
SoilFileWithLayout >> lockAttempts [
	"a second, ten milliseconds at a time"
	^ 100
]

{ #category : #writing }
SoilFileWithLayout >> writeBytes: aByteArray into: aField [
	"the field is written under a lock, see #lockField:, and the lock is let go of
	after the bytes are flushed - the flush is what hands them to the server"
	| lock |
	lock := self lockField: aField.
	[ self stream 
		position: aField start;
		nextPutAll: aByteArray;
		flush ]
		ensure: [ lock ifNotNil: [ lock release ] ]
]
