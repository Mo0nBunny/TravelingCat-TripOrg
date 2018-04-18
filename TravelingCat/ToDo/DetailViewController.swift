//
//  DetailViewController.swift
//  TravelingCat
//
//  Created by Sirin K on 07/12/2017.
//  Copyright © 2017 Sirin K. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate  {
    
    var category: Category?
    var taskArray = [ToDoList]()
    
    lazy var context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var taskTableView: UITableView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBAction func checkButtonTapped(_ sender: UIButton) {
        let cell: DetailTableViewCell = sender.superview?.superview as! DetailTableViewCell
        let table: UITableView = cell.superview as! UITableView
        let buttonIndexPath = table.indexPath(for: cell)
        let task = taskArray[(buttonIndexPath?.row)!]
        var taskIsDone: Bool
        
        if cell.checkButton.imageView?.image == #imageLiteral(resourceName: "check- empty") {
            taskIsDone = true
        } else {
            taskIsDone = false
        }
        task.isDone = taskIsDone
        task.category = category
        updateRecord(task: task)
        appDelegate.coreDataStack.saveContext()
        self.taskTableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let tasks = category?.tasks {
            self.taskArray = tasks.allObjects as! [ToDoList]
        }
        let taskArrayCount = taskArray.count
        if taskArrayCount == 0 {
            addNewTask()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(named: "background2")
        let imageView = UIImageView(image: image)
        imageView.center = taskTableView.center
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.8
        taskTableView.backgroundView = imageView
        
        
        if let detailCategory = self.category {
            navigationItem.title = detailCategory.title
            print(detailCategory)
        }
        
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
        return taskArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DetailTableViewCell
        cell.inputTask.delegate = self
        cell.inputTask.text = taskArray[indexPath.row].task
        cell.doneLabel.isHidden = true
        
        let taskDone = taskArray[indexPath.row].isDone
        if taskDone == true {
            cell.checkButton.setImage(#imageLiteral(resourceName: "check- done"), for: .normal)
            cell.doneLabel.isHidden = false
            cell.doneLabel.text = taskArray[indexPath.row].task
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: cell.doneLabel.text!)
            attributeString.addAttribute(NSAttributedStringKey.strikethroughStyle, value: 1, range: NSMakeRange(0, attributeString.length) )
            cell.doneLabel?.attributedText =  attributeString
            cell.inputTask.isHidden = true
           
        } else {
            cell.inputTask.isHidden = false
            cell.checkButton.setImage(#imageLiteral(resourceName: "check- empty"), for: .normal)
        }
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let cell: DetailTableViewCell = textField.superview?.superview as! DetailTableViewCell
        let table: UITableView = cell.superview as! UITableView
        let textFieldIndexPath = table.indexPath(for: cell)
        
        cell.isEditing = false

        let task = taskArray[(textFieldIndexPath?.row)!]
        task.task = cell.inputTask.text!
        task.isDone = false
        task.category = category
        updateRecord(task: task)
        appDelegate.coreDataStack.saveContext()
        self.taskTableView.reloadData()
        if taskArray[taskArray.count - 1].task != "" {
        addNewTask()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        self.taskTableView.endEditing(true)
    }
    
    func addNewTask() {
        let entity = NSEntityDescription.entity(forEntityName: "ToDoList", in: context)
        let task = ToDoList(entity: entity!, insertInto: context)
        task.task = ""
        task.isDone = false
        task.category = category
        appDelegate.coreDataStack.saveContext()
        taskArray.append(task)
        
        self.taskTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteRecord(task: self.taskArray[indexPath.row])
            context.delete(self.taskArray[indexPath.row])
            do {
                try context.save()

                self.taskArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                print("saved!")
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        taskTableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            taskTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardSize.height + 40, 0)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            taskTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
        }
    }
    
    func saveToCloud(task: ToDoList) {
        let toDoListRecord = CKRecord(recordType: "ToDoList")
        let reference = CKReference(recordID: CKRecordID(recordName: (category?.id)!), action: .deleteSelf)
        toDoListRecord["isDone"] = task.isDone as! CKRecordValue
        toDoListRecord["task"] = task.task as! CKRecordValue
        toDoListRecord["category"] = reference as CKRecordValue
        CKContainer.default().privateCloudDatabase.save(toDoListRecord) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    print("Task saved to iCloud")
                    task.id = record?.recordID.recordName
                }
            }
        }
    }
    
    func updateRecord(task: ToDoList) {
        if let taskId = task.id {
            CKContainer.default().privateCloudDatabase.fetch(withRecordID: CKRecordID(recordName: taskId)) { (record, error ) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        if let taskRecord = record {
                            taskRecord.setValue(task.isDone, forKey: "isDone")
                            taskRecord.setValue(task.task, forKey: "task")
                            let operation = CKModifyRecordsOperation(recordsToSave: [taskRecord], recordIDsToDelete: nil)
                            CKContainer.default().privateCloudDatabase.add(operation)
                            print("Task updated")
                        } else {
                            self.saveToCloud(task: task)
                        }
                    }
                }
            }
        } else {
            saveToCloud(task: task)
        }
    }
    
    func deleteRecord(task: ToDoList) {
        if let taskId = task.id {
            CKContainer.default().privateCloudDatabase.fetch(withRecordID: CKRecordID(recordName: taskId)) { (record, error ) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        if let taskRecord = record {
                            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [taskRecord.recordID])
                            CKContainer.default().privateCloudDatabase.add(operation)
                            print("Task deleted")
                        }
                    }
                }
            }
        }
    }
}
