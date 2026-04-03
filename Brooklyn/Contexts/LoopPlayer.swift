//
//  LoopPlayer.swift
//  Brooklyn
//
//  Created by Pedro Carrasco on 23/02/2019.
//  Copyright © 2019 Pedro Carrasco. All rights reserved.
//

import AVFoundation

// MARK: - LoopPlayer
final class LoopPlayer: AVQueuePlayer {
    
    // MARK: Lifecycle
    init(items: [Animation], numberOfLoops: Int, shouldRandomize: Bool) {
        let items = (shouldRandomize ? items.shuffled() : items)
            .reduce(into: [AVPlayerItem]()) {
                guard let item = AVPlayerItem(video: $1, extension: .mp4, for: LoopPlayer.self) else { return }
                $0.append(contentsOf: Array(copy: item, count: numberOfLoops))
            }
            .prepareForQueue()

        super.init(items: items)
        isMuted = true
        volume = 0
        observe()
    }
    
    override init() {
        super.init()
    }
    
    
    deinit {
        unobserve()
    }
}

// MARK: - Actions
extension LoopPlayer {
    
    func play(_ animation: Animation) {
        guard let item = AVPlayerItem(video: animation, extension: .mp4, for: LoopPlayer.self) else { return }
        actionAtItemEnd = .none
        removeAllItems()
        [item].prepareForQueue().forEach {
            insert($0, after: items().last)
        }
        actionAtItemEnd = .advance
    }
}

// MARK: - Observers
private extension LoopPlayer {
    
    func observe() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidFinish(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    func unobserve() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
    }
    
    @objc
    func playerItemDidFinish(_ notification: Notification) {
        // Only handle our own player items
        guard let finishedItem = notification.object as? AVPlayerItem,
              items().contains(where: { $0 === finishedItem }) || currentItem === finishedItem else { return }
        // Keep queue small: only add if running low
        if items().count < 3 {
            guard let copy = finishedItem.copy() as? AVPlayerItem else { return }
            insert(copy, after: items().last)
        }
    }
}

// MARK: - AVPlayerItems' Utils
fileprivate extension Array where Element: AVPlayerItem {
    
    func prepareForQueue() -> [AVPlayerItem] {
        if count == 1, let itemCopy = first?.copy() as? AVPlayerItem {
            return self + [itemCopy]
        }
        
        return self
    }
    
    init(copy item: Element, count: Int) {
        let elements = [Int](0...count).compactMap { _ in return item.copy() as? Element }
        self.init(elements)
    }
}
