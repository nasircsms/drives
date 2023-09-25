//
//  MainListPresenter.swift
//  GPS Tracker
//
//  Created by Guntis on 2022.
//  Copyright (c) 2022 . All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import CoreData
import CoreLocation

protocol MainListPresentationLogic {
	func presentList(response: MainList.FetchDrives.Response)
	func loadStats(response: MainList.FetchStats.Response)
}

class MainListPresenter: MainListPresentationLogic {
	weak var viewController: MainListDisplayLogic?

	// MARK: MainListPresentationLogic

	func presentList(response: MainList.FetchDrives.Response) {

		var finalArray = [[MainList.FetchDrives.ViewModel.DisplayedCellItem]]()

		var subArray = [MainList.FetchDrives.ViewModel.DisplayedCellItem]()

		var subDayArray = [MainList.FetchDrives.ViewModel.DisplayedCellItem]()

		let currentYear = ActivityWorker.shared.yearDateFormatter.string(from: Date())

		for section in response.fetchedDrives {

			subArray.removeAll()
			subDayArray.removeAll()

			var numberOfDrives: Int = 0
			var thisDriveIndex: Int = -1
			var previousDateString = ""

			let sectionsYear = ActivityWorker.shared.yearDateFormatter.string(from: Date.init(timeIntervalSince1970: section.first?.startTime ?? Date().timeIntervalSince1970))

			for item in section {

				numberOfDrives += 1
				thisDriveIndex += 1

				let monthString = (item.monthString ?? "").lowercased().localized()
				var dateString = ActivityWorker.shared.dayMonthDateFormatter.string(from: Date.init(timeIntervalSince1970: item.startTime))

				if sectionsYear != currentYear {
					dateString = ActivityWorker.shared.dayMonthYearDateFormatter.string(from: Date.init(timeIntervalSince1970: item.startTime))
				}

				var startAddress = (item.startAddress?.count == 0 ? "-" : item.startAddress) ?? "-"
				var endAddress = (item.endAddress?.count == 0 ? "-" : item.endAddress) ?? "-"

				let startCountry = (item.startCountry?.count == 0 ? "-" : item.startCountry) ?? "-"
				let endCountry = (item.endCountry?.count == 0 ? "-" : item.endCountry) ?? "-"

				if(startCountry != endCountry && startCountry != "-") {
					startAddress += ", \(startCountry)"
					endAddress += ", \(endCountry)"
				}


				if dateString != previousDateString {
					if subDayArray.count != 0 {
						for var cellItem in subDayArray {
							cellItem.numberOfDrives = numberOfDrives
							subArray.append(cellItem)
						}
						subDayArray.removeAll()
					}

					numberOfDrives = 0
					thisDriveIndex = 0
				}


				subDayArray.append(MainList.FetchDrives.ViewModel.DisplayedCellItem.init(thisDriveIndex:thisDriveIndex, monthName: monthString, dateString: dateString, distance: item.totalDistance, time: item.totalTime, identificator: item.identificator!, startAddress: startAddress, endAddress: endAddress, isBusinessType: item.isBusinessDrive, sectionedMonthString: item.sectionedMonthString!))


				previousDateString = dateString
			}

			if(subDayArray.count != 0) {
				for var cellItem in subDayArray {
					cellItem.numberOfDrives = numberOfDrives + 1
					subArray.append(cellItem)
				}
			}

			if(subArray.count != 0) {
				finalArray.append(subArray)
			}
		}

    	let viewModel = MainList.FetchDrives.ViewModel(displayedCellItems: finalArray)
    	viewController?.presentList(viewModel: viewModel)
	}


	func loadStats(response: MainList.FetchStats.Response) {

		var yearDistance: Double = 0
		var yearTime: Double = 0

		var driveDaysInAYear = Set<String>()
        
        if let firstDrive = response.fetchedDrives.first {
            let lastDrive = response.fetchedDrives.last!
            
            let daysBetween = max(Date.daysBetween(start: Date.init(timeIntervalSince1970: firstDrive.startTime), end: Date.init(timeIntervalSince1970: lastDrive.startTime)), 1)
            
            for drive in response.fetchedDrives {
                yearDistance += drive.totalDistance
                yearTime += drive.totalTime
                driveDaysInAYear.insert(drive.sortingMonthDayYearString!)
            }
            
            let weeksInGivenYear = (daysBetween > 340) ? 365.0 / 7 : Double(daysBetween) / 7
            
            let monthsInGivenYear = (daysBetween > 340) ? 365.0 / 30.4 : Double(daysBetween) / 30.4
            
            let weekDays = Double(driveDaysInAYear.count) / weeksInGivenYear
            let monthDays = Double(driveDaysInAYear.count) / monthsInGivenYear
            
            let weekDrives = Double(response.fetchedDrives.count) / weeksInGivenYear
            let monthDrives = Double(response.fetchedDrives.count) / monthsInGivenYear
            
            let ratio = 365.0/Double(daysBetween)
            let value1 = Double(driveDaysInAYear.count) * ratio
            let drivingDays = (daysBetween > 340) ? driveDaysInAYear.count : Int(value1)
            let drives = (daysBetween > 340) ? response.fetchedDrives.count : Int(Double(response.fetchedDrives.count) * ratio)
            
            
            
            let firstItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .year, yearDistance: yearDistance, yearTime: yearTime, driveDaysInAYear: drivingDays, drivesInAYear: drives, avgWeekDays: weekDays, avgMonthDays: monthDays, avgWeekDrives: weekDrives, avgMonthDrives: monthDrives)
            
            
            var valueDropDuringYears: Double = 1
            var costDuringYears: Double = 1
            var myCarTotalCostInYear: Double = 1
            
            // I was lazy to think of something better - but for now - this will work only if you have at least 12 months worth of data
            // I have more than 12 months, so I will just ignore any other scenario for now.
            if response.valueDrop.count >= 12 && response.carCosts.count >= 12 {
                if response.statsShowType == .firstYear {
                    valueDropDuringYears = Array(response.valueDrop[0..<12]).reduce(0, +)
                    costDuringYears = Array(response.carCosts[0..<12]).reduce(0, +)
                    myCarTotalCostInYear = (valueDropDuringYears + costDuringYears)
                } else if response.statsShowType == .lastYear {
                    valueDropDuringYears = Array(response.valueDrop[response.valueDrop.count-12..<response.valueDrop.count]).reduce(0, +)
                    costDuringYears = Array(response.carCosts[response.carCosts.count-12..<response.carCosts.count]).reduce(0, +)
                    myCarTotalCostInYear = (valueDropDuringYears + costDuringYears)
                } else {
                    valueDropDuringYears = response.valueDrop.reduce(0, +)
                    costDuringYears = response.carCosts.reduce(0, +)
                    myCarTotalCostInYear = (valueDropDuringYears + costDuringYears) / (Double(response.carCosts.count) / 12.0)
                }
            }
            
            let secondItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .myCar, title: "stats_my_car".localized(), avgMonthCost: myCarTotalCostInYear/12, avgHalfYearCost: myCarTotalCostInYear/2, avgYearCost: myCarTotalCostInYear)
            
            
            var totalCost: Double = 0
            var totalBoltCost: Double = 0
            var totalCarGuruCost: Double = 0
            var totalMixedCost: Double = 0
            
            let homeRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: PrivateGatesHelperWorker.homeLatitude,
                                                                             longitude: PrivateGatesHelperWorker.homeLongitude), radius: 300, identifier: "")
            
            var summedTotalDistance: Double = 0
            var summedActualTime: Double = 0
            var startDate: Date?
            var distances: [Double] = []
            
            let cityBee = CityBeePricing.init()
            let boltDrive = BoltDrivePricing.init()
            let carGuruDrive = CarGuruPricing.init()
            
            for section in response.fetchedSectionedDrives {
                
                let firstDrive = section.first!
                let lastDrive = section.last!
                
                //			print("\n\nDate: \(firstDrive.sortingYearMonthDayString!) \(firstDrive.startTime) \(firstDrive.endTime)") //\(firstDrive)
                
                let totalDriveTime = lastDrive.endTime - firstDrive.startTime
                var actualDriveTime: Double = 0
                var actualDistance: Double = 0
                
                for drive in section {
                    actualDriveTime += drive.endTime - drive.startTime//drive.totalTime
                    actualDistance += drive.totalDistance
                }
                
                
                distances.append(actualDistance)
                
                var lastDriveLastPoint = lastDrive.rLastPoint
                
                if lastDriveLastPoint == nil {
                    let sortedPoints: [PointEntity] = lastDrive.rPoints?.sortedArray(using: [NSSortDescriptor(key: "timestamp", ascending: true)]) as! [PointEntity]
                    lastDriveLastPoint = sortedPoints.last
                }
                
                if homeRegion.contains(CLLocationCoordinate2D.init(latitude: lastDriveLastPoint!.latitude, longitude: lastDriveLastPoint!.longitude)) {
                    //print("\nEnded day at home!")
                } else {
                    //print("\nEnded day somewhere else!")
                    if startDate == nil {
                        startDate = Date.init(timeIntervalSince1970: firstDrive.startTime)
                    }
                    
                    summedTotalDistance += actualDistance
                    summedActualTime += actualDriveTime
                    continue
                }
                
                var numberOfDays = 1
                
                if let startDate = startDate {
                    let thisDriveDay = Date.init(timeIntervalSince1970: firstDrive.startTime)
                    numberOfDays = startDate.daysBetween(date: thisDriveDay) + 1
                    
                }
                
                let totalDistance = actualDistance + summedTotalDistance
                let totalActualDriveTime = actualDriveTime + summedActualTime
                summedTotalDistance = 0
                summedActualTime = 0
                startDate = nil
                
                //print("Number of days: \(numberOfDays) | TotalDistance: \(totalDistance) | Total Time: \(HelperWorker.timeFromSeconds(Int(totalDriveTime))) | Actual Time: \(HelperWorker.timeFromSeconds(Int(totalActualDriveTime))) | Wait Time: \(HelperWorker.timeFromSeconds(Int(totalDriveTime - totalActualDriveTime)))")
                
                let cityBeePricing = cityBee.cost(days: numberOfDays, time: totalDriveTime, distance: totalDistance)
                //print("CityBee Final Pricing: \(max(2.29, pricing))")
                
                totalCost += max(2.29, cityBeePricing)
                
                let boltPricing = boltDrive.cost(days: numberOfDays, time: totalDriveTime, distance: totalDistance)
                //print("BOLT Final Pricing: \(max(2.00, boltPricing))")
                
                totalBoltCost += max(2.00, boltPricing)
                
                
                let carGuruPricing = carGuruDrive.cost(totalDriveDays: numberOfDays, totalDriveTime: totalDriveTime, actualDriveTime: totalActualDriveTime, distances: distances)
                //print("Car Guru Final Pricing: \(max(2.50, carGuruPricing))")
                
                totalCarGuruCost += max(2.50, carGuruPricing)
                
                distances.removeAll()
                
                
                let mixedMin = fmin(max(cityBee.minPrice(), cityBeePricing), fmin(max(carGuruDrive.minPrice(), carGuruPricing), max(boltDrive.minPrice(), boltPricing)))
                //print("Mixed Final Pricing: \(mixedMin)")
                
                totalMixedCost += mixedMin
            }
            
            // MARK: CITYBEE
            //		let yearlyCost = totalCost // Real
            let yearlyCostCityBee: Double = (daysBetween > 340) ? totalCost : totalCost * ratio // Optimised for a year
            
            let ratioCityBeeText = "\(Int(yearlyCostCityBee/myCarTotalCostInYear*100)) %"
            let thirdItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .cityBee, title: "stats_citybee".localized(), ratioText: ratioCityBeeText, avgMonthCost: yearlyCostCityBee/12, avgHalfYearCost: yearlyCostCityBee/2, avgYearCost: yearlyCostCityBee)
            
            
            // MARK: BOLT DRIVE
            //		let yearlyCost = totalCost // Real
            let yearlyCostBolt: Double = (daysBetween > 340) ? totalBoltCost : totalBoltCost * ratio // Optimised for a year
            
            let ratioBoltDriveText = "\(Int(yearlyCostBolt/myCarTotalCostInYear*100)) %"
            let fourthItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .boltDrive, title: "stats_bolt_drive".localized(), ratioText: ratioBoltDriveText, avgMonthCost: yearlyCostBolt/12, avgHalfYearCost: yearlyCostBolt/2, avgYearCost: yearlyCostBolt)
            
            
            // MARK: CARGURU
            //		let yearlyCost = totalCost // Real
            let yearlyCostCarGuru: Double = (daysBetween > 340) ? totalCarGuruCost : totalCarGuruCost * ratio // Optimised for a year
            
            let ratioCarGuruText = "\(Int(yearlyCostCarGuru/myCarTotalCostInYear*100)) %"
            let fifthItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .carGuru, title: "stats_carguru".localized(), ratioText: ratioCarGuruText, avgMonthCost: yearlyCostCarGuru/12, avgHalfYearCost: yearlyCostCarGuru/2, avgYearCost: yearlyCostCarGuru)
            
            
            // MARK: MIXED
            let yearlyCostMixed: Double = (daysBetween > 340) ? totalMixedCost : totalMixedCost * ratio // Optimised for a year
            
            let ratioMixedText = "\(Int(yearlyCostMixed/myCarTotalCostInYear*100)) %"
            let sixtItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .mixed, title: "stats_mixed".localized(), ratioText: ratioMixedText, avgMonthCost: yearlyCostMixed/12, avgHalfYearCost: yearlyCostMixed/2, avgYearCost: yearlyCostMixed)
            
            let viewModel = MainList.FetchStats.ViewModel(displayedCellItems: [[firstItem], [secondItem, thirdItem, fourthItem, fifthItem, sixtItem]])
            
            viewController?.loadStats(viewModel: viewModel)
        } else {
            
            // No drives yet..
            
            let firstItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .year, yearDistance: 0, yearTime: 0, driveDaysInAYear: 0, drivesInAYear: 0, avgWeekDays: 0, avgMonthDays: 0, avgWeekDrives: 0, avgMonthDrives: 0)
            
            let secondItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .myCar, title: "stats_my_car".localized(), avgMonthCost: 0, avgHalfYearCost: 0, avgYearCost: 0)
            
            let thirdItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .cityBee, title: "stats_citybee".localized(), ratioText: "", avgMonthCost: 0, avgHalfYearCost: 0, avgYearCost: 0)
            
            let fourthItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .boltDrive, title: "stats_bolt_drive".localized(), ratioText: "", avgMonthCost: 0, avgHalfYearCost: 0, avgYearCost: 0)
            
            let fifthItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .carGuru, title: "stats_carguru".localized(), ratioText: "", avgMonthCost: 0, avgHalfYearCost: 0, avgYearCost: 0)

            let sixtItem = MainList.FetchStats.ViewModel.StatsCellItem.init(statsCellType: .mixed, title: "stats_mixed".localized(), ratioText: "", avgMonthCost: 0, avgHalfYearCost: 0, avgYearCost: 0)
            
            let viewModel = MainList.FetchStats.ViewModel(displayedCellItems: [[firstItem], [secondItem, thirdItem, fourthItem, fifthItem, sixtItem]])
            
            
            viewController?.loadStats(viewModel: viewModel)
        }
	}
}
