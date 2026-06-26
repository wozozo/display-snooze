import Foundation

public enum DisplayServiceError: Error, Equatable {
    case discoveryFailed
    case beginConfigurationFailed
    case privateAPIFailed
    case completeConfigurationFailed
}

public enum UserDisplayError: String, Equatable {
    case discoveryFailed = "ディスプレイ一覧の取得に失敗した。"
    case snoozeFailed = "ディスプレイの Off に失敗した。"
    case wakeFailed = "ディスプレイの On に失敗した。"
    case restoreFailed = "終了時の復帰に失敗した。"
}
