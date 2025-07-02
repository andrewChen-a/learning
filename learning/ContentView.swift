import SwiftUI
import AVKit // 导入 AVKit 框架，用于视频播放器视图
import AVFoundation // 导入 AVFoundation 框架，用于处理媒体资产

struct ContentView: View {
    // 声明一个 @State 变量来保存 AVPlayer 实例
    // @State 属性包装器让视图在 player 发生变化时进行刷新
    @State private var player: AVPlayer?
    @State private var showingFileImporter = false // 新增：控制文件选择器显示与隐藏的状态

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
                    player?.play()
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
                            // ****** 关键：需要处理安全范围访问权限 ******
                            // 启动安全范围访问，这样 App 才能访问这个文件（即使 App 关闭再打开）
                            _ = selectedURL.startAccessingSecurityScopedResource()
                            
                            // 使用选择的 URL 初始化 AVPlayer
                            player = AVPlayer(url: selectedURL)
                            player?.play() // 自动播放
                            
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
            }
            .padding()
        }
        // MARK: - 视图出现时加载视频
        .onAppear { // content view出现时回调
        }
    }

    
}

// MARK: - 预览
#Preview {
    ContentView()
}
