
//ランキングView


import SwiftUI
import CoreLocation
import RealmSwift

// 都道府県選択View

struct PrefectureSelectView: View {

    // PrefectureSelectViewの表示管理
    @Binding var selected: String

    // Sheetを閉じるための変数
    @Environment(\.dismiss) var dismiss

    // 都道府県一覧
    // String直書きは typo に弱いので、
    // 将来的には enum 化しても良い
 
    let list = [
        "全国",
        "北海道",
        "青森県",
        "岩手県",
        "宮城県",
        "秋田県",
        "山形県",
        "福島県",
        "茨城県",
        "栃木県",
        "群馬県",
        "埼玉県",
        "千葉県",
        "東京都",
        "神奈川県",
        "新潟県",
        "富山県",
        "石川県",
        "福井県",
        "山梨県",
        "長野県",
        "岐阜県",
        "静岡県",
        "愛知県",
        "三重県",
        "滋賀県",
        "京都府",
        "大阪府",
        "兵庫県",
        "奈良県",
        "和歌山県",
        "鳥取県",
        "島根県",
        "岡山県",
        "広島県",
        "山口県",
        "徳島県",
        "香川県",
        "愛媛県",
        "高知県",
        "福岡県",
        "佐賀県",
        "長崎県",
        "熊本県",
        "大分県",
        "宮崎県",
        "鹿児島県",
        "沖縄県"
    ]

    var body: some View {

        List(list, id: \.self) { pref in

            Button {

                // 選択した都道府県を親Viewへ返す
                selected = pref

                // 選択後にSheetを閉じる
                dismiss()

            } label: {
                Text(pref)
            }
        }
        .navigationTitle("都道府県")
    }
}

// ランキング計算用 ViewModel
// Viewと処理を分離するために作成

/*onChange + update() を struct 内でやっても、処理タイミング制御はできるので普通にアリ。
それでも ViewModel に分けるのは、「UI」と「データ処理（sort/filter/asyncなど）」を分離してコードを読みやすく・保守しやすくするため。
特に規模が大きくなると、View を「表示専用」に近づけた方が管理しやすい。
*/


final class RankingViewModel: ObservableObject {

    // フィルタ後のデータ
    @Published var filteredList: [VRamenDatabase] = []

    // 評価順にソート済みデータ
    @Published var sortedList: [VRamenDatabase] = []

    // 順位付きデータ
    // (rank: 順位, item: データ)
    @Published var rankedList: [(rank: Int, item: VRamenDatabase)] = []

    // 評価値合計
    @Published var totalEvaluate: Double = 0

    // 多重実行防止用
    private var isCalculating = false

    // データ更新処理
 
    func update(
        data: [VRamenDatabase],
        genre: String,
        pref: String
    ) {

        // 多重実行防止
        // ボタン連打などによるフリーズ回避
     
        guard !isCalculating else { return }

        isCalculating = true

        // 重い処理はバックグラウンドで実行

        DispatchQueue.global(qos: .userInitiated).async {

  
            // ジャンル・都道府県でフィルタリング
            let filtered = data.filter {

                (genre.isEmpty || $0.genre == genre) &&
                (pref == "全国" || $0.prefecture == pref)
            }
         
            // 評価順ソート(降順)

            let sorted = filtered.sorted {
                $0.evaluate > $1.evaluate
            }

            // 順位計算
            // 同点は同順位

            var ranked: [(Int, VRamenDatabase)] = []

            var rank = 0
            var last: Double?

            // 平均計算用
            var sum: Double = 0

            for item in sorted {

                // 評価値合計
                sum += item.evaluate

                // 前回と評価値が違えば順位を進める
                if item.evaluate != last {
                    rank += 1
                }

                // 現在値を保存
                last = item.evaluate

                // 順位付きで追加
                ranked.append((rank, item))
            }


            // UI更新はmainスレッドで
         
            DispatchQueue.main.async {

                self.filteredList = filtered
                self.sortedList = sorted
                self.rankedList = ranked
                self.totalEvaluate = sum

                self.isCalculating = false
            }
        }
    }
}

// ランキング画面

struct RankingView: View {

    // 戻る操作用
    @Environment(\.presentationMode) var presentationMode

    // Realm(訪問済みラーメン店)のDB取得
    @ObservedResults(VRamenDatabase.self)  var visitramendatabase
 
    // ViewModel
    @StateObject var vm = RankingViewModel()

    // 選択ジャンル
    @State var selectgenre: String = ""

    // 選択都道府県
    @State var selectedPrefecture = "全国"

    // 都道府県選択Sheet管理
    @State var isPrefSheet = false

    // 日付表示用
    let dateFormatter = DateFormatter()


    var body: some View {

        ZStack {

            // 背景色
            Color(
                Color(
                    red: 0.97,
                    green: 0.92,
                    blue: 0.75,
                    opacity: 0.4
                )
            )
            .ignoresSafeArea()


            ScrollView {

                VStack(spacing: 18) {

                    VStack(spacing: 10) {

                        Text("ランキング")
                            .font(.title2.bold())

                        HStack(spacing: 20) {

                            // 件数
                            VStack {

                                Text("\(vm.sortedList.count)")
                                    .font(.title3.bold())

                                Text("件数")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }


                            // 平均評価
                            VStack {

                                Text(
                                    String(
                                        format: "%.2f",
                                        vm.sortedList.isEmpty
                                        ? 0
                                        : vm.totalEvaluate / Double(vm.sortedList.count)
                                    )
                                )
                                .font(.title3.bold())

                                Text("平均評価")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }


                            // エリア
                            VStack {

                                Text(selectedPrefecture)
                                    .font(.title3.bold())

                                Text("エリア")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 4
                    )
                    .padding(.horizontal)


                    // 都道府県選択ボタン
                 
                    Button {

                        isPrefSheet = true

                    } label: {

                        HStack {

                            Text(selectedPrefecture)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(
                            color: .black.opacity(0.05),
                            radius: 2
                        )
                    }
                    .padding(.horizontal)

                    // Sheet表示
                    .sheet(isPresented: $isPrefSheet) {

                        PrefectureSelectView(
                            selected: $selectedPrefecture
                        )
                    }



                    // ジャンル選択　横スクロール
                 
                    ScrollView(
                        .horizontal,
                        showsIndicators: false
                    ) {

                        HStack(spacing: 10) {

                            ForEach(
                                RamenGenre2.allCases,
                                id: \.self
                            ) { item in

                                Button {

                                    // 「全て」なら空文字
                                    selectgenre =
                                    (item.rawValue == "全て")
                                    ? ""
                                    : item.rawValue

                                } label: {

                                    Text(item.rawValue)
                                        .font(.caption)

                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 14)

                                        // 選択中のみグラデーション
                                        .background(
                                            Group {

                                                if selectgenre == item.rawValue {

                                                    LinearGradient(
                                                        colors: [.orange, .red],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )

                                                } else {

                                                    Color.gray.opacity(0.12)
                                                }
                                            }
                                        )

                                        .foregroundColor(.primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }


                    // ランキング一覧

                    VStack(spacing: 12) {

                        ForEach(
                            vm.rankedList,
                            id: \.item.id
                        ) { data in

                            VStack(
                                alignment: .leading,
                                spacing: 8
                            ) {

                                // 順位・評価・店名
 
                                HStack(spacing: 4) {

                                    // 1,2位だけ特別UI 
                                    if data.rank == 1 {

                                        Text("👑 1位")
                                            .font(.headline)

                                    } else if data.rank == 2 {

                                        Text("🥈 2位")
                                            .font(.headline)
                                    }


                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)

                                    Text(
                                        String(
                                            format: "%.1f",
                                            data.item.evaluate
                                        )
                                    )
                                    .bold()

                                    Spacer().frame(width: 6)

                                    Text(data.item.name)

                                    Spacer()
                                }

                                // 日付・地域・ジャンル
                             
                                HStack {

                                    Text(
                                        dateFormatter.string(
                                            from: data.item.visitAt
                                        )
                                    )
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                    Text(data.item.prefecture)
                                        .font(.caption)
                                        .foregroundColor(.gray)

                                    Spacer().frame(width: 60)

                                    Text(data.item.genre)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(4)
                                        .background(
                                            .gray.opacity(0.3)
                                        )
                                        .cornerRadius(5)
                                }
                            }
                            .padding(14)

                            // 背景
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                            )

                            // 1,2くらいだけ枠の色を変える
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        data.rank > 2
                                        ? Color.white
                                        : data.rank == 2
                                        ? Color.gray.opacity(0.5)
                                        : Color.yellow.opacity(0.5),

                                        lineWidth: 3
                                    )
                            )

                            .shadow(
                                color: .black.opacity(0.05),
                                radius: 3
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }

        // 初回表示時

        .onAppear {

            // 日付フォーマット設定
            dateFormatter.locale = Locale(identifier: "ja_JP")
            dateFormatter.dateFormat = "yyyy年MM月dd日"

            // 初回データ計算
            vm.update(
                data: Array(visitramendatabase),
                genre: selectgenre,
                pref: selectedPrefecture
            )
        }


        // ジャンル変更時
        .onChange(of: selectgenre) { _ in

            vm.update(
                data: Array(visitramendatabase),
                genre: selectgenre,
                pref: selectedPrefecture
            )
        }

        // 都道府県変更時
        .onChange(of: selectedPrefecture) { _ in

            vm.update(
                data: Array(visitramendatabase),
                genre: selectgenre,
                pref: selectedPrefecture
            )
        }
    }
}


// スワイプ戻るの有効化
struct EnableSwipeBackGesture: UIViewControllerRepresentable {

    func makeUIViewController(
        context: Context
    ) -> UIViewController {

        let controller = UIViewController()

        DispatchQueue.main.async {

            controller
                .navigationController?
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








