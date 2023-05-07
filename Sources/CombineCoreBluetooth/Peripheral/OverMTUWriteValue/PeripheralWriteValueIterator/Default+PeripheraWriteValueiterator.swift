//
//  Default+PeripheraWriteValueiterator.swift
//  
//
//  Created by Woody Liu on 2023/5/5.
//

struct DefaultPeripheralWriteValueIterator: PeripheralWriteValueIterator {
    
    func isFinished(_ index: Int, _ data: Data, maxMTU: Int) -> Bool {
        let maxCount = data.count
        return (index + 1) * maxMTU >= maxCount
    }
    
    func slice(at index: Int, with data: Data, maxMTU: Int) -> Data? {
        let maxCount = data.count
        guard !isFinished(index - 1, data, maxMTU: maxMTU) else { return nil }
        let startIndex = index * maxMTU
        let endIndex = min(startIndex + maxMTU, maxCount)
        return data[startIndex..<endIndex]
    }
}
