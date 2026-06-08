import SwiftUI
import MapKit // Apple純正の地図ライブラリ
import CoreLocation
import RealmSwift
import Charts // グラフ描画用

// - 分析画面

struct VisitAnalizeView: View {

    // 親Viewから渡される分析表示管理
    
    @Binding var isvisitanalize: Bool

    // 総訪問回数
    @State var visitcount = 0

    // 総訪問店舗数
    @State var visitshopcount = 0

    // Realmから取得
    @ObservedResults(VRamenDatabase.self) var visitramendatabase
    @ObservedResults(UserInfo.self) var userinfo

    // 現在レベル
    @State var level = 0

    // ProgressView用
    @State var progress = 0.0

    // 選択中の年/月
    @State var selectedYear = 2026
    @State var selectedMonth = 4

    // ランキング画面遷移用
    @State var rankingnavigation = false

    // 次レベルまで必要な残り経験値
    @State var res = 0

    // ジャンル別集計
    @State var ramengenrecount: [String: Int] = [:]

    // - 月ごとの訪問数

    // computed var
    
    var monthlyList: Int {
        
        // 指定した年/月の訪問店データだけ抽出
        
        visitramendatabase.filter { //O(N)

            Calendar.current.component(.year, from: $0.visitAt) == selectedYear &&
            Calendar.current.component(.month, from: $0.visitAt) == selectedMonth
        }

        // visitnumberを合計
        .reduce(0) { $0 + $1.visitnumber }
    }

    // - 総評価値
    
    var totalEvaluate: Double {

        // 全店舗の評価値合計
        visitramendatabase.reduce(0) { $0 + $1.evaluate }
    }
    
    @State var ramengenrecount: [String: Int] = [:]  //ラーメンのジャンルごとのcount
    
    
    var body: some View {
        NavigationStack {

                NavigationLink(
                    destination: RankingView(), isActive: $rankingnavigation
                ) {
                    
                }
                .navigationBarBackButtonHidden(true)
                
            
                 ZStack {
                     Color(red: 0.97, green: 0.92, blue: 0.75)
                         .ignoresSafeArea()

                     ScrollView {
                         VStack(spacing: 20) {

                             // ヘッダー
                             Text("訪問データ")
                                 .font(.title2.bold())
                                 .padding(.top, 8)

                             // - レベル UI 
                             
                             VStack(spacing: 12) {

                                 HStack {
                                     VStack(alignment: .leading, spacing: 4) {
                                         Text("LEVEL")
                                             .font(.caption)
                                             .foregroundColor(.gray)

                                         Text("Lv \(level)")
                                             .font(.largeTitle.bold())
                                     }

                                     Spacer()

                                     VStack(alignment: .trailing, spacing: 4) {
                                         Text("NEXT")
                                             .font(.caption)
                                             .foregroundColor(.gray)

                                         Text("\(res)")
                                             .font(.headline)
                                     }
                                 }

                                 ProgressView(value: progress)
                                     .tint(.orange)
                             }
                             .padding(18)
                             .background(Color.white)
                             .cornerRadius(18)
                             .shadow(color: .black.opacity(0.05), radius: 5)
                             .padding(.horizontal)

                             // - 基本統計
                             
                             HStack(spacing: 12) {
                                 statCard(title: "総訪問回数", value: "\(visitcount)")

                                 statCard(
                                     title: "平均評価",
                                     value: visitcount > 0
                                     ? String(format: "%.2f", Double(totalEvaluate)/Double(visitshopcount))
                                     : "-"
                                 )
                             }
                             .padding(.horizontal)

                             // - ジャンル円グラフ
                             
                             VStack(alignment: .leading, spacing: 12) {

                                 Text("ジャンル割合")
                                     .font(.headline)

                                 Chart {
                                     ForEach(
                                         ramengenrecount.sorted(by: { $0.value > $1.value }),
                                         id: \.key
                                     ) { key, value in

                                         let percent = Double(value) / Double(max(visitshopcount, 1)) * 100

                                         SectorMark(
                                             angle: .value("Count", value),
                                             angularInset: 1.5
                                         )
                                         .foregroundStyle(by: .value("Genre", key))
                                         .annotation(position: .overlay) {
                                             if percent > 10 {
                                                 Text("\(Int(percent))%")
                                                     .font(.caption2.bold())
                                             }
                                         }
                                     }
                                 }
                                 .frame(height: 260)

                             }
                             .padding(18)
                             .background(Color.white)
                             .cornerRadius(18)
                             .shadow(color: .black.opacity(0.05), radius: 5)
                             .padding(.horizontal)

                             // - 年/月フィルター
                             
                             VStack(alignment: .leading, spacing: 16) {

                                 Text("TIME FILTER")
                                     .font(.caption)
                                     .foregroundColor(.gray)

                                 // 年
                                 Picker("年", selection: $selectedYear) {
                                     Text("2025年").tag(2025)
                                     Text("2026年").tag(2026)
                                     Text("2027年").tag(2027)
                                 }
                                 .pickerStyle(.segmented)

                                 // 月
                                 ScrollView(.horizontal, showsIndicators: false) {
                                     HStack(spacing: 10) {
                                         ForEach(1...12, id: \.self) { month in
                                             Text("\(month)月")
                                                 .font(.caption.bold())
                                                 .padding(.vertical, 8)
                                                 .padding(.horizontal, 12)
                                                 .background(
                                                     selectedMonth == month
                                                     ? Color.orange
                                                     : Color.gray.opacity(0.15)
                                                 )
                                                 .foregroundColor(
                                                     selectedMonth == month ? .white : .primary
                                                 )
                                                 .cornerRadius(12)
                                                 .onTapGesture {
                                                     selectedMonth = month
                                                 }
                                         }
                                     }
                                 }
                                 
                             }
                             .padding(.horizontal,15)
                             

                             // - 月別結果
                             
                             VStack(spacing: 8) {

                                 Text("\(String(selectedYear))年 \(selectedMonth)月")
                                     .font(.headline)

                                 Text("\(monthlyList) visits")
                                     .font(.title3.bold())
                                     .foregroundColor(.orange)
                             }
                             .padding(16)
                             .frame(maxWidth: .infinity)
                             .background(Color.white)
                             .cornerRadius(18)
                             .shadow(color: .black.opacity(0.05), radius: 5)
                             .padding(.horizontal)

                             // - ボタン群
                             
                             VStack(spacing: 10) {

                                 Button {
                                     isvisitanalize = false
                                 } label: {
                                     actionButton(label: "戻る", icon: "chevron.left")
                                 }

                                 Button {
                                     rankingnavigation = true
                                 } label: {
                                     actionButton(label: "ランキング", icon: "trophy.fill")
                                 }
                             }
                             .padding(.horizontal)

                             Spacer(minLength: 20)
                         }
                         .padding(.top, 8)
                     }
                     
                     .onAppear(){
                         
                            // 訪問数に応じてレベルチェック
                             levelCheck()

                          
                             ramengenrecount = [:]
                             
                             //ジャンルごとの訪問数集計処理
                             for ramen in visitramendatabase{
                                 if let genreCount = ramengenrecount[ramen.genre]{//ここで保証するのはgenreCountの存在 ramengenrecount[ramen.genre]にアクセスしても保証されてない   pythonとの違い pythonだとif ramengenrecount[ramen.genre]{}になるかな swiftではramengenrecountはアンラップしないと使えない
                                     ramengenrecount[ramen.genre] = genreCount + 1
                                 }
                                 else{
                                     ramengenrecount[ramen.genre] = 1
                                     
                                 }    
                             } 
                             
                         }
                 }
            }
        }
        
        }
    
//　レベルに対して　経験値計算
    func RequiredExp(level: Int) -> Int {
        if level >= 0{
            let t = Double(level) / 100.0
            return Int(5 + 295 * pow(t, 3))
        }
        else{
            return 1
        }
    }

// レベルの更新

    func levelCheck(){
        
        if let userinf = userinfo.first{

            level = userinf.level // 現在のレベル

        // 再訪回数含めて訪問回数取得

            visitcount = visitramendatabase.map { $0.visitnumber }.reduce(0, +)  // O(N)

        // 更新訪問数

            var visit_exp_now = visitcount - userinf.lastExp 

        //　そのレベルに対しての途中経験値

            var base = userinf.resExp 

        //  そのレベルに対して　途中経験値 + 更新分

            var tempExp = visit_exp_now + base

        // レベルup

            if tempExp >= Int(RequiredExp(level: level)){
                
                while visit_exp_now + base >= Int(RequiredExp(level: level)){
                    for i in base...Int(RequiredExp(level: level)){

                        // 他のUI更新変数とタイミングずらす

                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02){
                            progress = Double(i) / Double(RequiredExp(level: level))
                        }
                    }

                    level += 1

                    // 使用経験値分減算

                    visit_exp_now -= Int(RequiredExp(level: level)) - base

                    //レベルアップしたら途中経験値0

                    base = 0

                }//この時点で0<=visit_exp_now<=Required

            // 残り経験値
                for i in base...base + visit_exp_now{
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02){
                        progress = Double(i) / Double(RequiredExp(level: level))
                    }
                }
                base = visit_exp_now // 途中経験値
            }

            else{ // level down or stay

                if visit_exp_now >= 0{ //stay

                    for i in base...min(Int(RequiredExp(level: level)),tempExp){
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02){
                            progress = Double(i) / Double(RequiredExp(level: level))
                        }
                    }
                }
                else{ // down

                    while tempExp < 0{ // level down処理
                        level -= 1
                        tempExp += RequiredExp(level: level) // 下げたレベルでのtempExp
                        base = RequiredExp(level: level) // 途中経験値は下げたレベルでのbase
                    }

                    for i in stride(from: base - 1, through: base + visit_exp_now - 1, by: -1) {//基本は1ずつしか経験値は減らないし貯まらない
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02){
                            progress = Double(i) / Double(RequiredExp(level: level))
                        }
                    }

                }
                base += visit_exp_now //ベース変更
                
            }

        // - Realm保存 (ユーザ情報)

            let realm = try! Realm()
            if let user = realm.objects(UserInfo.self).first {
                try! realm.write{
                    user.level = level
                    user.lastExp = visitcount
                    user.resExp = base
                }
            }
            
            res = RequiredExp(level: level) - base

        }
    }
           
    
    @ViewBuilder
    func statCard(title: String, value: String) -> some View {
        
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title3.bold())
            
        }
        
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
    @ViewBuilder
    func actionButton(label: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(label)
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }
    
}
