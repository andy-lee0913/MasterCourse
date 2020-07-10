//
//  WeatherManager.swift
//  WeatherWebCrawler
//
//  Created by Gunasegarran on 01/06/2020.
//
//

import Foundation
import CoreLocation

protocol WeatherManagerDelegate { //[Delegate] 1. delegate WeatherManager
    func didUpdateWeather(weather : WeatherModel)
    func didFailWithError(error : Error )
}
struct WeatherManager{
//https://openweathermap.org/api/one-call-api?gclid=EAIaIQobChMI-vnWsZeE6gIVmgsrCh3GxQbxEAAYAiAAEgLsT_D_BwE
    let weatherURL = "https://api.openweathermap.org/data/2.5/weather?appid=e2d4502d62c34e34acd375542c4315d2&units=metric"
    var delegate : WeatherManagerDelegate? //[Delegate] 2. delegate WeatherManager
    
    func fetchWeather(cityName : String){
        let urlString = "\(weatherURL)&q=\(cityName)"
        print(urlString)
        performRequest(url : urlString)
    }
    
    func fetchWeather (latitude: CLLocationDegrees , longitude : CLLocationDegrees){ //make sure to import CoreLocation
           let urlString = "\(weatherURL)&lat=\(latitude)&lon=\(longitude)"
           print(urlString)
           performRequest(url : urlString)
       }
    func performRequest(url: String){
        //1.create a URL
        if let url = URL(string: url){
            //2.create url session
            let session = URLSession(configuration: .default)
            
            //3.give the session a task
            
            //apply closure (anonymous func)
            let task = session.dataTask(with: url) { ( data, response, error) in
                if error != nil{
                    print(error!)
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                if let safeData = data{
                    let dataString = String (data: safeData, encoding: .utf8)
                    print(dataString!)
                    //must go with self for calling any function outside anonymous func
                    if let weather = self.parseJSON(weatherData: safeData){
                        //[Delegate]4.  delegate WeatherManager
                        self.delegate?.didUpdateWeather(weather: weather)
                    }
                }
            }
            //4.start the task
            task.resume()
        }
    }
    func parseJSON(weatherData : Data) -> WeatherModel? {
        let decoder = JSONDecoder()
        do{
            //need to apply Decodable protocol for WeatherData
            let decodedData = try decoder.decode(WeatherData.self, from: weatherData)

            print(decodedData.name)
            print(decodedData.main.temp)
            print(decodedData.weather[0].id)
            let id = decodedData.weather[0].id
            let cityName = decodedData.name
            let temperatureVal = decodedData.main.temp
            let weather = WeatherModel(id: id, cityName: cityName, temperature: temperatureVal)
            print(weather.conditionName)
            print(weather.tempString)
            return weather
        }catch{
            print(error)
            self.delegate?.didFailWithError(error: error)
            return nil
        }
    }
    
   
        
    func handle(data : Data? , response: URLResponse? , error: Error?){
        if error != nil{
            print(error! )
            return
        }
        if let safeData = data{
            let dataString = String (data: safeData, encoding: .utf8)
            print(dataString!)
        }
    }
}

