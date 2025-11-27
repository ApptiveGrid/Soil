Extension { #name : #SoilSkipListPage }

{ #category : #'*Soil-Core-Tests' }
SoilSkipListPage >> level: anInteger [ 
	right := Array new: anInteger withAll: 0.
	left := Array new: anInteger withAll: 0
]

{ #category : #'*Soil-Core-Tests' }
SoilSkipListPage >> setLeft: aCollection [ 
	left := aCollection 
]

{ #category : #'*Soil-Core-Tests' }
SoilSkipListPage >> setRight: aCollection [ 
	right := aCollection 
]
