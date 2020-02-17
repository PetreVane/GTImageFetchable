//
//  GTImageFetchable.swift
//
//  Created by Gabriel Theodoropoulos
//  Copyright © 2020 Gabriel Theodoropoulos. All rights reserved.
//

import UIKit


/**
 Fetch, cache and handle remote and local images fast and reliably.
 
 Available methods:
 
 ```
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
 
 See the documentation of each method for more information and details.
 
 */
public protocol GTImageFetchable {
    func fetchImage(from imageURL: String?, customFilename: String?, useLocalCache: Bool, useCachesDirectory: Bool, completion: @escaping (_ image: UIImage?) -> Void)
    func fetchMultipleImages(from imageURLs: [String?], useLocalCache: Bool, partialFetchHandler: @escaping (_ image: UIImage?, _ index: Int) -> Void, completion: @escaping () -> Void)
    func save(image: UIImage, withFilename imageName: String, saveAsJPEG: Bool, quality: CGFloat, inCachesDirectory: Bool) -> Bool
    func deleteCachedImage(using imageURL: String?, customFilename: String?, fromCachesDirectory: Bool) -> Bool
    func deleteCachedImages(using imageURLs: [String?], fromCachesDirectory: Bool)
    func imageFileURL(imageURL: String?, customFilename: String?, inCachesDirectory: Bool) -> URL?
    func documentsDirectoryURL() -> URL
    func cachesDirectoryURL() -> URL
}


// MARK: - GTImageFetchable Extension

extension GTImageFetchable {
    /**
     Fetch an image from a remote URL, or load it from a local file.
     
     To fetch an image you must provide either its remote URL, or a custom file name.
     If the image is downloaded from the Internet and `useLocalCache` is true, then
     the image is stored locally either in the Caches or the Documents directory of
     the app, depending on the `useCachesDirectory` parameter value.
     
     When fetching an image, first it's attempted to be found locally. If it exists,
     then it's loaded and returned back through the completion handler. If it doesn't
     exist and given that the `imageURL` has been provided, it's fetched from the
     remote URL.
     
     All tasks take place asynchronously in the background.
     
     - Note: Don't provide a custom file name when fetching the image from a remote URL.
     URL will be used to create the image's file name for both saving to and loading from
     a local file.
     
     - Parameter imageURL: The URL string that the image should be fetched from.
     - Parameter customFilename: A custom file name to use when loading from a local file.
     Use it when you've saved an image using the `save(image:withFilename:saveAsJPEG:quality:inCachesDirectory:)`
     method. Default value is `nil`.
     - Parameter useLocalCache: When true, the image is stored locally after it's been
     fetched from the remote URL.
     - Parameter useCachesDirectory: When true, the fetched image is stored in the Caches
     directory of the app, otherwise it's stored in the Documents directory. Respectively,
     that's the lookup folder when it's attempted to load the image from a locally stored file.
     Default value is `true`, meaning the Caches directory.
     - Parameter completion: The completion handler that gets called after fetching the image
     is finished.
     - Parameter image: The fetched image either loaded from a local file or downloaded
     from the Internet, or `nil` if it cannot be fetched.
     
     */
    public func fetchImage(from imageURL: String?, customFilename: String? = nil,
                           useLocalCache: Bool = true, useCachesDirectory: Bool = true,
                           completion: @escaping (_ image: UIImage?) -> Void) {
    
        // Fetch the image asynchronously on the background.
        DispatchQueue.global(qos: .userInteractive).async {
            // If "useLocalCache" is true and the image file exists locally,
            // then "fetchFromInternet" flag will become "false" in the following steps.
            // If "useLocalCache" is false or the image file doesn't exist locally,
            // then this flag remains "true" and the image will be fetched from
            // the Internet.
            var fetchFromInternet = true
            
            // Check if the image should be searched locally first, and
            // then get the URL to local file and check if it exists.
            if useLocalCache,
                let localFileURL = self.imageFileURL(imageURL: imageURL, customFilename: customFilename, inCachesDirectory: useCachesDirectory),
                FileManager.default.fileExists(atPath: localFileURL.path) {
                
                // The image file exists locally, so just load it.
                let loadedImage = self.loadLocalImage(from: localFileURL)
                
                // Pass the loaded image to the completion handler as argument.
                completion(loadedImage)
                
                // Change this flag to false so the image won't be downloaded.
                fetchFromInternet = false
            }
            
            // Check the value of the "fetchFromInternet" flag.
            // If it's true, then the image should be downloaded from Internet.
            // Create the URL object based on the given imageURL value.
            if fetchFromInternet {
                if let urlString = imageURL, let url = URL(string: urlString) {
                    self.downloadImage(from: url) { (imageData) in
                        // Check if should store the image locally, and do so if necessary.
                        if useLocalCache, let localFileURL = self.imageFileURL(imageURL: imageURL, customFilename: customFilename, inCachesDirectory: useCachesDirectory) {
                            do {
                                try imageData?.write(to: localFileURL)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                        
                        // Create a UIImage object from the fetched data
                        // and pass it as an argument to the completion handler.
                        guard let data = imageData else { completion(nil); return }
                        let image = UIImage(data: data)
                        completion(image)
                    }
                } else {
                    completion(nil)
                }
            }
        }
        
    }
        
    
    /**
     Fetch multiple images by either downloading them from remote URLs, or loading them
     from local files if they have already been fetched and saved.
     
     - Parameter imageURLs: An array with the remote URLs as String values.
     - Parameter useLocalCache: When true, fetched images are stored locally. Note
     that the Caches directory is the target directory by default.
     - Parameter partialFetchHandler: A closure that gets called everytime an image has been
     fetched. The first argument is the fetched image and the second is the index of the image.
     - Parameter image: The fetched image.
     - Parameter index: The index of the fetched image.
     - Parameter completion: The completion handler that gets called right after all images have
     been fetched.
     */
    public func fetchMultipleImages(from imageURLs: [String?], useLocalCache: Bool = true,
                                    partialFetchHandler: @escaping (_ image: UIImage?, _ index: Int) -> Void,
                                    completion: @escaping () -> Void) {
        
        // Create a dispatch queue to use for getting prepared and fetching the images.
        let queue = DispatchQueue(label: "fetchMultipleImages_\(Date.timeIntervalSinceReferenceDate)", qos: .userInteractive)
        
        // Execute it asynchronously.
        queue.async {
            // Image fetching will take place concurrently, and this can be
            // a problem if too many image URLs are provided and the threads given
            // by the system to the app are not enough.
            // For that reason break the original imageURLs array to several
            // smaller arrays, where each one will keep up to 12 image URLs.
            // The concurrent operations will be limited to that number and
            // they will be repeated as many times as necessary until all images
            // are fetched.
            let splitImageURLs = self.breakArray(imageURLs, inSubArraysOf: 12)
            
            // Start fetching images in groups using recursion.
            self.performMultipleImageFetching(from: splitImageURLs, iteration: 0, useLocalCache: useLocalCache, notifyQueue: queue, partialFetchHandler: { (image, index) in
                partialFetchHandler(image, index)
            }) {
                completion()
            }
        }
    }
    
    
    
    /**
     Save the provided image using the specified file name either in Documents
     or Caches directory, choosing to save as a JPEG or a PNG image.
     
     - Parameter image: The image to save.
     - Parameter imageName: The image file name.
     - Parameter saveAsJPEG: True to save the image as JPEG, false to save as PNG.
     Default value is `true`.
     - Parameter quality: The compression quality when saving as JPEG. It's disregarded
     when `saveAsJPEG` is `false`. Default value is 0.9.
     - Parameter inCachesDirectory: Set `true` to save the image in the Caches directory of the app,
     `false` to save in Documents directory.
     
     - Returns: A Boolean value, `true` when saving the image succeeds, `false` otherwise.
     */
    public func save(image: UIImage, withFilename imageName: String,
                     saveAsJPEG: Bool = true, quality: CGFloat = 0.9,
                     inCachesDirectory: Bool) -> Bool {
        guard let imageData = saveAsJPEG ? image.jpegData(compressionQuality: quality) : image.pngData(),
            let localFileURL = imageFileURL(imageURL: nil, customFilename: imageName, inCachesDirectory: inCachesDirectory)
            else { return false }
        
        do {
            try imageData.write(to: localFileURL)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    
    /**
     Delete a cached image either using its remote URL or a custom file name.
     
     Provide only the `imageURL` or the `customFilename` parameter value.
     If you provide both, `imageURL` will be used.
     
     - Parameter imageURL: The *remote* URL of the image.
     - Parameter customFilename: A custom file name that was given to the image file.
     - Parameter fromCachesDirectory: Pass `true` when the image is saved in the Caches
     directory, `false` when it's in the Documents directory.
     
     - Returns: A Boolean value indicating the result of the deletion.
     */
    public func deleteCachedImage(using imageURL: String?, customFilename: String? = nil, fromCachesDirectory: Bool = true) -> Bool {
        guard let url = imageFileURL(imageURL: imageURL, customFilename: customFilename, inCachesDirectory: fromCachesDirectory) else { return false }
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    
    /**
     Delete multiple images using their remote URLs.
     
     Images are being deleted asynchronously on the bacgkround.
     
     - Parameter imageURLs: The *remote* URLs of the images to delete as String values.
     - Parameter fromCachesDirectory: Pass `true` when images reside in the Caches
     directory, `false` when they exist the Documents directory.
     */
    public func deleteCachedImages(using imageURLs: [String?], fromCachesDirectory: Bool = true) {
        DispatchQueue.global().async {
            imageURLs.forEach { _ = self.deleteCachedImage(using: $0, customFilename: nil, fromCachesDirectory: fromCachesDirectory) }
        }
    }
    
    
    /**
     Get the URL to a local image file.
     
     If the remote URL of the image is provided, its base64 representation
     is used as the file name (shortened if it's too long). Otherwise the custom file
     name is used instead.
     
     - Note: Provide only the `imageURL` or the `customFilename` parameter value. If you
     provide both, `imageURL` will be used.
     
     - Parameter imageURL: The URL of the image as a String value.
     - Parameter customFilename: A custom name to use for the image file name.
     - Parameter inCachesDirectory: `true` if the URL should point to the Caches
     directory of the app, `false` to point to the Documents directory.
     
     - Returns: Either the URL to the local file, or `nil` if the URL cannot be formed.
     */
    public func imageFileURL(imageURL: String?, customFilename: String?, inCachesDirectory: Bool) -> URL? {
        let dirURL = inCachesDirectory ? cachesDirectoryURL() : documentsDirectoryURL()
        
        if let urlString = imageURL {
            // Use the URL string as the image's file name.
            if var imageName = urlString.data(using: .utf8)?.base64EncodedString() {
                if imageName.count > 100 {
                    imageName = String(imageName.dropLast(imageName.count - 100))
                }
                return dirURL.appendingPathComponent(imageName)
            }
        } else if let customFilename = customFilename {
            // Use the tag as the image's local file name.
            return dirURL.appendingPathComponent(customFilename)
        }
        
        return nil
    }
    
    
    /**
     The URL to the Documents directory of the app.
     */
    public func documentsDirectoryURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
        
    
    /**
     The URL to the Caches directory of the app.
     */
    public func cachesDirectoryURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    
    
    // MARK: - Private Helper Methods
    
    /**
     It loads the image from the given local URL.
     
     - Parameter url: The URL of the path to the local image file.
     - Returns: Either an image object, or `nil` if the image cannot be loaded.
     */
    private func loadLocalImage(from url: URL) -> UIImage? {
        do {
            let imageData = try Data(contentsOf: url)
            let image = UIImage(data: imageData)
            return image
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    
    
    /**
     Download an image from the given URL.
     
     - Parameter url: The URL to download the image from.
     - Parameter completion: The completion handler to call upon finishing
     fetching the image.
     - Parameter imageData: The fetched image data as a Data object, or `nil`
     if an error occurred and no image was fetched.
     */
    private func downloadImage(from url: URL, completion: @escaping (_ imageData: Data?) -> Void) {
        // Create a URL session data task to fetch the image data.
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfiguration)
        let task = session.dataTask(with: url) { (data, response, error) in
            // Check if there's data fetched.
            guard let data = data else { completion(nil); return }
            completion(data)
        }
        task.resume()
    }
        
    
    
    /**
     It fetches multiple images.
     
     This method is executed recursively until all images for the given URLs
     have been fetched. The actual image fetching takes place in the
     `fetchImage(from:customFilename:useLocalCache:useCachesDirectory:completion:)`
     method.
     
     - Parameter imageURLs: A two-dimensional array that contains collections of
     image URLs as String values.
     - Parameter iteration: The index of the URLs collection to use in the `imageURls` array.
     - Parameter useLocalCache: It indicates whether a downloaded image should be
     stored locally or not.
     - Parameter notifyQueue: The queue in which all the work will take place.
     - Parameter partialFetchHandler:  A closure that gets called everytime an image has been
     fetched. The first argument is the fetched image and the second is the index of the image.
     - Parameter image: The fetched image.
     - Parameter index: The index of the fetched image.
     - Parameter completion: The completion handler that gets called when all images have
     been fetched.
     */
    private func performMultipleImageFetching(from imageURLs: [[String?]],
                                              iteration: Int,
                                              useLocalCache: Bool,
                                              notifyQueue: DispatchQueue,
                                              partialFetchHandler: @escaping (_ image: UIImage?, _ index: Int) -> Void,
                                              completion: @escaping () -> Void) {
        
        // Check if the current iteration points to a valid position in
        // the imageURLs array.
        // If not, then call the completion handler to indicate that all images
        // have been fetched and return from the method.
        guard iteration < imageURLs.count else { completion(); return }
        
        // Create a new dispatch group to gather all fetching tasks
        // for the current iteration.
        let group = DispatchGroup()
        
        // Enter to the group as many times as the images that should be fetched are.
        for _ in imageURLs[iteration] { group.enter() }
        
        // Make a loop and fetch the image for each image URL string.
        for (index, imageURL) in imageURLs[iteration].enumerated() {
            // Make sure the current image URL string is not nil.
            // If the image URL is nil, don't forget to leave the group in the
            // following else case, since the code execution won't keep going
            // and the leave() method won't be called later.
            guard let imageURL = imageURL else { group.leave(); continue }
            
            // Perform the actual fetching.
            fetchImage(from: imageURL, customFilename: nil, useLocalCache: useLocalCache) { (image) in
                // Call the partial handler passing the fetched image (or nil if it's nil)
                // and the index among all images as arguments.
                partialFetchHandler(image, (iteration * 12) + index)
                
                // Leave the group when an image has been fetched.
                group.leave()
            }
            
            // Add a small delay to avoid problems by not loading
            // images due to fast execution.
            _ = group.wait(timeout: .now() + 0.025)
        }
        
        
        // When the following is called, all tasks in the dispatch group
        // have been finished. In that case call self to pass to the next
        // group of images to be fetched, or finish the entire task if there
        // are no more images to fetch.
        group.notify(queue: notifyQueue) {
            self.performMultipleImageFetching(from: imageURLs, iteration: iteration + 1, useLocalCache: useLocalCache,
                                              notifyQueue: notifyQueue, partialFetchHandler: partialFetchHandler, completion: completion)
        }
    }
    
    
    
    
    /**
     Break the provided array to smaller arrays based on the specified maximum
     number of items on each.
     
     - Parameter array: The original array to break in pieces.
     - Parameter maxItems: The maximum number of elements that each subarray should contain.

     - Returns: A two-dimensional array that contains the subarrays as elements.
     
     Find a *generic implementation* of this method
     [here](https://gist.github.com/gabrieltheodoropoulos/58f0566e99d677a4bfa801b382ee80c2).
     */
    private func breakArray(_ array: [String?], inSubArraysOf maxItems: Int) -> [[String?]] {
        var resultArray = [[String?]]()
        var temp = [String?]()
        for (index, item) in array.enumerated() {
            temp.append(item)
            
            if (index + 1).isMultiple(of: maxItems) {
                resultArray.append(temp)
                temp.removeAll()
            }
        }
        
        resultArray.append(temp)
        temp.removeAll()
        
        return resultArray
    }
}

