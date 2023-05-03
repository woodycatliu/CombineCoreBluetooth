//
//  File.swift
//  
//
//  Created by Woody Liu on 2023/5/1.
//

import Foundation
import Combine
import CoreBluetooth

extension Publishers {
    
    struct OverMTUWriteValuePublisher: Publisher {
        
        typealias Output = Void
        
        typealias Failure = Error
        
        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Void == S.Input {
            
        }
        
        
    }
    
    fileprivate class OverMTUWriteValueSubscription<Failure: Error>: Subscription {
        
        typealias Output = Void
        
        init<S: Subscriber>(_ subscriber: S,
                            data: Data,
                            peripheral: Peripheral,
                            characteristicUUID: UUID,
                            serviceUUID: UUID,
                            dataIterator: PeripheralWriteValueIterator) where Failure == S.Failure, Output == S.Input {
            self.subscriber = AnySubscriber(subscriber)
            self.data = data
            self.peripheral = peripheral
            self.characteristicCBUUID = CBUUID(nsuuid: characteristicUUID)
            self.serviceCBUUID = CBUUID(nsuuid: serviceUUID)
            self.iterator = dataIterator
        }
        
        func request(_ demand: Subscribers.Demand) {
            lock.lock(); defer { lock.unlock() }
            self.leftDemand += demand
        }
        
        func cancel() {
            
        }
        
        private let iterator: PeripheralWriteValueIterator
        
        private let serviceCBUUID: CBUUID
        
        private let characteristicCBUUID: CBUUID
        
        private var data: Data
        
        private var peripheral: Peripheral
        
        private var subscriber: AnySubscriber<Output, Failure>? = nil
        
        private var leftDemand: Subscribers.Demand = .none
        
        private let queue: DispatchQueue = DispatchQueue(label: "Publishers.OverMTUWriteValueSubscription")
        
        private var bag = Set<AnyCancellable>()
        
        private var lock = NSRecursiveLock()
    }
}

fileprivate extension Publishers.OverMTUWriteValueSubscription {
    
    func writeValue() {
        self.writeValue(at: 0)
    }
    
    private func writeValue(at index: Int) {
        
        let serviceCBUUID = self.serviceCBUUID
        
        let characteristicCBUUID = self.characteristicCBUUID
        
        let peripheral = self.peripheral
        
        let iterator = iterator
        
        guard let sliceData = iterator.slice(at: index, with: data) else {
            subscriber?.receive(completion: .finished)
            return
        }
        
        peripheral.writeValue(sliceData, writeType: .withResponse,
                              forCharacteristic: characteristicCBUUID,
                              inService: serviceCBUUID)
        .receive(on: queue)
        .flatMap {
            peripheral.listerForWrites(with: characteristicCBUUID, in: serviceCBUUID).first()
        }
        .sink { [weak self] output in
            guard let self = self,
            !iterator.isFinished(index, self.data) else {
                _ = self?.subscriber?.receive(())
                self?.subscriber?.receive(completion: .finished)
                return
            }
            self.writeValue(at: index + 1)
        }.store(in: &bag)
        
    }
    
}


extension Peripheral {
    
    public func listerForWrites(with characteristic: CBUUID, in service: CBUUID) -> AnyPublisher<Void, Error> {
        return discoverCharacteristic(withUUID: characteristic, inServiceWithUUID: service)
            .flatMap { characteristic in
                self.didWriteValueForCharacteristic
                    .filter({ (readCharacteristic, error) -> Bool in
                        return readCharacteristic.uuid == characteristic.uuid
                    })
                    .tryMap {
                        if let error = $1 { throw error }
                        return $0.value
                    }
                    .map { _ in }
            }
            .eraseToAnyPublisher()
    }
    
}

protocol PeripheralWriteValueIterator {
    func isFinished(_ index: Int, _ data: Data) -> Bool
    func slice(at index: Int, with data: Data) -> Data?
}

fileprivate extension Publisher {
    
    func sink(_ reveiveValue: @escaping (Output) -> Void ) -> AnyCancellable {
        return self.sink(receiveCompletion: { _ in }, receiveValue: reveiveValue)
    }
}
