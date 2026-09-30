Extension { #name : #SoilObjectIdOutsideSegment }

{ #category : #'*Soil-Roassal' }
SoilObjectIdOutsideSegment >> nodeIn: aSoilGraphTracker [
	^ aSoilGraphTracker nodeAt: objectId ifAbsent: [ nil ]
]
