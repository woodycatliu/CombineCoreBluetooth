//
//  Interface+PeripheralWriteValueIterator.swift
//  
//
//  Created by Woody Liu on 2023/5/5.
//

public protocol PeripheralWriteValueIterator {
    func isFinished(_ index: Int, _ data: Data) -> Bool
    func slice(at index: Int, with data: Data) -> Data?
}
