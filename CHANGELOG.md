# Change Log
All notable changes to this project will be documented in this file.

#### 1.x Releases
- `1.4.x` Releases - [1.4.0](#140)
- `1.3.x` Releases - [1.3.0](#130) | [1.3.1](#131) | [1.3.2](#132) | [1.3.3](#133)
- `1.2.x` Releases - [1.2.0](#120)
- `1.1.x` Releases - [1.1.0](#110) | [1.1.1](#111)
- `1.0.x` Releases - [1.0.0](#100)

---
## [1.4.0](https://github.com/AndreyZarembo/EasyDi/releases/tag/1.4.0)
Released on 2017-10-23

#### Updated
- !Breaking changes! Decided to replaced 'inout' closure variable type with return value. To fix issue with NSObject release. (Thanx to @alekseykolchanov for Pull Request)
- @alekseykolchanov advised to remove 'Definition Cache'
- Moved singletons and substitutions storages to the context

#### Fixed
- [Issue #14. Weird NSObject dealloc with Swift 4](https://github.com/AndreyZarembo/EasyDi/issues/14)


## [1.3.3](https://github.com/AndreyZarembo/EasyDi/releases/tag/1.3.3)
Released on 2017-07-24

#### Fixed
- Fixed singletons retain bug.(Thanx to @alekseykolchanov)


## [1.3.2](https://github.com/AndreyZarembo/EasyDi/releases/tag/1.3.2)
Released on 2017-07-24

#### Fixed
- Another fix for circular dependency resolution bug


## [1.3.1](https://github.com/AndreyZarembo/EasyDi/releases/tag/1.3.1)
Released on 2017-07-24

#### Fixed
- Circular dependency resolution bug

#### Added
- Substitution type check with fatalError


## [1.3.0](https://github.com/AndreyZarembo/EasyDi/releases/tag/1.3.0)
Released on 2017-07-18

#### Added
- macOS support
- Code documentation

#### Updated
- Little refactoring
- travis build script


## [1.2.0](https://github.com/AndreyZarembo/EasyDi/releases/tag/1.2.0)
Released on 2017-07-17

#### Added
- Injections into swift structures
- Carthage support

#### Updated
- Renamed `define(init: ...)` without return value to `defineInjection(into: )`

#### Fixed
- Fixed bug with queue lock in assembly context


## [1.1.1](https://github.com/AndreyZarembo/EasyDi/releases/tag/1.1.1)
Released on 2017-06-26

#### Fixed
- Fixed bug with definition retain.

## [1.1.0](https://github.com/AndreyZarembo/EasyDi/releases/tag/1.1.0)
Released on 2017-06-22.

#### Updated
- Renamed `Patch` to `Substitution`

#### Fixed
- Fixed bug with cross-assembly object resolution when two assemblies uses same keys

---

## [1.0.0](https://github.com/AndreyZarembo/EasyDi/releases/tag/1.0.0)
Released on 2017-06-13.

#### Added
- Initial release of EasyDi.
  - Added by [Andrey Zarembo](https://github.com/AndreyZarembo).
