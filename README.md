# Soil

[![CI matrix](https://github.com//ApptiveGrid/Soil/actions/workflows/build.yml/badge.svg)](https://github.com//ApptiveGrid/Soil/actions/workflows/build.yml)

Soil is an object oriented database in [pharo](http://pharo.org). It is transaction based having ACID transactions. It has binary search capabilities with SkipList and BTree+ indexes. It aims to be a simple yet powerful database making it easy to develop with, easy to debug with, easy to inspect, ... 


To read more please have a look at the [documentation](./docs/soil.md)


## Loading

Load it in 64bit Pharo 11/12/13 with Metacello:

```smalltalk
Metacello new 
	repository: 'github://ApptiveGrid/Soil:main/src';
	baseline: 'Soil';
	load.
```
Note: For now, Windows is not supported. Contact us if you want to help!

**caution** Soil is in an early stage meaning there are might be things missing. It is battle tested as it is the driving database behind [ApptiveGrid](http://www.apptivegrid.de) but you might have different requirements. If so, tell us!

## Latest release

The latest release is [v2](https://github.com/ApptiveGrid/Soil/tree/v2) which you can load via

```smalltalk
Metacello new 
	repository: 'github://ApptiveGrid/Soil:v2/src';
	baseline: 'Soil';
	load.
```

The changelog can be found [here](https://github.com/ApptiveGrid/Soil/blob/v2/docs/changelog.md)

*note*: Releases in Soil are branches. Loading it with a release tag will get the hot fixes of that release. If you do not want this please use the commit hash as version instead

### Development

We use github for organizing our development. You can see what we are doing right now on the [project board](https://github.com/orgs/ApptiveGrid/projects/2). An up-to-date list of milestones you can find in [milestones](https://github.com/ApptiveGrid/Soil/milestones?direction=desc&sort=completeness&state=open). 

**NEWS** 
- The Soil Database has now an entry in [HAL](https://hal.science/hal-04726251) and is archived by [https://www.softwareheritage.org](https://www.softwareheritage.org) 2024-11-22
- [ANN] Release V2 of Soil, the object oriented database for Pharo implemented in Pharo [Mail](https://lists.pharo.org/empathy/thread/OE434T74GYE74GUNP3GLKYAZGGBXUSWT) 2024-08-28
- [ANN] Soil release v1 [Mail](https://lists.pharo.org/empathy/thread/6VYPN7R6TQPWDKQTRXUV7S6UU5AEMPV7) 2024-04-24
- ESUG2023 talk "Soil:a fresh look on object oriented databases"
	- [Slides PDF](http://archive.esug.org/ESUG2023/day3/02_1%20-%20Soil,%20a%20Fresh%20Look%20on%20Object%20Oriented%20Databases.pdf), [Slides SlideShare](https://www.slideshare.net/slideshow/soil-a-fresh-look-on-object-oriented-databases/260898335)
 	- Video on [Youtube](https://www.youtube.com/watch?v=ui4TXcv7tus)
- ESUG 2023 talk "Soil and Pharo"
  	- [Slides PDF](http://archive.esug.org/ESUG2023/day3/02_2%20-%20Soil%20and%20Pharo.pdf)
	- [Slides SlideShare](https://www.slideshare.net/esug/soil-and-pharo-260898369)
- Soil got the second prize in the [2023 ESUG Innovation Technology Awards](https://esug.github.io/2023-Conference/awardsSubmissions.html) !
- 06/2023: [ApptiveGrid](https://www.apptivegrid.de) starts using Soil
- Development of Soil announced at ESUG 2022
	- Talk "here's no magic... until you talk about databases"  [Slides PDF](http://archive.esug.org/ESUG2022/02Tuesday/08-hartl-deployment.pdf), [Slides SlideShare](https://www.slideshare.net/slideshow/theres-no-magic-until-you-talk-about-databases/253132135)

![esug medal](https://esug.github.io/2022-Conference/esugAwards2ndSilverRoundMedal.png)
