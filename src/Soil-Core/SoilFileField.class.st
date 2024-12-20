Class {
	#name : #SoilFileField,
	#superclass : #Object,
	#instVars : [
		'name',
		'size',
		'start',
		'initialBlock'
	],
	#category : #'Soil-Core'
}

{ #category : #'instance creation' }
SoilFileField class >> name: aName size: anInteger initialBlock: aBlock [
	^ self new 
		name: aName;
		size: anInteger;
		initialBlock: aBlock
]

{ #category : #accessing }
SoilFileField >> initialBlock [
	^ initialBlock
]

{ #category : #accessing }
SoilFileField >> initialBlock: aBlock [ 
	initialBlock := aBlock
]

{ #category : #accessing }
SoilFileField >> initialValue [
	^ initialBlock value
]

{ #category : #accessing }
SoilFileField >> name [
	^ name
]

{ #category : #accessing }
SoilFileField >> name: aString [ 
	name := aString
]

{ #category : #printing }
SoilFileField >> printOn: aStream [ 	
	aStream 
		<< 'field ' << name printString 
		<< ', start: ' << start printString
		<< ', size: ' << size printString
]

{ #category : #accessing }
SoilFileField >> size [
	^ size
]

{ #category : #accessing }
SoilFileField >> size: anInteger [ 
	size := anInteger
]

{ #category : #accessing }
SoilFileField >> start [
	^ start
]

{ #category : #accessing }
SoilFileField >> start: anInteger [ 
	start := anInteger
]
