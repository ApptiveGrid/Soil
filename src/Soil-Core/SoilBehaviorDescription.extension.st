Extension { #name : #SoilBehaviorDescription }

{ #category : #'*Soil-Core' }
SoilBehaviorDescription class >> metaId [
	"the id of the class is alway 2 and pre-initialized to break recursion"
	^ SoilObjectId segment: 0 index: 2
]
