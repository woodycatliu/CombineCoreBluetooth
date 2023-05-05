//
//  Peripheral+WriteValueIterator.swift
//  
//
//  Created by Woody Liu on 2023/5/5.
//

extension Peripheral {
    public struct WriteValueIterator { }
}

extension Peripheral.WriteValueIterator {
    public static let nonMutatingIterator: PeripheralWriteValueIterator = DefaultPeripheralWriteValueIterator()
}
