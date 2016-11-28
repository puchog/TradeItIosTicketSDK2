import UIKit

@objc public class TradeItTheme: NSObject {
    static public var textColor = UIColor.white
    //static public var headerTextColor = UIColor(red: 1.00, green: 0.57, blue: 0.00, alpha: 1.0)
    static public var warningTextColor = UIColor.tradeItDeepRoseColor()

    static public var backgroundColor = UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1.0)

    static public var tableBackgroundColor = UIColor(red: 0.36, green: 0.36, blue: 0.36, alpha: 1.0)
    static public var tableHeaderBackgroundColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)
    static public var tableHeaderTextColor = UIColor.white

    static public var interactivePrimaryColor = UIColor(red: 1.00, green: 0.57, blue: 0.00, alpha: 1.0)
    static public var interactiveSecondaryColor = backgroundColor

    static public var warningPrimaryColor = UIColor.tradeItDeepRoseColor()
    static public var warningSecondaryColor = UIColor.white

    static public var inputFrameColor = UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1.0)
}


@objc class TradeItThemeConfigurator: NSObject {
    static let TEMPLATE_ACCESSIBILITY_IDENTIFIERS = [
        "chevron_up",
        "chevron_down",
        "native_arrow"
    ]

    static func configure(view: UIView?) {
        guard let view = view else { return }
        configureTheme(view: view)
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    static func configureTableHeader(header: UIView?) {
        guard let header = header else { return }
        configureTheme(view: header, withinTableHeader: true)
        header.setNeedsLayout()
        header.layoutIfNeeded()
    }

    private static func configureTheme(view: UIView, withinTableHeader: Bool = false, withinTableCell: Bool = false) {
        var isTableCell = withinTableCell // TODO: This doesn't make sense
        switch view {
        case let label as UILabel:
            label.textColor = TradeItTheme.textColor
        case let button as UIButton:
            if button.backgroundColor == UIColor.clear {
                button.setTitleColor(TradeItTheme.interactivePrimaryColor, for: .normal)
            } else if button.title(for: .normal) == "Unlink Account" {
                button.setTitleColor(TradeItTheme.warningSecondaryColor, for: .normal)
                button.backgroundColor = TradeItTheme.warningPrimaryColor
            } else {
                button.setTitleColor(TradeItTheme.interactiveSecondaryColor, for: .normal)
                button.backgroundColor = TradeItTheme.interactivePrimaryColor
            }
        case let input as UITextField:
            input.backgroundColor = UIColor.clear
            input.layer.borderColor = TradeItTheme.inputFrameColor.cgColor
            input.layer.borderWidth = 1
            input.layer.cornerRadius = 4
            input.layer.masksToBounds = true
            input.textColor = TradeItTheme.textColor
            input.attributedPlaceholder = NSAttributedString(
                string: input.placeholder ?? "",
                attributes: [NSForegroundColorAttributeName: TradeItTheme.inputFrameColor]
            )
        case let input as UISwitch:
            input.tintColor = TradeItTheme.interactivePrimaryColor
            input.onTintColor = TradeItTheme.interactivePrimaryColor
        case let imageView as UIImageView:
            if isTemplateImage(imageView: imageView) {
                let image = imageView.image?.withRenderingMode(.alwaysTemplate)
                imageView.image = image
                imageView.tintColor = TradeItTheme.interactivePrimaryColor
            }
        case let tableView as UITableView:
            tableView.backgroundColor = TradeItTheme.tableBackgroundColor
            print("GGG \(type(of: tableView.backgroundView))")
            isTableCell = true
        case let cell as UITableViewCell:
            if withinTableHeader {
                cell.backgroundColor = TradeItTheme.tableHeaderBackgroundColor
            } else {
                isTableCell = true
                cell.backgroundColor = TradeItTheme.tableBackgroundColor
            }
        default:
//            print(type(of: view))
            if !(withinTableCell || withinTableHeader) {
                print("WHATTTT: \(type(of: view))")
                view.backgroundColor = UIColor.red//TradeItTheme.backgroundColor
            } else {
//                view.backgroundColor = UIColor.clear
            }
        }

        view.subviews.forEach { subview in
            configureTheme(view: subview, withinTableHeader: withinTableHeader, withinTableCell: isTableCell || withinTableCell)
        }
    }

    private static func isTemplateImage(imageView: UIImageView) -> Bool {
        return self.TEMPLATE_ACCESSIBILITY_IDENTIFIERS.contains(imageView.accessibilityIdentifier ?? "")
    }
}
