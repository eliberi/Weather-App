//
//  Model.swift
//  Mobile App Test
//
//  Created by Eric Liberi on 11/26/24.
//

import Foundation

struct WeatherData: Decodable {
    let daily: Daily

    struct Daily: Decodable {
        let time: [String]
        let weather_code: [Int]
        let temperature_2m_max: [Float]
        let temperature_2m_min: [Float]
    }
}
