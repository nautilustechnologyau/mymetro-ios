//
//  VehicleStatusModelOperation.swift
//  OBAKit
//
//  Created by Aaron Brethorst on 10/18/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Foundation

@objc(OBAVehicleStatusModelOperation)
public class VehicleStatusModelOperation: RESTModelOperation {
    public private(set) var vehicles: [VehicleStatus] = []

    override public func main() {
        super.main()
        vehicles = decodeModels(type: VehicleStatus.self)
    }
}
