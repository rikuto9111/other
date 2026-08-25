//
//  ramenApp.swift
//  ramen
//
//  Created by user on 2025/12/12.
//

import SwiftUI
import RealmSwift

@main
struct ramenApp: App {
    @State private var isLoading = true
    init(){
        migrationRealm()
        
        
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoading {//2sくらいLoad画面にしておく
                        LoadingView()
                            .task {
                                try? await Task.sleep(for: .seconds(2))
                                isLoading = false
                            }
                    } else {
                        ContentView()
                    }
                }
    }
    
    func migrationRealm(){
        let config = Realm.Configuration(
            schemaVersion: 22,
            // deleteRealmIfMigrationNeeded: true
            
            
            //  Realm.Configuration.defaultConfiguration = config
            // 新しいスキーマバージョン
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 22
                {
                    
                    /*migration.enumerateObjects(ofType: VRamenDatabase.className()) { oldObject,newObject in //グループリスト情報の更新Grouplistclassnamemigrate
                        //newObject!["label"] = List<String>()
                        
                        if let oldDate = oldObject?["visitAt"] as? Date {
                            
                            newObject?["visitAt"] = [oldDate]
                            
                        }
                    }*/
                }
            }
        )
        
        
        Realm.Configuration.defaultConfiguration = config
        
       // Realm.Configuration.defaultConfiguration.deleteRealmIfMigrationNeeded = true//こいつのせいで古いバージョンは消される
        
    }
    
}
