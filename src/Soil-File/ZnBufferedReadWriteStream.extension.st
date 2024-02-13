Extension { #name : #ZnBufferedReadWriteStream }

{ #category : #'*Soil-File' }
ZnBufferedReadWriteStream >> fileStream [
	^ writeStream fileStream
]
