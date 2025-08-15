import SwiftUI

struct ContentView: View {
    @StateObject private var scrollSimulator = ScrollSimulator()
    @State private var startSpeed: Double = 1
    @State private var endSpeed: Double = 80
    @State private var steps: Double = 80
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("滚轮滚动模拟器")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // 倒计时显示
            if scrollSimulator.isCountingDown {
                VStack(spacing: 10) {
                    Text("准备开始滚动")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.orange.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(3 - scrollSimulator.countdownValue) / 3.0)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: scrollSimulator.countdownValue)
                        
                        Text("\(scrollSimulator.countdownValue)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(15)
            }
            
            // 参数设置区域
            VStack(alignment: .leading, spacing: 15) {
                Text("滚动参数设置")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // 起始速度
                VStack(alignment: .leading, spacing: 5) {
                    Text("起始速度: \(Int(startSpeed))")
                        .font(.subheadline)
                    Slider(value: $startSpeed, in: 1...100, step: 1)
                        .accentColor(.blue)
                }
                
                // 最终速度
                VStack(alignment: .leading, spacing: 5) {
                    Text("最终速度: \(Int(endSpeed))")
                        .font(.subheadline)
                    Slider(value: $endSpeed, in: 1...200, step: 1)
                        .accentColor(.green)
                }
                
                // 发送次数
                VStack(alignment: .leading, spacing: 5) {
                    Text("发送次数: \(Int(steps))")
                        .font(.subheadline)
                    Slider(value: $steps, in: 10...200, step: 1)
                        .accentColor(.orange)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // 控制按钮
            HStack(spacing: 15) {
                Button(action: startScrolling) {
                    HStack {
                        Image(systemName: getButtonIcon())
                        Text(getButtonText())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(getButtonColor())
                    .cornerRadius(8)
                }
                .disabled(!scrollSimulator.hasAccessibilityPermission && !scrollSimulator.isScrolling && !scrollSimulator.isCountingDown)
                
                
                Button(action: showPermissionInfo) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("权限")
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // 状态显示
            VStack(spacing: 10) {
                Text("当前状态")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(getStatusColor())
                            .frame(width: 12, height: 12)
                        Text(getStatusText())
                            .font(.subheadline)
                        Spacer()
                    }
                    
                    HStack {
                        Circle()
                            .fill(scrollSimulator.hasAccessibilityPermission ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(scrollSimulator.hasAccessibilityPermission ? "权限已授予" : "需要权限")
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            Spacer()
            
            // 说明文字
            Text("点击开始滚动后，将有3秒倒计时准备时间")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .alert("权限设置说明", isPresented: $showingPermissionAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("为了模拟滚轮滚动，需要在系统偏好设置 > 安全性与隐私 > 辅助功能中授予此应用权限。")
        }
    }
    
    // MARK: - 辅助方法
    
    private func getButtonIcon() -> String {
        if scrollSimulator.isCountingDown {
            return "stop.circle.fill"
        } else if scrollSimulator.isScrolling {
            return "stop.circle.fill"
        } else {
            return "play.circle.fill"
        }
    }
    
    private func getButtonText() -> String {
        if scrollSimulator.isCountingDown {
            return "取消倒计时"
        } else if scrollSimulator.isScrolling {
            return "停止滚动"
        } else {
            return "开始滚动"
        }
    }
    
    private func getButtonColor() -> Color {
        if scrollSimulator.isCountingDown || scrollSimulator.isScrolling {
            return Color.red
        } else if scrollSimulator.hasAccessibilityPermission {
            return Color.blue
        } else {
            return Color.gray
        }
    }
    
    private func getStatusColor() -> Color {
        if scrollSimulator.isCountingDown {
            return Color.orange
        } else if scrollSimulator.isScrolling {
            return Color.green
        } else {
            return Color.gray
        }
    }
    
    private func getStatusText() -> String {
        if scrollSimulator.isCountingDown {
            return "倒计时中"
        } else if scrollSimulator.isScrolling {
            return "正在滚动"
        } else {
            return "待机中"
        }
    }
    
    // MARK: - 按钮动作
    private func startScrolling() {
        if scrollSimulator.isCountingDown || scrollSimulator.isScrolling {
            scrollSimulator.stopAll()
        } else {
            scrollSimulator.startScrollingWithCountdown(
                startSpeed: startSpeed,
                endSpeed: endSpeed,
                steps: Int(steps)
            )
        }
    }
    
    
    private func showPermissionInfo() {
        scrollSimulator.checkAccessibilityPermission()
        showingPermissionAlert = true
    }
}

#Preview {
    ContentView()
}
