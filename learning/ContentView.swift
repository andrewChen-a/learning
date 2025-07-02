import SwiftUI
import AVKit // 导入 AVKit 框架，用于视频播放器视图
import AVFoundation // 导入 AVFoundation 框架，用于处理媒体资产

struct ContentView: View {
    // 声明一个 @State 变量来保存 AVPlayer 实例
    // @State 属性包装器让视图在 player 发生变化时进行刷新
    @State private var player: AVPlayer?
    @State private var showingFileImporter = false // 新增：控制文件选择器显示与隐藏的状态
    @State private var showingRecentVideosSheet = false // 新增：控制最近观看列表的显示
    @State private var recentVideos: [RecentVideo] = [] // 新增：存储最近观看的视频列表
    // 定义预设的播放速度选项
    let playbackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    // MARK: - 新增：当前播放速度的状态变量
    @State private var currentPlaybackRate: Float = 1.0
    var body: some View {
        VStack {
            // MARK: - 视频播放器视图
            if let player = player {
                // VideoPlayer 是 AVKit 提供的 SwiftUI 视图，用于播放 AVPlayer
                VideoPlayer(player: player)
                    .frame(minWidth: 400, minHeight: 300) // 设置播放器最小尺寸
                    .border(Color.gray, width: 1) // 添加边框以便观察
            } else {
                // 如果 player 尚未加载，显示一个占位符
                Text("加载视频中...")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .frame(minWidth: 400, minHeight: 300)
                    .border(Color.gray, width: 1)
            }

            // MARK: - 控制按钮
            HStack {
                Button("播放") {
                    player?.playImmediately(atRate: currentPlaybackRate) // 使用 playImmediately(atRate:) 确保按当前速度播放
                }
                .buttonStyle(.borderedProminent) // macOS 风格的按钮样式

                Button("暂停") {
                    player?.pause()
                }
                .buttonStyle(.bordered)

                Spacer() // 填充剩余空间

                
                Button("-10s") {
                    guard let player = player else { return }
                    let currentTime = player.currentTime()
                    let newTime = CMTimeSubtract(currentTime, CMTimeMakeWithSeconds(10, preferredTimescale: 1))
                    player.seek(to: newTime)
                }
                .buttonStyle(.bordered)

                Button("+10s") {
                    guard let player = player else { return }
                    let currentTime = player.currentTime()
                    let newTime = CMTimeAdd(currentTime, CMTimeMakeWithSeconds(10, preferredTimescale: 1))
                    player.seek(to: newTime)
                }
                .buttonStyle(.bordered)
                Spacer()

                // MARK: - 倍速按钮和弹出菜单
                Menu {
                    ForEach(playbackRates, id: \.self) { rate in
                        Button {
                            setPlaybackRate(Float(rate)) // 将 Double 转换为 Float 传递给 setPlaybackRate
                        } label: {
                            // 高亮显示当前选中的速度
                            if Float(rate) == currentPlaybackRate { // 比较时也转为 Float
                                Label(String(format: "%.2fx", rate), systemImage: "checkmark")
                            } else {
                                Text(String(format: "%.2fx", rate))
                            }
                        }
                    }
                } label: {
                    // 按钮的显示文本，显示当前速度
                    Label(String(format: "倍速 (%.2fx)", currentPlaybackRate), systemImage: "speedometer")
                        .font(.body)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.accentColor.opacity(0.2))) // 简单背景
                        .foregroundColor(.primary)
                }
                .menuStyle(.borderlessButton) // 确保按钮样式简洁
                .fixedSize() // 防止按钮内容改变时大小跳动
                
                Spacer() // 在速度控制和文件选择之间加个间隔
                
                Button("选择视频文件...") {
                    showingFileImporter = true // 设置状态为 true，显示文件选择器
                }
                .buttonStyle(.bordered)
                
                // ***** 新增：文件导入器修饰符 *****
                .fileImporter(
                    isPresented: $showingFileImporter, // 绑定控制显示的状态
                    allowedContentTypes: [UTType.movie], // 允许选择的类型为电影（视频）文件
                    allowsMultipleSelection: false // 不允许多选，只选择一个文件
                ) { result in
                    // 处理文件选择的结果
                    switch result {
                    case .success(let urls):
                        // 用户成功选择了文件
                        if let selectedURL = urls.first { // 因为不允许选择多个，所以直接取第一个
                            
                            // 1. 创建新的 RecentVideo 实例 (如果成功)
                            if let newRecentVideo = RecentVideo(url: selectedURL) {
                                // 2. 将视频添加到 UserDefaults (持久化存储)
                                UserDefaults.standard.addOrUpdateRecentVideo(newRecentVideo)
                                
                                // 3. 重新从 UserDefaults 加载更新后的列表到 @State 变量
                                //    这将确保 `recentVideos` 数组是最新的
                                recentVideos = UserDefaults.standard.loadRecentVideos()
                                
                                // 4. 打印更新后的 recentVideos 列表
                                print("--- 更新后的 Recent 列表数据 ---")
                                for video in recentVideos {
                                    print("ID: \(video.id.uuidString.prefix(8))... Name: \(video.name), Last Watched: \(video.lastWatchedDate)")
                                    // 可以在这里进一步打印 video.url 来验证 URL 是否正确解析
                                }
                                print("----------------------------")
                            
                            // ****** 关键：需要处理安全范围访问权限 ******
                            // 启动安全范围访问，这样 App 才能访问这个文件（即使 App 关闭再打开）
                            _ = selectedURL.startAccessingSecurityScopedResource()
                            
                            // 使用选择的 URL 初始化 AVPlayer
                                
                            player = AVPlayer(url: selectedURL)
                                // 播放新视频时，默认设置为 1.0x 速度
                                currentPlaybackRate = 1.0
                                player?.playImmediately(atRate: currentPlaybackRate) // 播放时使用当前速度
                            } else {
                                print("无法为选定的URL创建RecentVideo条目：\(selectedURL)")
                            }
                            // 注意：理论上，当不再需要访问时，应该调用 selectedURL.stopAccessingSecurityScopedResource()
                            // 但对于播放器，只要播放器存在，就一直需要访问。
                            // 更复杂的应用会保存书签数据（bookmark data）以便下次启动时直接访问
                        }
                    case .failure(let error):
                        // 用户取消选择或发生错误
                        print("选择文件失败：\(error.localizedDescription)")
                        // 可以在这里显示一个用户友好的错误消息
                    }
                }
                
                // ***** 新增：Recent 按钮 *****

                Button("Recent") {
                    showingRecentVideosSheet = true // 设置状态为 true，显示最近观看列表
                }
                .buttonStyle(.bordered)
                // ***** 新增：Sheet 修饰符，用于显示最近观看列表 *****
                .sheet(isPresented: $showingRecentVideosSheet) {
                    // 最近观看视频列表视图
                    RecentVideosListView(recentVideos: $recentVideos) { selectedVideoURL in
                        // 用户从列表中选择了一个视频，进行播放
                        player = AVPlayer(url: selectedVideoURL)
                        player?.playImmediately(atRate: currentPlaybackRate)// 播放时使用当前速度
                        showingRecentVideosSheet = false // 关闭列表
                    }
                }
            }
            .padding()
        }
        // MARK: - 视图出现时加载视频
        .onAppear { // content view出现时回调
            // 视图出现时加载最近观看的视频列表
            recentVideos = UserDefaults.standard.loadRecentVideos()
        }
    }
    
    // MARK: - 设置播放速度的函数 (已优化为立即生效)
    private func setPlaybackRate(_ rate: Float) {
        guard let player = player else {
            print("DEBUG: Player instance is nil, cannot set rate.")
            return
        }

        currentPlaybackRate = rate // 更新 SwiftUI 视图的状态变量

        // 核心改变：直接使用 playImmediately(atRate:) 强制播放并设置新速度
        player.playImmediately(atRate: rate)

        print("DEBUG: Player rate set and playing immediately at: \(rate)")

        // 如果你愿意，可以保留延时打印用于最终确认
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("DEBUG: Player rate after delay: \(player.rate)")
        }
    }
}

// MARK: - 最近观看视频列表视图
// 为了保持 ContentView 简洁，我们将 RecentVideosListView 放在单独的 struct 中
struct RecentVideosListView: View {
    @Binding var recentVideos: [RecentVideo] // 绑定最近视频列表数据
    @Environment(\.dismiss) var dismiss // 用于关闭 Sheet
    var onSelectVideo: (URL) -> Void // 回调闭包，用于传递选中的视频 URL

    var body: some View {
        VStack {
            Text("最近观看")
                .font(.largeTitle)
                .padding()

            if recentVideos.isEmpty {
                Spacer()
                Text("还没有观看记录。")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List {
                    ForEach(recentVideos) { video in
                        Button {
                            // 当用户点击视频时
                            if let videoURL = video.url {
                                onSelectVideo(videoURL) // 调用回调，播放视频
                            } else {
                                print("无法解析视频URL：\(video.name)")
                            }
                        } label: {
                            HStack {
                                Text(video.name)
                                Spacer()
                                Text(video.lastWatchedDate, format: .dateTime.month().day().hour().minute())
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .buttonStyle(.plain) // 列表中的按钮通常使用 .plain 样式
                    }
                    // 添加删除功能 (可选)
                    .onDelete { offsets in
                        recentVideos.remove(atOffsets: offsets)
                        UserDefaults.standard.saveRecentVideos(recentVideos) // 更新 UserDefaults
                    }
                }
            }

            Button("关闭") {
                dismiss() // 关闭当前 Sheet
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300) // 给 Sheet 设置最小尺寸
    }
}

// MARK: - 预览
#Preview {
    ContentView()
}
