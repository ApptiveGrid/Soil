# Soil

[![CI matrix](https://github.com//ApptiveGrid/Soil/actions/workflows/build.yml/badge.svg)](https://github.com//ApptiveGrid/Soil/actions/workflows/build.yml)

Soil is an object oriented database in [pharo](http://pharo.org). It is transaction based having ACID transactions. It has binary search capabilities with SkipList and BTree+ indexes. It aims to be a simple yet powerful database making it easy to develop with, easy to debug with, easy to inspect, ... 


To read more please have a look at the [documentation](./docs/soil.md)


## Loading

Load it in 64bit Pharo 11/12 with Metacello:

```smalltalk
Metacello new 
	repository: 'github://ApptiveGrid/Soil:main/src';
	baseline: 'Soil';
	load.
```
Note: For now, Windows is not supported. Contact us if you want to help!

**caution** Soil is in an early stage meaning there are might be things missing. It is battle tested as it is the driving database behind [ApptiveGrid](http://www.apptivegrid.de) but you might have different requirements. If so, tell us!

## Current release

We are working towards release 1 which should appear soon. When ready you will find them here: [releases](https://github.com/ApptiveGrid/Soil/releases)

### Development

We use github for organizing our development. You can see what we are doing right now on the [project board](https://github.com/orgs/ApptiveGrid/projects/2). An up-to-date list of milestones you can find in [milestones](https://github.com/ApptiveGrid/Soil/milestones?direction=desc&sort=completeness&state=open). 

**NEWS** 
- Slides from the ESUG2023 talk: [Download PDF](http://www.esug.org/data/ESUG2023/day3/02_1%20-%20Soil,%20a%20Fresh%20Look%20on%20Object%20Oriented%20Databases.pdf)
- Soil got the second prize in the [2023 ESUG Innovation Technology Awards](https://esug.github.io/2023-Conference/awardsSubmissions.html) !

![esug medal](https://esug.github.io/2022-Conference/esugAwards2ndSilverRoundMedal.png)
