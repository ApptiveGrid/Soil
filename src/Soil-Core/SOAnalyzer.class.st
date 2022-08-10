Class {
	#name : #SOAnalyzer,
	#superclass : #FLAnalyzer,
	#instVars : [
		'transaction'
	],
	#category : #'Soil-Core'
}

{ #category : #'as yet unclassified' }
SOAnalyzer >> databaseMapper [ 
	^ SOMapper new
		transaction: transaction
]

{ #category : #protected }
SOAnalyzer >> mappers [

	^ OrderedCollection new
		add: self databaseMapper;
		addAll: self pluggableSubstitutionMappers;
		addAll: self globalMappers;
		add: self generalMapper;
		reduceRight: [:left :right | left next: right ];
		yourself
]

{ #category : #protected }
SOAnalyzer >> privateMappers [

	^ OrderedCollection new
		add: self databaseMapper;
		addAll: self globalMappers;
		add: self generalMapper;
		reduceRight: [:left :right | left next: right ];
		yourself
]

{ #category : #accessing }
SOAnalyzer >> transaction: aSOTransaction [ 
	transaction := aSOTransaction
]
