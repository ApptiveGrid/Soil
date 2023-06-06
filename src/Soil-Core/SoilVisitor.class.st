Class {
	#name : #SoilVisitor,
	#superclass : #Object,
	#category : #'Soil-Core-Model'
}

{ #category : #visiting }
SoilVisitor >> visit: anObject [ 
	^ anObject acceptSoil: self 
	
]

{ #category : #visiting }
SoilVisitor >> visitAll: aCollection [ 
	^ aCollection collect: [ :each |
		self visit: each ]
]

{ #category : #'as yet unclassified' }
SoilVisitor >> visitMetaSegment: aSoilMetaSegment [ 
	^ aSoilMetaSegment 
]

{ #category : #visiting }
SoilVisitor >> visitObjectRepository: aSoilObjectRepository [ 
	self visitAll: aSoilObjectRepository allSegments.
	^ aSoilObjectRepository 
]

{ #category : #visiting }
SoilVisitor >> visitObjectSegment: aSoilObjectSegment [ 
	self visit: (aSoilObjectSegment at: 1).
	^ aSoilObjectSegment 
]

{ #category : #visiting }
SoilVisitor >> visitParameters: aSoilParameterFile [ 

]

{ #category : #visiting }
SoilVisitor >> visitPersistentClusterVersion: aSoilPersistentClusterVersion [ 
	^ aSoilPersistentClusterVersion 
]

{ #category : #visiting }
SoilVisitor >> visitSoil: aSoil [ 
	self visit: aSoil objectRepository.
	self visit: aSoil settings.
	^ aSoil
]
