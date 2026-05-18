import SwiftUI
import MapKit //GoogleMap的な　有料のライブラリ
import CoreLocation
import RealmSwift
import Combine
 
// 訪問ラーメン登録ビュー

struct VisitAlert: View {
    @Binding var isimpress: String
    @Binding var evaluate: Double
    @Binding var isvisitalert: Bool
    @Binding var genre: RamenGenre   // ←追加
    @FocusState private var isFocused: Bool //キーボードフォーカス用 //FocusState型をviewにわたし紐づけることで、フォーカス管理ができる　入力中だと勝手にtrueになったり、falseだとviewが戻ったり
    
    

    
    var valuelist = [0.0,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0]
    var onSave: () -> Void
    
    var body: some View {
        

            
            
            ScrollView{//こいつ自体も縦スクロールを検知しているから さらにonTapGesture監視する余裕はない
                VStack{
                    VStack(spacing: 18) {
                        
                        // ===== ヘッダー =====
                        HStack {
                            Text("レビューを書く")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                isvisitalert = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        
                        // ===== 評価 =====
                        VStack(spacing: 10) {
                            Text("あなたの評価")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                
                                Text("\(evaluate, specifier: "%.1f")")
                                    .font(.title3)
                                    .bold()
                            }
                            
                            Picker("", selection: $evaluate) {
                                ForEach(valuelist, id: \.self) { value in
                                    Text(String(value)).tag(value)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // ===== ジャンル（追加） =====      普通のPicker嫌だからAIに頼んだ　機能は一緒
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ジャンル")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: [//Viewにたて3つで並べる　Grid設定
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())//アイテムをForEachで並べるだけで勝手に3個ずつになる
                                               ], spacing: 8) {
                                                   
                                                   ForEach(RamenGenre.allCases, id: \.self) { item in //.allCases でenum列挙
                                                       Button {
                                                           genre = item
                                                       } label: {
                                                           Text(item.rawValue)//.enumの表示文字 変数 -> 文字String
                                                           
                                                               .font(.caption)//ここから
                                                               .padding(.vertical, 8)
                                                               .frame(maxWidth: .infinity)//横幅を自由に任せる
                                                               .background(
                                                                Group {//方が異なるもものを同じっぽく扱わせる  LinearGradient  Color
                                                                    if genre == item {//それが選ばれているジャンルなら
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
                                                               .foregroundColor(genre == item ? .white : .primary) //ここまで装飾
                                                               .cornerRadius(10)
                                                       }
                                                   }
                                               }
                        }
                        
                        // ===== コメント =====
                        VStack(alignment: .leading, spacing: 8) {
                            Text("感想")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            ZStack(alignment: .topLeading) {
                                if isimpress.isEmpty {
                                    Text("美味しさや雰囲気などを書こう...")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(10)
                                }
                                
                                TextEditor(text: $isimpress)
                                    .focused($isFocused)//フォーカスされたらisFocused = True
                                    .frame(height: 120)
                                    .padding(6)
                            }
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(12)
                        }
                        
                        // ===== ボタン =====
                        HStack(spacing: 12) {
                            
                            Button("キャンセル") {
                                isvisitalert = false
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(12)
                            
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()//なんじゃこれ？
                                //print("evaluate:", evaluate)
                                onSave()
                                isvisitalert = false
                            }) {
                                Text("保存")
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.orange, Color.red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                    }//これ全体のVStack
                    
                    .contentShape(Rectangle()) //このビュー全体をタップ対象にする　<-  こうしないとVStackの中の中身のある部分(ビュー)だけタップ対象だから余白タップできない
                    .onTapGesture{//   今までならdismissKeyBoard呼び出して　無理やりfocusを剥がしていたけど　関数じゃなくて　変数で管理できる　FocusState型作って、focusビューに入れておけば
                        isFocused = false
                    }
                    
                }
                
                .padding(18)
                .padding(.horizontal, 15)
                .transition(.scale)
            }
            
        }

    
}
