//
//  LocationManager.swift
import CoreLocation

// 緯度・経度 → 都道府県・市区町村名に変換するヘルパークラス

class LocationHelper{
//非同期で座標から住所（県・市）を取得する

    static func getAreaName(latitude:Double,longitude:Double,completion:@escaping (String,String)-> Void){
    //緯度・経度,変換結果を受け取るクロージャーcompletion

        let location = CLLocation(latitude: latitude, longitude: longitude)// 緯度・経度をCoreLocation用の形式に変換
        let geocoder = CLGeocoder() //座標 → 住所変換を行うクラス
        geocoder.reverseGeocodeLocation(location){placemarks,error in //ジオコーディングの逆処理　 非同期
            if let place = placemarks?.first{
                let city = place.locality ?? "不明" // 市
                let prefecture = place.administrativeArea ?? "不明" // 県
                completion(prefecture,city) // 呼び出し元へ結果を返す
                
            }else{
                completion("不明","不明")
            }
            
        }
        
    }
}
