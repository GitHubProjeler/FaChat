//
//  ViewController.swift
//  FaChat
//
//  Created by fatih acar on 29.05.2018.
//  Copyright © 2018 fatih acar. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseStorage
import FirebaseDatabase
import SDWebImage

class ViewController: JSQMessagesViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var imagePicker = UIImagePickerController()
    var messages = [JSQMessage]()
    
    //Mesajların rengini ayarlama, Bubbles images, outgoingBubble çağrıldığında yapılacak işlemler
    
    //Giden mesaj renk ayarı
    lazy var outgoingBubble:JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    }()
    //Gelen mesaj renk ayarı
    lazy var incomingBubble:JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Başlangıçta bazı şeyleri gizleme
//        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
//        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        senderId = "1"
        senderDisplayName = "Fatih"
        
        //text Mesaj içeriklerinin ekrana çekilmesi
        let lastMessages = Constants.dbChats.queryLimited(toLast: 20)//son 20 mesaj gösterilmektedir
        lastMessages.observe(.childAdded, with: {snapshot in
            if let data = snapshot.value as? [String:String],
            let senderId = data["senderId"],
            let displayName = data["senderName"],
            let text = data["mesaj"],
                !text.isEmpty{ //text boş değilse işlem yap
                if let message = JSQMessage(senderId: senderId, displayName: displayName, text: text){
                     self.messages.append(message)
                    self.finishReceivingMessage()
                   
                }
            }
        })
        
        //video Mesaj içeriklerinin ekrana çekilmesi
        let lastMediaMessages = Constants.dbMedias.queryLimited(toLast: 20)//son 20 mesaj gösterilmektedir
        lastMediaMessages.observe(.childAdded, with: {snapshot in
            if let data = snapshot.value as? [String:String],
                let senderId = data["senderId"],
                let displayName = data["senderName"],
                let url = data["url"],
                !url.isEmpty{ // boş değilse işlem yap
                if let mediaURL = URL (string:url){
                    do{
                        let data = try Data(contentsOf:mediaURL)
                        if let _ = UIImage(data: data){
                        let _ = SDWebImageDownloader.shared().downloadImage(with: mediaURL, options: [], progress: nil, completed: { (image, data, error, finish) in
                            DispatchQueue.main.async {
                                let photo = JSQPhotoMediaItem(image: image)
                                if senderId == senderId{
                                    photo?.appliesMediaViewMaskAsOutgoing = true
                                } else {
                                    photo?.appliesMediaViewMaskAsOutgoing = false
                                }
                                self.messages.append(JSQMessage(senderId: senderId, displayName: displayName, media: photo))
                                self.collectionView.reloadData()
                            }
                        })
                            
                        }
                        else {
                            let video = JSQVideoMediaItem(fileURL: mediaURL, isReadyToPlay: true)
                            if senderId == senderId{
                                video?.appliesMediaViewMaskAsOutgoing = true
                            } else {
                                video?.appliesMediaViewMaskAsOutgoing = false
                            }
                            self.messages.append(JSQMessage(senderId: senderId, displayName: displayName, media: video))
                            self.collectionView.reloadData()
                        }
                    }catch{
                        print("Bir hata oluştu.")
                    }
                    
                }
            }
        })
    
    }
    
    //CollectionView Metotlar
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
  
    
    //mesajın gelen-giden olduğunu anlamak için
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == senderId ? outgoingBubble : incomingBubble
        
    }

    //avatar gizleme
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }

    //Gönderici ismini gönderme ayarı
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return messages[indexPath.item].senderId == senderId ? nil : NSAttributedString(string:messages[indexPath.item].senderDisplayName)
    }

    //mesaj yüksekliği
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return messages[indexPath.item].senderId == senderId ? 0 : 20
    }
    
    //Gönder butonuna yapılacak işlemler
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        let ref = Constants.dbChats.childByAutoId() // Uniq id oluşturu
        let message = ["senderId":senderId, "senderName":senderDisplayName, "mesaj":text]

        self.messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
        
        collectionView.reloadData()
        ref.setValue(message)
        finishSendingMessage()
        
    }
    
    //ATTACHMENT İLE DOSYA GÖNDERME
    
    //alttan yukarı çıkan menü-actionSheet
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let actionSheet = UIAlertController(title: "Görsel Öğeler", message: "Lütfen bir görsel seçiniz", preferredStyle: .actionSheet) //style .actionSheet alttan çıkan mesaj - alert ortada mesaj
        
        //Kayıtlı görsel seçme
        let resim = UIAlertAction(title: "Resimler", style: .default){(action) in
            self.gorselSec(type: kUTTypeImage)//seçilen öğenin türü resim
        }
        let video = UIAlertAction(title: "Video", style: .default){(action) in
            self.gorselSec(type: kUTTypeMovie)//seçilen öğenin türü video
        }

        
        //iptal etmek için
        let iptal = UIAlertAction(title:"İptal", style: .cancel, handler: nil)
        
        
        actionSheet.addAction(resim)
        actionSheet.addAction(video)
        actionSheet.addAction(iptal)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func gorselSec(type:NSString){
        self.imagePicker.delegate = self // Delegate kod ile bağlanıyor
        self.imagePicker.mediaTypes = [type as String]  // media tipi neden string
        self.present(self.imagePicker, animated: true, completion:nil)
        
    }
    
    //Resim seçilmesi seçildikten sonra resim albümünün kapanması ve resim olarak görünmesi
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
       
        //resim bilgileri alınarak kütüphanenin anlayacağı şekle dönüştürülüyor ve gönderiliyor
        if let resim = info[UIImagePickerControllerOriginalImage] as? UIImage{
//            let image = JSQPhotoMediaItem(image:resim)
//            self.messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: image))
       let data = UIImageJPEGRepresentation(resim, 0.05)
            self.gorselMesajGonderme(image: data, video: nil, senderId: senderId, senderName: senderDisplayName)
        }
        //videonun bilgileri kütüphanenin anlayacağı şekle dönüştürülüyor ve gönderiliyor
        else if let video = info[UIImagePickerControllerMediaURL] as? URL{
//            let myVideo = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
//            self.messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: myVideo))
            self.gorselMesajGonderme(image: nil, video: video, senderId: senderId, senderName: senderDisplayName)
        }
        
        
        dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
    //videonun çalıştırılması
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let message = messages[indexPath.item]
        
        //tipi sadece media olanlar
        if message.isMediaMessage{
            if let videoMesaj = message.media as? JSQVideoMediaItem{ // media olanlardan sadece video olanlar
                let oynatici = AVPlayer(url: videoMesaj.fileURL) //videonun adresini al
                let oynaticiKontroller = AVPlayerViewController()
                oynaticiKontroller.player = oynatici
                present(oynaticiKontroller, animated: true, completion: nil)
            }
        }
    }
    
    func gorselMesajKaydetme(senderId: String, senderName: String, url: String){
        let data = ["senderId": self.senderId, "senderName": self.senderDisplayName, "url": url];
        print("***********DATAA:\(data)")
        Constants.dbMedias.childByAutoId().setValue(data)
    }
    
    func gorselMesajGonderme(image: Data?, video: URL?, senderId: String, senderName: String){
        if image != nil {
            Constants.imageStorageRef.child(senderId + "\(NSUUID().uuidString).jpg").putData(image!, metadata: nil) {(metadata: StorageMetadata?, error: Error?) in
                
                if error != nil{
                    print(error!)
                } else {
                 //   let downloadUrl = metadata!.downloadURL()
                 //   downloadUrl?.absoluteString
                    self.gorselMesajKaydetme(senderId: senderId, senderName: self.senderDisplayName, url: String(describing: metadata!.downloadURL()!))
                    
                }
                
            }
        } else {
            Constants.videoStorageRef.child(senderId + "\(NSUUID().uuidString)").putFile(from: video!, metadata: nil){(metadata: StorageMetadata?, error: Error?) in
            if error != nil {
                print(error!)
            } else {
                self.gorselMesajKaydetme(senderId: senderId, senderName:self.senderDisplayName, url: String(describing: metadata!.downloadURL()!))
            }
        }
        }
    }
}












