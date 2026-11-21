import Foundation
import HealthKit

/// HealthKit 步数写入器
/// 关键点：HealthKit 是「累加」的，不能直接写 23800，否则会和系统已记录的步数叠加。
/// 正确做法：读当天总和 -> 算差值 -> 只写差值。
final class StepWriter: ObservableObject {

    private let store = HKHealthStore()
    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    @Published var authorized = false
    @Published var todayTotal: Int = 0
    @Published var message = ""
    @Published var busy = false

    // MARK: - 授权
    func requestAuth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            message = "此设备不支持健康数据"
            return
        }
        store.requestAuthorization(toShare: [stepType], read: [stepType]) { [weak self] ok, err in
            DispatchQueue.main.async {
                self?.authorized = ok
                self?.message = ok ? "已授权" : (err?.localizedDescription ?? "授权失败")
                self?.refreshTotal()
            }
        }
    }

    // MARK: - 读当天总步数
    func refreshTotal() {
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let q = HKStatisticsQuery(quantityType: stepType,
                                  quantitySamplePredicate: pred,
                                  options: .cumulativeSum) { [weak self] _, stat, _ in
            let sum = stat?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async { self?.todayTotal = Int(sum) }
        }
        store.execute(q)
    }

    // MARK: - 把「今天」设置成指定步数
    func setToday(_ target: Int, completion: ((Bool, String) -> Void)? = nil) {
        busy = true
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let q = HKStatisticsQuery(quantityType: stepType,
                                  quantitySamplePredicate: pred,
                                  options: .cumulativeSum) { [weak self] _, stat, _ in
            guard let self else { return }
            let total = stat?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            let delta = Double(target) - total

            guard delta > 0 else {
                DispatchQueue.main.async {
                    self.busy = false
                    let msg = "今天已记录 \(Int(total)) 步，已经达到目标，无需写入"
                    self.message = msg
                    completion?(true, msg)
                }
                return
            }

            let end = Date()
            let sample = HKQuantitySample(
                type: self.stepType,
                quantity: HKQuantity(unit: .count(), doubleValue: delta),
                start: end.addingTimeInterval(-60),
                end: end,
                metadata: [HKMetadataKeyWasUserEntered: false]
            )
            self.store.save(sample) { ok, err in
                DispatchQueue.main.async {
                    self.busy = false
                    if ok {
                        let msg = "写入 \(Int(delta)) 步成功，今天共 \(target) 步"
                        self.message = msg
                        self.refreshTotal()
                        completion?(true, msg)
                    } else {
                        let msg = "写入失败：\(err?.localizedDescription ?? "未知错误")"
                        self.message = msg
                        completion?(false, msg)
                    }
                }
            }
        }
        store.execute(q)
    }

    // MARK: - 删除本 App 今天写入的样本（重置用）
    func deleteTodaySamples(completion: ((Bool) -> Void)? = nil) {
        let start = Calendar.current.startOfDay(for: Date())
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        store.deleteObjects(of: stepType, predicate: pred) { ok, _, err in
            DispatchQueue.main.async {
                self.message = ok ? "已清除今天本 App 写入的数据" : "清除失败：\(err?.localizedDescription ?? "")"
                self.refreshTotal()
                completion?(ok)
            }
        }
    }
}
