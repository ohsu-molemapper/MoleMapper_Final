//
// MoleMapper
//
// Copyright (c) 2017-2022 OHSU. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit

protocol DenominationViewDelegate: class {
    func didPickDenomination(_ denomination: CoinType?)
}

class DenominationViewController: UIViewController {

    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var pickedCoinType: CoinType?
    weak var delegate: DenominationViewDelegate?
    
    convenience init() {
        self.init(nibName: "DenominationViewController", bundle: nil)
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overCurrentContext
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        okButton.setTitle("OK", for: .normal)
        okButton.setTitleColor(.mmBlue, for: .normal)
        okButton.backgroundColor = .white
        okButton.layer.cornerRadius = 8.0
        
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.layer.cornerRadius = 8.0
        
        if pickedCoinType == nil {
            pickedCoinType = .penny
        }
    }
    @IBAction func onOK(_ sender: Any) {
        // TODO: call a delegate with results
        self.dismiss(animated: true) {
            self.delegate?.didPickDenomination(self.pickedCoinType)
        }
        
    }
}

extension DenominationViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return CoinType.pickSequence.count + 1
    }
}

extension DenominationViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (row + 1) > CoinType.pickSequence.count {
            return "Delete coin"
        }else{
            return CoinType.pickSequence[row].toString()
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (row + 1) > CoinType.pickSequence.count {
            pickedCoinType = nil
        }else{
            pickedCoinType = CoinType.pickSequence[row]
        }
    }
}
