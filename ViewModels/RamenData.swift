import MapKit
import SwiftUI
import RealmSwift

enum Config { // APIkeyのセット   APIKeys.plist を作成してください。

    static var googleAPIKey: String {

        guard let path = Bundle.main.path(
            forResource: "APIKeys",
            ofType: "plist"
        ),
        let dict = NSDictionary(contentsOfFile: path),
        let key = dict["GOOGLE_API_KEY"] as? String
        else {
            fatalError("API Key not found")
        }

        return key
    }
}

// 地図表示用のラーメン店モデル
struct RamenShop: Identifiable {

    let id = UUID()

    let name: String                  // 店名
    let rating: Double                // Google評価
    let coordinate: CLLocationCoordinate2D // 店舗座標（緯度経度）

    let isOpenNow: Bool               // 現在営業中か
    let regularHours: [String]?       // 通常営業時間

    let isvisited: Bool               // 訪問済みか
    let vid: ObjectId?                // 訪問済みデータID

    let visitrating: Double?          // 自分の評価
}

@Observable
class RamenData {

    // Places API のJSON構造
    struct ResultJson: Codable {

        struct Place: Codable {

            // 店名
            struct DisplayName: Codable {
                let text: String?
            }

            // 座標
            struct Location: Codable {
                let latitude: Double
                let longitude: Double
            }

            // 営業情報
            struct OpeningHours: Codable {
                let openNow: Bool?
                let weekdayDescriptions: [String]?
            }

            let displayName: DisplayName?
            let rating: Double?
            let location: Location?

            // 現在営業中か
            let currentOpeningHours: OpeningHours?

            // 通常営業時間
            let regularOpeningHours: OpeningHours?
        }

        // 検索結果一覧
        let places: [Place]?
    }

    // API取得結果（SwiftUI側が監視）
    var shops: [RamenShop] = []

    // 外部から呼ぶ入口
    func fetch(latitude: Double, longitude: Double) {

        // 非同期処理開始
        Task {
            await fetchInternal(
                latitude: latitude,
                longitude: longitude
            )
        }
    }

     //実際の検索処理

    @MainActor
    private func fetchInternal(  //  UI更新用のデータ（shops）はメインスレッドで安全に更新する
        latitude: Double,
        longitude: Double
    ) async {

        // Places API URL
        guard let url = URL(
            string: "https://places.googleapis.com/v1/places:searchText"
        ) else {
            return
        }
// HTTPリクエスト生成
        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        // APIキー   APIKeys.plist を作成してください。
        request.setValue(
            Config.googleAPIKey,
            forHTTPHeaderField: "X-Goog-Api-Key"
        )

        // 必要なフィールドだけ取得
        request.setValue(
            "places.displayName,places.rating,places.location,places.id,places.currentOpeningHours,places.regularOpeningHours",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        // リクエスト本文
        let body: [String: Any] = [

            // 検索ワード
            "textQuery": "ラーメン",

            // 日本語指定
            "languageCode": "ja",

            // 現在地周辺検索
            "locationBias": [
                "circle": [
                    "center": [
                        "latitude": latitude,
                        "longitude": longitude
                    ],

                    // 半径1500m
                    "radius": 1500
                ]
            ]
        ]


        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            //ここからが実際の検索
            
            let (data, _) = try await URLSession.shared.data(for: request)//通信完了まで非同期の中で待つ

            let json = try JSONDecoder().decode(ResultJson.self, from: data)

            guard let places = json.places else { return } // 店舗一覧取得

            shops.removeAll()

            for place in places {//一箇所ずつ取り出す
                if let name = place.displayName?.text,
                   let location = place.location {

                    let shop = RamenShop(
                        name: name,
                        rating: place.rating ?? 0,
                        coordinate: CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        ),
                        isOpenNow: place.currentOpeningHours?.openNow ?? false,
                        regularHours: place.regularOpeningHours?.weekdayDescriptions ?? [],

                        isvisited: false,//訪問済みでないからfalse
                        vid:nil, // nil
                        
                        visitrating: nil // 訪問済みでないため nil
                    )
                    shops.append(shop)
                }
            }

            addRamenshop(latitude:latitude,longitude:longitude)  // API節約用にローカル保存       一度取得した店舗情報を保存 毎回API通信しなくても済むようにする
        } catch {
            print("Places API error:", error)
        }
    }
    
    func addRamenshop(latitude:Double,longitude:Double){  //RamenDatabaseに保存
        
        do{
            let realm = try Realm()
            let ramendatabase = RamenDatabase()
            ramendatabase.id = ObjectId.generate()
            ramendatabase.longitude = longitude
            ramendatabase.latitude = latitude
            ramendatabase.timestamp = Date()
            
            
            if !shops.isEmpty{
                for shop in shops{
                    let ramendata = Ramendetails()
                    ramendata.id = ObjectId.generate()
                    ramendata.name = shop.name
                    ramendata.rating = shop.rating
                    ramendata.latitude = shop.coordinate.latitude
                    ramendata.longitude = shop.coordinate.longitude
                    ramendata.isOpenNow = shop.isOpenNow
                    ramendata.isvisited = shop.isvisited
                    
                    if let regularHours = shop.regularHours{
                        for hours in regularHours{
                            ramendata.regularHours.append(hours)
                        }
                    }

                    print("失敗")
                    ramendatabase.ramenshops.append(ramendata)
                }
            }
            else{
                print("失敗")
            }
            
            try realm.write{
                realm.add(ramendatabase)
            }
            
            
        }catch{
            print("error")
        }
        
    }
    
}

