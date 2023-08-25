//
//  utils_date.swift
//  aBicycle
//
//  Created by 1 on 8/13/23.
//

import Foundation

func getCurrentFormattedTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let currentTime = Date()
    return dateFormatter.string(from: currentTime)
}

// 格式化当前日期
func formatDateTime(date: Date, format: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    return dateFormatter.string(from: date)
}
