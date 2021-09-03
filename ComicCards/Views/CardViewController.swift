
import Foundation
import UIKit
import Kingfisher
import Moya

class CardViewController: UIViewController {
  // - MARK: - Dependencies
  private var comic: Comic?
  private let provider = MoyaProvider<Imgur>()
  private var uploadResult: UploadResult?
  //->모야 프로바이더 인스턴스 생성. 업로드 결과를 정의

  // - MARK: - Outlets
  @IBOutlet weak private var lblTitle: UILabel!
  @IBOutlet weak private var lblDesc: UILabel!
  @IBOutlet weak private var lblChars: UILabel!
  @IBOutlet weak private var lblDate: UILabel!
  @IBOutlet weak private var image: UIImageView!
  @IBOutlet weak private var card: UIView!
  @IBOutlet weak private var progressBar: UIProgressView!
  @IBOutlet weak private var viewUpload: UIView!

  @IBOutlet weak private var btnShare: UIButton!
  @IBOutlet weak private var btnDelete: UIButton!

  private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM dd, yyyy"

    return df
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    guard let comic = comic else { fatalError("Please pass in a valid Comic object") }

    layoutCard(comic: comic)
  }
}

// MARK: - Imgur handling
extension CardViewController {
  private func layoutCard(comic: Comic) {
    // 1 :만화의 타이틀과 설명을 설정
    lblTitle.text = comic.title
    lblDesc.text = comic.description ?? "Not available"
    
    // 2 :만화에 대한 캐릭터 목록을 설정
    if comic.characters.items.isEmpty {
      lblChars.text = "No characters"
    } else {
      lblChars.text = comic.characters.items
        .map { $0.name}
        .joined(separator: ",")
    }
    // 3 : 미리 구성된 dateformatter을 사용하여 만화의 onsale날짜를 설정
    lblDate.text = dateFormatter.string(from: comic.onsaleDate)
    
    // 4 : kingfisher 사용하여 만화의 이미지를 로딩
    image.kf.setImage(with: comic.thumbnail.url)

  }

  @IBAction private func uploadCard() {
    UIView.animate(withDuration: 0.15) {
      self.viewUpload.alpha = 1.0
      self.btnShare.alpha = 0.0
      self.btnDelete.alpha = 0.0
    }
    progressBar.progress = 0.0
    
    // 1 스크린에 보여지는 카드에서 스냅 카드라고 부르는 도우미 메소드를 사용하여 uiimage생성
    let card = snapCard()
    
    // 2 marvel api 같이 provider을 사용하여 카드 이미지와 관련된 값으로 업로드 끝점을 호출
    provider.request(.upload(card),
                     // 3 콜백큐는 다음 콜백에서 업로드 진행 상태 업데이트를 받을 대기열을 생성
                     callbackQueue: DispatchQueue.main,
                     // 4 이미지가 업로드 되어질때 호출되는 프로그래서 클로저를 정의
                     progress: { [weak self] progress in
                      self?.progressBar.setProgress(Float(progress.progress), animated: true)
                     },
                     completion: { [weak self] response in
                      guard let self = self else {return}
                      // 5 요청이 완료 되었을때 공유 버튼과 업로드 버튼을 블러 처리
                      UIView.animate(withDuration: 0.15) {
                        self.viewUpload.alpha = 0.0
                        self.btnShare.alpha = 0.0
                      }
                      // 6 성공 실패 옵션을 처리 성공 하면 imgurResponse에 맵핑하고 이전에 정의한 인스천스 속성에 맵핑한 응답을 저장.
                      switch response {
                      case .success(let result):
                        do {
                          let upload = try result.map(ImgurResponse<UploadResult>.self)
                          
                          self.uploadResult = upload.data
                          self.btnDelete.alpha = 1.0
                          
                          self.presentShare(image: card, url: upload.data.link)
                        } catch {
                          self.presentError()
                        }
                      case .failure:
                        self.presentError()
                      }
                     })
  }

  @IBAction private func deleteCard() {
    // 1 uploadResult를 사용할수 있는지 확인하고 삭제 버튼을 비활성화 시켜서 사용자가 다시 탭하지 않도록 하기.
    guard let uploadResult = uploadResult else { return }
    btnDelete.isEnabled = false
    
    // 2 imgurprovider을 사용하여업로드 결과의 deletehash 와 연관된 값으로 deletegate끝점에 호출
    provider.request(.delete(uploadResult.deletehash)) { [weak self] response in
      guard let self = self else {return}
      
      let message: String
      
      // 3 삭제가 성공또는 실패하면 적절한 메시지를 표시한다.
      switch response {
      case .success:
        message = "Deleted successfully!"
        self.btnDelete.alpha = 0.0
      case .failure:
        message = "Failed deleting card! Try again later."
        self.btnDelete.isEnabled = true
      }
      let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Done", style: .cancel))
      self.present(alert, animated: true, completion: nil)
    }
  }
}

// MARK: - Helpers
extension CardViewController {
  static func instantiate(comic: Comic) -> CardViewController {
    guard let vc = UIStoryboard(name: "Main", bundle: nil)
      .instantiateViewController(withIdentifier: "ComicViewController") as? CardViewController else { fatalError("Unexpectedly failed getting ComicViewController from Storyboard") }

    vc.comic = comic

    return vc
  }

  private func presentShare(image: UIImage, url: URL) {
    let alert = UIAlertController(title: "Your card is ready!", message: nil, preferredStyle: .actionSheet)

    let openAction = UIAlertAction(title: "Open in Imgur", style: .default) { _ in
      UIApplication.shared.open(url)
    }

    let shareAction = UIAlertAction(title: "Share", style: .default) { [weak self] _ in
      let share = UIActivityViewController(activityItems: ["Check out my iMarvel card!", url, image],
                                           applicationActivities: nil)
      share.excludedActivityTypes = [.airDrop, .addToReadingList]
      self?.present(share, animated: true, completion: nil)
    }

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

    alert.addAction(openAction)
    alert.addAction(shareAction)
    alert.addAction(cancelAction)

    present(alert, animated: true, completion: nil)
  }

  private func presentError() {
    let alert = UIAlertController(title: "Uh oh", message: "Something went wrong. Try again later.",
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    present(alert, animated: true, completion: nil)
  }

  private func snapCard() -> UIImage {
    UIGraphicsBeginImageContextWithOptions(card.bounds.size, true, UIScreen.main.scale)
    card.layer.render(in: UIGraphicsGetCurrentContext()!)
    guard let image = UIGraphicsGetImageFromCurrentImageContext() else { fatalError("Failed snapping card") }
    UIGraphicsEndImageContext()

    return image
  }
}
