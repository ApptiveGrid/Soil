Extension { #name : #OSPlatform }

{ #category : #'*Soil-Core' }
OSPlatform >> flockClass [
	Error signal: 'no support for file locking on this platform'
]
