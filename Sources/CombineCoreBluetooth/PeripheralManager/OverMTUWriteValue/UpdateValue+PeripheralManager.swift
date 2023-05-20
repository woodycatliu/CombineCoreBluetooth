//
//  File.swift
//  
//
//  Created by Woody Liu on 2023/5/20.
//

import Foundation
import Combine
import CoreBluetooth


fileprivate extension Publishers {
    
    struct OverMTUUpdateValuePublisher: Publisher {
        
        let data: Data
        
        let peripheralManager: PeripheralManager
        
        let characteristicUUID: UUID
        
        typealias Output = Void
        
        typealias Failure = Error
        
        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Void == S.Input {
            
        }
       
        
        
    }
    
    class OverMTUUpdateValueSubscription<Failure: Error>: Subscription {
        
        typealias Output = Void
        
        init<S: Subscriber>(subscriber: S,
                            data: Data,
                            peripheralManager: PeripheralManager,
                            characteristic: CBUUID,
                            dataIterator: PeripheralWriteValueIterator) where Failure == S.Failure, Output == S.Input {
            
            self.subscriber = AnySubscriber(subscriber)
            self.data = data
            self.peripheralManager = peripheralManager
            self.characteristicUUID = characteristic
            self.iterator = dataIterator
        }

        let data: Data
        
        let peripheralManager: PeripheralManager
        
        let characteristicUUID: CBUUID
        
        let iterator: PeripheralWriteValueIterator
        
        private(set) var subscriber: AnySubscriber<Output, Failure>?
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock(); defer { lock.unlock() }
            self.leftDemand += demand
            
            guard !isWriting else { return }
            isWriting = true
            sendData()
        }
        
        func cancel() {
            lock.lock(); defer { lock.unlock() }
            subscriber = nil
        }
        
        private var leftDemand: Subscribers.Demand = .none
        
        private let queue: DispatchQueue = DispatchQueue(label: "Publishers.OverMTUWriteValueSubscription")
        
        private var bag = Set<AnyCancellable>()
        
        private var lock = NSRecursiveLock()
        
        private var isWriting: Bool = false
        
    }

}

extension Publishers.OverMTUUpdateValueSubscription {
    
    func sendData() {
        
        
        
        
        
        
    }
    
}

