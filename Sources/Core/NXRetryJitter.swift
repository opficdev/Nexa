//
//  NXRetryJitter.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

/// 로컬 재시도 backoff 지연 무작위화
public enum NXRetryJitter: Sendable, Equatable {
    /// 로컬 backoff 지연 변경 없음
    case none
    /// 로컬 backoff 지연 범위의 임의값 사용
    case full
}
