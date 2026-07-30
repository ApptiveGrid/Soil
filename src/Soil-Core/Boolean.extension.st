Extension { #name : #Boolean }

{ #category : #'*Soil-Core' }
Boolean >> soilRecursiveHashWith: aSet [
	^ self basicIdentityHash * 16r85EBCA6B67C4BA9D
]
