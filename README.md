# Soil

[![CI matrix](https://github.com//ApptiveGrid/Soil/actions/workflows/build.yml/badge.svg)](https://github.com//ApptiveGrid/Soil/actions/workflows/build.yml)

Soil is a playground for exploring and learning OO database technology. It aims to be a fully transaction based database with plenty of indexing support. To read more please have a look at the [documentation](./docs/soil.md)

## Loading

Load it in 64bit Pharo 10/11/12 with Metacello:

```smalltalk
Metacello new 
	repository: 'github://ApptiveGrid/Soil:main/src';
	baseline: 'Soil';
	load.
```
Note: For now, Windows is not supported. Contact us if you want to help!

Soil is still in very early ramp up stage but we are working towards a milestone that can be used for very simple stuff. The up-to-date list of milestones you can find in [milestones](https://github.com/ApptiveGrid/Soil/milestones?direction=desc&sort=completeness&state=open).

**caution** Soil is a moving target and milestones are a way for us to focus. Nothing of this is considered stable, formats and structure will change. Do not expect to be able to load back data from an older version. If you need something reliable wait for a release

If you want to watch more closely what we are at have a look at the [project board](https://github.com/orgs/ApptiveGrid/projects/2)

**NEWS** 
- Slides from the ESUG2023 talk: [Dowdload PDF](http://www.esug.org/data/ESUG2023/day3/02_1%20-%20Soil,%20a%20Fresh%20Look%20on%20Object%20Oriented%20Databases.pdf)
- Soil got the second prize in the [2023 ESUG Innovation Technology Awards](https://esug.github.io/2023-Conference/awardsSubmissions.html) !

![esug medal](https://esug.github.io/2022-Conference/esugAwards2ndSilverRoundMedal.png)
