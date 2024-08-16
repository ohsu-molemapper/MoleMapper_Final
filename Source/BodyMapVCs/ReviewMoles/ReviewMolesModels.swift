//
//  ReviewMolesModels
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

enum ReviewMoles
{
    enum InitWithMole
    {
        struct Request {
            let mole: Mole30
            init(mole: Mole30) {
                self.mole = mole
            }
        }
        struct Response {
            let currentMeasurementIndex: Int
            let measurementCount: Int
            let previousMeasurement: MoleMeasurement30? // may not be one of these
            let currentMeasurement: MoleMeasurement30  // has to be one of these!
            let nextMeasurement: MoleMeasurement30?  // may not be one of these
            init(currentMeasurementIndex: Int, measurementCount: Int,
                 previousMeasurement: MoleMeasurement30?, currentMeasurement: MoleMeasurement30,
                 nextMeasurement: MoleMeasurement30?) {
                
                self.currentMeasurementIndex = currentMeasurementIndex
                self.measurementCount = measurementCount
                self.previousMeasurement = previousMeasurement
                self.currentMeasurement = currentMeasurement
                self.nextMeasurement = nextMeasurement
            }
        }
        struct ViewModel {
            var currentMeasurementIndex: Int
            var measurementCount: Int
            var previousMeasurement: MoleMeasurement30? // may not be one of these
            var currentMeasurement: MoleMeasurement30  // has to be one of these!
            var nextMeasurement: MoleMeasurement30?  // may not be one of these
            init(currentMeasurementIndex: Int, measurementCount: Int,
                 previousMeasurement: MoleMeasurement30?, currentMeasurement: MoleMeasurement30,
                 nextMeasurement: MoleMeasurement30?) {
                
                self.currentMeasurementIndex = currentMeasurementIndex
                self.measurementCount = measurementCount
                self.previousMeasurement = previousMeasurement
                self.currentMeasurement = currentMeasurement
                self.nextMeasurement = nextMeasurement
            }
            static func viewModelFromResponse(response: Response) -> ViewModel {
                let viewModel = ViewModel(currentMeasurementIndex: response.currentMeasurementIndex,
                                          measurementCount: response.measurementCount,
                                          previousMeasurement: response.previousMeasurement,
                                          currentMeasurement: response.currentMeasurement,
                                          nextMeasurement: response.nextMeasurement)
                return viewModel
            }
        }
    }
    enum ChangeMeasurement
    {
        struct Request {
            let newMeasurementIndex: Int
            init(newMeasurementIndex: Int) {
                self.newMeasurementIndex = newMeasurementIndex
            }
        }
        struct Response {
            let newMeasurementIndex: Int
            let previousMeasurement: MoleMeasurement30? // may not be one of these
            let currentMeasurement: MoleMeasurement30  // has to be one of these!
            let nextMeasurement: MoleMeasurement30?  // may not be one of these
            init(newMeasurementIndex: Int, previousMeasurement: MoleMeasurement30?,
                 currentMeasurement: MoleMeasurement30,
                 nextMeasurement: MoleMeasurement30?) {
                self.newMeasurementIndex = newMeasurementIndex
                self.previousMeasurement = previousMeasurement
                self.currentMeasurement = currentMeasurement
                self.nextMeasurement = nextMeasurement
            }
        }
        struct ViewModel {
            let newMeasurementIndex: Int
            let previousMeasurement: MoleMeasurement30? // may not be one of these
            let currentMeasurement: MoleMeasurement30  // has to be one of these!
            let nextMeasurement: MoleMeasurement30?  // may not be one of these
            init(newMeasurementIndex: Int, previousMeasurement: MoleMeasurement30?,
                 currentMeasurement: MoleMeasurement30,
                 nextMeasurement: MoleMeasurement30?) {
                self.newMeasurementIndex = newMeasurementIndex
                self.previousMeasurement = previousMeasurement
                self.currentMeasurement = currentMeasurement
                self.nextMeasurement = nextMeasurement
            }
            static func viewModelFromResponse(response: Response) -> ViewModel {
                let viewModel = ViewModel(newMeasurementIndex: response.newMeasurementIndex,
                                          previousMeasurement: response.previousMeasurement,
                                          currentMeasurement: response.currentMeasurement,
                                          nextMeasurement: response.nextMeasurement)
                return viewModel
            }
        }
    }
    enum EmailMole
    {
        struct Request {
            let mole: Mole30
            init(mole: Mole30) {
                self.mole = mole
            }
        }
        struct Response {
            let viewControllerToPresent: UIViewController
            init(viewControllerToPresent: UIViewController) {
                self.viewControllerToPresent = viewControllerToPresent
            }
        }
        struct ViewModel {
            let viewControllerToPresent: UIViewController
            init(viewControllerToPresent: UIViewController) {
                self.viewControllerToPresent = viewControllerToPresent
            }
        }
    }

}
