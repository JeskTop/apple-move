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
    private var momentumTimer: Timer?
    private var currentStep = 0
    private var totalSteps = 0
    private var startSpeed: Double = 0
    private var endSpeed: Double = 0
    private var currentSpeed: Double = 0
    
    // 动量滚动相关
    private var isMomentumScrolling = false
    private var momentumSpeed: Double = 0
    private var momentumStep = 0
    private var momentumTotalSteps = 0
    
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
    
    // 动量阶段枚举
    enum MomentumPhase: Int64 {
        case none = 0       // 无动量
        case began = 1      // 动量开始
        case changed = 2    // 动量进行中
        case ended = 3      // 动量结束
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
        sendScrollEvent(speed: startSpeed, phase: .initial, momentumPhase: .none)
        sendScrollEvent(speed: startSpeed, phase: .began, momentumPhase: .none)
        
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
            // 发送取消事件，然后开始动量滚动
            sendScrollEvent(speed: currentSpeed, phase: .cancel, momentumPhase: .none)
            startMomentumScrolling()
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
        
        // 停止动量滚动
        stopMomentumScrolling()
        
        // 停止滚动
        timer?.invalidate()
        timer = nil
        isScrolling = false
        currentStep = 0
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
        sendScrollEvent(speed: currentSpeed, phase: .changed, momentumPhase: .none)
        
        currentStep += 1
    }
    
        /// 发送滚动事件
    /// - Parameters:
    ///   - speed: 滚动速度
    ///   - phase: 滚动阶段
    ///   - momentumPhase: 动量阶段
    private func sendScrollEvent(speed: Double, phase: ScrollPhase, momentumPhase: MomentumPhase = .none) {
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
        event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentumPhase.rawValue)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        
        // 发送事件到系统
        event.post(tap: .cghidEventTap)
        
        // 打印详细信息
        if phase == .began || phase == .initial || momentumPhase != .none {
            print("发送滚动事件 - 速度: \(speed), 阶段: \(phase.rawValue), 动量: \(momentumPhase.rawValue)")
        }
    }
    
    /// 开始动量滚动（长尾递减）
    private func startMomentumScrolling() {
        // 如果当前速度太小，直接结束
        guard abs(currentSpeed) > 0.1 else {
            print("速度太小，跳过动量滚动")
            return
        }
        
        isMomentumScrolling = true
        momentumSpeed = currentSpeed * 0.8  // 动量滚动起始速度为当前速度的80%
        momentumStep = 0
        momentumTotalSteps = 30  // 动量滚动持续30步，约0.5秒
        
        print("🌊 开始动量滚动 - 起始速度: \(momentumSpeed)")
        
        // 发送动量开始事件
        sendScrollEvent(speed: momentumSpeed, phase: .ended, momentumPhase: .began)
        
        // 启动动量滚动定时器
        momentumTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.sendNextMomentumEvent()
        }
    }
    
    /// 发送下一个动量滚动事件
    private func sendNextMomentumEvent() {
        guard momentumStep < momentumTotalSteps else {
            // 动量滚动完成
            stopMomentumScrolling()
            return
        }
        
        // 计算当前动量速度（指数递减）
        let progress = Double(momentumStep) / Double(momentumTotalSteps)
        let decayFactor = exp(-3.0 * progress)  // 指数衰减
        let currentMomentumSpeed = momentumSpeed * decayFactor
        
        // 发送动量滚动事件
        let momentumPhase: MomentumPhase = (momentumStep == momentumTotalSteps - 1) ? .ended : .changed
        sendScrollEvent(speed: currentMomentumSpeed, phase: .ended, momentumPhase: momentumPhase)
        
        momentumStep += 1
    }
    
    /// 停止动量滚动
    private func stopMomentumScrolling() {
        momentumTimer?.invalidate()
        momentumTimer = nil
        
        if isMomentumScrolling {
            // 发送动量结束事件
            sendScrollEvent(speed: 0, phase: .ended, momentumPhase: .ended)
            print("🏁 动量滚动结束")
        }
        
        isMomentumScrolling = false
        momentumStep = 0
        momentumSpeed = 0
    }
    
}
