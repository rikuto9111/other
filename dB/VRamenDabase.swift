//
//  LocationManager.swift
//  ramen
//
//  Created by user on 2025/12/19.
//
import RealmSwift
import Foundation

class VRamenDatabase:Object,Identifiable{// 訪問済みのラーメン店DB
    
    @Persisted(primaryKey: true) var id:ObjectId = ObjectId()
    
    @Persisted var name:String  //　店名
    @Persisted var rating:Double // Google評価
    @Persisted var latitude:Double // 座標
    @Persisted var longitude:Double
    @Persisted var isOpenNow:Bool  //　空いているか否か
    
    @Persisted var regularHours: List<String> // 営業時間
    
    @Persisted var isimpress:String // 感想
    @Persisted var evaluate:Double // 自己評価

    @Persisted var prefecture:String //　住所
    
    @Persisted var city:String
    
    @Persisted var visitAt:Date = Date() // 訪問日
    
    @Persisted var genre:String // ジャンル
    
    @Persisted var visitnumber:Int // 訪問回数
}
