//
//  XKCDStrip+FromJSONDictionary.swift
//  EasyDi
//
//  Created by Andrey Zarembo
//

import Foundation

extension Dictionary where Key: TextOutputStream, Value: Any {
 
    var xkcdStrip: XKCDStrip? {
        
        guard let jsonDictionary = self as? [String: Any] else {
            return nil
        }
        
        guard
            let stripId = jsonDictionary["num"] as? Int,
            let title = jsonDictionary["title"] as? String,
            let imgURLString = jsonDictionary["img"] as? String, let imgURL = URL(string: imgURLString),
            let notes = jsonDictionary["alt"] as? String,
            let yearString = jsonDictionary["year"] as? String, let year = Int(yearString),
            let monthString = jsonDictionary["month"] as? String, let month = Int(monthString),
            let dayString = jsonDictionary["day"] as? String, let day = Int(dayString)
            
            else {
            
                return nil
        }
        
        let calendar = Calendar(identifier: .gregorian)
        let components = DateComponents(calendar: calendar, year: year, month: month, day: day)
        
        guard let date = components.date else {
            return nil
        }
        
        return XKCDStrip(id: stripId, date: date, title: title, notes: notes, imgURL: imgURL)
    }
}
