# Soil

[![CI matrix](https://github.com//ApptiveGrid/Soil/actions/workflows/build.yml/badge.svg)](https://github.com//ApptiveGrid/Soil/actions/workflows/build.yml)

Soil is a playground for exploring and learning OO database technology. It aims to be a fully transaction based database with plenty of indexing support. To read more please have a look at the [documentation](./docs/soil.md)

## Loading

First, load it in Pharo 10 or 11 with Metacello:

```smalltalk
Metacello new 
	repository: 'github://ApptiveGrid/Soil:development/src';
	baseline: 'Soil';
	load.
```


Here is the plan that grows faster than we can finish things:

- [ ] combining skiplist, object factory and serialization
- [ ] approach for manage class shape changes 
- [ ] a skiplist implementation for a first indexing structure
- [ ] storing classes/object factories in an index structure so they can be looked up by name
- [ ] management of classes/object factories. We want not only classes to be able to create instances
- [x] transparent proxies for inter-cluster connections (makes the whole graph traversable)
- [x] Adressing a cluster per objectId
- [x] Serialization of a cluster
- [x] Basic support for splitting an arbitrary object graph into clusters
