import Foundation
import UIKit
import Moya

public enum Imgur {
  // 1 클라이언트 아이디 저장
  static private let clientId = "4c6fdd72f91c509"
  
  // 2 사용할 두개의 끝점을 정의
  case upload(UIImage)
  case delete(String)
}

extension Imgur: TargetType {
  // 1 베이스 api설정
  public var baseURL: URL {
    return URL(string: "https://api.imgur.com/3")!
  }
  // 2 케이스 기반인 적절한 끝점인 path를 반환
  public var path: String {
    switch self {
    case .upload: return "/image"
    case .delete(let deletehash): return "/image/\(deletehash)"
    }
  }
  // 3 이 메소드는 케이스에 따라서 다르다.
  public var method: Moya.Method {
    switch self {
    // 업로드는 포스트
    case .upload: return .post
    // delete는 델리트 처리 그대로
    case .delete: return .delete
    }
  }
  // 4 샘플 데이타에대해 빈 구조체를 반환
  public var sampleData: Data {
    return Data()
  }
  // 5 모든 끝점에 대해서 task를 반환
  public var task: Task {
    switch self {
    case .upload(let image):
      let imageData = image.jpegData(compressionQuality: 1.0)!
      return .uploadMultipart([MultipartFormData(provider: .data(imageData),
                                                 name: "image",
                                                 fileName: "card.jpg",
                                                 mimeType: "image/jpg")])
    case .delete:
      return .requestPlain
    }
  }
  // 6 mavel api 와 같이 헤더 속성은 추가적인 헤더를 반환 여기서 클라이언트 아이디를 제공하는 것이 중요
  public var headers: [String : String]? {
    return [
      "Authorization": "Client-ID \(Imgur.clientId)",
      "Content-Type": "application/json"
    ]
  }
  // 7 상태코드를 위한 유효성 검사
  public var validationType: ValidationType {
    return .successCodes
  }
}
