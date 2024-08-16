//
//  ReminderFrequencyViewController.swift
//  MoleMapper
//
//  Created by Tracy Petrie on 4/9/19.
//  Copyright © 2019 OHSU. All rights reserved.
//

import UIKit

enum ReminderFrequency: Int, CaseIterable {
    case monthly = 1
    case threemonthly = 3
    case sixmonthly = 6
    case none = 0
    
    static let asText: [ReminderFrequency: String] = [
        .monthly: "Monthly",
        .threemonthly: "Every 3 months",
        .sixmonthly: "Every 6 months",
        .none: "Don't remind me"
    ]
    
    var text: String {
        return ReminderFrequency.asText[self]!
    }
}

struct ReminderFrequencyInfo {
    let frequency: ReminderFrequency
    let displayText: String
}

protocol ReminderFrequencyDelegate {
    func frequencySelected(newFrequency: ReminderFrequency)
}

class ReminderFrequencyViewController: UIViewController {

    @IBOutlet weak var backdrop: UIView!
    @IBOutlet weak var picker: UIPickerView!
    
    var frequencyList = [ReminderFrequencyInfo]()
    var delegate: ReminderFrequencyDelegate!
    var currentFrequency: ReminderFrequency!
    var newFrequency: ReminderFrequency?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        backdrop.layer.cornerRadius = 7.0
        for frequency in ReminderFrequency.allCases {
            let info = ReminderFrequencyInfo(frequency: frequency, displayText: frequency.text)
            frequencyList.append(info)
        }
        picker.delegate = self
        picker.dataSource = self

        // which row?
        var row = 0
        for freq in frequencyList {
            if freq.displayText == currentFrequency.text {
                break
            }
            row += 1
        }
        // set spinner to that row
        picker.selectRow(row, inComponent: 0, animated: true)
    }
    
    func setup(currentFrequency: ReminderFrequency, delegate: ReminderFrequencyDelegate) {
        self.delegate = delegate
        self.currentFrequency = currentFrequency
    }
    
    @IBAction func accept(_ sender: Any) {

        if let frequency = newFrequency {
            delegate.frequencySelected(newFrequency: frequency)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension ReminderFrequencyViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return frequencyList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        newFrequency = frequencyList[row].frequency
    }
}

extension ReminderFrequencyViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return frequencyList[row].displayText
    }
}
