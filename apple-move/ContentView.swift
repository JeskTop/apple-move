//
//  ContentView.swift
//  apple-move
//
//  Created by 冯锐 on 2025/8/8.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var scrollSimulator = ScrollSimulator()
    @State private var startSpeed: Double = 1
    @State private var endSpeed: Double = 80
    @State private var steps: Double = 80
    @State private var selectedCurve: CurveType = .linear
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("滚轮滚动模拟器")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
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
                
                // 加速度曲线选择
                VStack(alignment: .leading, spacing: 5) {
                    Text("加速度曲线")
                        .font(.subheadline)
                    Picker("加速度曲线", selection: $selectedCurve) {
                        ForEach(CurveType.allCases, id: \.self) { curve in
                            Text(curve.rawValue).tag(curve)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // 控制按钮
            HStack(spacing: 20) {
                Button(action: startScrolling) {
                    HStack {
                        Image(systemName: scrollSimulator.isScrolling ? "stop.circle.fill" : "play.circle.fill")
                        Text(scrollSimulator.isScrolling ? "停止滚动" : "开始滚动")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(scrollSimulator.isScrolling ? Color.red : (scrollSimulator.hasAccessibilityPermission ? Color.blue : Color.gray))
                    .cornerRadius(8)
                }
                .disabled(!scrollSimulator.hasAccessibilityPermission && !scrollSimulator.isScrolling)
                
                Button(action: showPermissionInfo) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("权限设置")
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
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
                            .fill(scrollSimulator.isScrolling ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        Text(scrollSimulator.isScrolling ? "正在滚动" : "待机中")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Circle()
                            .fill(scrollSimulator.hasAccessibilityPermission ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        Text(scrollSimulator.hasAccessibilityPermission ? "权限已授予" : "需要权限")
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            Spacer()
            
            // 说明文字
            Text("注意：使用此功能需要授予辅助功能权限")
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
    
    private func startScrolling() {
        if scrollSimulator.isScrolling {
            scrollSimulator.stopScrolling()
        } else {
            scrollSimulator.startScrollingWithCurve(
                startSpeed: startSpeed,
                endSpeed: endSpeed,
                steps: Int(steps),
                curveType: selectedCurve
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
