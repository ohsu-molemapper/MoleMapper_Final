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

// IMPORTANT: the Play button in the Storyboard MUST have a tag of 42

import UIKit
import AVFoundation

enum TheaterPlayingState {
    case playing
    case paused
    case fastforwarding
    case rewinding
}


class TheaterViewController: UIViewController {
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var playerToolbar: UIToolbar!
    @IBOutlet weak var videoView: TheaterView!

    var assetName: String?
    private var avplayer: AVPlayer!
    private var playerLayer: AVPlayerLayer!
    private var currentState: TheaterPlayingState!
    let playButtonTag = 42

    override func viewDidLoad() {
        super.viewDidLoad()
        videoView.layer.cornerRadius = 7.0

        guard let videoUrl = Bundle.main.url(forResource: assetName, withExtension:"mp4") else { return }

        avplayer = AVPlayer(url: videoUrl)
        videoView.player = avplayer
        videoView.playerLayer.videoGravity = .resizeAspect
        
        changeState(.paused)
        doneButton.mmMakePillButton()
    }
    
    func changeState(_ newState: TheaterPlayingState) {
        // maybe this should be a setter for the var currentState??
        func swapPlayButton(for systemItem: UIBarButtonItem.SystemItem, at: Int) {
            let newButton = UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: #selector(TheaterViewController.play))
            newButton.tag = playButtonTag
            playerToolbar.items![at] = newButton
        }
        
        // Find play button
        var playButtonIndex = -1
        for (index, item) in (playerToolbar?.items)!.enumerated() {
            if item.tag == playButtonTag {
                playButtonIndex = index
            }
        }
        // Change it as needed
        switch newState {
        case .playing:
            // middle button should pause if we're playing
            swapPlayButton(for: .pause, at: playButtonIndex)
            avplayer.rate = 1.0
            avplayer.play()
        case .paused:
            // middle button should play if we're paused
            swapPlayButton(for: .play, at: playButtonIndex)
            avplayer.pause()
        case .fastforwarding:
            // middle button should pause if we're fast forwarding
            swapPlayButton(for: .pause, at: playButtonIndex)
            avplayer.rate = 2.0
        case .rewinding:
            // middle button should pause if we're rewinding
            swapPlayButton(for: .pause, at: playButtonIndex)
            avplayer.rate = -2.0
        }
        currentState = newState
    }
    
    // MARK: - Event handlers
    @IBAction func donePlaying(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func play(_ sender: Any) {
        if currentState == .paused {
            changeState(.playing)
        } else {
            // All states other than paused are somehow playing
            changeState(.paused)
        }
    }
    
    @IBAction func fastForward(_ sender: Any) {
        changeState(.fastforwarding)
    }
    
    @IBAction func rewind(_ sender: Any) {
        changeState(.rewinding)
    }
    
}
