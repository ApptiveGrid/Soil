# Soil 

1. [initial plan](initial-plan.md)

2. Basic Usage

A simple example for the most basic usage. We have the data that we want to store pointed to by the "yourModelRoot":

```
db := Soil path: ‚mydb‘.
db initializeFilesystem.
txn := db newTransaction.
txn root: yourModelRoot.
txn commit.
```

it will save the whole object graph pointed to by youModelRoot the database. Every time you do 

```
txn := db newTransaction.
txn root
```

it will read all of the model you have just write now but concurrent safe.

Optimizing this is partitioning your graph and saying which of your objects are standalaone by saying

```
txn makeRoot: anObject.
```

then only the needed parts of your model are loaded. But in order to save it you have to mark the objects you made root dirty by saying

```
txn markDirty: anObject
```
That‘s all for basic usage. 
