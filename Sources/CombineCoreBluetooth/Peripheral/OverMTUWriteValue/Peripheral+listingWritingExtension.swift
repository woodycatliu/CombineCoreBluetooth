//
//  Peripheral+listingWritingExtension.swift
//  
//
//  Created by Woody Liu on 2023/5/5.
//

import Combine
import CoreBluetooth

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
