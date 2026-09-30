Extension { #name : #SoilIndexFinding }

{ #category : #'*Soil-Roassal' }
SoilIndexFinding >> nodeIn: aSoilGraphTracker [
	"the cluster that holds the index"
	^ aSoilGraphTracker ownerOfIndex: indexId segment: segment
]
