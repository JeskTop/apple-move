//
//  ScrollSimulator.swift
//  apple-move
//
//  Created by 冯锐 on 2025/8/8.
//

import Foundation
import CoreGraphics
import ApplicationServices

class ScrollSimulator: ObservableObject {
    @Published var isScrolling = false
    @Published var hasAccessibilityPermission = false
    
    private var timer: Timer?
    private var currentStep = 0
    private var totalSteps = 0
    private var startSpeed: Double = 0
    private var endSpeed: Double = 0
    private var currentSpeed: Double = 0
    
    // 滚动阶段枚举
    enum ScrollPhase: Int64 {
        case began = 1      // 开始阶段
        case changed = 2    // 进行中阶段
        case ended = 3      // 结束阶段
    }
    
    init() {
        checkAccessibilityPermission()
    }
    
    /// 检查辅助功能权限
    func checkAccessibilityPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        if !hasAccessibilityPermission {
            // 请求权限
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
    }
    
    /// 开始模拟滚动
    /// - Parameters:
    ///   - startSpeed: 起始速度
    ///   - endSpeed: 最终速度
    ///   - steps: 发送数据次数
    func startScrolling(startSpeed: Double, endSpeed: Double, steps: Int) {
        // 检查权限
        checkAccessibilityPermission()
        guard hasAccessibilityPermission else {
            print("没有辅助功能权限，无法模拟滚动")
            return
        }
        
        // 如果正在滚动，先停止
        if isScrolling {
            stopScrolling()
        }
        
        self.startSpeed = startSpeed
        self.endSpeed = endSpeed
        self.totalSteps = steps
        self.currentStep = 0
        self.isScrolling = true
        
        // 发送开始阶段事件
        sendScrollEvent(speed: startSpeed, phase: .began)
        
        // 启动定时器，每16ms发送一次事件
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.sendNextScrollEvent()
        }
    }
    
    /// 停止滚动模拟
    func stopScrolling() {
        timer?.invalidate()
        timer = nil
        
        if isScrolling {
            // 发送结束事件（速度为0）
            sendScrollEvent(speed: 0, phase: .ended)
        }
        
        isScrolling = false
        currentStep = 0
    }
    
    /// 发送下一个滚动事件
    private func sendNextScrollEvent() {
        guard currentStep < totalSteps else {
            // 滚动完成，发送结束事件
            stopScrolling()
            return
        }
        
        // 计算当前速度（线性插值）
        let progress = Double(currentStep) / Double(totalSteps - 1)
        currentSpeed = startSpeed + (endSpeed - startSpeed) * progress
        
        // 发送滚动事件
        sendScrollEvent(speed: currentSpeed, phase: .changed)
        
        currentStep += 1
    }
    
    /// 发送滚动事件
    /// - Parameters:
    ///   - speed: 滚动速度
    ///   - phase: 滚动阶段
    private func sendScrollEvent(speed: Double, phase: ScrollPhase) {
        let delta = Int32(speed.rounded())
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: delta,
            wheel2: 0,
            wheel3: 0
        ) else {
            print("无法创建滚动事件")
            return
        }
        
        
        // 设置滚动阶段
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase.rawValue)
        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        
        // 发送事件到系统
        event.post(tap: .cghidEventTap)
        
        print("发送滚动事件 - 速度: \(speed), 阶段: \(phase.rawValue)")
    }
    
    /// 使用自定义加速度曲线计算速度
    /// - Parameters:
    ///   - progress: 进度 (0.0 到 1.0)
    ///   - curveType: 曲线类型
    /// - Returns: 调整后的进度值
    private func applyCurve(_ progress: Double, curveType: CurveType) -> Double {
        switch curveType {
        case .linear:
            return progress
        case .easeIn:
            return progress * progress
        case .easeOut:
            return 1 - pow(1 - progress, 2)
        case .easeInOut:
            if progress < 0.5 {
                return 2 * progress * progress
            } else {
                return 1 - pow(-2 * progress + 2, 2) / 2
            }
        }
    }
    
    /// 使用加速度曲线开始滚动
    /// - Parameters:
    ///   - startSpeed: 起始速度
    ///   - endSpeed: 最终速度
    ///   - steps: 发送数据次数
    ///   - curveType: 加速度曲线类型
    func startScrollingWithCurve(startSpeed: Double, endSpeed: Double, steps: Int, curveType: CurveType) {
        // 检查权限
        checkAccessibilityPermission()
        guard hasAccessibilityPermission else {
            print("没有辅助功能权限，无法模拟滚动")
            return
        }
        
        // 如果正在滚动，先停止
        if isScrolling {
            stopScrolling()
        }
        
        self.startSpeed = startSpeed
        self.endSpeed = endSpeed
        self.totalSteps = steps
        self.currentStep = 0
        self.isScrolling = true
        
        // 发送开始阶段事件
        sendScrollEvent(speed: startSpeed, phase: .began)
        
        // 启动定时器，每16ms发送一次事件
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.sendNextScrollEventWithCurve(curveType: curveType)
        }
    }
    
    /// 使用曲线发送下一个滚动事件
    private func sendNextScrollEventWithCurve(curveType: CurveType) {
        guard currentStep < totalSteps else {
            // 滚动完成，发送结束事件
            stopScrolling()
            return
        }
        
        // 计算当前进度
        let progress = Double(currentStep) / Double(totalSteps - 1)
        
        // 应用加速度曲线
        let curvedProgress = applyCurve(progress, curveType: curveType)
        
        // 计算当前速度
        currentSpeed = startSpeed + (endSpeed - startSpeed) * curvedProgress
        
        // 发送滚动事件
        sendScrollEvent(speed: currentSpeed, phase: .changed)
        
        currentStep += 1
    }
}

/// 加速度曲线类型
enum CurveType: String, CaseIterable {
    case linear = "线性"
    case easeIn = "缓入"
    case easeOut = "缓出"
    case easeInOut = "缓入缓出"
}
