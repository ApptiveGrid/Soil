Class {
	#name : #SoilCommitTransactionEntry,
	#superclass : #SoilTransactionJournalEntry,
	#instVars : [
		'committedAt'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilCommitTransactionEntry class >> journalTypeCode [ 
	^ 9
]

{ #category : #accessing }
SoilCommitTransactionEntry >> address [
	^ ''
]

{ #category : #committing }
SoilCommitTransactionEntry >> commitIn: soil recovery: aBoolean [
	"nothinng to do"
]

{ #category : #accessing }
SoilCommitTransactionEntry >> committedAt [
	^ committedAt
]

{ #category : #accessing }
SoilCommitTransactionEntry >> committedAt: aDateAndTime [ 
	committedAt := aDateAndTime 
]

{ #category : #accessing }
SoilCommitTransactionEntry >> container [
	^ #soil
]

{ #category : #initialization }
SoilCommitTransactionEntry >> initialize [ 
	super initialize.
	committedAt := DateAndTime now
]

{ #category : #testing }
SoilCommitTransactionEntry >> isCommitEntry [
	^ true
]

{ #category : #accessing }
SoilCommitTransactionEntry >> objectIds [
	^ {  }
]

{ #category : #'instance creation' }
SoilCommitTransactionEntry >> readFrom: aStream [ 
	super readFrom: aStream.
	committedAt := (DateAndTime epoch + ((aStream nextLengthEncodedInteger) asInteger / 1000) milliSeconds) asLocal
]

{ #category : #accessing }
SoilCommitTransactionEntry >> value [ 
	^ committedAt 
]

{ #category : #writing }
SoilCommitTransactionEntry >> writeOn: aStream [ 
	| timestamp |
	super writeOn: aStream.
	
	timestamp := committedAt asSeconds * 1000000 + (committedAt nanoSecond // 1000).
	
	aStream nextPutLengthEncodedInteger:  timestamp
]
