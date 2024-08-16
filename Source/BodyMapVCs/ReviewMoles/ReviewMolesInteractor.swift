//
//  ReviewMolesInteractor
//  MoleMapper
//
// Copyright (c) 2018 OHSU. All rights reserved.
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
//
import UIKit
import MessageUI

protocol ReviewMolesBusinessLogic
{
    func initializeWithMole(request: ReviewMoles.InitWithMole.Request)
    func changeMeasurement(request: ReviewMoles.ChangeMeasurement.Request)
    func emailMole(request: ReviewMoles.EmailMole.Request)
    func requestHelp(request: PopupHelp.Help.Request)
    func requestHint()
}

class ReviewMolesInteractor: ReviewMolesBusinessLogic
{
    var presenter: ReviewMolesPresentationLogic?
    var sortedMeasurements: [MoleMeasurement30] = []  // Not bothering with a Worker
    var userIsActive = false

    func initializeWithMole(request: ReviewMoles.InitWithMole.Request) {
        sortedMeasurements = request.mole.allMeasurementsSorted()
        
        // Do we really want to extract the images now, or just the measurements?
        if sortedMeasurements.count > 0 {
            let currentMeasurement = sortedMeasurements[0]
            var previousMeasurement: MoleMeasurement30?
            if sortedMeasurements.count > 1 {
                previousMeasurement = sortedMeasurements[1]
            }
            let response = ReviewMoles.InitWithMole.Response(currentMeasurementIndex: 0,
                                                             measurementCount: sortedMeasurements.count,
                                                             previousMeasurement: previousMeasurement,
                                                             currentMeasurement: currentMeasurement,
                                                             nextMeasurement: nil)
            presenter?.presentInitialMole(response: response)
        }
    }
    
    func changeMeasurement(request: ReviewMoles.ChangeMeasurement.Request) {
        userIsActive = true
        let newIndex = request.newMeasurementIndex
        if newIndex < sortedMeasurements.count && newIndex >= 0 {
            let currentMeasurement = sortedMeasurements[newIndex]
            var previousMeasurement: MoleMeasurement30?
            var nextMeasurement: MoleMeasurement30?
            if newIndex > 0 {
                nextMeasurement = sortedMeasurements[newIndex - 1]
            }
            if newIndex < sortedMeasurements.count-1 {
                previousMeasurement = sortedMeasurements[newIndex + 1]
            }
            let response = ReviewMoles.ChangeMeasurement.Response(newMeasurementIndex: newIndex,
                                                                  previousMeasurement: previousMeasurement,
                                                                  currentMeasurement: currentMeasurement,
                                                                  nextMeasurement: nextMeasurement)
            presenter?.presentChangedMeasurement(response: response)
        } else {
            presenter?.restoreCurrentMeasurement()
        }
        
    }

    func emailMole(request: ReviewMoles.EmailMole.Request) {
        userIsActive = true
        let forMole = request.mole
        if (MFMailComposeViewController.canSendMail()) {
            let subjectText = "[MoleMapper] images for \(forMole.moleName!)"
            let zoneDescription = Zone30.zoneNameForZoneID(forMole.whichZone!.zoneID!) ?? "unknown zone"
            var bodyText = "Measurement data for this mole on \(zoneDescription):\n"
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 1
            
            let mailVC = MFMailComposeViewController()
//            mailVC.mailComposeDelegate = self  <- now handled in ViewController
            mailVC.setSubject(subjectText)
            mailVC.setToRecipients(defaultEmailRecipient())
            for moleMeasurement in forMole.allMeasurementsSorted() {
                var index = 0
                if let data = moleMeasurement.getDataAsJPEG() {
                    let filename = "image\(index).jpg"
                    index += 1
                    mailVC.addAttachmentData(data, mimeType: "image/jpg", fileName: filename)
                    let measurementDate = moleMeasurement.date!.description
                    var sizeString = "Size: n/a"
                    if let moleSize = moleMeasurement.calculatedMoleDiameter {
                        if moleSize.floatValue > 0 {
                            let formatter = NumberFormatter()
                            formatter.maximumFractionDigits = 1
                            sizeString = "Size: " + (formatter.string(from: moleSize) ?? "bad") + " mm"
                        }
                    }
                    
                    var description = "Measurement date: \(measurementDate)\n"
                    description.append("mole size: \(sizeString)\n\n")
                    bodyText.append(description)
                }
            }
            mailVC.setMessageBody(bodyText, isHTML: false)
            presenter?.presentEmailMole(response: ReviewMoles.EmailMole.Response(viewControllerToPresent: mailVC))
        }
        else {
            
            let invalidEmailController = UIAlertController(title: "Email Account", message: "There is no email account configured on this device.",
                                                           preferredStyle: UIAlertController.Style.actionSheet)
            invalidEmailController.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            presenter?.presentEmailMole(response: ReviewMoles.EmailMole.Response(viewControllerToPresent: invalidEmailController))
        }

    }
    
    func requestHelp(request: PopupHelp.Help.Request) {
        var requestCleared = true  // default case unless first time and autoPopup
        if (request.requestType == .autoPopup) {
            if PopupTracker.hasSeen("ReviewMoleHelp") || UserDefaults.areHelpScreensDisabled {
                requestCleared = false
            }
        }
        if requestCleared {
            let helpData = ReviewMolesWorker().retrieveHelp()
            let response = PopupHelp.Help.Response(title: helpData.helpTitle, text: helpData.helpText)
            presenter?.presentHelp(response: response)
        }
        else {
            presenter?.presentNoHelp()
        }
    }
    
    func requestHint() {
        if !userIsActive && UserDefaults.areHintsEnabled {
            presenter?.presentHint()
        }
    }
    
    // Helper Function(s)
    
    func defaultEmailRecipient() -> [String] {
        let ud = UserDefaults.standard
        let defaultEmail = ud.string(forKey: "emailForExport") ?? ""
        return [defaultEmail]
    }
    

}
