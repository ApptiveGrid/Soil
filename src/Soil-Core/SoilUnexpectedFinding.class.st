"
A check that failed in a way no other finding names. Kept as a finding rather than raised, so that one surprise neither ends the walk nor gets lost.
"
Class {
	#name : #SoilUnexpectedFinding,
	#superclass : #SoilFinding,
	#instVars : [
		'subject',
		'errorClassName',
		'messageText'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilUnexpectedFinding class >> subject: anObject error: anError [
	^ self new
		subject: anObject printString
		errorClassName: anError class name
		messageText: anError messageText asString;
		yourself
]

{ #category : #accessing }
SoilUnexpectedFinding >> asDictionary [
	^ super asDictionary
		at: #subject put: subject;
		at: #error put: errorClassName asString;
		at: #messageText put: messageText;
		yourself
]

{ #category : #accessing }
SoilUnexpectedFinding >> description [
	^ subject, ': ', errorClassName asString, ' ', messageText
]

{ #category : #accessing }
SoilUnexpectedFinding >> kind [
	^ #unexpected
]

{ #category : #accessing }
SoilUnexpectedFinding >> messageText [
	^ messageText
]

{ #category : #initialization }
SoilUnexpectedFinding >> subject: aString errorClassName: aSymbol messageText: aText [
	subject := aString.
	errorClassName := aSymbol.
	messageText := aText
]
