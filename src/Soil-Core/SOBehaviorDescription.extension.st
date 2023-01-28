Extension { #name : #SOBehaviorDescription }

{ #category : #'*Soil-Core' }
SOBehaviorDescription class >> metaId [
	"the id of the class is alway 2 and pre-initialized to break recursion"
	^ SOObjectId segment: 0 index: 2
]
