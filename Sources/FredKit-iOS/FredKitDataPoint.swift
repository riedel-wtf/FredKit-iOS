//
//  FredKitDataPoint.swift
//  FredKit
//
//  Created by Frederik Riedel on 11/8/20.
//

import Foundation
#if canImport(Charts)
import Charts
#endif
import FredKit

public extension Array where Element == FredKitDataPoint {
    @available(iOS 10.0, macOS 10.12, *)
    func accumulatedDataPoints(for dateInterval: DateInterval, chartConfiguration: FredKitChartConfiguration) -> [Element] {
        return self.filter { element in
            
            let timeIntervalSinceStartDate = element.timeStamp.timeIntervalSince(chartConfiguration.startDate)
            let normalizedTimeStampSinceStartDate = Int(timeIntervalSinceStartDate).mod(divideBy: Int(chartConfiguration.pageTimeInterval))
            let normalizedElementDate = chartConfiguration.startDate.addingTimeInterval(Double(normalizedTimeStampSinceStartDate))
            
            return normalizedElementDate >= dateInterval.start && normalizedElementDate <= dateInterval.end
        }
    }
    
    @available(iOS 10.0, *)
    func segmentedDataPoints(for timeIntervalConfiguration: FredKitChartConfiguration, completion: @escaping ([ Date: [Element] ]) -> Void) {
        
        let segmentIntervals = timeIntervalConfiguration.segmentIntervals
        
        let backgroundQueue = DispatchQueue(label: "data point calculations", qos: .userInteractive, attributes: .concurrent)
        let nonConcurrentQueue = DispatchQueue(label: "non concurrent queue", qos: .userInteractive)
        
        let dispatchGroup = DispatchGroup()
        
        var segmentedDataPoints = [Date: [Element]]()
        
        segmentIntervals.forEach { interval in
            dispatchGroup.enter()
            backgroundQueue.async {
                var filteredDataPoints = [Element]()
                
                switch timeIntervalConfiguration.chartType {
                case .timeline:
                    filteredDataPoints = self.filteredDataPoints(for: interval)
                case .seasonal:
                    filteredDataPoints = self.accumulatedDataPoints(for: interval, chartConfiguration: timeIntervalConfiguration)
                }
                
                nonConcurrentQueue.async {
                    segmentedDataPoints[interval.middle] = filteredDataPoints
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: nonConcurrentQueue) {
            completion(segmentedDataPoints)
        }
    }
    
    @available(iOS 10.0, *)
    func accumulate(for timeIntervalConfiguration: FredKitChartConfiguration, accumulationType: AccumulationType, completion: @escaping ([FredKitDataPoint]) -> Void) {
        
        let backgroundQueue = DispatchQueue(label: "data point calculations", qos: .userInteractive)
        
        backgroundQueue.async {
            self.segmentedDataPoints(for: timeIntervalConfiguration) { segmentedDataPoints in
                let accumulatedDPs = segmentedDataPoints.keys.map { keyDate -> FredKitSimpleDataPoint in
                    
                    var value = 0.0
                    
                    if let dataPointsForSegment = segmentedDataPoints[keyDate] {
                        value = dataPointsForSegment.accumulated(for: accumulationType)
                    }
                    
                    return FredKitSimpleDataPoint(value: value, timeStamp: keyDate)
                }.sorted { dp1, dp2 in
                    return dp1.timeStamp < dp2.timeStamp
                }
                
                if FredKitContext.isCurrentlyRunningUnitTests {
                    completion(accumulatedDPs)
                } else {
                    DispatchQueue.main.async {
                        completion(accumulatedDPs)
                    }
                }
                
            }
        }
    }
    
    var barChartDataEntries: [BarChartDataEntry] {
        return self.map { (dataPoint) -> BarChartDataEntry in
            return BarChartDataEntry(x: dataPoint.timeStamp.timeIntervalSince1970, y: dataPoint.value)
        }
    }
    
    var chartDataEntries: [ChartDataEntry] {
        return self.map { (dataPoint) -> ChartDataEntry in
            return ChartDataEntry(x: dataPoint.timeStamp.timeIntervalSince1970, y: dataPoint.value)
        }
    }
}

extension Int {
    func mod (divideBy: Int) -> Int {
        if self >= 0 { return self % divideBy }
        if self >= -divideBy { return (self+divideBy) }
        return ((self % divideBy)+divideBy)%divideBy
    }
}
