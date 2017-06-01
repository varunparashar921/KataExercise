//
//  ViewController.swift
//  VendingMachine
//
//  Created by Dulio Denis on 5/29/17.
//  Copyright © 2017 Mallikarjuna. All rights reserved.
//

import UIKit

private let reuseIdentifier = "vendingItem"
private let screenWidth = UIScreen.main.bounds.width

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    // Vending Machine Stored Property using the type of the protocol that defines Vending Machines
    let vendingMachine: VendingMachineType
    
    // the current selection (optional)
    var currentSelection: VendingSelection?
    
    // the quantity to purchase
    var quantity: Double = 1.0
    
    
    required init?(coder aDecoder: NSCoder) {
        // encapsulate the vending machine inside a do catch statement since initializing may throw errors
        do {
            let dictionary = try PlistConverter.dictionaryFromFile("VendingInventory", ofType: "plist")
            let inventory = try InventoryUnarchiver.vendingInventoryFromDictionary(dictionary)
            self.vendingMachine = VendingMachine(inventory: inventory)
        } catch let error {
            fatalError("\(error)")
        }
        
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViewCells()
        setupViews()
    }

    
    func setupViews() {
        updateQuantityLabel()
        updateBalanceLabel()
    }
    
    
    // MARK: - UICollectionView 

    func setupCollectionViewCells() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        let padding: CGFloat = 10
        layout.itemSize = CGSize(width: (screenWidth / 3) - padding, height: (screenWidth / 3) - padding)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vendingMachine.selection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VendingItemCell
        
        // display the item's icon by assigning to the CollectionView's custom cell's iconView
        let item = vendingMachine.selection[indexPath.row]
        cell.iconView.image = item.icon()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateCellBackgroundColor(indexPath, selected: true)
        
        resetLabels()
        currentSelection = vendingMachine.selection[indexPath.row]
        
        updateTotalPriceLabel()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateCellBackgroundColor(indexPath, selected: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        updateCellBackgroundColor(indexPath, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        updateCellBackgroundColor(indexPath, selected: false)
    }
    
    func updateCellBackgroundColor(_ indexPath: IndexPath, selected: Bool) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = selected ? UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0) : UIColor.clear
        }
    }
    
    
    // MARK: - Helper Methods
    
    @IBAction func purchase() {
        if let pickedSelection = currentSelection {
            do {
                try vendingMachine.vend(pickedSelection, quantity: quantity)
                updateBalanceLabel()
                resetLabels()
                showAlert("Succuess", message: "Your Purchase Sussuessfully done.")

            } catch VendingMachineError.outOfStock {
                showAlert("Out of Stock", message: "Sorry, but we are all out of that item")
            } catch VendingMachineError.invalidSelection {
                showAlert("Invalid Selection")
            } catch VendingMachineError.insufficientFunds(let amount) {
                showAlert("Insufficient Funds", message: "You need $\(amount) more in order to buy that item")
            } catch {
                showAlert("Generic Error")
            }
        } else {
            // FIXME: Alert user to no selection.
        }
    }
    
    
    @IBAction func updateQuantity(_ sender: UIStepper) {
        let itemQuantity = sender.value
        
        if let pickedSelection = currentSelection,
            let item = vendingMachine.itemForCurrentSelection(pickedSelection) {
            let totalPrice = item.price * itemQuantity
            if vendingMachine.amountDeposited >= totalPrice {
                totalLabel.text = "$ \(item.price * quantity)"
                quantity = sender.value
                updateTotalPriceLabel()
                updateQuantityLabel()
            } else {
               
                sender.value = itemQuantity-1
                showAlert("Insufficient Funds", message: "You are exceeded deposited amount")

            }
            
        }
        
    }
    
    
    @IBAction func depositFunds() {
        vendingMachine.deposit(5.00)
        updateBalanceLabel()
        showAlert("Deposit Successful", message: "You have an additional $5 to spend")
    }
    
    
    func updateTotalPriceLabel() {
        if let pickedSelection = currentSelection,
            let item = vendingMachine.itemForCurrentSelection(pickedSelection) {
                totalLabel.text = "$ \(item.price * quantity)"
        }
    }
    
    
    func updateQuantityLabel() {
        quantityLabel.text = "\(quantity)"
    }
    
    
    func updateBalanceLabel() {
        balanceLabel.text = "$ \(vendingMachine.amountDeposited)"
    }
    
    
    func resetLabels() {
        quantity = 1
        stepper.value = 1
        updateTotalPriceLabel()
        updateQuantityLabel()
    }
    
    
    func showAlert(_ title: String, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: dismissAlert)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    func dismissAlert(_ sender: UIAlertAction) {
        resetLabels()
    }
}

