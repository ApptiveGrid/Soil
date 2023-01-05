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

Soil is still in very early ramp up stage but we are working towards a milestone that can be used for very simple stuff. The up-to-date list of milestones you can find in [milestones](https://github.com/ApptiveGrid/Soil/milestones)

A list of past milestones: 

- [ ] M2 manage behavior versions so that we can change classes between writing and reading the graph 
- [ ] M1 basic support for splitting and storing an arbitrary object graph (not all object classes but including clean blocks)

If you want to watch more closely what we are at have a look at the [project board](https://github.com/orgs/ApptiveGrid/projects/2)
