Extension { #name : #ProcessorScheduler }

{ #category : #'*Soil-Core' }
ProcessorScheduler >> soilBasicSerialize: serializer [
	self class == ProcessorScheduler ifFalse: [ ^ super soilBasicSerialize: serializer ].
	serializer nextPutProcessorScheduler: self
]

{ #category : #'*Soil-Core' }
ProcessorScheduler >> soilSerialize: serializer [
	"registration not needed, as we always return the current Process value on read"
	self soilBasicSerialize: serializer
]
