//
//  XCTestCase+MemoryLeakTracker.swift
//  ContactAppTests
//
//  Created by Arifin Firdaus on 26/12/20.
//

import XCTest

extension XCTestCase {
    
    func trackForMemoryLeaks(instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leaks.", file: file, line: line)
        }
    }
    
}
