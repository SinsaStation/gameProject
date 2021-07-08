import Foundation
import RxSwift

protocol ItemStorageType {
    
    func availableMoeny() -> Int
    
    func itemList() -> [Unit]
    
    @discardableResult
    func create(item: Unit) -> Observable<Unit>
    
    @discardableResult
    func list() -> Observable<[Unit]>
    
    @discardableResult
    func update(previous: Unit, new: Unit) -> Observable<Unit>
}
