//
//  NXCache.swift
//  Nexa
//
//  Created by opfic on 6/19/26.
//

import Foundation

/// 성공한 GET 응답과 진행 중인 동일 요청의 캐시 동작
public enum NXCache: Sendable, Equatable {
    /// 동일한 요청에 캐시를 적용하지 않고 개별 실행
    case disabled
    /// 지정된 TTL 동안 성공한 GET 응답을 메모리에 저장하고 식별값으로 재검증하지 않으며 진행 중인 동일 GET 요청 결과 재사용
    case memory(ttl: TimeInterval)
    /// 지정된 TTL 동안 성공한 GET 응답을 메모리에 저장하고 식별값이 있는 만료 `200` 응답 재검증
    ///
    /// 캐시 소유권은 정책을 적용한 `NXAPIClient` 인스턴스 단위이며 클라이언트를 새로 만들면 독립된 캐시 생성
    case revalidatingMemory(ttl: TimeInterval)
}
