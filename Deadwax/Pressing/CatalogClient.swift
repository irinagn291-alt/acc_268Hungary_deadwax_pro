import Foundation

protocol CatalogTransporting: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionTransport: CatalogTransporting {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

enum CatalogFault: Error, Sendable, Equatable {
    case cancelled
    case missing
    case transport
    case malformed
    case emptyQuery
}

/// Role: Owns MusicBrainz release search and catalog-code lookup, plus Cover Art Archive front URLs. DTO then domain CatalogHit.
actor CatalogClient {
    static let userAgent = "Deadwax/1.0 (iOS; +https://deadwax-wall.pro)"

    /// Known https URL. Cannot fail in practice.
    static let releaseSearchURL = URL(string: "https://musicbrainz.org/ws/2/release")!
    static let coverHost = "coverartarchive.org"
    static let searchHost = "musicbrainz.org"

    private let transport: any CatalogTransporting
    private let decoder: JSONDecoder

    init(transport: any CatalogTransporting) {
        self.transport = transport
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 15
        config.httpAdditionalHeaders = ["User-Agent": CatalogClient.userAgent]
        let session = URLSession(configuration: config)
        self.init(transport: URLSessionTransport(session: session))
    }

    func search(query: String, page: Int, pageSize: Int = 24) async throws -> [CatalogHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let request = Self.searchRequest(query: trimmed, page: page, pageSize: pageSize)
        let data = try await send(request)
        do {
            let dto = try decoder.decode(MusicBrainzReleaseListDTO.self, from: data)
            return (dto.releases ?? []).compactMap { $0.asHit }
        } catch is CancellationError {
            throw CatalogFault.cancelled
        } catch let fault as CatalogFault {
            throw fault
        } catch {
            throw CatalogFault.malformed
        }
    }

    func lookup(code: String) async throws -> CatalogHit {
        guard let lucene = SleeveCode.lucene(for: code) else {
            throw CatalogFault.emptyQuery
        }
        let hits = try await search(query: lucene, page: 1, pageSize: 8)
        guard let first = hits.first else { throw CatalogFault.missing }
        return first
    }

    nonisolated static func searchRequest(query: String, page: Int, pageSize: Int = 24) -> URLRequest {
        let limit = min(max(pageSize, 1), 100)
        let pageIndex = max(page, 1)
        let offset = (pageIndex - 1) * limit
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = searchHost
        parts.path = "/ws/2/release"
        // cgi search pl: query, json, page, page_size → fmt=json, query, limit, offset
        parts.queryItems = [
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        var request = URLRequest(url: parts.url ?? releaseSearchURL)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        return request
    }

    nonisolated static func frontURL(mbid: String) -> URL {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = coverHost
        parts.path = "/release/\(mbid)/front-250"
        return parts.url ?? releaseSearchURL
    }

    private func send(_ request: URLRequest, retry: Bool = true) async throws -> Data {
        do {
            let (data, response) = try await transport.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 404 {
                throw CatalogFault.missing
            }
            if status == 429 || (500 ... 599).contains(status) {
                if retry {
                    return try await send(request, retry: false)
                }
                throw CatalogFault.transport
            }
            guard (200 ... 299).contains(status) else {
                throw CatalogFault.transport
            }
            return data
        } catch is CancellationError {
            throw CatalogFault.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CatalogFault.cancelled
        } catch let fault as CatalogFault {
            throw fault
        } catch {
            if retry {
                return try await send(request, retry: false)
            }
            throw CatalogFault.transport
        }
    }
}

struct MusicBrainzReleaseListDTO: Decodable, Sendable {
    var count: Int?
    var offset: Int?
    var releases: [MusicBrainzReleaseDTO]?
}

struct MusicBrainzReleaseDTO: Decodable, Sendable {
    var id: String
    var title: String
    var barcode: String?
    var date: String?
    var artistCredit: [MusicBrainzArtistCreditDTO]?
    var labelInfo: [MusicBrainzLabelInfoDTO]?
    var releaseGroup: MusicBrainzReleaseGroupDTO?
    var tags: [MusicBrainzTagDTO]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case barcode
        case date
        case tags
        case artistCredit = "artist-credit"
        case labelInfo = "label-info"
        case releaseGroup = "release-group"
    }

    var asHit: CatalogHit? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !id.isEmpty else { return nil }
        let artist = (artistCredit ?? []).map(\.displayName).filter { !$0.isEmpty }.joined(separator: " ")
        let label = labelInfo?.first?.label?.name ?? ""
        let catno = labelInfo?.first?.catalogNumber ?? ""
        let genre = tags?.first?.name ?? releaseGroup?.primaryType ?? ""
        return CatalogHit(
            musicBrainzId: id,
            artist: artist,
            title: trimmedTitle,
            label: label,
            genre: genre,
            catalogCode: catno,
            barcode: barcode ?? "",
            sleeveFrontURL: CatalogClient.frontURL(mbid: id).absoluteString
        )
    }
}

struct MusicBrainzArtistCreditDTO: Decodable, Sendable {
    var name: String?
    var artist: MusicBrainzNamedDTO?

    var displayName: String {
        let credit = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !credit.isEmpty { return credit }
        return artist?.name ?? ""
    }
}

struct MusicBrainzLabelInfoDTO: Decodable, Sendable {
    var catalogNumber: String?
    var label: MusicBrainzNamedDTO?

    enum CodingKeys: String, CodingKey {
        case label
        case catalogNumber = "catalog-number"
    }
}

struct MusicBrainzReleaseGroupDTO: Decodable, Sendable {
    var id: String?
    var primaryType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case primaryType = "primary-type"
    }
}

struct MusicBrainzTagDTO: Decodable, Sendable {
    var name: String?
    var count: Int?
}

struct MusicBrainzNamedDTO: Decodable, Sendable {
    var id: String?
    var name: String?
}
