//
//  NXRetryInterceptor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

struct NXRetryInterceptor: NXHTTPInterceptor {
    private let dependencies: NXRetryExecutionDependencies

    init(dependencies: NXRetryExecutionDependencies = .live) {
        self.dependencies = dependencies
    }

    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        guard let retryPolicy = context.specification.retryPolicy else {
            return try await next(context)
        }

        guard retryPolicy.allowedMethods.contains(context.specification.method) else {
            return try await next(context)
        }

        for attemptNumber in 1..<retryPolicy.maxAttempts {
            let attemptContext = context.withAttemptNumber(attemptNumber)
            try Task.checkCancellation()

            do {
                let response = try await next(attemptContext)

                if response.response.statusCode == 401 {
                    return response
                }

                if attemptNumber < retryPolicy.maxAttempts,
                   retryPolicy.retryableStatusCodes.contains(response.response.statusCode) {
                    let delay = retryDelay(
                        after: response,
                        retryPolicy: retryPolicy,
                        attemptNumber: attemptNumber
                    )
                    try await scheduleRetry(
                        context: context,
                        nextAttemptNumber: attemptNumber + 1,
                        delay: delay
                    )
                    continue
                }

                return response
            } catch {
                if attemptNumber < retryPolicy.maxAttempts,
                   isRetryable(error: error) {
                    let delay = localDelay(
                        retryPolicy: retryPolicy,
                        attemptNumber: attemptNumber
                    )
                    try await scheduleRetry(
                        context: context,
                        nextAttemptNumber: attemptNumber + 1,
                        delay: delay
                    )
                    continue
                }

                throw error
            }
        }

        return try await next(context.withAttemptNumber(retryPolicy.maxAttempts))
    }

    private func isRetryable(error: any Error) -> Bool {
        guard let urlError = error as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .notConnectedToInternet,
             .networkConnectionLost,
             .resourceUnavailable:
            return true
        default:
            return false
        }
    }

    private func retryDelay(
        after response: NXRawResponse,
        retryPolicy: RetryPolicy,
        attemptNumber: Int
    ) -> TimeInterval {
        if let serverDelay = serverDelay(from: response.response) {
            return min(serverDelay, retryPolicy.maximumServerDelay)
        }

        return localDelay(retryPolicy: retryPolicy, attemptNumber: attemptNumber)
    }

    private func serverDelay(from response: HTTPURLResponse) -> TimeInterval? {
        guard response.statusCode == 429 || response.statusCode == 503,
              let value = response.value(forHTTPHeaderField: "Retry-After") else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if let seconds = delaySeconds(from: trimmedValue) {
            return seconds
        }

        guard let date = httpDate(from: trimmedValue) else {
            return nil
        }

        return max(0, date.timeIntervalSince(dependencies.now()))
    }

    private func delaySeconds(from value: String) -> TimeInterval? {
        guard !value.isEmpty,
              value.utf8.allSatisfy({ 48 <= $0 && $0 <= 57 }) else {
            return nil
        }

        return value.utf8.reduce(into: 0) { seconds, character in
            let digit = TimeInterval(character - 48)

            if (TimeInterval.greatestFiniteMagnitude - digit) / 10 < seconds {
                seconds = .greatestFiniteMagnitude
                return
            }

            seconds = seconds * 10 + digit
        }
    }

    private func httpDate(from value: String) -> Date? {
        if let date = formattedDate(
            from: value,
            format: "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
        ) {
            return date
        }

        if let date = rfc850Date(from: value) {
            return date
        }

        return formattedDate(
            from: value,
            format: "EEE MMM  d HH':'mm':'ss yyyy"
        ) ?? formattedDate(
            from: value,
            format: "EEE MMM dd HH':'mm':'ss yyyy"
        )
    }

    private func rfc850Date(from value: String) -> Date? {
        let formatter = httpDateFormatter(
            format: "EEEE',' dd-MMM-yy HH':'mm':'ss 'GMT'"
        )

        guard let parsedDate = formatter.date(from: value) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: parsedDate
        )

        guard let year = components.year else {
            return nil
        }

        components.year = 2_000 + year % 100

        guard let futureDate = calendar.date(from: components),
              let futureLimit = calendar.date(
                byAdding: .year,
                value: 50,
                to: dependencies.now()
              ) else {
            return nil
        }

        let date: Date

        if futureLimit < futureDate {
            guard let pastDate = calendar.date(byAdding: .year, value: -100, to: futureDate) else {
                return nil
            }
            date = pastDate
        } else {
            date = futureDate
        }

        guard formatter.string(from: date) == value else {
            return nil
        }

        return date
    }

    private func formattedDate(from value: String, format: String) -> Date? {
        let formatter = httpDateFormatter(format: format)

        guard let date = formatter.date(from: value),
              formatter.string(from: date) == value else {
            return nil
        }

        return date
    }

    private func httpDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.isLenient = false
        formatter.dateFormat = format
        return formatter
    }

    private func localDelay(
        retryPolicy: RetryPolicy,
        attemptNumber: Int
    ) -> TimeInterval {
        let delay = retryPolicy.backoff.delay(forAttempt: attemptNumber)

        switch retryPolicy.jitter {
        case .none:
            return delay
        case .full:
            return delay * min(max(0, dependencies.randomUnit()), 1)
        }
    }

    private func scheduleRetry(
        context: NXRequestExecutionContext,
        nextAttemptNumber: Int,
        delay: TimeInterval
    ) async throws {
        try Task.checkCancellation()
        await context.clientConfiguration.logger.log(
            .retry(
                NXRetryLog(
                    requestIdentifier: context.requestIdentifier,
                    nextAttemptNumber: nextAttemptNumber,
                    delay: delay
                )
            )
        )
        try Task.checkCancellation()
        try await dependencies.sleep(delay)
        try Task.checkCancellation()
    }
}
