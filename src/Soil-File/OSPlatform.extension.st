Extension { #name : #OSPlatform }

{ #category : #'*Soil-File' }
OSPlatform >> flockClass [
	Error signal: 'no support for file locking on this platform'
]
