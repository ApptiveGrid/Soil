Extension { #name : #String }

{ #category : #'*Soil-Core' }
String >> asIndexKeyOfSize: anInteger [ 
	^ self asByteArray asIndexKeyOfSize: anInteger 
]
