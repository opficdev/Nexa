//
//  NXCache.swift
//  Nexa
//
//  Created by opfic on 6/19/26.
//

import Foundation

/// Response cache behavior for successful GET responses and in-flight identical requests.
public enum NXCache: Sendable, Equatable {
    /// Does not cache responses and executes identical requests separately.
    case disabled
    /// Stores successful GET responses in memory for the specified TTL and reuses in-flight identical GET request results.
    case memory(ttl: TimeInterval)
}
