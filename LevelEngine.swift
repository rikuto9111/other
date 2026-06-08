import SwiftUI
import MapKit
import CoreLocation
import RealmSwift

// -- レベル計算まわりのロジック
------------------------------

struct LevelEngine {

    // レベルが上がるほど必要経験値が増えるようにしてる
    // 単純な線形じゃなくて、ちょっと重くなる感じ    /*最初のうちはレベルが上がりやすく、だんだんレベルを上がりづらくする　やり込み要素というか飽きさせない*/
    static func requiredExp(level: Int) -> Int {
        if level >= 0 {
            let t = Double(level) / 100.0
            return Int(5 + 295 * pow(t, 3))
        } else {
            return 1
        }
    }

    // レベル計算の結果まとめる用
    struct Result {
        let level: Int
        let baseExp: Int
    }

    // メインのレベル更新処理
    // visitCount（ラーメン食べた回数みたいなやつ）を元に経験値を計算してる
  
    static func calculate(
        level: Int,
        lastExp: Int,
        resExp: Int,
        visitCount: Int
    ) -> Result {

        var level = level

        // 今回どれくらい増えたか
        let visit_exp_now = visitCount - lastExp

        // もともとの経験値
        var base = resExp

        // 合計経験値
        var tempExp = visit_exp_now + base

        let req = requiredExp(level: level)

        // レベルアップする場合
        if tempExp >= req {

            // 一気に複数レベル上がるケースもあるので while
            while visit_exp_now + base >= requiredExp(level: level) {

                let needExp = requiredExp(level: level)

                level += 1

                // レベルアップ分を引く（ここちょっとややこしい）
                visit_exp_now -= needExp - base

                base = 0
            }

            base = visit_exp_now
            return Result(level: level, baseExp: base)
        }

        // レベルが下がる or 変わらないとき
        else {

            // もしマイナスになってたら下のレベルに戻す
            if visit_exp_now < 0 {

                while tempExp < 0 && level >= 1 {
                    level -= 1
                    tempExp += requiredExp(level: level)
                }

                base = requiredExp(level: level)
            }

            base = tempExp

            return Result(level: level, baseExp: base)
        }
    }
}

// ユーザー情報（Realm）
=--------------------------------
final class UserRepository {

    private let realm = try! Realm()

    // ユーザー取得（基本1人前提）
    func fetchUser() -> UserInfo? {
        realm.objects(UserInfo.self).first
    }

    // 今までのラーメン訪問回数を全部合計
    func fetchVisitCount() -> Int {
        realm.objects(VRamenDatabase.self)
            .map { $0.visitnumber }
            .reduce(0, +)
    }

    // レベルとか経験値を保存
    func save(level: Int, lastExp: Int, resExp: Int) {
        guard let user = fetchUser() else { return }

        try! realm.write {
            user.level = level
            user.lastExp = lastExp
            user.resExp = resExp
        }
    }
}

// ViewModel（UIとロジックの橋渡し）
----------------------------------------------

final class LevelViewModel: ObservableObject {

    @Published var level: Int = 1
    @Published var progress: Double = 0
    @Published var res: Int = 0
    @Published var shougou: String = ""
    @Published var visitcount: Int = 0

    private let repo = UserRepository() // ユーザ情報

    // レベルごとの称号（なんとなく作ったやつ）
    func levelTitle(level: Int) -> String {
        switch level {
        case 0..<5: return "見習い"
        case 5..<15: return "常連"
        case 15..<30: return "探求者"
        case 30..<50: return "職人"
        default: return "覇者"
        }
    }

    // メイン更新処理
    func levelCheck() {

        guard let user = repo.fetchUser() else { return }

        let visitCount = repo.fetchVisitCount()

        let result = LevelEngine.calculate(
            level: user.level,
            lastExp: user.lastExp,
            resExp: user.resExp,
            visitCount: visitCount
        )

        // アニメーション付きでバー更新
        animateProgress(
            from: user.resExp,
            to: result.baseExp,
            level: result.level
        )

        level = result.level
        visitcount = visitCount

        // 次レベルまであとどれくらいか
        res = LevelEngine.requiredExp(level: level) - result.baseExp

        shougou = levelTitle(level: level)

        // DBに保存
        repo.save(
            level: level,
            lastExp: visitCount,
            resExp: result.baseExp
        )
    }

    // 進捗バーのアニメーション
    private func animateProgress(from: Int, to: Int, level: Int) {

        let req = LevelEngine.requiredExp(level: level)

        if from <= to {
            var step = 0
            for i in from...to {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.02) { // 進捗バーの更新に動きをつけるため
                    self.progress = Double(i) / Double(req)
                }
                step += 1
            }
        } else {
            var step = 0
            for i in stride(from: from - 1, through: to, by: -1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.02) {
                    self.progress = Double(i) / Double(req)
                }
                step += 1
            }
        }
    }
}
