**YOLO-DL v0.6**

**New features:**

* Improved user interface logic and implemented a more responsive user interface.
* The UI now more clearly communicates a waiting state when the app is preparing or fetching metadata.
* The "Overwrite" function now moves the old file to Trash instead of directly overwriting it.

**YOLO-DL v0.51**

**Bug fixes:**
* Fixed missing recording source picker.

**YOLO-DL v0.5**

**UI changes:**
* Reworked the app mode picker into the window toolbar
* Moved the main UI elements to be visually more coherent. The app now follows a flow from up to down:
	* URL input
	* Options
	* Download / Record

**YOLO-DL v0.45**

**New features:**
* Log window toolbar now follows native styling and macOS Tahoe conventions.

**Other:**
* Various optimization fixes.

**YOLO-DL v0.44**

**New features:**

* A warning is now displayed before starting a recording with a duration of over 6 hours.
* Recording timer must now explicitly turned off before recording for an indefinite duration.
* A minutes input of over 61 now gets normalized to hours & minutes.

**Bug fixes:**

* Matched default window size to minimum.
* Fixed a race condition during metadata fetch

**YOLO-DL v0.43**

**New features:**

- Accessibility: Added VoiceOver labels to recording duration controls.
- Added quit confirmation dialog when download or recording is in progress.

**Bug fixes:**

- Added folder path truncating in the user interface
- User is now alerted if the location folder does not exist

**YOLO-DL v0.42**

**New features:**

- Improved accessibility: 
	- Alternate indicators when using Reduce Motion
	- Alternate indicators when using Differentiate Without Color
- Added symbols for app states

**YOLO-DL v0.41**

**Bug fixes:**

- Made metadata fetch cancellable.

**YOLO-DL v0.4**

Initial release