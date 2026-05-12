//
//  LocationManager.swift
//  ramen
//
//  Created by user on 2025/12/19.
//
import RealmSwift
import Foundation//Date用

class RamenDatabase:Object,Identifiable{ //現在地周辺検索用のDB

    @Persisted(primaryKey: true) var id :ObjectId = ObjectId()

    @Persisted var latitude:Double = 0.0 //検索時の中心座標
    @Persisted var longitude:Double = 0.0
    
    @Persisted var timestamp: Date　//日付

    @Persisted var ramenshops : List<Ramendetails>  // 周辺のラーメン屋情報リスト
    
    
}

class Ramendetails:Object,Identifiable{// 周辺のラーメン屋情報リスト
    @Persisted(primaryKey: true) var id:ObjectId = ObjectId()
    
    @Persisted var name:String
    @Persisted var rating:Double
    @Persisted var latitude:Double
    @Persisted var longitude:Double
    @Persisted var isOpenNow:Bool
    
    @Persisted var regularHours: List<String>
    @Persisted var isvisited:Bool
}
