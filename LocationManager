//
//  LocationManager.swift
//  ramen
//
//  Created by user on 2025/12/19.
//
import CoreLocation//GPSを扱う
import MapKit
import SwiftUI

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {//ObservableObjectはPublishedを使うため CLLocationMangereDelegateは受け取れたかの通知を受け取る役を作る
    
    private let manager = CLLocationManager()//位置情報を扱うクラス/プロトコル
    
    @Published var didSetInitialRegion = false// SwiftUIに通知するフラグ（初回取得済みか）
    
    //@Published var region: MKCoordinateRegion?// 地図の表示領域（SwiftUIにバインドされる） 初期化
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )

    
    override init() {
        super.init()//NSObjectの初期設定
        manager.delegate = self//managerの取得情報とこのクラスインスタンスの橋渡し delegate登録
        manager.desiredAccuracy = kCLLocationAccuracyBest//精度の決定
        manager.requestWhenInUseAuthorization()//位置情報許可リクエスト  
        manager.startUpdatingLocation()//位置情報の取得開始 (非同期) 
    }
    
    //位置情報が取得 => CoreLocation => locationManagerを呼ぶ

    func requestLocation() {
            manager.requestLocation()// 手動で1回だけ位置取得したいとき
        }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }// 最新の現在位置を取得
        didSetInitialRegion = true// 初回取得フラグ
        
        region = MKCoordinateRegion( center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02) )//取得した地図の表示領域
        manager.stopUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {//位置情報取得失敗
            print(error)
        }

    func startUpdatingLocation() {// 外から更新再開したいとき用
        manager.startUpdatingLocation()
    }
    
}



