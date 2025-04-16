import CoreServices
import Foundation

enum LoginItemHelper {
    /// Retrieves an array of URLs for applications currently registered as system login items.
    /// - Returns: An array of `URL` objects representing the login items, or an empty array if retrieval fails or there are no items.
    static func snapshotLoginItemURLs() -> [URL] {
        guard
            let loginItemsRef = LSSharedFileListCreate(nil, Constants.sessionLoginItemsKey as CFString, nil)?.takeRetainedValue(),
            let snapshot = LSSharedFileListCopySnapshot(loginItemsRef, nil)?
            .takeRetainedValue() as NSArray?
        else {
            return []
        }

        return snapshot.compactMap { item in
            guard
                let cfURL = LSSharedFileListItemCopyResolvedURL(item as! LSSharedFileListItem, 0, nil)?.takeRetainedValue()
            else {
                return nil
            }
            return cfURL as URL
        }
    }
}
