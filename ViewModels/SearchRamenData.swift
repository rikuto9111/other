import MapKit
import SwiftUI
import RealmSwift

//  検索ボックスからクエリをもとに検索する　非同期クラス

@Observable
class SearchRamenData {

    // Places API のレスポンス構造
    struct ResultJson: Codable {

        struct Place: Codable {

            // 店名
            struct DisplayName: Codable {
                let text: String?
            }

            // 店舗座標
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

            // Google評価
            let rating: Double?

            // 店舗位置
            let location: Location?

            // 現在空いているか否か
            let currentOpeningHours: OpeningHours?

            // 通常営業時間
            let regularOpeningHours: OpeningHours?
        }

        // 検索結果一覧
        let places: [Place]?
    }

    // 検索結果
    // 値が変わるとSwiftUI側も更新される  Observableのため
    var ramenshops: [RamenShop] = []

    // 検索関数
    func fetch(
        latitude: Double,
        longitude: Double,
        text: String
    ) {

        // 非同期処理開始
        Task {

            // API検索
            let shops = await fetchInternal(
                latitude: latitude,
                longitude: longitude,
                text: text
            )

            // UI更新はMainActorで行う
            await MainActor.run {

                self.ramenshops = shops
            }
        }
    }

    
    private func fetchInternal( // 実際のPlaces API通信   非同期
        latitude: Double, 
        longitude: Double,
        text: String
    ) async -> [RamenShop] {

        // Places API URL
        guard let url = URL(
            string: "https://places.googleapis.com/v1/places:searchText"
        ) else {
            return []
        }

        // HTTPリクエスト生成
        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        // APIキー
        request.setValue(
            "AIzaSyD9V-EGiuEnL7vgd-m7iP7KmooyILUoxVU",
            forHTTPHeaderField: "X-Goog-Api-Key"
        )

        // 必要なデータだけ取得
        request.setValue(
            "places.displayName,places.rating,places.location,places.id,places.currentOpeningHours,places.regularOpeningHours",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        // APIへ送る検索条件　本文
        let body: [String: Any] = [

            // 検索ワード
            "textQuery": text,

            // 日本語指定
            "languageCode": "ja",

            // 現在地周辺を優先検索
            "locationBias": [
                "circle": [

                    "center": [
                        "latitude": latitude,
                        "longitude": longitude
                    ],

                    // 半径5000m   1500 => 5000m に変更
                    "radius": 5000
                ]
            ]
        ]

        do {

            // bodyJSON形式変換 追加
            request.httpBody = try JSONSerialization.data(
                withJSONObject: body
            )

            let (data, _) = try await URLSession.shared.data( //検索　非同期 終わるまで await
                for: request
            )

            let json = try JSONDecoder().decode(
                ResultJson.self,
                from: data
            )

            // 店舗一覧取得
            guard let places = json.places else {
                return []
            }

            // 返却用配列
            var newShops: [RamenShop] = []

            // 店舗ごとに変換
            for place in places {

                if let name = place.displayName?.text,
                   let location = place.location {

                    let ramenshop = RamenShop(

                        name: name,

                        rating: place.rating ?? 0,

                        coordinate: CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        ),

                        isOpenNow: place.currentOpeningHours?.openNow ?? false,

                        regularHours: place.regularOpeningHours?.weekdayDescriptions ?? [],

                        // 検索時点では未訪問扱い
                        isvisited: false,

                        vid: nil,

                        visitrating: nil
                    )

                    newShops.append(ramenshop)
                }
            }

            // 検索結果を返す
            return newShops

        } catch {

            // 通信失敗
            print("Places API error:", error)
        }

        // エラー時は空配列
        return []
    }
}
