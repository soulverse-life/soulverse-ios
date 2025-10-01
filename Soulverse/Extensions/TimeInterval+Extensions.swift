import Foundation

extension TimeInterval{

    func stringFromTimeInterval() -> String {
        
        let time = NSInteger(self)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        
        if hours > 0 {
            return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
        }
        return
            String(format: "%0.2d:%0.2d",minutes,seconds)
    }
    
    var minute: String {
        let mins = self / 60.0
        let time = NSInteger(mins.rounded())
        return String(format: "%d", time)
    }
}
