//
//  NXRetryJitter.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

/// 로컬 retry backoff delay 무작위화
public enum NXRetryJitter: Sendable, Equatable {
    /// 로컬 backoff delay 비변경
    case none
    /// 로컬 backoff delay 범위 임의값 사용
    case full
}
