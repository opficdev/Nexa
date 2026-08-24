//
//  NXRetryJitter.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

/// 로컬 재시도 백오프 지연에 적용하는 무작위화입니다.
public enum NXRetryJitter: Sendable, Equatable {
    /// 로컬 백오프 지연을 변경하지 않습니다.
    case none
    /// 로컬 백오프 지연 범위 내의 임의 값을 사용합니다.
    case full
}
