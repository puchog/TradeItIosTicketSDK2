import UIKit

class TradeItPreviewOrderWarningTableViewCell: UITableViewCell {
    @IBOutlet weak var warning: UILabel!

    override func awakeFromNib() {
        TradeItThemeConfigurator.configure(view: self)
        self.warning.textColor = TradeItSDK.theme.warningTextColor
    }

    func populate(withWarning warning: String) {
        self.warning.text = warning
    }
}
