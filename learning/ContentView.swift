import SwiftUI
import AVKit // 导入 AVKit 框架，用于视频播放器视图
import AVFoundation // 导入 AVFoundation 框架，用于处理媒体资产

struct ContentView: View {
    // 声明一个 @State 变量来保存 AVPlayer 实例
    // @State 属性包装器让视图在 player 发生变化时进行刷新
    @State private var player: AVPlayer?

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
            }
            .padding()
        }
        // MARK: - 视图出现时加载视频
        .onAppear { // content view出现时回调
            loadLocalVideo()
        }
    }

    // MARK: - 加载本地视频的函数
    private func loadLocalVideo() {
        // 尝试获取本地视频文件的 URL
        // 假设你的视频文件名为 "sample_video.mp4"
        // 确保它已经添加到了你的 Xcode 项目中，并且在 Build Phases -> Copy Bundle Resources 中
        // 替换 "sample_video" 为你实际的视频文件名（不含扩展名）
        // 替换 "mp4" 为你实际的视频文件扩展名
        if let videoURL = Bundle.main.url(forResource: "sample_video", withExtension: "mp4") {
            // 使用视频 URL 初始化 AVPlayer
            player = AVPlayer(url: videoURL)
            // 可选：加载完成后自动播放
            // player?.play()
        } else {
            print("错误：无法找到本地视频文件 'sample_video.mp4'。请检查文件名和路径。")
            // 你可以在这里显示一个错误提示给用户
        }
    }
}

// MARK: - 预览
#Preview {
    ContentView()
}
