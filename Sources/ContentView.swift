import SwiftUI

struct ContentView: View {
    @StateObject private var writer = StepWriter()
    @State private var input: String = "23800"

    var body: some View {
        NavigationStack {
            Form {
                Section("当前状态") {
                    HStack {
                        Text("今天已记录")
                        Spacer()
                        Text("\(writer.todayTotal) 步").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("健康权限")
                        Spacer()
                        Text(writer.authorized ? "已授权" : "未授权")
                            .foregroundStyle(writer.authorized ? .green : .orange)
                    }
                    if !writer.authorized {
                        Button("请求健康权限") { writer.requestAuth() }
                    }
                }

                Section("设置步数") {
                    TextField("目标步数", text: $input)
                        .keyboardType(.numberPad)
                    Button {
                        guard let n = Int(input), n > 0, n <= 60000 else {
                            writer.message = "请输入 1–60000 之间的数字"
                            return
                        }
                        writer.setToday(n)
                    } label: {
                        HStack {
                            Spacer()
                            Text(writer.busy ? "写入中…" : "写入今天")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(writer.busy || !writer.authorized)

                    Button("清除本 App 今天写入的数据", role: .destructive) {
                        writer.deleteTodaySamples()
                    }
                }

                Section("说明") {
                    Text("写入后打开微信运动 → 下拉刷新，通常 1–3 分钟显示新步数。")
                        .font(.footnote)
                    Text("HealthKit 是累加的，本 App 只写入「目标 − 已有」的差值，不会重复叠加。")
                        .font(.footnote)
                    Text("超过 60000 步容易被判异常，建议 20000–35000。")
                        .font(.footnote)
                }

                if !writer.message.isEmpty {
                    Section("结果") {
                        Text(writer.message).font(.callout)
                    }
                }
            }
            .navigationTitle("步数写入")
            .onAppear {
                writer.requestAuth()
                writer.refreshTotal()
            }
        }
    }
}

#Preview {
    ContentView()
}
