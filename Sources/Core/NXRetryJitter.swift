//
//  NXRetryJitter.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

/// Randomization applied to local retry backoff delays.
public enum NXRetryJitter: Sendable, Equatable {
    /// Keeps the local backoff delay unchanged.
    case none
    /// Uses a random value within the local backoff delay range.
    case full
}
