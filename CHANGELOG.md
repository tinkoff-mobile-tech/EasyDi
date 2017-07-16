# Change Log
All notable changes to this project will be documented in this file.

#### 1.x Releases
- `1.2.x` Releases - [1.2.0](#120)
- `1.1.x` Releases - [1.1.0](#110) | [1.1.1](#111)
- `1.0.x` Releases - [1.0.0](#100)

---

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
