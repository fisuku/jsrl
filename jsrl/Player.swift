//
//  MediaPlayer.swift
//  jsrl
//
//  Created by Fisk on 14/11/2016.
//  Copyright © 2016 fisk. All rights reserved.
//

import AVFoundation
import MediaPlayer

class Player {
    static let shared = Player()
    
    var playList: [Track] = []
    var cursor = 0
    var currentTrack: Track?
    var player = AVPlayer()
    var jsrl: JSRL? = nil
    var station = "Future"
    var onPlayStart: (()->())? = nil
    
    var urlAsset: AVURLAsset? = nil
    var avItem: AVPlayerItem? = nil
    
    init() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Nothing",
            MPMediaItemPropertyArtist: "Fuck"
        ]
        
        initialiseMediaRemote()
    }
    
    func initialiseMediaRemote() {
        let remote = MPRemoteCommandCenter.shared()
        
        remote.togglePlayPauseCommand.addTarget(handler: { (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            if (self.currentTrack == nil) {
                self.next()
            } else if (self.isPlaying()) {
                self.player.pause()
            } else {
                self.player.play()
            }
            
            return MPRemoteCommandHandlerStatus.success
        })
        
        remote.playCommand.addTarget(handler: { (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            if (self.currentTrack == nil) {
                self.next()
            } else {
                self.player.play()
            }
            
            return MPRemoteCommandHandlerStatus.success
        })
        
        remote.pauseCommand.addTarget(handler: { (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            self.player.pause()
            return MPRemoteCommandHandlerStatus.success
        })
        
        remote.nextTrackCommand.addTarget(handler: { (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            self.next()
            return MPRemoteCommandHandlerStatus.success
        })
        
        remote.stopCommand.addTarget(handler: { (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus in
            self.player.pause()
            self.next()
            return MPRemoteCommandHandlerStatus.success
        })
    }
    
    func setCurrent(track: Track) {
        currentTrack = track
        urlAsset = AVURLAsset(url: (jsrl?.getMedia().resolveUrl(track.filename!))!)
        avItem = AVPlayerItem(asset: urlAsset!)
    }
    
    /**
     Play something on the AVPlayer.
 	 */
    func play() {
        self.onPlayStart!()
        self.player = AVPlayer(playerItem: avItem)
        self.player.play()
        
        let metadata = JSRLSongMetadata(currentTrack!)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: metadata.title,
            MPMediaItemPropertyArtist: metadata.artist,
            MPNowPlayingInfoPropertyPlaybackRate: 1
        ]
        
        NotificationCenter.default.addObserver(self, selector: #selector(next), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avItem)
    }
    
    /**
     Is true if the AVPlayer is currently playing a track.
     */
    func isPlaying() -> Bool {
        return ((player.rate != 0) && (player.error == nil))
    }
    
    @objc func next() {
        setCurrent(track: Library.shared.getRandomFrom(station: station))
        play()
    }
}
