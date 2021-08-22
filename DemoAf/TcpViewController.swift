//
//  TcpViewController.swift
//  DemoAf
//
//  Created by Raheel Rehman on 22/08/2021.
//

import UIKit
import CocoaAsyncSocket

class TcpViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var openGallery: UIButton!
    @IBOutlet weak var imgView: UIImageView!
    
    let namesQueue = DispatchQueue(label: "SocketNamesQueue", attributes: .concurrent)
    var names = [
        "Belgarion",
        "Ce'Nedra",
        "Belgarath",
        "Polgara",
        "Durnik",
        "Silk",
        "Velvet",
        "Poledra",
        "Beldaran",
        "Beldin",
        "Geran",
        "Mandorallen",
        "Hettar",
        "Adara",
        "Barak"
    ]
    var myName = ""
    var socketNames: [GCDAsyncSocket: String] = [:]

    
    var netService: NetService?
    var socket: GCDAsyncSocket?
    let socketQueue = DispatchQueue(label: "SocketQueue")
    let clientArrayQueue = DispatchQueue(label: "ConnectedSocketsQueue", attributes: .concurrent)
    var connectedSockets: [GCDAsyncSocket] = []
    var netServiceBrowser: NetServiceBrowser?
    var serverAddresses: [Data]?
    
    var host = false
    var connected = false
    var joined = false
    var hostAfterTask: DispatchWorkItem?
    
    var tempimages = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACAAgMAAAC+UIlYAAAAA3NCSVQICAjb4U/gAAAACXBIWXMAAAbzAAAG8wEhr4blAAAAGXRFWHRTb2Z0d2FyZQB3d3cuaW5rc2NhcGUub3Jnm+48GgAAAAlQTFRF////AAAAAAAAflGpXQAAAAJ0Uk5TAICbK04YAAAA90lEQVRYw+3Vu5HFMAxDUTBxEazG9bgaFuGEr8pNPBpZJoEtQIhvcMYfCdjb29trdv3oEs6DGwcPAsaDUyAS4Igb4IgAOOIUTyIBjrgBjgiAI07xOvJ5X84JBBFPYILQInJ8NM4JLSJGYILQIHL6cp0TGkRMgQlCicjX7+OcUCLiFZggFIhc/mHnhAIRS2CC8EHk5yBxTvgg4hOYICyILE4z54QFEUVggvBCZHmkOie8EFEGJggTIptz3TlhQkQTmCAMRLaXi3PCQEQbmCA8iCQ3nHPCgwgSmCAAFycAzgnAwQmACQJwpbjr/RbBESKwE3t7e3v/2x/S4KgfRMIjpAAAAABJRU5ErkJggg=="
    
    @IBAction func gallery(_ sender: Any) {
        
        openImagePicker()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
     
     
      
        
        imgView.image = base64Convert(base64String: tempimages)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        join();
    }

    
    func getName() -> String {
        return names.remove(at: Int(arc4random_uniform(UInt32(names.count))))
    }
    
    func putName(_ name: String) {
        names.append(name)
    }
    
    
    func openImagePicker() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            let imagePickerController = UIImagePickerController()
               imagePickerController.allowsEditing = false //If you want edit option set "true"
               imagePickerController.sourceType = .photoLibrary
               imagePickerController.delegate = self
               present(imagePickerController, animated: true, completion: nil)
               }
    }
   
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let tempImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        print("finished pick image")

        imgView.image = tempImage
        let imageData = tempImage.jpegData(compressionQuality: 0.2)
        let base64String = imageData!.base64EncodedString()
        tempimages = base64String
        self.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func base64Convert(base64String: String?) -> UIImage{
       if (base64String?.isEmpty)! {
           return UIImage()
       }else {
        let dataDecoded:NSData = NSData(base64Encoded: base64String ?? "", options: NSData.Base64DecodingOptions(rawValue: 0)) ?? NSData()
        let decodedimage:UIImage = UIImage(data: dataDecoded as Data) ?? UIImage()
        print(decodedimage)
        return decodedimage
       }
     }
    @objc func join() {
       
        
        if joined {
            if host {
                stopHosting()
            } else {
                netServiceBrowser?.stop()
                socket?.disconnect()
                hostAfterTask?.cancel()
                socket = nil
                netService = nil
                serverAddresses = nil
            }
        } else {
            
            
            // Browse for an existing service
            startNetServiceBrowser()
            
            // After 3 seconds, if no service has been found, start one
            hostAfterTask = DispatchWorkItem {
                self.netServiceBrowser?.stop()
                self.startHosting()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: hostAfterTask!)
        }
        
        joined = !joined
    }
    
    func startNetServiceBrowser() {
        netServiceBrowser = NetServiceBrowser()
        netServiceBrowser?.delegate = self
        netServiceBrowser?.searchForServices(ofType: "_LocalNetworkingApp._tcp", inDomain: "local.")
    }
    
    func connectToNextAddress() {
        var done = false
        while (!done && serverAddresses?.count ?? 0 > 0) {
            if let addr = serverAddresses?.remove(at: 0) {
                do {
                    try socket?.connect(toAddress: addr)
                    done = true
                } catch let error {
                    print("ERROR: \(error)")
                }
            }
        }
        
        if !done {
            print("Unable to connect to any resolved address")
        }
    }
    
    func startHosting() {
        // Create the listen socket
        socket = GCDAsyncSocket(delegate: self, delegateQueue: socketQueue)
        do {
            try socket?.accept(onPort: 0)
        } catch let error {
            print("ERROR: \(error)")
            return
        }

        let port = socket!.localPort
        
        // Publish a NetService
        netService = NetService(domain: "local.", type: "_LocalNetworkingApp._tcp", name: "BelgariadChat", port: Int32(port))
        netService?.delegate = self
        netService?.publish()
        
        // Host mode on
        host = true
        
        
      
    }
    
    func stopHosting() {
        // Stop listening
        socket?.disconnect()
        
        netService?.stop()
        netService = nil
        
        // Remove the clients
        clientArrayQueue.async {
            for socket in self.connectedSockets {
                socket.disconnect()
            }
        }
      
        socket = nil
        
        // Host mode off
        host = false
    }
    
    
    

    
    @IBAction func sendButtonTapped(_ sender: Any) {
        
        let imageStr = tempimages
            //imageData?.base64EncodedString(options: .lineLength64Characters) ?? ""
        //print("Image Data: ",  imageStr)
        
        let message = ImageModel(sender: myName, message: "", timestamp: Date(), image: imageStr)
        print("Message Data: ", message)
        var messageData: Data
        do {
            messageData = try message.toJsonData()
            print("Message Data: ", messageData)
        } catch let error {
            print("ERROR: Couldn't serialize message \(error)")
            return
        }
        messageData.append(GCDAsyncSocket.crlfData())
        socket?.write(messageData, withTimeout: -1, tag: 0)
    
}
}


extension TcpViewController: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("ERROR: \(errorDict)")
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        hostAfterTask?.cancel()
        if netService == nil {
            netService = service
            netService?.delegate = self
            netService?.resolve(withTimeout: 5)
        }
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("NetServiceBrowser did stop search")
    }
}

extension TcpViewController: NetServiceDelegate {
    
    // Client
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("NetService did not resolve: \(errorDict)")
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        if serverAddresses == nil {
            serverAddresses = sender.addresses
        }
        if socket == nil {
            socket = GCDAsyncSocket(delegate: self, delegateQueue: socketQueue)
            connectToNextAddress()
        }
    }
    
    // Host
    func netServiceDidPublish(_ sender: NetService) {
        print("Bonjour Service Published: domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name)) port(\(sender.port))")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("Failed to publish Bonjour Service domain(\(sender.domain)) type(\(sender.type)) name(\(sender.name))\n\(errorDict)")
    }
}

extension TcpViewController: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Socket did connect to host \(host) on port \(port)")
        connected = true
        // Connected to host, start reading
        socket?.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        clientArrayQueue.async(flags: .barrier) {
            self.connectedSockets.append(newSocket)
        }
      
        
        // Send the client their name
        let nameMessage = ImageModel(sender: ImageModel.SERVER_NAME_SENDER, message: getName(), timestamp: Date(), image: tempimages)
        do {
            var messageData = try nameMessage.toJsonData()
            messageData.append(GCDAsyncSocket.crlfData())
            newSocket.write(messageData, withTimeout: -1, tag: 0)
        } catch let error {
            print("ERROR: \(error) - Couldn't serialize message \(nameMessage)")
        }
        
    
        
        // Send a system message alerting that a client has joined
        let message = ImageModel(sender: ImageModel.SERVER_MSG_SENDER, message: "\("Raheel") has joined", timestamp: Date(), image: tempimages)
       

        do {
            var messageData = try message.toJsonData()
            messageData.append(GCDAsyncSocket.crlfData())
            clientArrayQueue.async {
                for client in self.connectedSockets {
                    client.write(messageData, withTimeout: -1, tag: 0)
                }
            }
        } catch let error {
            print("ERROR: \(error) - Couldn't serialize message \(message)")
        }
        
        DispatchQueue.main.async {
            self.imgView.image = self.base64Convert(base64String: message.image)
        }
        
        // Wait for a message
        newSocket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("Socket did read data with tag \(tag)")
        
        if let string = String(data: data, encoding: .utf8) {
            print(string)
        }
        
        // Incoming message
        let messageData = data
        let message: ImageModel
        do {
            message = try ImageModel(jsonData: messageData)
            
            
        } catch let error {
            print("ERROR: Couldnt create Message from data \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async {
            print("image convert", message.image)
            self.imgView.image = self.base64Convert(base64String: message.image)
       
        }
        
        if message.sender == ImageModel.SERVER_NAME_SENDER {
            // Received name from the server
            guard !host else {
                print("ERROR: Why is the host getting sent a name?")
                return
            }
            myName = message.message
            
        }

        
        if host {
            
            // Forward the message to clients
            clientArrayQueue.async {
                for client in self.connectedSockets {
                    if client == sock {
                        // Don't send the message back to the client who sent it
                        continue
                    }
                        client.write(data, withTimeout: -1, tag: 0)
                }
            }
        }
        
        // Read the next message
        sock.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("Socket did disconnect \(err?.localizedDescription ?? "")")
        if host {
            clientArrayQueue.async(flags: .barrier) {
                if let index = self.connectedSockets.firstIndex(of: sock) {
                    self.connectedSockets.remove(at: index)
                }
            }
            
            

            
            
           
            
        } else {
            // Reset
            connected = false
            joined = false
            socket = nil
            netService = nil
            serverAddresses = nil
            
          
        }
    }
}
