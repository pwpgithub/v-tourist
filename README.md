# Virtual Tourist

The Virtual Tourist app downloads and stores images from Flickr. The app allows users to drop pins on a map, as if they were stops on a tour. Users will then be able to download pictures for the location and persist both the pictures, and the association of the pictures with the pin.

### Requirements
- Build
  * Xcode 9.4, Xcode 8.0 compatible, iOS 11.2 SDK
- Runtime
  * iOS 11.2 or later

### Overview
- A map view for user to drop pins at any location.
- A collection view displays downloaded photos from internet
- The downloaded photos are persisted using core data.
- Allows the following actions
  * Map view
    1) Long press to drop a pin on the Map
    2) Tap the "Edit" button, then tap on the dropped pins to delete them
    3) Tap on the pin to download photos at the location from internet
    4) Drag and drop the pins on the Map
  * Collection view
    1) If no photos to be downloaded, it shows a massage
    2) Press "New Collection" button to download new set of photos
    3) Tap on the collection cell to select and delete the photos

### Known bugs
