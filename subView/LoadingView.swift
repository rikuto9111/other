import SwiftUI
import MapKit // 地図（GoogleMap的なもの。Apple純正）
import CoreLocation
import RealmSwift

struct LoadingView: View {
    var body: some View {
        ZStack{
            Color(red:1.0,green: 0.9529,blue: 0.81176)
                .ignoresSafeArea()
            
            Image("Image")
                .resizable()
                .frame(width: 300, height: 300)
            

        }
    }
}
