# Store and retrieve a model with transactions

Soil is a transaction based database. This means that for reading or writing to the database you need to create a transaction. This can be done like this

```
txn := soil newTransaction.
```

## database root

A model is attached to soil by attaching it as *database root*. This is the object the database holds onto and this object holds onto other objects etc. This builds the connected graph of your model.

Attaching a model to the root of the database can be done this way

```
txn := soil newTransaction.
txn root: myModelRoot.
```

## commiting a transaction 

A transaction is used when writing to a database. But all changes made to a transaction are volatile until the transaction is committed. The commit collects all objects to be written and updates the files on the filesystem so the data is persistent.

In order to have the code from above be written to disk the full code snippet needs to look like this

```
txn := soil newTransaction.
txn root: myModelRoot.
txn commit
```
A committed transaction cannot be used for further actions. So the usual case is to create a transaction for every change we make to the database

## aborting a transaction

There are conditions when we do not want to write the changes to disk. This e.g. when an error occurs we rather terminate the current process and do not change the database with only part of the whole change. A simple

```
txn abort
```

does this. It aborts the transactions which means it removes all objects from its internal structure and marks the transaction invalid so it cannot be used further.

*note* Aborting a transaction does not roll back the changes made to objects in memory. This is the duty of the application controlling the life cycle of that objects.

## commitAndContinue

Sometimes you want to have the changes written to database but don't want to loose the association between in-memory objects and their disk representation. For this a 

```
txn commitAndContinue
```

will write the changes to disk but leaves a fully operable transaction that can be used again to do changes and then commit again.

**caution** When commitAndContinue is used the objects written to the database will stay in the state they were when the transaction was created. This means e.g. that if you create objects with another transaction (one that is newer than your transaction) you won't be able to see those objects. Same goes to all changes that are made to other objects 

## markDirty - write changes back to disk

Soil has no support yet for detecting which objects have been in-memory. This might be a future addtition but for now if you change an object in-memory you have to tell soil that this object has changed. This can be done like this

```
txn markDirty: myObject
```
This marks *myObject* as dirty object in the transaction. When the transaction is committed this object will be written to disk and changes persist.

So if we change the *myModelRoot* from above this needs to be done like this

```
txn := soil newTransaction.
txn root myMethod: newValue.
txn markDirty: txn root.
txn commit.
```

## partitioning the model

Soil can store an arbitrary object as database root (except full closures). This includes all object references that database root has. Everything that is connected from the database root or from a connected object will be written to disk. In other words the whole graph that is connected from the database root. 

While this is a good feature it might be less good if the graph becomes huge. That would mean that on each transaction read the whole graph will be read and on all writes the whole graph would be written. This is often not wanted.

Soil offers the possibilty to partition your model. Partitioning means that some references are cut and replaced with a surrogate reference. On accessing of the model this will load the graph until one of these surrogate references is detected and will return a proxy for the second graph instead. This way it is doable to make lots of of tiny graphs that are while being connected they will be loaded individually which results into just a few graphs being loaded. This way access for reading and writing is much faster.

To partition a model you just need to call 

```
txn makeRoot: anObject.
```

This way *anObject* becomes a database root with an address that can be loaded individually. It also means that every reference to *anObject* in the object graph when being written will write a reference with its address instead of the connected graph. 

On reading this reference will become a proxy object in-memory that when being accessed fetches the object from disk and returns it. 