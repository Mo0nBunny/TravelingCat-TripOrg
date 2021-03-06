//
//  NewTripViewController.swift
//  TravelingCat
//
//  Created by Sirin on 29/03/2018.
//  Copyright © 2018 Sirin K. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import Flurry_iOS_SDK

class NewTripViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var tripTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var remindDate: UILabel!
    
    let colorLabel = ["yellow", "blue", "green"]
    
    lazy var context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func addButtonTapped(_ sender: Any) {
        
        if tripTextField.text == "" || dateLabel.text == "" {
            let alertController = UIAlertController(title: NSLocalizedString("001_app_name", comment: ""),
                                                    message: NSLocalizedString("009_error_enter_trip_date", comment: ""),
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("007_ok", comment: ""), style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "Trip", in: context)
            let trip = Trip(entity: entity!, insertInto: context)
            // set all the properties
            trip.tripTitle = tripTextField.text
            trip.tripDate = dateLabel.text
            
            if  let remindDate = remindDate.text {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yy"
                trip.tripRemind = dateFormatter.date(from: remindDate)
            }
            trip.tripImage = colorLabel[Int(arc4random_uniform(UInt32(colorLabel.count)))]
            
            let tripRecord = CKRecord(recordType: "Trip")
            if let tripImageValue = trip.tripImage {
                tripRecord["tripImage"] = tripImageValue as CKRecordValue
            }
            if let tripTitleValue = trip.tripTitle {
                tripRecord["tripTitle"] = tripTitleValue as CKRecordValue
            }
            if let tripDateValue = trip.tripDate {
                tripRecord["tripDate"] = tripDateValue as CKRecordValue
            }
            if let tripRemindValue = trip.tripRemind {
                tripRecord["tripRemind"] = tripRemindValue as CKRecordValue
            }
            
            CKContainer.default().privateCloudDatabase.save(tripRecord) { record, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        print("Saved to iCloud")
                        trip.id = record?.recordID.recordName
                    }
                }
            }
            Flurry.logEvent("Trips", withParameters: ["tripName": trip.tripTitle as Any])
            appDelegate.coreDataStack.saveContext()
            performSegue(withIdentifier: "unwindSegueFromNewTrip", sender: self)
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tripTextField.delegate = self
        cancelButton.setTitleTextAttributes([NSAttributedStringKey.font : UIFont(name: "AppleSDGothicNeo-Regular", size: 20)!], for: UIControlState.normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDatePicker" {
            let popup = segue.destination as! DatePopupViewController
            popup.onSave = { (data: String) in
                self.dateLabel.text = data
            }
        }
        if segue.identifier == "ShowTimePicker" {
            let popup = segue.destination as! TimePopupViewController
            popup.onSave = { (data: String) in
                self.remindDate.text = data
            }
            
        }
    }
}
