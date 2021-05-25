//
//  Data.swift
//  app-search
//
//  Created by Ethan Groves on 3/5/21.
//

import Foundation

class AppSearch {
  func getResults(searchTerm: String, completion: @escaping ([Result]) -> ()) {
    let searchObject: [String: Any] = ["query": searchTerm]
    let jsonSearchQuery = try? JSONSerialization.data(withJSONObject: searchObject)
    let authenticationToken = "my_authentication_token"
    let appSearchURL = URL(string: "my_app_search_url")!
    var request = URLRequest(url: appSearchURL)
    request.httpMethod = "POST"
    request.setValue(authenticationToken, forHTTPHeaderField: "Authorization")
    request.httpBody = jsonSearchQuery
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
      let JSONData = try! JSONDecoder().decode(JSONResponse.self, from: data!)
      DispatchQueue.main.async {
        completion(JSONData.results)
      }
    }
    .resume()
  }
}


// MARK: - Welcome
struct JSONResponse: Codable {
    let meta: Meta
    let results: [Result]
}

// MARK: - Meta
struct Meta: Codable {
    let alerts, warnings: [JSONAny]
    let page: Page
    let engine: Engine
    let requestID: String

    enum CodingKeys: String, CodingKey {
        case alerts, warnings, page, engine
        case requestID = "request_id"
    }
}

// MARK: - Engine
struct Engine: Codable {
    let name: Name
    let type: String
}

enum Name: String, Codable {
    case movies = "movies"
}

// MARK: - Page
struct Page: Codable {
    let current, totalPages, totalResults, size: Int

    enum CodingKeys: String, CodingKey {
        case current
        case totalPages = "total_pages"
        case totalResults = "total_results"
        case size
    }
}

// MARK: - Result
struct Result: Codable, Identifiable {
  
  let id = UUID()
  
  let adult: RawString?
  let backdropPath: RawString?
  let belongsToCollection: RawString?
  let budget: RawNumber?
  let genres: RawArrayOfStrings?
  let homepage: RawString?
  let imdbID: RawString?
  let meta: MetaClass
  let originalLanguage: RawString?
  let originalTitle: RawString?
  let overview: RawString
  let popularity: RawNumber?
  let posterPath: RawString
  let productionCompanies: RawArrayOfStrings?
  let productionCountries: RawArrayOfStrings?
  let releaseDate: RawString?
  let revenue: RawNumber?
  let runtime: RawNumber?
  let spokenLanguages: RawArrayOfStrings?
  let status: RawString?
  let tagline: RawString?
  let title: RawString
  let video: RawString?
  let voteAverage: RawNumber?
  let voteCount: RawNumber?

    enum CodingKeys: String, CodingKey {
        case genres, overview, tagline
        case meta = "_meta"
        case id, runtime
        case spokenLanguages = "spoken_languages"
        case productionCompanies = "production_companies"
        case budget
        case belongsToCollection = "belongs_to_collection"
        case backdropPath = "backdrop_path"
        case homepage, title, adult
        case originalTitle = "original_title"
        case revenue
        case imdbID = "imdb_id"
        case video
        case voteCount = "vote_count"
        case status
        case voteAverage = "vote_average"
        case originalLanguage = "original_language"
        case productionCountries = "production_countries"
        case releaseDate = "release_date"
        case posterPath = "poster_path"
        case popularity
    }
}

// MARK: - RawString
struct RawString: Codable {
    let raw: String?
}

struct RawArrayOfStrings: Codable {
    let raw: [String]?
}

struct RawNumber: Codable {
    let raw: Double?
}

// MARK: - MetaClass
struct MetaClass: Codable {
    let id: String
    let engine: Name
    let score: Double
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
        return nil
    }

    required init?(stringValue: String) {
        key = stringValue
    }

    var intValue: Int? {
        return nil
    }

    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {

    let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }

    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
