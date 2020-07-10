//
//  ViewController.swift
//  WeatherWebCrawler
//
//  Created by Gunasegarran on 01/06/2020.
//
//

import UIKit
import CoreLocation
class WeatherViewController: UIViewController {
  
    //[Delegate] 1.  delegate WeatherManager

    @IBOutlet weak var conditionImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    let locationManager = CLLocationManager()
    var weatherManager = WeatherManager() //[Delegate] 2. delegate WeatherManager
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(searchTextField.text!)
        
        //how view controller sign up to be notify by TextField.
        //1. have textField obj, 2. delegate
        searchTextField.delegate = self
        
        //[Delegate] delegate WeatherManager
        weatherManager.delegate = self
        
        //permission from user
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()

    }

    @IBAction func searchPressed(_ sender: UIButton) {
        searchTextField.endEditing(true)
        print(searchTextField.text!)
    }
    
    @IBAction func currentLocationPressed(_ sender: UIButton) {
        locationManager.requestLocation()
    }
    
}
//MARK: - UITextFieldDelegate
//MARK: -
extension WeatherViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.endEditing(true)
        //when user hit RETURN
        print(searchTextField.text!)
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        //get fetch data
        if  let enteredCity = searchTextField.text {
            let city = enteredCity.replacingOccurrences(of: " ", with: "%20") //check url on browser, space is replaced with "%20"
            print(city)
            weatherManager.fetchWeather(cityName: city)
        }
        searchTextField.text = ""

    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        //user for text validation
        if textField.text != "" {
            return true
        } else{
            textField.placeholder = "Type something"
            return false
        }
    }
}
//MARK: - WeatherManagerDelegate
extension WeatherViewController : WeatherManagerDelegate {
    //[Delegate] 3 delegate WeatherManager
       func didUpdateWeather(weather: WeatherModel) {
        let cityName = weather.cityName
           let temperature = weather.tempString
           let conditionName = weather.conditionName
           print (cityName + temperature + conditionName)
           DispatchQueue.main.async {
                self.cityLabel.text = cityName
                self.temperatureLabel.text = temperature
                self.conditionImageView.image = UIImage(systemName: conditionName)
           }
           
           
       }
       func didFailWithError(error: Error) {
             print(error)
        //call request location
        
         }
}
//MARK: - CLLocationManagerDelegate

extension WeatherViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print ("got location")
        if let location = locations.last {
            //once result found, need to stop update
            locationManager.stopUpdatingLocation()
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            print (lat)
            print(lon)
            weatherManager.fetchWeather(latitude : lat, longitude : lon)
            
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
