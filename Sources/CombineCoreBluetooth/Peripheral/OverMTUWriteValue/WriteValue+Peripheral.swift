//
//  File.swift
//  
//
//  Created by Woody Liu on 2023/5/1.
//

import Foundation
import Combine
import CoreBluetooth

public extension Peripheral {
    
    func writeValueWithChunkedThanMTU(with data: Data,
                                      serviceUUID sid: UUID,
                                      characteristicUUID cid: UUID,
                                      dataIterator: PeripheralWriteValueIterator) -> AnyPublisher<Void, Error> {
        return Publishers.OverMTUWriteValuePublisher(data: data,
                                                     peripheral: self,
                                                     serviceUUID: sid,
                                                     characteristicUUID: cid,
                                                     dataIterator: dataIterator)
        .eraseToAnyPublisher()
    }
}

 fileprivate extension Publishers {
    
    struct OverMTUWriteValuePublisher: Publisher {
        
        let data: Data
                
        let peripheral: Peripheral
        
        let serviceUUID: UUID
        
        let characteristicUUID: UUID
        
        let dataIterator: PeripheralWriteValueIterator
                
        typealias Output = Void
        
        typealias Failure = Error
        
        func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Void == S.Input {
            let subscription = OverMTUWriteValueSubscription(subscriber,
                                                             data: data,
                                                             peripheral: peripheral,
                                                             characteristicUUID: characteristicUUID,
                                                             serviceUUID: serviceUUID,
                                                             dataIterator: dataIterator)
            subscriber.receive(subscription: subscription)
        }
        
        
    }
    
    class OverMTUWriteValueSubscription<Failure: Error>: Subscription {
        
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
            
            guard !isWriting else { return }
            isWriting = true
            writeValue()
        }
        
        func cancel() {
            lock.lock(); defer { lock.unlock() }
            self.subscriber = nil
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
        
        private var isWriting: Bool = false
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
        
        guard let sliceData = iterator.slice(at: index,
                                             with: data,
                                             maxMTU: peripheral.maximumWriteValueLength(for: .withResponse))
        else {
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
                  !iterator.isFinished(index,
                                       self.data,
                                       maxMTU: peripheral.maximumWriteValueLength(for: .withResponse))
            else {
                _ = self?.subscriber?.receive(())
                self?.subscriber?.receive(completion: .finished)
                return
            }
            self.writeValue(at: index + 1)
        }.store(in: &bag)
    }
    
}

fileprivate extension Publisher {
    
    func sink(_ reveiveValue: @escaping (Output) -> Void ) -> AnyCancellable {
        return self.sink(receiveCompletion: { _ in }, receiveValue: reveiveValue)
    }
}
