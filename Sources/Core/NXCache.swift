//
//  NXCache.swift
//  Nexa
//
//  Created by opfic on 6/19/26.
//

import Foundation

/// 성공한 GET 응답과 진행 중인 동일 요청에 대한 응답 캐시 동작입니다.
public enum NXCache: Sendable, Equatable {
    /// 응답을 캐시하지 않고 동일한 요청을 각각 별도로 실행합니다.
    case disabled
    /// 지정된 TTL 동안 성공한 GET 응답을 메모리에 저장하고, 검증자 재검증 없이 진행 중인 동일 GET 요청 결과를 재사용합니다.
    case memory(ttl: TimeInterval)
    /// 지정된 TTL 동안 성공한 GET 응답을 메모리에 저장하고, 만료된 검증자 기반 `200` 응답을 재검증합니다.
    ///
    /// 캐시는 이 정책을 받는 `NXAPIClient` 인스턴스에 속합니다. 클라이언트를 다시 생성하면 독립적인 캐시가 생깁니다.
    case revalidatingMemory(ttl: TimeInterval)
}
