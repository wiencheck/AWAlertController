//
//  GreatAlertController.swift
//  IdeaBox
//
//  Created by adam.wienconek on 21.08.2018.
//  Copyright © 2018 RKB. All rights reserved.
//

// swiftlint:disable switch_default_case

import UIKit

class GreatAlertController: UIViewController {

    public enum AlertContent {
        case picker
        case table
        case image
        case message
    }

    public enum AlertButtonStyle {
        /// Choosing this will perform action chosen by user
        case `default`
        /// Choosing this will take the selected row and perform confirmHandler(index:)
        case confirm
        /// Choosing this will dismiss the view and leave things unchanged
        case cancel
        /// choosing this will perform destructiveHandler(), dismiss the view and makes the button red
        case destructive
    }

    typealias ButtonAction = (title: String?, action: (() -> Void)?, style: AlertButtonStyle)

    static let nibName = "GreatAlertController"

    let contentType: AlertContent
    /// 
    var highlightedRow: Int?
    var messageTitle: String?
    var messageBody: String?
    var contentHeight: CGFloat = 0

    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var content: UIView!
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    var addedView: UIView?
    var data: [String]?
    var image: UIImage?

    var actions: [ButtonAction]?
    var buttons: [UIButton]?
    var onConfirmSelect: ((Int) -> Void)?
    var onDestructSelect: (() -> Void)?

    private let animator = DarkAnimator()

    /// Message
    init(title: String?, message: String?, actions: [ButtonAction]?) {
        contentType = .message
        messageTitle = title
        messageBody = message
        self.actions = actions
        super.init(nibName: GreatAlertController.nibName, bundle: nil)
    }

    /// Table & Picker
    init(title: String?, message: String?, actions: [ButtonAction]?, data: [String]?, style: AlertContent) {
        contentType = style
        messageTitle = title
        messageBody = message
        self.actions = actions
        self.data = data
        super.init(nibName: GreatAlertController.nibName, bundle: nil)
    }

    /// Image
    init(title: String?, message: String?, actions: [ButtonAction]?, image: UIImage?) {
        contentType = .image
        messageTitle = title
        messageBody = message
        self.actions = actions
        self.image = image
        super.init(nibName: GreatAlertController.nibName, bundle: nil)
    }

    @available (*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not available")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .fullScreen
        transitioningDelegate = self
        setLabels()
        setButtons()
        setContent()
        setAppearance()
    }

    @objc func dismissAction() {
        dismiss(animated: true, completion: nil)
    }

    private func setAppearance() {
        toolbar.barStyle = GreatAlertController.barStyle
        messageLabel.textColor = GreatAlertController.textColor
        titleLabel.textColor = GreatAlertController.textColor
        content.backgroundColor = GreatAlertController.backgroundColor
    }

    private func setContentHeight() {
        switch contentType {
        case .table:
            let maxHeight = Int(view.frame.height * 0.6)
            let dataCount = data?.count ?? 0
            let dataHeight = dataCount * 44
            content.heightAnchor.constraint(equalToConstant: CGFloat(min(maxHeight, dataHeight))).isActive = true
        case .picker:
            content.heightAnchor.constraint(equalToConstant: 64)
        case .image:
            guard let image = image else {
                return
            }
            content.addConstraint(NSLayoutConstraint(item: content, attribute: .height, relatedBy: .equal, toItem: content,
                                                     attribute: .width, multiplier: image.size.height / image.size.width, constant: 0))
        case .message:
            content.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
    }

    func setContent() {
        switch contentType {
        case .table:
            addedView = UITableView(frame: .zero)
            if let table = addedView as? UITableView {
                table.delegate = self
                table.dataSource = self
                if let row = highlightedRow, row < data?.count ?? 0 {
                    table.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .top)
                }
            }
        case .picker:
            addedView = UIPickerView(frame: .zero)
            if let picker = addedView as? UIPickerView {
                picker.delegate = self
                picker.dataSource = self
                if let row = highlightedRow, row < data?.count ?? 0 {
                    picker.selectRow(row, inComponent: 0, animated: false)
                }
            }
        case .image:
            addedView = UIImageView(image: image)
        default:
            break
        }
        guard let added = addedView else { return }
        added.backgroundColor = .clear
        added.translatesAutoresizingMaskIntoConstraints = false
        added.layer.borderColor = GreatAlertController.borderColor
        added.layer.borderWidth = 0.7
        setContentHeight()
        content.addSubview(added)
        added.pinToSuperviewEdges()
    }

    func setLabels() {
        titleLabel.text = messageTitle
        messageLabel.text = messageBody
    }

    func setButtons() {
        buttons = []
        if let actions = actions {
            actions.forEach { action in
                let newButton = UIButton(type: .system)
                newButton.setTitle(action.title, for: .normal)
                let color: UIColor
                color = action.style == .destructive ? .red : GreatAlertController.buttonColor
                newButton.setTitleColor(color, for: .normal)
                let selector: Selector
                switch action.style {
                case .cancel:
                    selector = #selector(cancelPressed)
                case .confirm:
                    selector = #selector(confirmPressed)
                case .default:
                    selector = #selector(buttonPressed(_:))
                case .destructive:
                    selector = #selector(destructivePressed)
                }
                newButton.addTarget(self, action: selector, for: .touchUpInside)
                buttons?.append(newButton)
                stack.addArrangedSubview(newButton)
            }
        }
    }

    @objc private func confirmPressed() {
        var index: Int?
        switch contentType {
        case .table:
            if let table = addedView as? UITableView {
                index = table.indexPathForSelectedRow?.row
            }
        case .picker:
            if let picker = addedView as? UIPickerView {
                index = picker.selectedRow(inComponent: 0)
            }
        default:
            return
        }
        guard let indexo = index else { return }
        onConfirmSelect?(indexo)
        dismissAction()
    }

    @objc private func destructivePressed() {
        onDestructSelect?()
        dismissAction()
    }

    @objc private func buttonPressed(_ sender: UIButton) {
        guard let actions = actions, let indexOfButton = buttons?.index(of: sender) else {
            return
        }
        actions[indexOfButton].action?()
        dismissAction()
    }

    @objc private func cancelPressed() {
        dismissAction()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let first = touches.first else {
            return
        }
        let location = first.location(in: view)
        if !alertView.frame.contains(location) {
            dismissAction()
        }
    }

}

extension GreatAlertController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data?[component].count ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data?[row]
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

extension GreatAlertController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = .clear
        cell.textLabel?.text = data?[indexPath.row]
        cell.textLabel?.textColor = GreatAlertController.textColor
        return cell
    }
}

extension GreatAlertController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.transitionType = .present
        return animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.transitionType = .dismiss
        return animator
    }

}

extension GreatAlertController {
    static var barStyle: UIBarStyle = .default
    static var textColor: UIColor = .black
    static var backgroundColor: UIColor = .groupTableViewBackground
    static var destructiveButtonColor: UIColor = .red
    static var buttonColor: UIColor = UIApplication.shared.keyWindow?.tintColor ?? .blue
    static var highlightedCellColor: UIColor = .darkGray
    static var borderColor: CGColor = UIColor.lightGray.cgColor
}

extension UIView {
    func pinToSuperviewEdges() {
        guard let sup = superview else {
            return
        }
        NSLayoutConstraint.activate([
        leadingAnchor.constraint(equalTo: sup.leadingAnchor),
        trailingAnchor.constraint(equalTo: sup.trailingAnchor),
        topAnchor.constraint(equalTo: sup.topAnchor),
        bottomAnchor.constraint(equalTo: sup.bottomAnchor)
            ])
    }
}
