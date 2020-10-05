//
//  File.swift
//  
//
//  Created by daniele on 30/09/2020.
//

import Foundation
import MapKit
import CoreLocation

public struct GeofencingOptions: Codable {
    
    // MARK: - Public Properties
    
    /// Region monitored.
    public let region: Region
    
    /// Set `true` to be notified on enter in region events (by default is `true`).
    public var notifyOnEntry: Bool {
        set {
            region.circularRegion.notifyOnEntry = newValue
        }
        get {
            region.circularRegion.notifyOnEntry
        }
    }
    
    /// Set `true` to be notified on exit from region events (by default is `true`).
    public var notifyOnExit: Bool {
        set {
            region.circularRegion.notifyOnExit = newValue
        }
        get {
            region.circularRegion.notifyOnExit
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize to monitor a specific polygon.
    ///
    /// - Parameter polygon: polygon to monitor.
    public init(polygon: MKPolygon) {
        // TODO: inner circle!
        let innerCircle = CLCircularRegion(center: CLLocationCoordinate2D(), radius: 0, identifier: UUID().uuidString)
        self.region = .polygon(polygon, innerCircle)
        
        defer {
            self.notifyOnEntry = true
            self.notifyOnExit = true
        }
    }
    
    /// Initialize a new region monitoring to geofence passed circular region.
    ///
    /// - Parameters:
    ///   - center: center of the circle.
    ///   - radius: radius of the circle in meters.
    public init(circleWithCenter center: CLLocationCoordinate2D, radius: CLLocationDegrees) {
        let circle = CLCircularRegion(center: center, radius: radius, identifier: UUID().uuidString)
        self.region = .circle(circle)
        
        defer {
            self.notifyOnEntry = true
            self.notifyOnExit = true
        }
    }
    
}

// MARK: - GeofencingOptions Options

public extension GeofencingOptions {
    
    /// Region monitored.
    /// - `circle`: monitoring a circle region.
    /// - `polygon`: monitoring a polygon region.
    ///             (it's always a circle but it's evaluated by request and it's inside the circular region identified by the second parameter, generated internally)
    enum Region: Codable {
        case circle(CLCircularRegion)
        case polygon(MKPolygon, CLCircularRegion)
        
        /// Unique identifier of the region monitored.
        internal var uuid: String {
            switch self {
            case .circle(let circle):
                return circle.identifier
            case .polygon(_, let boundCircle):
                return boundCircle.identifier
            }
        }
        
        internal var kind: Int {
            switch self {
            case .circle: return 0
            case .polygon: return 1
            }
        }
        
        /// Return the observed circle (outer circle which inscribes the polygon for polygon monitoring)
        var circularRegion: CLCircularRegion {
            switch self {
            case .circle(let c): return c
            case .polygon(_, let c): return c
            }
        }
        
        /// Return monitored polygon if monitoring is about a polygon.
        var polygon: MKPolygon? {
            switch self {
            case .circle: return nil
            case .polygon(let p, _): return p
            }
        }
        
        // MARK: - Codable Support
        
        enum CodingKeys: String, CodingKey {
            case kind, cRegionCenter, clRegionRadius, polygonCoordinates, identifier
        }
        
        // Encodable protocol
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(kind, forKey: .kind)
            switch self {
            case .circle(let circularRegion):
                try container.encode(circularRegion.center, forKey: .cRegionCenter)
                try container.encode(circularRegion.radius, forKey: .clRegionRadius)
                try container.encode(circularRegion.identifier, forKey: .identifier)

            case .polygon(let polygon, let circularRegion):
                try container.encode(circularRegion.center, forKey: .cRegionCenter)
                try container.encode(circularRegion.radius, forKey: .clRegionRadius)
                try container.encode(circularRegion.identifier, forKey: .identifier)

                try container.encode(polygon.coordinates, forKey: .polygonCoordinates)
            }
        }
        
        // Decodable protocol
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            switch try container.decode(Int.self, forKey: .kind) {
            case 0:
                let center = try container.decode(CLLocationCoordinate2D.self, forKey: .cRegionCenter)
                let radius = try container.decode(CLLocationDegrees.self, forKey: .clRegionRadius)
                let identifier = try container.decode(String.self, forKey: .identifier)
                let cRegion = CLCircularRegion(center: center, radius: radius, identifier: identifier)
                
                self = .circle(cRegion)
                
            case 1:
                let center = try container.decode(CLLocationCoordinate2D.self, forKey: .cRegionCenter)
                let radius = try container.decode(CLLocationDegrees.self, forKey: .clRegionRadius)
                let identifier = try container.decode(String.self, forKey: .identifier)
                let cRegion = CLCircularRegion(center: center, radius: radius, identifier: identifier)
                
                let coordinates = try container.decode([CLLocationCoordinate2D].self, forKey: .polygonCoordinates)
                let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
                
                self = .polygon(polygon, cRegion)
                
            default:
                fatalError()
            }
        }
        
    }
    
}
