# GTImageFetchable

![Platform iOS](https://img.shields.io/badge/Platform-iOS-informational)
![Language](https://img.shields.io/badge/Language-Swift-orange)
![License](https://img.shields.io/badge/License-MIT-brightgreen)
![Version](https://img.shields.io/badge/Version-1.0.0-blue)

#### Fetch, cache and handle remote and local images fast and reliably in iOS apps.

## What is GTImageFetchable?

GTImageFetchable is a **Swift protocol** that allows to **fetch and cache remote images**, as well as to *work with local images only* effortlessly and at no hassle at all.

GTImageFetchable is a plug-and-play protocol, as all provided features and functionalities have been already implemented as an extension of it. Just adopt it, and start using it right away!

## Available public API

The following methods are becoming available to any class or view controller that adopts GTImageFetchable protocol:

```swift
fetchImage(from:customFilename:useLocalCache:useCachesDirectory:completion:)
// Fetch an image from a remote URL, or load it from a local file.

fetchMultipleImages(from:useLocalCache:partialFetchHandler:completion:)
// Fetch multiple images by either downloading them from remote URLs,
// or loading them from local files if they have already been fetched and saved.
 
save(image:withFilename:saveAsJPEG:quality:inCachesDirectory:)
// Save the provided image using the specified file name either
// in Documents or Caches directory, choosing to save as a JPEG
// or a PNG image.

deleteCachedImage(using:customFilename:fromCachesDirectory:)
// Delete a cached image either using its remote URL or a custom file name.

deleteCachedImages(using:fromCachesDirectory:)
// Delete multiple images using their remote URLs.

imageFileURL(imageURL:customFilename:inCachesDirectory:)
// Get the URL to a local image file.
 
documentsDirectoryURL()
// The URL to the Documents directory of the app.

cachesDirectoryURL()
// The URL to the Caches directory of the app.
```

Each method is well documented. Use Xcode's Quick Help to get details and information about each method.

## Integrating GTImageFetchable

To integrate `GTImageFetchable` into your projects follow the next steps:

1. Copy the repository's URL to GitHub (it can be found by clicking on the *Clone or Download* button).
2. Open your project in Xcode.
3. Go to menu **File > Swift Packages > Add Package Dependency...**.
4. Paste the URL, select the package when it appears and click Next.
5. In the *Rules* leave the default option selected (*Up to Next Major*) and click Next.
6. Select the *GTImageFetchable* package and select the *Target* to add to; click Finish.
7. In Xcode, select your project in the Project navigator and go to *General* tab.
8. Add GTImageFetchable framework under *Frameworks, Libraries, and Embedded Content* section.

Don't forget to import it anywhere you need to use it:

```swift
import GTImageFetchable
```

Finally, adopt it:

```swift
class ViewController: UIViewController, GTImageFetchable {
    ...
}
```

## Remarks

Most of the provided methods work asynchronously in the background. Use the main thread dispatch queue to update your UI when getting results through the completion handlers.

## License

GTImageFetchable is licensed under the MIT license.
