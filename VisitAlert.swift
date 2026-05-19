import SwiftUI
import MapKit //GoogleMap的な　有料のライブラリ
import CoreLocation
import RealmSwift
import Combine
 
// 訪問ラーメン登録ビュー
struct VisitAlert: View {
 
    // 感想テキスト
    @Binding var isimpress: String

    // 評価
    @Binding var evaluate: Double

    // Alert表示管理
    @Binding var isvisitalert: Bool

    // ラーメンジャンル
    @Binding var genre: RamenGenre

    // TextEditorがフォーカス中か否か
    @FocusState private var isFocused: Bool

    // Picker用 
    var valuelist = [0.0,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0]
 
    var onSave: () -> Void
    
    var body: some View {
        

            
            
            ScrollView{
             
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
                        
                        // - 評価 
                     
                        VStack(spacing: 10) {
                            Text("あなたの評価")
                                .font(.caption)
                                .foregroundColor(.gray)

                         //星 + 数値
                         
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
                        
                        // ===== ジャンル（追加） =====   
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ジャンル")
                                .font(.caption)
                                .foregroundColor(.gray)

                         // 3列Grid
                         
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                                               ], spacing: 8) {
                                                   
                                                   ForEach(RamenGenre.allCases, id: \.self) { item in // enum 全列挙
                                                       Button {
                                                        // ジャンル変更
                                                           genre = item
                                                        
                                                       } label: {
                                                           Text(item.rawValue)
                                                           
                                                               .font(.caption)
                                                               .padding(.vertical, 8)
                                                               .frame(maxWidth: .infinity)
                                                               .background(
                                                                Group {
                                                                    if genre == item { // 選択中
                                                                        LinearGradient(
                                                                            colors: [Color.orange, Color.red],
                                                                            startPoint: .leading,
                                                                            endPoint: .trailing
                                                                        )
                                                                    } else {
                                                                        Color.gray.opacity(0.15)
                                                                    }
                                                                }
                                                                
                                                               )
                                                               .foregroundColor(genre == item ? .white : .primary)
                                                               .cornerRadius(10)
                                                       }
                                                   }
                                               }
                        }
                        
                        // - 感想入力
                     
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
                        
                        // ボタン群
                     
                        HStack(spacing: 12) {

                         // キャンセル
                            Button("キャンセル") {
                                isvisitalert = false
                            }
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(12)

                         // 保存
                            Button(action: {
                             
                             // タップ時の振動 (AI考案)
                             
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                        
                    }
                    
                    .contentShape(Rectangle()) // VStack余白もタップ可能にする
                 
                 // 背景タップでキーボード閉じる
                    .onTapGesture{
                        isFocused = false
                    }
                    
                }
                
                .padding(18)
                .padding(.horizontal, 15)
                .transition(.scale)
            }
            
        }

    
}
