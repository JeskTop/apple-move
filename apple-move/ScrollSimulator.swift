import Foundation
import CoreGraphics
import ApplicationServices

class ScrollSimulator: ObservableObject {
    @Published var isScrolling = false
    @Published var hasAccessibilityPermission = false
    @Published var isCountingDown = false
    @Published var countdownValue = 0
    
    private var timer: Timer?
    private var countdownTimer: Timer?
    private var currentStep = 0
    private var totalSteps = 0
    private var startSpeed: Double = 0
    private var endSpeed: Double = 0
    private var currentSpeed: Double = 0
    
    // 存储待执行的滚动参数
    private var pendingStartSpeed: Double = 0
    private var pendingEndSpeed: Double = 0
    private var pendingSteps: Int = 0
    
    // 滚动阶段枚举
    enum ScrollPhase: Int64 {
        case ended = 0
        case began = 1      // 开始阶段
        case changed = 2    // 进行中阶段
        case cancel = 4     // 取消阶段
        case initial = 128  // 初始阶段
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
    
    /// 开始倒计时并准备滚动
    func startScrollingWithCountdown(startSpeed: Double, endSpeed: Double, steps: Int) {
        // 检查权限
        checkAccessibilityPermission()
        guard hasAccessibilityPermission else {
            print("没有辅助功能权限，无法模拟滚动")
            return
        }
        
        // 如果正在滚动或倒计时，先停止
        if isScrolling || isCountingDown {
            stopAll()
        }
        
        // 保存滚动参数
        pendingStartSpeed = startSpeed
        pendingEndSpeed = endSpeed
        pendingSteps = steps
        
        // 开始倒计时
        startCountdown()
    }
    
    /// 开始3秒倒计时
    private func startCountdown() {
        isCountingDown = true
        countdownValue = 3
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.countdownValue -= 1
            
            if self.countdownValue <= 0 {
                // 倒计时结束，开始滚动
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
                self.isCountingDown = false
                
                // 开始实际滚动
                self.startActualScrolling()
            }
        }
    }
    
    /// 开始实际的滚动过程
    private func startActualScrolling() {
        self.startSpeed = pendingStartSpeed
        self.endSpeed = pendingEndSpeed
        self.totalSteps = pendingSteps
        self.currentStep = 0
        self.isScrolling = true
        
        // 发送开始阶段事件
        sendScrollEvent(speed: startSpeed, phase: .initial)
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
    
    /// 停止所有活动（包括倒计时和滚动）
    func stopAll() {
        // 停止倒计时
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountingDown = false
        countdownValue = 0
        
        // 停止滚动
        stopScrolling()
    }
    
    /// 发送下一个滚动事件（线性变化）
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
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: 0,
            wheel2: 0,
            wheel3: 0
        ) else {
            print("无法创建滚动事件")
            return
        }

        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: speed)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: speed)
        
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase.rawValue)
        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 0)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        
        // 发送事件到系统
        event.post(tap: .cghidEventTap)
        
        // 只在调试时打印详细信息
        if phase == .began || phase == .initial {
            print("发送滚动事件 - 速度: \(speed), 阶段: \(phase.rawValue)")
        }
    }
    
}
