import CoreServices
import Foundation

let CFSharedFileListSessionLoginItems = "com.apple.LSSharedFileList.SessionLoginItems" as CFString

enum LoginItemHelper {
    /// Retrieves an array of URLs for applications currently registered as system login items.
    /// - Returns: An array of `URL` objects representing the login items, or an empty array if retrieval fails or there are no items.
    static func snapshotLoginItemURLs() -> [URL] {
        var urls = [URL]()
        guard
            let loginItemsRef = LSSharedFileListCreate(nil, CFSharedFileListSessionLoginItems, nil)?.takeRetainedValue(),
            let snapshot = LSSharedFileListCopySnapshot(loginItemsRef, nil)?
            .takeRetainedValue() as NSArray?
        else {
            return []
        }
        for item in snapshot {
            guard
                let cfURL = LSSharedFileListItemCopyResolvedURL(item as! LSSharedFileListItem, 0, nil)?.takeRetainedValue()
            else {
                continue
            }
            urls.append(cfURL as URL)
        }
        return urls
    }
}
