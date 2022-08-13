Class {
	#name : #SOObjectSegment,
	#superclass : #Object,
	#instVars : [
		'id',
		'soil'
	],
	#category : #'Soil-Core'
}

{ #category : #accessing }
SOObjectSegment >> id [

	^ id
]

{ #category : #accessing }
SOObjectSegment >> id: anObject [

	id := anObject
]

{ #category : #initialization }
SOObjectSegment >> initializeDatabase [
	self path ensureCreateDirectory.
	SOObjectIndexFile new
		segment: self;
		fileVersion: 1;
		fuelVersion: 1;
		initializeDatabase 
]

{ #category : #accessing }
SOObjectSegment >> path [
	^ soil path / #segments / self id asString
]

{ #category : #accessing }
SOObjectSegment >> soil: aSoil [ 
	soil := aSoil
]
