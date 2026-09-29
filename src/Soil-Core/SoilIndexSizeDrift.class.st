"
The size in an index's header page is not what the index holds. The size is kept counting up and down and can drift; SoilIndex>>recomputeSize makes it what is there.
"
Class {
	#name : #SoilIndexSizeDrift,
	#superclass : #SoilIndexFinding,
	#instVars : [
		'stored',
		'counted'
	],
	#category : #'Soil-Core-Consistency'
}

{ #category : #'instance creation' }
SoilIndexSizeDrift class >> segment: anInteger indexId: anIndexId stored: aStored counted: aCounted [
	^ self new
		segment: anInteger indexId: anIndexId;
		stored: aStored counted: aCounted;
		yourself
]

{ #category : #accessing }
SoilIndexSizeDrift >> asDictionary [
	^ super asDictionary
		at: #stored put: stored;
		at: #counted put: counted;
		yourself
]

{ #category : #accessing }
SoilIndexSizeDrift >> counted [
	^ counted
]

{ #category : #accessing }
SoilIndexSizeDrift >> description [
	^ 'index ', indexId printString, ' of segment ', segment printString, ' says it holds ', stored printString, ' entries and holds ', counted printString
]

{ #category : #testing }
SoilIndexSizeDrift >> isRepairable [
	^ true
]

{ #category : #accessing }
SoilIndexSizeDrift >> kind [
	^ #indexSizeDrift
]

{ #category : #repairing }
SoilIndexSizeDrift >> repairWith: aRepair [
	^ aRepair repairIndexSizeDrift: self
]

{ #category : #accessing }
SoilIndexSizeDrift >> stored [
	^ stored
]

{ #category : #initialization }
SoilIndexSizeDrift >> stored: aStored counted: aCounted [
	stored := aStored.
	counted := aCounted
]
