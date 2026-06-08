import SwiftUI
import MapKit 
import CoreLocation
import RealmSwift
import Combine

// - 訪問リストビュー

/* 訪問リスト一覧*/

struct VisitList: View {

    var valuelist = [0.0,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0]

    @Binding var visitlistflag: Bool

    @ObservedResults(VRamenDatabase.self) var visitramendatabase

    let dateFormatter = DateFormatter()

    @Binding var selvramendata_latitude: Double
    @Binding var selvramendata_longitude: Double

    var onChoice: () -> Void

    @State var isAscending = false
    @State var selectGenres: Set<String> = []

    @State var isselectgenreview = false

    // - sorted data 
    var sortedList: [VRamenDatabase] {
        let filtered = Array(visitramendatabase.filter {
            selectGenres.isEmpty || selectGenres.contains($0.genre)
        })

        return isAscending
        ? filtered
        : filtered.sorted { $0.evaluate > $1.evaluate }
    }

    var body: some View {

        ZStack {
            
            Color.white  //これで白い面をつけることで透け透けにしない
            // ===== 背景 =====
            LinearGradient(
                colors: [Color.orange.opacity(0.55), Color.yellow.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {

                // ヘッダー
                HStack {

                    Text("🍜 訪問ログ")
                        .font(.title3)
                        .bold()

                    Spacer()

                // 評価値を元にリストを昇順　降順に並べる
                    
                    Button {
                        isAscending.toggle()
                    } label: {
                        Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                            .font(.caption)
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

              // ジャンル別フィルター
                
                HStack {

                    Button {
                        selectGenres.removeAll()

                        //ジャンル選択ビュー表示
                        
                        isselectgenreview.toggle()
                        
                    } label: {
                        Text("フィルター")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding(.horizontal)

                // リスト 
                ScrollView {

                    VStack(spacing: 12) {

                        ForEach(sortedList) { visitramen in

                        // リストの訪問店を選択 => 選択したお店の座標を取得 => Mapの移動
                                             
                            Button {
                                    
                                selvramendata_latitude = visitramen.latitude
                                selvramendata_longitude = visitramen.longitude
                                onChoice()

                            } label: {
                                
                        // 店名, 自己評価, 訪問日, 都道府県, ジャンル情報

                                VStack(alignment: .leading, spacing: 10) {

                                    HStack {

                                        Text(visitramen.name)
                                            .font(.body)
                                            .bold()
                                            .lineLimit(1)

                                        Spacer()

                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)

                                            Text(String(format: "%.1f", visitramen.evaluate))
                                                .font(.caption)
                                                .bold()
                                        }
                                        .padding(6)
                                        .background(Color.yellow.opacity(0.15))
                                        .cornerRadius(8)
                                    }

                                    Text(dateFormatter.string(from: visitramen.visitAt))
                                        .font(.caption2)
                                        .foregroundColor(.gray)

                                    HStack(spacing: 6) {

                                        Text(visitramen.prefecture)
                                            .font(.caption2)
                                            .foregroundColor(.gray)

                                        Text("•")
                                            .foregroundColor(.gray)

                                        Text(visitramen.genre)
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(genreColor(genre: visitramen.genre))
                                            .cornerRadius(8)

                                        Spacer()
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                }

                // 閉じる
                Button {
                    visitlistflag = false
                } label: {
                    Text("閉じる")
                        .font(.caption)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.50))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
                .padding(.bottom, 10)

            }
            .padding(.top, 10)

            // フィルタービューの表示
            
            if isselectgenreview {
                SelectGenreView(
                    isselectgenreview: $isselectgenreview,
                    selectGenres: $selectGenres,
                    onSave: {}
                )
            }
        }
        .onAppear {
            dateFormatter.locale = Locale(identifier: "ja_JP")
            dateFormatter.dateFormat = "yyyy年MM月dd日"
        }
    }

    // お店のジャンルに合わせてUI表示する時 背景色をつける
    
    func genreColor(genre: String) -> Color {
        switch genre {
        case "醤油": return .brown
        case "味噌": return .yellow
        case "塩": return .blue.opacity(0.5)
        case "豚骨": return .purple.opacity(0.5)
        case "家系": return .red
        case "二郎系": return .green.opacity(0.5)
        case "つけ麺": return .pink.opacity(0.5)
        default: return .gray.opacity(0.5)
        }
    }
}





struct SelectGenreView: View {
    
    @Binding var isselectgenreview: Bool
    @Binding var selectGenres: Set<String>
    
    var onSave: () -> Void
    
    var body: some View {
        ZStack {
            // 背景
            
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // ===== ヘッダー =====
                VStack(spacing: 6) {
                    Text("ジャンル選択")
                        .font(.headline)
                    
                    Text("\(selectGenres.count)個選択中")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // ===== グリッド =====
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 12
                ) {
                    
                    ForEach(RamenGenre.allCases, id: \.self) { item in
                                                              
                        // ジャンル表示                                                

                        // ジャンルを選択  /*灰色 => 背景グラデーション UI変化を自然にする為 easeInOut*/
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                toggle(genre:item.rawValue)
                            }
                        }) {
                            Text(item.rawValue)
                                .font(.caption)
                                .padding(.vertical, 10)
                                
                                .frame(maxWidth: .infinity)
                                
                                .background(
                                    Group {
                                        if selectGenres.contains(item.rawValue) { 
                                            LinearGradient(//グラデーション背景
                                                colors: [Color.orange, Color.red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        } else {
                                            Color.gray.opacity(0.15)//無色
                                        }
                                    }
                                    
                                        )
                                
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .foregroundColor(
                                    selectGenres.contains(item.rawValue)
                                    ? .white
                                    : .primary
                                )
                            
                        }
                    }
                }
                
                // ===== 操作ボタン =====
                HStack {
                    Button("全解除") {
                        selectGenres.removeAll()
                    }
                    
                    Spacer()
                    
                    Button("適用") {
                        onSave()
                        isselectgenreview = false
                    }
                    .bold()
                }
                .padding(.top, 10)
                
            }
            .padding(20)
            
            .frame(width:320,height:350)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10)
            )
        }
        
    }
    
    // ===== トグル処理 =====
    func toggle(genre: String) {
        if selectGenres.contains(genre) {
            selectGenres.remove(genre)
        } else {
            selectGenres.insert(genre)
        }
    }
}
