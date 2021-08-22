//
//  ViewController.swift
//  DemoAf
//
//  Created by Raheel Rehman on 22/08/2021.
//

import UIKit
import Alamofire

class ViewController: UIViewController {
    
    @IBOutlet weak var imgView1 : UIImageView!
    @IBOutlet weak var imgView2 : UIImageView!
    @IBOutlet weak var imgView3 : UIImageView!
    
    @IBOutlet weak var progressBar1 : UIProgressView!
    @IBOutlet weak var progressBar2 : UIProgressView!
    @IBOutlet weak var progressBar3 : UIProgressView!
    
    private let byteFormatter: ByteCountFormatter = {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            return formatter
        }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.downloadImage(url: "https://i.imgur.com/fM7wMuu.jpeg", imageView:  self.imgView1, progressView:  self.progressBar1)
            self.downloadImage(url: "https://i.imgur.com/fM7wMuu.jpeg", imageView:  self.imgView2, progressView:  self.progressBar2)
            self.downloadImage(url: "https://i.imgur.com/fM7wMuu.jpeg", imageView:  self.imgView3, progressView:  self.progressBar3)
        }
    }
    
    func downloadImage(url: String, imageView: UIImageView, progressView: UIProgressView) {
        AF.download(url)
            .responseData(completionHandler: { data in
                imageView.image = UIImage(data: data.value ?? Data())
            })
            .downloadProgress {  progress in
                print("Download Progress: \(progress.fractionCompleted)")
                progressView.progress = Float(progress.fractionCompleted)
            }
           
    }
}

  
