"
An index whose header page is in a format older than the one read today: version 1 (written before 2024-07-29, without the size) or 2 (before 2025-10-14, without the unique keys flag). A header page was written back in the version it was read in, so such an index stayed old however often it was used, and since 8532494d it is read in today's format only. What comes after the version - the size, the level and the pointers to the pages - is read from the wrong bytes, and its values cannot be read.

There is no repair. Old headers are left in many databases, in indexes nothing reaches any more; one that is reached is a case for a person.
"
Class {
	#name : #SoilOutdatedIndexHeader,
	#superclass : #SoilIndexFinding,
	#instVars : [
		'version'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilOutdatedIndexHeader class >> segment: anInteger indexId: anIndexId version: aVersion [
	^ self new
		segment: anInteger indexId: anIndexId;
		version: aVersion;
		yourself
]

{ #category : #accessing }
SoilOutdatedIndexHeader >> asDictionary [
	^ super asDictionary
		at: #version put: version;
		yourself
]

{ #category : #accessing }
SoilOutdatedIndexHeader >> description [
	^ 'index ', indexId printString, ' of segment ', segment printString, ' has a header in format version ', version printString, ', which is no longer read: its values cannot be read'
]

{ #category : #accessing }
SoilOutdatedIndexHeader >> kind [
	^ #outdatedIndexHeader
]

{ #category : #accessing }
SoilOutdatedIndexHeader >> version [
	^ version
]

{ #category : #initialization }
SoilOutdatedIndexHeader >> version: anInteger [
	version := anInteger
]
