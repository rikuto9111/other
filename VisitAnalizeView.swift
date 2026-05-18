import SwiftUI
import MapKit //GoogleMap的な　有料のライブラリ
import CoreLocation
import RealmSwift

import Charts//グラフ用

// 分析ビュー

struct VisitAnalizeView: View {
    
    
    @Binding var isvisitanalize:Bool
    //let dateFormatter = DateFormatter()
    
    
    
    @State var visitcount = 0 //総訪問回数
    
    
    @State var visitshopcount = 0//総訪問店数
    
    @ObservedResults(VRamenDatabase.self) var visitramendatabase
    
    @ObservedResults(UserInfo.self) var userinfo
    
    @State var level = 0//これはRealmに自分データを保存しておくことにしてそこから取り出すわ
    
    
    @State var progress = 0.0
    //必要なのは自分のそう訪問数 - 今のレベル のそう訪問数で　あとどれくらいか決まる
    
    //@State var visit_exp_now = 0
    
    @State var selectedYear = 2026
    @State var selectedMonth = 4
    /*
     var required:Double{//そのレベルでの必要な経験値(訪問数)
     let progress = Double(self.level) / 100.0
     return 10000 * progress * progress
     }
     */
    
    
    
    
    var monthlyList: Int {//monthlyList.countでしか使ってないのやば
        //let calender = Calender.current//現在の月
        visitramendatabase.filter {
            Calendar.current.component(.year, from: $0.visitAt) == selectedYear &&
            Calendar.current.component(.month, from: $0.visitAt) == selectedMonth
        }//選択した
        .reduce(0) { $0 + $1.visitnumber }
    }

    
    @State var res = 0
    @State var rankingnavigation = false

    
    var totalEvaluate: Double {//計算用 O(N)
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

                             // ======================
                             // HEADER
                             // ======================
                             Text("訪問データ")
                                 .font(.title2.bold())
                                 .padding(.top, 8)

                             // ======================
                             // LEVEL CARD
                             // ======================
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

                             // ======================
                             // STATS
                             // ======================
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

                             // ======================
                             // GENRE CHART（カード化）
                             // ======================
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

                             // ======================
                             // FILTER CARD
                             // ======================
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
                             

                             // ======================
                             // MONTH RESULT
                             // ======================
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

                             // ======================
                             // ACTIONS
                             // ======================
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
                         
                         if let userinf = userinfo.first{
                             level = userinf.level//今の自分のレベルを取り出す
                             
                             
                             visitshopcount = visitramendatabase.count//総訪問店数
                             
                             visitcount = visitramendatabase.map { $0.visitnumber }.reduce(0, +)//再訪含めてカウントしている　訪問回数
                             //visit_exp_now = 全層訪問数 - Required(level:)の自分のレベルまでの累積経験値を計算したもの 意外と時間がかかるのかもしれない だったらいっそ保存しておこう
                             
                             var visit_exp_now = visitcount - userinf.lastExp//最後の訪問数
                             
                             //var base = max(userinf.lastExp - Int(RequiredExp(level: level-1)),0)//今現在のそのレベルの途中経験値
                             //始め以外
                             
                             
                             //ここからレベル計算
                             var base = userinf.resExp//最初のbase
                             
                             if visit_exp_now + base >= Int(RequiredExp(level: level)){
                                 
                                 while visit_exp_now + base >= Int(RequiredExp(level: level)){
                                     for i in base...Int(RequiredExp(level: level)){
                                         DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02){
                                             progress = Double(i) / Double(RequiredExp(level: level))
                                         }
                                         
                                         print(progress)
                                     }
                                     level += 1
                                     
                                     visit_exp_now -= Int(RequiredExp(level: level)) - base//レベルアップしたらそこで使用したぶん消費
                                     base = 0//レベルアップしたらbase = 0
                                     print(level)
                                     
                                 }//この時点で0<=visit_exp_now<=Required
                                 
                                 
                                 
                                 for i in base...base + visit_exp_now{
                                     DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02){
                                         progress = Double(i) / Double(RequiredExp(level: level))
                                         print(508)
                                     }
                                     
                                 }
                                 base = visit_exp_now//残り
                             }
                             else{
                                 print(base)
                                 print(visit_exp_now)
                                 for i in base...min(Int(RequiredExp(level: level)),base + visit_exp_now){
                                     DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02){
                                         progress = Double(i) / Double(RequiredExp(level: level))
                                         print(508)
                                     }
                                     
                                     
                                     print(progress)
                                 }
                                 base += visit_exp_now//ベース変更
                                 
                                 
                             }
                             
                             let realm = try! Realm()//一旦画面表示のたびにrealm触ることになるけど暫定
                             if let user = realm.objects(UserInfo.self).first {
                                 try! realm.write{
                                     user.level = level
                                     user.lastExp = visitcount
                                     user.resExp = base
                                 }//userinfは本物のものじゃないからダメ
                             }
                             
                             res = RequiredExp(level: level) - base
                             
                             //ここまで
                             
                             
                             ramengenrecount = [:]
                             
                             //ここからジャンルごとの訪問数集計処理
                             for ramen in visitramendatabase{
                                 if let genreCount = ramengenrecount[ramen.genre]{//ここで保証するのはgenreCountの存在 ramengenrecount[ramen.genre]にアクセスしても保証されてない   pythonとの違い pythonだとif ramengenrecount[ramen.genre]{}になるかな swiftではramengenrecountはアンラップしないと使えない
                                     ramengenrecount[ramen.genre] = genreCount + 1
                                 }
                                 else{
                                     ramengenrecount[ramen.genre] = 1
                                     
                                 }
                                 
                             }//ここまで
                             
                             
                         }
                 }
            }
        }
        
        }
    func RequiredExp(level: Int) -> Int {
        if level >= 0{
            let t = Double(level) / 100.0
            return Int(5 + 295 * pow(t, 3))
        }
        else{
            return 1
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
