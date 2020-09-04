import Foundation
import RxSwift
import RxCocoa
import RxDataSources

class FolderViewModel {
	let folder: Variable<Folder>
	private let folderUntilDeleted: Observable<Folder?>
	
	init(initialFolder: Folder = Store.shared.rootFolder) {
		// 将 initialFolder 包装成「可观察量」
		folder = Variable(initialFolder)
		folderUntilDeleted = folder.asObservable() //观察 folder
			// Every time the folder changes
			.flatMapLatest { currentFolder in
				// Start by emitting the initial value
				Observable.just(currentFolder)
					// Re-emit the folder every time a non-delete change occurs
					.concat(currentFolder.changeObservable.map { _ in currentFolder })
					// Stop when a delete occurs
					.takeUntil(currentFolder.deletedObservable)
					// After a delete, set the current folder back to `nil`
					.concat(Observable.just(nil))
			}.share(replay: 1)
	}
	
	// controller 会调用的方法，因为上面观察了 folder 的变更，所以 folder 操作完，就会触发 folderUntilDeleted 的变更
	func create(folderNamed name: String?) {
		guard let s = name else { return }
		let newFolder = Folder(name: s, uuid: UUID())
		folder.value.add(newFolder)
	}
	
	// controller 会调用的方法
	func deleteItem(_ item: Item) {
		folder.value.remove(item)
	}
	
	// 将内部状态转换为可以直接绑定到 view 上的格式
	var navigationTitle: Observable<String> {
		return folderUntilDeleted.map { folder in
			guard let f = folder else { return "" }
			return f.parent == nil ? .recordings : f.name
		}
	}
	
	// AnimatableSectionModel 是 RxDataSource
	// folderContents 将当前文件夹的内容通过一种可以绑定到 table view 的方式发送出去
	var folderContents: Observable<[AnimatableSectionModel<Int, Item>]> {
		return folderUntilDeleted.map { folder in
			guard let f = folder else { return [AnimatableSectionModel(model: 0, items: [])] }
			return [AnimatableSectionModel(model: 0, items: f.contents)]
		}
	}
	
	static func text(for item: Item) -> String {
		return "\((item is Recording) ? "🔊" : "📁")  \(item.name)"
	}
}

fileprivate extension String {
	static let recordings = NSLocalizedString("Recordings", comment: "Heading for the list of recorded audio items and folders.")
}

