import SwiftUI
import MapKit
import CoreLocation
import RealmSwift
import Combine

final class HanteiViewModel: ObservableObject {

    // 総訪問数
    @Published var visitcount = 0

    // 都道府県ごとの訪問数
    @Published var displayPrefCount: [(String, Int)] = []

    // ジャンルごとの訪問数
    @Published var displaytypeCount: [String:Int] = [:]

    // 診断結果
    @Published var mytype = ""

    // 読み込み中か
    @Published var isLoading: Bool = true

    // 円グラフ用割合
    @Published var asari: Double = 0
    @Published var kotteri: Double = 0
    @Published var balance: Double = 0

    //　処理が重くなるのでバックグラウンドスレッドで行う
    
    func recalc(data: [VRamenDatabase]) {

        DispatchQueue.global(qos: .userInitiated).async {  //バックグラウンド

            // 都道府県ごとの訪問数
            var pref: [String:Int] = [:]

            // ジャンルごとの訪問数
            var type = [
                "あっさり系": 0,
                "こってり系": 0,
                "バランス系": 0
            ]

            // データ集計
            for r in data {

                // 都道府県集計
                pref[r.prefecture, default: 0] += 1

                // ジャンル分類
                switch r.genre {

                case "塩", "醤油":
                    type["あっさり系", default: 0] += 1

                case "二郎系", "家系", "豚骨":
                    type["こってり系", default: 0] += 1

                default:
                    type["バランス系", default: 0] += 1
                }
            }

            // 総訪問数
            let total = data.count

            // 都道府県ランキング
            let sortedPref = pref
                .sorted { $0.value > $1.value }

            // 上位2県の訪問数
            let topPrefCount = sortedPref
                .prefix(2)
                .map { $0.value }

            // ジャンル割合
            let a =
                Double(type["あっさり系"] ?? 0)
                / Double(max(total, 1))

            let k =
                Double(type["こってり系"] ?? 0)
                / Double(max(total, 1))

            let b =
                Double(type["バランス系"] ?? 0)
                / Double(max(total, 1))

            // タイプ判定
            let result = self.decideType(
                a: a,
                k: k,
                b: b,
                prefSorted: topPrefCount,
                total: total
            )

            //UI更新部分はmainスレッドで
            
            DispatchQueue.main.async {

                self.visitcount = total

                self.displayPrefCount = Array(sortedPref)

                self.displaytypeCount = type

                self.mytype = result

                // 円グラフ用割合
                self.asari = a
                self.kotteri = k
                self.balance = b

                self.isLoading = false
            }
        }
    }

    // ジャンル割合 + 地域集中度から  ラーメンタイプを判定
    func decideType(
        a: Double,
        k: Double,
        b: Double,
        prefSorted: [Int],
        total: Int
    ) -> String {

        guard total > 0 else {
            return "判定不可"
        }

        // 上位2県への集中度 85%を基準
        let concentration =
            Double(prefSorted.reduce(0, +))
            / Double(total)

        // あっさり系メイン
        if a >= 0.5 {

            return concentration >= 0.85
                ? "おしゃれ勢"
                : "まったり勢"
        }

        // こってり系メイン
        if k >= 0.5 {

            return concentration >= 0.85
                ? "地元ガチ勢"
                : "遠征ジャンキー"
        }

        // バランス系メイン
        if b >= 0.5 {

            return concentration >= 0.85
                ? "安定思考"
                : "ラーメントラベラー"
        }

        // それ以外
        return "究極のバランサー"
    }
}

struct HanteiView: View {

    // 戻る用
    @Environment(\.presentationMode)  var presentationMode

    // Realm監視
    @ObservedResults(VRamenDatabase.self) var visitramendatabase

    // ViewModel
    @StateObject var vm = HanteiViewModel()

    // タイプ一覧シート表示
    @State var isramentypeview = false

    var body: some View {

        ZStack {

            // 背景
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.3),
                    Color.yellow.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // ローディング中
            if vm.isLoading {

                VStack {

                    ProgressView()

                    Text("分析中...")
                        .foregroundColor(.gray)
                }

            } else {

                ScrollView {

                    VStack(spacing: 28) {

                        //  診断結果 
                        VStack(spacing: 10) {

                            Text("診断結果")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text(vm.mytype)
                                .font(
                                    .system(
                                        size: 34,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            // タイプ一覧表示
                            Button {

                                isramentypeview.toggle()

                            } label: {

                                Text("タイプ一覧を見る")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Color.orange.opacity(0.15)
                                    )
                                    .cornerRadius(10)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)

                        // ===== 円グラフ =====
                        ZStack {

                            Circle()
                                .stroke(
                                    Color.gray.opacity(0.2),
                                    lineWidth: 20
                                )

                            // あっさり
                            Circle()
                                .trim(from: 0, to: vm.asari)
                                .stroke(
                                    Color.blue,
                                    style: StrokeStyle(
                                        lineWidth: 20,
                                        lineCap: .round
                                    )
                                )
                                .rotationEffect(.degrees(-90))

                            // こってり
                            Circle()
                                .trim(
                                    from: vm.asari,
                                    to: vm.asari + vm.kotteri
                                )
                                .stroke(
                                    Color.red,
                                    style: StrokeStyle(
                                        lineWidth: 20,
                                        lineCap: .round
                                    )
                                )
                                .rotationEffect(.degrees(-90))

                            // バランス
                            Circle()
                                .trim(
                                    from: vm.asari + vm.kotteri,
                                    to: 1
                                )
                                .stroke(
                                    Color.green,
                                    style: StrokeStyle(
                                        lineWidth: 20,
                                        lineCap: .round
                                    )
                                )
                                .rotationEffect(.degrees(-90))

                            VStack {

                                Text("訪問店数")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Text("\(vm.visitcount)")
                                    .font(.title)
                                    .bold()
                            }
                        }
                        .frame(width: 180, height: 180)

                        // ジャンル割合 
                        VStack(spacing: 14) {

                            ForEach(
                                Array(vm.displaytypeCount.keys),
                                id: \.self
                            ) { key in

                                HStack {

                                    Circle()
                                        .fill(color(for: key))
                                        .frame(width: 10, height: 10)

                                    Text(key)

                                    Spacer()

                                    let value =
                                        vm.displaytypeCount[key] ?? 0

                                    Text(
                                        "\(vm.visitcount == 0 ? 0 : value * 100 / vm.visitcount)%"
                                    )
                                    .bold()
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 5)

                        // 都道府県ランキング Top2 割合
                        VStack(alignment: .leading, spacing: 14) {

                            Text("よく行くエリア")
                                .font(.headline)

                            ForEach(
                                vm.displayPrefCount,
                                id: \.0
                            ) { item in

                                HStack {

                                    Text(item.0)

                                    Spacer()

                                    Text(
                                        "\(Int(Double(item.1) * 100 / Double(max(vm.visitcount,1))))%"
                                    )
                                    .foregroundColor(.orange)
                                }

                                ProgressView(
                                    value: Double(item.1),
                                    total: Double(max(vm.visitcount,1))
                                )
                                .tint(.orange)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                    }
                    .padding()
                }
            }
        }

        // 初回表示時
        .onAppear {

            vm.isLoading = true

            DispatchQueue.main.asyncAfter( //いきなり画面を切り替えずロード感を出す
                deadline: .now() + 0.2
            ) {

                vm.recalc(
                    data: Array(visitramendatabase)
                )

                vm.isLoading = false
            }
        }

        // タイプ一覧表示
        .sheet(isPresented: $isramentypeview) {

            RamenTypeView(
                isramentypeview: $isramentypeview
            )
        }
    }

    // ジャンル色
    func color(for key: String) -> Color {

        switch key {

        case "あっさり系":
            return .blue

        case "こってり系":
            return .red

        case "バランス系":
            return .green

        default:
            return .gray
        }
    }
}


 // スワイプ有効化

struct EnableSwipeBackGesture2:
UIViewControllerRepresentable {

    func makeUIViewController(
        context: Context
    ) -> UIViewController {

        let controller = UIViewController()

        DispatchQueue.main.async {

            controller.navigationController?
                .interactivePopGestureRecognizer?
                .delegate = nil
        }

        return controller
    }

    func updateUIViewController(
        _ uiViewController: UIViewController,
        context: Context
    ) {}
}


 // タイプ一覧画面
struct RamenTypeView: View {

    // タイプ一覧
    @State var typelist: [RamenType] = [

        RamenType(
            name: "まったり勢",
            description:
                "並ばず急がず遠出しない 喫茶店のようなゆるラーメンスタイル"
        ),

        RamenType(
            name: "おしゃれ勢",
            description:
                "インスタ映えもチェック! 新世代のラーメンスタイル"
        ),

        RamenType(
            name: "地元ガチ勢",
            description:
                "気に入ったお店へ通い詰める ガッツリラーメンスタイル"
        ),

        RamenType(
            name: "遠征ジャンキー",
            description:
                "好きなもののためならどこへでも 行動力の化身"
        ),

        RamenType(
            name: "安定思考",
            description:
                "冒険より安心 外さない一杯を求める堅実スタイル"
        ),

        RamenType(
            name: "ラーメントラベラー",
            description:
                "ラーメンと旅行はセット 土地ごとのラーメンを味わい尽くすスタイル"
        ),

        RamenType(
            name: "究極のバランサー",
            description:
                "満遍なくラーメンを食べる 究極のラーメン好き"
        )
    ]

    @Binding var isramentypeview: Bool

    var body: some View {

        ZStack {

            // 背景
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.25),
                    Color.yellow.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {

                Spacer()
                    .frame(height: 10)

                Text("タイプ一覧")
                    .font(.title)

                ScrollView {

                    ForEach(typelist) { type in

                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {

                            Text(type.name)
                                .font(.title3)
                                .bold()
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text(type.description)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )
                        }
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(
                            color: .black.opacity(0.08),
                            radius: 5,
                            x: 0,
                            y: 3
                        )
                        .padding(.horizontal)
                    }

                    .padding(.vertical)
                }
            }
        }
    }
}


 //ラーメンタイプモデル

struct RamenType: Identifiable {

    let id = UUID()

    let name: String

    let description: String
}
