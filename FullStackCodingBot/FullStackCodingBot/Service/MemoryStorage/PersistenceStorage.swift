import Foundation
import RxSwift
import CoreData

final class PersistenceStorage: PersistenceStorageType {
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreDataStorage")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError()
            }
        }
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private var unitStore: [Unit] = []
    private lazy var unitList = BehaviorSubject<[Unit]>(value: unitStore)
    private var moneyStore = 0
    private lazy var moneyStatus = BehaviorSubject<Int>(value: moneyStore)
    
    @discardableResult
    func append(unit: Unit) -> Observable<Unit> {
        unitStore.append(unit)
        addItemInfo(from: unit)
        unitList.onNext(unitStore)
        return Observable.just(unit)
    }
    
    @discardableResult
    func listUnit() -> Observable<[Unit]> {
        return unitList
    }
    
    @discardableResult
    func raiseLevel(of unit: Unit, using moeny: Int) -> Observable<Unit> {
        let newUnit = Unit(original: unit, level: unit.level+1)
        if let index = unitStore.firstIndex(where: { $0 == unit}) {
            unitStore.remove(at: index)
            deleteUnit(unit: unit)
            unitStore.insert(newUnit, at: index)
            addItemInfo(from: unit)
            moneyStore -= moeny
            updateMoney(money: moeny)
        }
        unitList.onNext(unitStore)
        moneyStatus.onNext(moeny)
        return Observable.just(newUnit)
    }
    
    @discardableResult
    func availableMoeny() -> Observable<Int> {
        return moneyStatus
    }
    
    @discardableResult
    func raiseMoney(by money: Int) -> Observable<Int> {
        moneyStore += money
        moneyStatus.onNext(moneyStore)
        updateMoney(money: money)
        return Observable.just(money)
    }
    
    private func deleteUnit(unit: Unit) {
        if let shouldBeRemoved = fetchUnit().filter({ $0.uuid == unit.uuid}).first {
            context.delete(shouldBeRemoved)
            do {
                try context.save()
            } catch {
                print(error)
            }
        }
    }
    
    private func fetchUnit() -> [ItemInformation] {
        do {
            guard let fetchResult = try context.fetch(ItemInformation.fetchRequest()) as? [ItemInformation] else { return [] }
            return fetchResult
        } catch {
            print(error)
            return []
        }
    }
    
    private func addItemInfo(from unit: Unit) {
        if let entity = NSEntityDescription.entity(forEntityName: "ItemInformation", in: context) {
            let info = NSManagedObject(entity: entity, insertInto: context)
            info.setValue(unit.uuid, forKey: "uuid")
            info.setValue(unit.image, forKey: "image")
            info.setValue(unit.level, forKey: "level")
            
            do {
                try context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func updateMoney(money: Int) {
        let previousInfo = fetchMoneyInfo().first!
        context.delete(previousInfo)
        if let entity = NSEntityDescription.entity(forEntityName: "MoneyInformation", in: context) {
            let info = NSManagedObject(entity: entity, insertInto: context)
            info.setValue(money, forKey: "myMoney")
            
            do {
                try context.save()
            } catch {
                print(error)
            }
        }
        
    }
    
    private func fetchMoneyInfo() -> [MoneyInformation] {
        do {
            guard let fetchResult = try context.fetch(MoneyInformation.fetchRequest()) as? [MoneyInformation] else {
                return []
            }
            return fetchResult
        } catch {
            print(error)
            return []
        }
    }
}
