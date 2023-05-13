Class {
	#name : #SoilNewBehaviorEntry,
	#superclass : #SoilJournalEntry,
	#instVars : [
		'identifier',
		'objectId'
	],
	#category : #'Soil-Core-Journal'
}

{ #category : #'accessing - defaults' }
SoilNewBehaviorEntry class >> journalTypeCode [ 
	^ 7
]

{ #category : #commiting }
SoilNewBehaviorEntry >> commitIn: aSoilTransaction [ 
	aSoilTransaction behaviorRegistry 
		nameAt: identifier  
		put: objectId 
]

{ #category : #accessing }
SoilNewBehaviorEntry >> identifier: aString [ 
	identifier := aString 
]

{ #category : #accessing }
SoilNewBehaviorEntry >> objectId: aSoilObjectId [ 
	objectId := aSoilObjectId 
]

{ #category : #printing }
SoilNewBehaviorEntry >> printOn: aStream [ 
	super printOn: aStream.
	aStream 
		<< ' objectId: '
		<< objectId asString
		<< ' name: ' 
		<< identifier asString
		
]
