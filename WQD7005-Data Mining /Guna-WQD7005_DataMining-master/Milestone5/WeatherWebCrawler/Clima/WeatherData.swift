//
//  WeatherData.swift
//  WeatherWebCrawler
//
//  Created by Gunasegarran on 01/06/2020.
//
//

import Foundation
//our struct conforms to the Decodable protocol: a data type that can decode themselves.
struct WeatherData : Codable{
    let name: String
    let main : Main
    let weather: [Weather]
}

struct Main: Codable {
    let temp: Double
}

struct Weather : Codable {
    let description: String
    let id : Int
}
