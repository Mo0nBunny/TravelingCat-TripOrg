//
//  MasterViewController.swift
//  TravelingCat
//
//  Created by Sirin K on 07/12/2017.
//  Copyright © 2017 Sirin K. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var addBttn: UIButton!
    
  
    var isEditAction: Bool = false
    var isAddAction: Bool = false
    let colorLabel = ["yellow", "blue", "green"]
    var categoryArray = [Category]()
    var trip: Trip?
    
    lazy var context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var categoryTableView: UITableView!
    
    @IBAction func addButton(_ sender: UIButton) {
        self.isAddAction = true
        
        // MARK: Create Core Data category
        let entity = NSEntityDescription.entity(forEntityName: "Category", in: context)
        
        let category = Category(entity: entity!, insertInto: context)
        category.title = "New Category"
        category.imageName = colorLabel[Int(arc4random_uniform(UInt32(colorLabel.count)))]
        category.trip = trip
        appDelegate.coreDataStack.saveContext()
        categoryArray.append(category)
        self.categoryTableView.reloadData()
        
        UIView.animate(withDuration: 0, delay: 0, options: .allowUserInteraction, animations: {
            let lastIndexPath = IndexPath(item: self.categoryArray.count - 1, section: 0)
            self.categoryTableView.scrollToRow(at: lastIndexPath, at: .top, animated: false)
        }) { (finished) in
            let newCell = self.categoryTableView.visibleCells.last as! CategoryTableViewCell
            newCell.inputCategory.text = "New Category \(self.categoryArray.count)"
            newCell.inputCategory.selectAll(nil)
            newCell.inputCategory.isHidden = false
            newCell.inputCategory.delegate = self
            newCell.inputCategory.becomeFirstResponder()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let categories = trip?.categories {
            self.categoryArray = categories.allObjects as! [Category]
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        
        do {
            let results = try context.fetch(fetchRequest)
            categoryArray = results as! [Category]
        } catch let error as NSError {
            print("Fetching Error: \(error.userInfo)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categoryTableView.tableFooterView = UIView(frame: CGRect.zero)
        //Mark - without text on back button
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        
        //MARK: - Keyboard issue
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CategoryTableViewCell
        cell.inputCategory.delegate = self
        let category = categoryArray[indexPath.row]
        let categoryName = category.title
        let categoryImage = category.imageName
        
        cell.categoryLabel.text = categoryName
        cell.categoryColor.image = UIImage(named: categoryImage!)
        cell.inputCategory.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        addBttn.isHidden = true
        
        let delete = UITableViewRowAction(style: .default, title: "Delete") {(action, indexPath) in
            self.context.delete(self.categoryArray[indexPath.row])
            
            do {
                try self.context.save()
                self.categoryArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                print("saved!")
                self.addBttn.isHidden = false
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
        
        let edit = UITableViewRowAction(style: .default, title: "Edit") {(action, indexPath) in
            self.isEditAction = true
            let cell = tableView.cellForRow(at: indexPath) as! CategoryTableViewCell
            let oldName = cell.categoryLabel.text
            cell.inputCategory.text = oldName
            cell.inputCategory.selectAll(nil)
            cell.inputCategory.isHidden = false
            self.addBttn.isHidden = false
        }
        
        edit.backgroundColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        delete.backgroundColor = #colorLiteral(red: 0.5803921569, green: 0.1764705882, blue: 0.1725490196, alpha: 1)
        
        return [delete, edit]
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        self.categoryTableView.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if isAddAction == true {
            let cell = self.categoryTableView.visibleCells.last as! CategoryTableViewCell
            cell.isEditing = false
            
            let category = categoryArray[categoryArray.count - 1]
            category.title = cell.inputCategory.text!
            category.trip = trip
            appDelegate.coreDataStack.saveContext()
            self.categoryTableView.reloadData()
            
            isAddAction = false
            
        } else if isEditAction == true {
            let cell: CategoryTableViewCell = textField.superview?.superview as! CategoryTableViewCell
            let table: UITableView = cell.superview as! UITableView
            let textFieldIndexPath = table.indexPath(for: cell)
            
            let category = categoryArray[(textFieldIndexPath?.row)!]
            category.title = cell.inputCategory.text!
            category.trip = trip
            appDelegate.coreDataStack.saveContext()
            self.categoryTableView.reloadData()

            isEditAction = false
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            if let indexPath = self.categoryTableView.indexPathForSelectedRow {
                let category = categoryArray[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.category = category
            }
        }
    }
    
    //MARK: Move textField
    @objc func keyboardWillShow(_ notification:Notification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            categoryTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardSize.height + 40, 0)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            categoryTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        categoryTableView.deselectRow(at: indexPath, animated: true)
    }
}
