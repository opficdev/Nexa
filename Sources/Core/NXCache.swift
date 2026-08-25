//
//  NXCache.swift
//  Nexa
//
//  Created by opfic on 6/19/26.
//

import Foundation

/// 성공한 GET 응답과 진행 중인 동일 요청의 cache 동작
public enum NXCache: Sendable, Equatable {
    /// 동일한 요청 cache 미적용, 개별 실행
    case disabled
    /// 지정된 TTL 동안 성공한 GET 응답 메모리 저장, validator 재검증 없음, 진행 중 동일 GET 요청 결과 재사용
    case memory(ttl: TimeInterval)
    /// 지정된 TTL 동안 성공한 GET 응답 메모리 저장, 만료된 validator 기반 `200` 응답 재검증
    ///
    /// cache 소유권은 정책 적용 `NXAPIClient` instance 단위, client 재생성 시 독립 cache 생성
    case revalidatingMemory(ttl: TimeInterval)
}
