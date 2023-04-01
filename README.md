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

Soil is still in very early ramp up stage but we are working towards a milestone that can be used for very simple stuff. The up-to-date list of milestones you can find in [milestones](https://github.com/ApptiveGrid/Soil/milestones?direction=desc&sort=completeness&state=open).

**caution** Soil is a moving target and milestones are a way for us to focus. Nothing of this is considered stable, formats and structure will change. Do not expect to be able to load back data from an older version. If you need something reliable wait for a release

If you want to watch more closely what we are at have a look at the [project board](https://github.com/orgs/ApptiveGrid/projects/2)
