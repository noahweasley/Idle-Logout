## 2.1.0

- Explicitly mark `isLoggedIn` and `isLockedOut` with an `AsyncOrBoolGetter` type signifying they can be synchronous or asynchronous. Also mark `onLockedOut` as `AsyncOrVoid` signifying it can be synchronous or asynchronous.
- Mark `isLockedOut` optional, defaulting to `false` (useful for applications that do not have a lock-screen state).

## 2.0.0

- Introduced `Params` wrapper to group configuration options into a single object
- Updated `IdleLogout` constructor to accept params instead of multiple named parameters
- Add optional `debug` to `Params` to enable debug mode
- Rename `pauseThreshold` to `backgroundTimeout`
- Rename `lockedOutAction` to `onLockedOut`

## 1.0.0+1

- Update documentation

## 1.0.0

- `isLockedOut()` and `isLoggedIn()` are now an asynchronous functions, you can still return a result synchronously if you prefer
- Update documentation
- Add missing `kDebugMode`
- Clear unused memory when timer is no longer needed
- Improve example

## 0.1.4

- Update documentation to provide more details on usage
- Reduce package size by removing unwanted files

## 0.1.3

- Fix analyzer issues and add supported platforms

## 0.1.2

- Add optional `pauseThreshold`; duration after which we consider the app paused for too long
- Improve Readme and example app
- Fix app timeout while user typing on keyboard - it is now treated as user interaction

## 0.1.1

- Add necessary `kDebugMode` where necessary
- Remove unnecessary main.dart file in library
- Fix grammatical error in example

## 0.1.0+2

- Minor updates to example and readme

## 0.1.0+1

- Initial release 🎉
- Added automatic idle timeout with logout callback.
- Supports Android, iOS, Web, macOS, Windows, and Linux.
