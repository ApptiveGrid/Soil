Extension { #name : #String }

{ #category : #'*Soil-Core' }
String >> asSkipListKeyOfSize: anInteger [
	^ self asByteArray asSkipListKeyOfSize: anInteger
]
