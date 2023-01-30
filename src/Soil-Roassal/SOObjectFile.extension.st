Extension { #name : #SOObjectFile }

{ #category : #'*Soil-Roassal' }
SOObjectFile >> allRecords [
	| records start record |
	stream position: self headerSize.
	records := OrderedCollection new.
	[ stream atEnd ] whileFalse: [
		start := stream position.
		record := SOClusterRecord readFrom: stream.
		records add: ({ start . stream position}  -> record )].
	^ records
]
