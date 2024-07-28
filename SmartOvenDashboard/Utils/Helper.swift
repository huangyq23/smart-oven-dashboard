//
//  Helper.swift
//  SmartOvenDashboard
//
//

import Foundation

func findClosestHistoryPoint(in sortedList: [HistoryPoint], to inputValue: Date) -> HistoryPoint? {
    guard !sortedList.isEmpty else { return nil }

    if inputValue <= sortedList.first!.updatedTimestamp {
        return sortedList.first
    }

    if inputValue >= sortedList.last!.updatedTimestamp {
        return sortedList.last
    }

    var low = 0
    var high = sortedList.count - 1

    while low < high {
        let mid = low + (high - low) / 2
        let midValue = sortedList[mid].updatedTimestamp

        if midValue == inputValue {
            return sortedList[mid]
        }

        if midValue < inputValue {
            if mid + 1 <= high && sortedList[mid + 1].updatedTimestamp > inputValue {
                return abs(midValue.timeIntervalSince(inputValue)) < abs(sortedList[mid + 1].updatedTimestamp.timeIntervalSince(inputValue)) ? sortedList[mid] : sortedList[mid + 1]
            }
            low = mid + 1
        } else {
            if mid - 1 >= low && sortedList[mid - 1].updatedTimestamp < inputValue {
                return abs(midValue.timeIntervalSince(inputValue)) < abs(sortedList[mid - 1].updatedTimestamp.timeIntervalSince(inputValue)) ? sortedList[mid] : sortedList[mid - 1]
            }
            high = mid - 1
        }
    }

    return sortedList[low]
}


struct LimitedList<T>: Sequence, RandomAccessCollection {
    private var elements: [T] = []
    private let maxCount: Int = 30
    
    var startIndex: Int { elements.startIndex }
    var endIndex: Int { elements.endIndex }

    var count: Int {
        return elements.count
    }

    mutating func append(_ element: T) {
        guard elements.count < maxCount else { return }
        elements.append(element)
    }

    subscript(index: Int) -> T {
        return elements[index]
    }

    func makeIterator() -> IndexingIterator<[T]> {
        return elements.makeIterator()
    }
}
