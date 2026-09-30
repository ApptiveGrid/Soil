Extension { #name : #SoilUnknownBehaviorDescription }

{ #category : #'*Soil-Roassal' }
SoilUnknownBehaviorDescription >> nodeIn: aSoilGraphTracker [
	^ aSoilGraphTracker nodeAt: descriptionId ifAbsent: [ nil ]
]
