Extension { #name : #ByteString }

{ #category : #'*Soil-Core' }
ByteString >> asSoilObjectId [
	| colonIndex |
	colonIndex := self indexOf: $:.
	^ SoilObjectId 
		segment: (self copyFrom: 1 to: colonIndex - 1) asNumber
		index: (self copyFrom: colonIndex + 1 to: self size) asNumber
]
