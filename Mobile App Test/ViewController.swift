//
//  ViewController.swift
//  Mobile App Test
//
//  Created by Eric Liberi on 11/25/24.
//

import UIKit

class ViewController: UITableViewController {
    
    var weatherData: WeatherData?
    var currentLocation = "Lindenwold"
    
    enum CustomError : Error {
        case invalidRepsonse
        case invalidData
    }

    @IBOutlet weak var locationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            do {
                try await parseData(location: currentLocation)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        locationButton.setTitle(currentLocation, for: .normal)
        locationButton.showsMenuAsPrimaryAction = true
        configureLocationMenu()
    }
    
    func parseData(location: String) async throws -> Void {
        
        var coordinates: String
        var timezone: String
        
        switch location {
        case "Lindenwold":
            coordinates = "latitude=39.8243&longitude=-74.9977"
            timezone = "America%2FNew_York"
        case "Melbourne":
            coordinates = "latitude=-37.814&longitude=144.9633"
            timezone = "auto"
        case "Toronto":
            coordinates = "latitude=43.7001&longitude=-79.4163"
            timezone = "auto"
        default:
            coordinates = "latitude=39.8243&longitude=-74.9977"
            timezone = "America%2FNew_York"
        }
        
        let urlString = "https://api.open-meteo.com/v1/forecast?"+coordinates+"&daily=weather_code,temperature_2m_max,temperature_2m_min&temperature_unit=fahrenheit&timezone="+timezone+"&forecast_days=5"
        
        let url = URL(string: urlString)!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CustomError.invalidRepsonse
        }
        
        do {
            let decoder = JSONDecoder()
            weatherData = try decoder.decode(WeatherData.self, from: data)
        } catch {
            print("Error: \(error)")
            throw CustomError.invalidData
        }
        
        tableView.reloadData()
    }
    
    func configureLocationMenu() {
        let lindenwoldItem = UIAction(title: "Lindenwold, NJ", state: currentLocation == "Lindenwold" ? .on : .off) { [self] (_) in
            currentLocation = "Lindenwold"
            Task {
                do {
                    try await parseData(location: currentLocation)
                } catch {
                    print(error.localizedDescription)
                }
            }
            locationButton.setTitle(currentLocation, for: .normal)
            configureLocationMenu()
        }

        let melbourneItem = UIAction(title: "Melbourne, Victoria\nAustralia", state: currentLocation == "Melbourne" ? .on : .off) { [self] (_) in
            currentLocation = "Melbourne"
            Task {
                do {
                    try await parseData(location: currentLocation)
                } catch {
                    print(error.localizedDescription)
                }
            }
            locationButton.setTitle(currentLocation, for: .normal)
            configureLocationMenu()
         }
        
        let torontoItem = UIAction(title: "Toronto, Ontario\nCanada", state: currentLocation == "Toronto" ? .on : .off) { [self] (_) in
            currentLocation = "Toronto"
            Task {
                do {
                    try await parseData(location: currentLocation)
                } catch {
                    print(error.localizedDescription)
                }
            }
            locationButton.setTitle(currentLocation, for: .normal)
            configureLocationMenu()
         }

        let menu = UIMenu(title: "Select a Location", options: .displayInline, children: [lindenwoldItem, melbourneItem, torontoItem])
        locationButton.menu = menu
    }
    
    
    func getForecastImage(code: Int) -> UIImage {
        var image: UIImage?
        let configuration = UIImage.SymbolConfiguration(scale: .large)
        
        switch code {
        case 0: //Clear sky
            image = UIImage(systemName: "sun.max.fill", withConfiguration: configuration)?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        case 1, 2: //Mainly clear, partly cloudy
            image = UIImage(systemName: "cloud.sun")
        case 3: // Overcast
            image = UIImage(systemName: "cloud")
        case 45, 48: // Fog and depositing rime fog
            image = UIImage(systemName: "cloud.fog")
        case 51, 53, 55: // Drizzle: Light, moderate, and dense intensity
            image = UIImage(systemName: "cloud.drizzle")
        case 56, 57: // Freezing Drizzle: Light and dense intensity
            image = UIImage(systemName: "cloud.drizzle")
        case 61, 63, 65: // Rain: Slight, moderate and heavy intensity
            image = UIImage(systemName: "cloud.rain")
        case 66, 67: // Freezing Rain: Light and heavy intensity
            image = UIImage(systemName: "cloud.sleet")
        case 71, 73, 75: // Snow fall: Slight, moderate, and heavy intensity
            image = UIImage(systemName: "snowflake")
        case 77: // Snows grains
            image = UIImage(systemName: "cloud.snow")
        case 80, 81, 82: // Rain showers: Slight, moderate, and violent
            image = UIImage(systemName: "cloud.heavyrain")
        case 85, 86: // Snow showers slight and heavy
            image = UIImage(systemName: "cloud.snow")
        case 95: // Thunderstorm: Slight or moderate
            image = UIImage(systemName: "cloud.bolt")
        case 96, 99: // Thunderstorm with slight and heavy hail
            image = UIImage(systemName: "cloud.bolt.rain")
        default:
            image = UIImage()
        }
        
        return image ?? UIImage()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weatherData?.daily.weather_code.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        
        guard let dateString = weatherData?.daily.time[indexPath.row] else { return UITableViewCell() }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateString) else { return UITableViewCell() }
        dateFormatter.dateFormat = "EEEE"
        cell.textLabel?.text = indexPath.row == 0 ? "Today" : dateFormatter.string(from: date)
        
        guard let highTemp = weatherData?.daily.temperature_2m_max[indexPath.row] else { return UITableViewCell() }
        guard let lowTemp = weatherData?.daily.temperature_2m_min[indexPath.row] else { return UITableViewCell() }
        cell.detailTextLabel?.text = "H: " + String(format: "%.0f", highTemp) + "°  L: " + String(format: "%.0f", lowTemp) + "°"
        
        guard let weatherCode = weatherData?.daily.weather_code[indexPath.row] else { return UITableViewCell() }
        cell.imageView?.image = getForecastImage(code: weatherCode)
        
        return cell
    }

}

