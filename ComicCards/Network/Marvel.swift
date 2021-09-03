import Foundation
import Moya

public enum Marvel {
  // 1
  static private let publicKey = "007bf0f305c748862f07d679b1e24c81"
  static private let privateKey = "2b0ffe68daac75ef6625c5a3f5d19bd9fe2a4541"
  // 2
  case comics
}
//->api 서비스를 설명하는 간단한 열거형
//1, 공개키와 개인키
//2, 마블 api의 끝점

//->target을 설정

extension Marvel: TargetType {
  // 1 : 모든 타겟은 기초 url 이 필요
  public var baseURL: URL {
    return URL(string: "https://gateway.marvel.com/v1/public")!
  }
  // 2 : 도달하기 원하는 정확한 경로
  public var path: String {
    switch self {
      case .comics: return "/comics"
    }
  }
  // 3 : 정확한 http 메소드를 제공
  public var method: Moya.Method {
    switch self {
      case .comics: return .get
    }
  }
  // 4 : 중요한 속성 사용할 모든 끝점마다 열거형 케이스를 반환
  public var sampleData: Data {
    return Data()
  }
  // 5 : 테스트에 사용될 가짜객체
  public var task: Task {
    let ts = "\(Date().timeIntervalSince1970)"
      // 1
      let hash = (ts + Marvel.privateKey + Marvel.publicKey).md5
      
      // 2
      let authParams = ["apikey": Marvel.publicKey, "ts": ts, "hash": hash]
      
      switch self {
      case .comics:
        // 3
        return .requestParameters(
          parameters: [
            "format": "comic",
            "formatType": "comic",
            "orderBy": "-onsaleDate",
            "dateDescriptor": "lastWeek",
            "limit": 50] + authParams,
          encoding: URLEncoding.default)
      }
  }
  // 6 : 모든 타켓의 끝점을 위한 적절한 헤더를 반환하는 장소
  public var headers: [String : String]? {
    return ["Content-Type": "application/json"]
  }
  // 7 : 성공적인 api요청의 정의 제공하는데 사용.
  public var validationType: ValidationType {
    return .successCodes
  }
}

