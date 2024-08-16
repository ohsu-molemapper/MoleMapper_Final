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
import AVKit

struct Movie {
    let movieName: String
    let movieResourceName: String
}

class TheaterListViewController: UIViewController {

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var movieList = [Movie]()
    
    override func loadView() {
        super.loadView()
        
        populateMovieListData()
        
        tableView.dataSource = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up Done button
        if self.navigationController != nil {
            doneButton.isHidden = true
        } else {
            doneButton.layer.cornerRadius = doneButton.bounds.height / 2.0
            doneButton.titleLabel?.font = UIFont.init(name: "Helvetica neue", size: 20.0)
            doneButton.contentEdgeInsets.left = 14.0
            doneButton.contentEdgeInsets.right = 14.0
            doneButton.contentEdgeInsets.top = 4.0
            doneButton.contentEdgeInsets.bottom = 4.0
            doneButton.sizeToFit()
            doneButton.layer.cornerRadius = doneButton.bounds.height/2
        }
    }
    
    func populateMovieListData() {
        movieList.append(Movie(movieName: "Measure Moles", movieResourceName: "MeasureMoles"))
        movieList.append(Movie(movieName: "Remeasure Moles", movieResourceName: "remeasure"))
        movieList.append(Movie(movieName: "Review Moles", movieResourceName: "ReviewZone"))
    }
    
    @IBAction func onDone(_ sender: UIButton) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension TheaterListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieListCell") as! MovieListTableViewCell
        
        let cellModel = movieList[indexPath.row]
        cell.setup(movieName: cellModel.movieName, assetName: cellModel.movieResourceName, delegate: self)
        return cell
    }
}

extension TheaterListViewController: MovieListTableViewCellProtocol {
    func itemSelected(assetName: String) {
        let sb = UIStoryboard(name: "Theater", bundle: nil)
        if let vc = sb.instantiateViewController(withIdentifier: "TheaterViewController") as? TheaterViewController {
            vc.assetName = assetName
            present(vc, animated: true, completion: nil)
        }
    }
}
