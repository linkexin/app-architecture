import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UISlider {
	public var maximumValue: Binder<Float> {
		return Binder(self.base, binding: { slider, value in
			slider.maximumValue = value
		})
	}
}

class PlayViewController: UIViewController, UITextFieldDelegate {
	@IBOutlet var nameTextField: UITextField!
	@IBOutlet var playButton: UIButton!
	@IBOutlet var progressLabel: UILabel!
	@IBOutlet var durationLabel: UILabel!
	@IBOutlet var progressSlider: UISlider!
	@IBOutlet var noRecordingLabel: UILabel!
	@IBOutlet var activeItemElements: UIView!
	
	let viewModel = PlayViewModel()
	let disposeBag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// controller 将 view-model 暴露的接口和 view 绑定上
		viewModel.navigationTitle.bind(to: rx.title).disposed(by: disposeBag)
		viewModel.noRecording.bind(to: activeItemElements.rx.isHidden).disposed(by: disposeBag)
		viewModel.hasRecording.bind(to: noRecordingLabel.rx.isHidden).disposed(by: disposeBag)
		viewModel.timeLabelText.bind(to: progressLabel.rx.text).disposed(by: disposeBag)
		viewModel.durationLabelText.bind(to: durationLabel.rx.text).disposed(by: disposeBag)
		viewModel.sliderDuration.bind(to: progressSlider.rx.maximumValue).disposed(by: disposeBag)
		viewModel.sliderProgress.bind(to: progressSlider.rx.value).disposed(by: disposeBag)
		viewModel.playButtonTitle.bind(to: playButton.rx.title(for: .normal)).disposed(by: disposeBag)
		viewModel.nameText.bind(to: nameTextField.rx.text).disposed(by: disposeBag)
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		// view -> controller -> view-model
		viewModel.nameChanged(textField.text)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		// 不涉及 view-model 的更改
		textField.resignFirstResponder()
		return true
	}
	
	@IBAction func setProgress() {
		guard let s = progressSlider else { return }
		// 数据流向是单向的，view -> controller -> view-model -> view
		// 在这个方法中不应该直接去更改 view，而是去更改 view-model，再根据 view-model 的更改去更新 view
		// 其中 view-model -> view 在 viewdidload 中已经绑定上了
		viewModel.setProgress.onNext(TimeInterval(s.value))
	}
	
	@IBAction func play() {
		viewModel.togglePlay.onNext(())
	}
	
	// MARK: UIStateRestoring
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		coder.encode(viewModel.recording.value?.uuidPath, forKey: .uuidPathKey)
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		if let uuidPath = coder.decodeObject(forKey: .uuidPathKey) as? [UUID], let recording = Store.shared.item(atUUIDPath: uuidPath) as? Recording {
			self.viewModel.recording.value = recording
		}
	}
}

fileprivate extension String {
	static let uuidPathKey = "uuidPath"
}
