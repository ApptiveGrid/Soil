Class {
	#name : #SOSerializer,
	#superclass : #FLSerializer,
	#category : #'Soil-Core'
}

{ #category : #protected }
SOSerializer >> defaultAnalyzer [ 
	^ SOAnalyzer new 
]
