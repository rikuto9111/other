//
//  LocationManager.swift
//  ramen
//
//  Created by user on 2025/12/19.
//
import RealmSwift
import Foundation

class UserInfo:Object,Identifiable{//ユーザ情報　　(名前、レベル、レベルアップまで残り訪問数など)
    
    @Persisted(primaryKey: true) var id:ObjectId
    
    
    @Persisted var name:String //後々使う予定

    @Persisted var level:Int  // レベル
    @Persisted var lastExp:Int //　現在の訪問数
    
    @Persisted var resExp:Int//　レベルアップまで残り経験値
    
    
}
