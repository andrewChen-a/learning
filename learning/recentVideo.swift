import Foundation

// 定义 RecentVideo 结构体，遵循 Codable, Identifiable, Equatable 协议
struct RecentVideo: Codable, Identifiable, Equatable {
    let id = UUID()
    let urlData: Data // 存储 URL 的书签数据
    var name: String
    var lastWatchedDate: Date

    // 修改 init 方法，使其能够处理 url.bookmarkData() 可能抛出的错误
    init?(url: URL, name: String? = nil, lastWatchedDate: Date = Date()) {
        do {
            // 尝试将 URL 转换为书签数据
            self.urlData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            // .withSecurityScope 选项很重要，确保可以在App重启后重新获得文件访问权限

            self.name = name ?? url.lastPathComponent
            self.lastWatchedDate = lastWatchedDate
        } catch {
            // 如果转换失败，打印错误并返回 nil，表示初始化失败
            print("Error creating bookmark data for URL '\(url)': \(error.localizedDescription)")
            return nil // 初始化失败，返回 nil
        }
    }

    // 从 urlData 属性计算得到原始的 URL
    var url: URL? {
        var isStale = false
        // 从书签数据恢复 URL，并重新获取安全范围访问权限
        if let restoredURL = try? URL(resolvingBookmarkData: urlData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
            if isStale {
                // 书签数据可能已过期，但URL已解析。实际应用中可能需要重新保存新的书签数据
                print("Bookmark data for \(name) is stale, but URL was resolved. Consider re-saving bookmark.")
            }
            // 重新开始安全范围访问。如果之前没有停止访问，这里会重新授权。
            // 每次从书签数据解析出 URL 后，都应该调用 startAccessingSecurityScopedResource()
            // 在不再需要时，调用 stopAccessingSecurityScopedResource()
            _ = restoredURL.startAccessingSecurityScopedResource()
            return restoredURL
        }
        return nil
    }

    // Equatable 协议要求，用于比较两个 RecentVideo 是否相同
    static func == (lhs: RecentVideo, rhs: RecentVideo) -> Bool {
        lhs.id == rhs.id // 简单地比较 ID
    }
}

// UserDefaults Extension (保持不变，因为它不直接调用 RecentVideo 的 init)
extension UserDefaults {
    private static let recentVideosKey = "recentVideos"

    // 加载最近观看的视频列表 (Decoding)
       func loadRecentVideos() -> [RecentVideo] {
           if let data = data(forKey: Self.recentVideosKey) {
               do {
                   let decoder = JSONDecoder() // Correct: Use JSONDecoder for decoding
                   let videos = try decoder.decode([RecentVideo].self, from: data)
                   // 在加载时，可以尝试清理无效的 URL（如果 bookmarkData 无法解析）
                   return videos.filter { $0.url != nil } // 过滤掉无法解析URL的条目
               } catch {
                   print("Failed to decode recent videos: \(error.localizedDescription)")
               }
           }
           return []
       }

       // 保存最近观看的视频列表 (Encoding)
       func saveRecentVideos(_ videos: [RecentVideo]) {
           do {
               let encoder = JSONEncoder() // FIX: Corrected to use JSONEncoder for encoding
               let data = try encoder.encode(videos) // Correct: Use encode on JSONEncoder
               set(data, forKey: Self.recentVideosKey)
           } catch {
               print("Failed to encode recent videos: \(error.localizedDescription)")
           }
       }

       // 添加或更新一个最近观看的视频 (remains unchanged)
       func addOrUpdateRecentVideo(_ newVideo: RecentVideo) {
           var videos = loadRecentVideos()

           // 检查是否已经存在该视频，如果存在则更新时间并移到最前
           // IMPORTANT: The comparison `videos.firstIndex(where: { $0.url == newVideo.url })`
           // relies on $0.url being resolved correctly. If the bookmarkData is stale
           // or fails to resolve, this comparison might not work as expected.
           // It's generally better to compare `id`s if you're updating an existing item.
           // However, if the intent is to update based on the *same file path*, then `url` comparison is needed.
           // Given that `RecentVideo` has `Equatable` on `id`, we might use `id` here instead of `url`.
           // Let's assume for now that comparing `url` is the desired behavior for "same video file".
           if let index = videos.firstIndex(where: { $0.id == newVideo.id || ($0.url != nil && $0.url == newVideo.url) }) {
                // If a video with the same ID or the same resolved URL is found
               videos[index].lastWatchedDate = Date()
               let existingVideo = videos.remove(at: index)
               videos.insert(existingVideo, at: 0)
           } else {
               // New video, add to the front
               videos.insert(newVideo, at: 0)
           }

           // Limit the list length, e.g., keep only the 10 most recent videos
           if videos.count > 10 {
               videos = Array(videos.prefix(10))
           }

           saveRecentVideos(videos)
       }
}
