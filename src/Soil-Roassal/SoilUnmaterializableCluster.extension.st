Extension { #name : #SoilUnmaterializableCluster }

{ #category : #'*Soil-Roassal' }
SoilUnmaterializableCluster >> nodeIn: aSoilGraphTracker [
	^ aSoilGraphTracker nodeAt: objectId ifAbsent: [ nil ]
]
