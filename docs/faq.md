# Frequently asked questions

## Release 

### Why are releases branches and not tags?

Tags in git are an easy way to have a non-cryptic reference to the tree of commits. This maps in general very nice to the idea of having a release that points to a certain version of the code. 
But the usage pattern of releases makes this a lot less nice. Some usage patterns for releases are: I want 

- the newest code 
- the latest release 
- the latest release including all hotfixes
- ...

This makes a solution less obvious. Well, the first one is easy because it is the HEAD of the default branch. 
For the others one way to do it is to use tags with semantics. In this you would tag the latest release with e.g. v1.1 and the release including hotfixes 1.x. In that scenario the next release would be tagged 1.2 and the 1.x tag would be moved to the commit of the 1.2 commit. 
But here releasing becomes cumbersome which shouldn't be. If you would apply that scheme to semantic versioning you would have 1.1.1, 1.1.x, 1.x etc. This is annoying to do and error prone, too.

We want to concentrate on providing a database that is fun to work with instead of putting all our energy in keeping up a process. In order to get the best out of all needs we provide the following levels:

- if you want the newest code load the HEAD of the main branch
- if you want to latest release including hotfixes (e.g. v1) then load the brannch v1 and you will get the newest hotfix v1 release everytime you load it
- if you want to pin soil to a specific version of the code then use the commit hash of that version. Commit hashes are undervalued but is the only references in git that you can trust. Tags can be moved but commit hashes not easily 

So if you are reading this because you ask yourself why there are no releases in the github releases section then the reason is because github only supports tags in the release section and we don't use them for releases.

### Why don't you use semantic versioning?

Versioning is sometimes considered hard but actually it isn't. The reason why it is hard is because people try to force a lot of requirements/assumptions onto version numbers. 

There seems to be a notion that semantic version is the way to go. We don't see it that way. If we look at semantic versioning we have MAJOR.MINOR.PATCH but none of these is clear to use and so we've never seen it working. PATCH is supposed to be a bug fix without side effects. MINOR should be a structural/behavioral change without breaking the API. And MAJOR you use when you have a new version of your API.
That sounds nice but 

- there is no change to a software without side effect so what is PATCH then meant to be 
- a MINOR change is keeping the API as it is. But the usefulness depends on the definiton what the API is and that is often lacking
- MAJOR finally is a level nobody is able to decide when it should be a MAJOR version or not because the difference between a MINOR and a MAJOR version is also blurry. MAJOR becomes a mimicking of maturity when you bump the number

As we don't want to waste a lot of time discussing the problems above we use a scheme v1, v2, v3,... So it is clear v3 is newer than v2 and that's it.
The changes and their impact needs to be put in documentation so you can do a risk assesment. People tend to want to read all of that from the version number.

So we just make the decision of low risk and high risk change where the risk is meant to be the odds of breaking some client software. And that is purely our assumption. With that assumption of ours we easily can decide if the commit goes only on the main trunk our also in one or many version branches. Yet again we think you might not like it but it covers desired effects without putting a lot burden on us which kills the fun

