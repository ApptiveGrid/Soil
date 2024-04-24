# 2. Getting started

## Loading

Load it in 64bit Pharo 11/12 with Metacello:

```smalltalk
Metacello new 
	repository: 'github://ApptiveGrid/Soil:main/src';
	baseline: 'Soil';
	load.
```
Note: For now, Windows is not supported. Contact us if you want to help!

## Storing and retrieving of an object

After soil is loaded you can create a database and store your object in it using: 

```
soil := Soil createOnPath: 'mydb'.
txn := soil newTransaction.
txn root: yourModelRoot.
txn commit.
```

In order to read the object back you only need to do the following:

```
soil := Soil openOnPath: 'mydb'.
txn := soil newTransaction.
yourModelRoot := txn root.
...
```

