import AVFoundation
import AudioToolbox

final class SoundManager: NSObject, AVAudioPlayerDelegate {
    static let shared = SoundManager()

    private var player: AVAudioPlayer?

    private override init() {
        super.init()
    }

    func playBeep() {
        guard let url = Bundle.main.url(forResource = "Glass", withExtension: "aiff") else {
            AudioServicesPlaySystemSound(1057)
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
        } catch {
            AudioServicesPlaySystemSound(1057)
        }
    }
}
