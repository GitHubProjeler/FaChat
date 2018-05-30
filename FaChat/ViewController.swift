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

class ViewController: JSQMessagesViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var imagePicker = UIImagePickerController()
    var messages = [JSQMessage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Başlangıçta bazı şeyleri gizleme
//        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
//        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        senderId = "1"
        senderDisplayName = "Fatih"
    
    }
    
    //CollectionView Metotlar
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    //Mesajların rengini ayarlama, Bubbles images, outgoingBubble çağrıldığında yapılacak işlemler
    
    //Giden mesaj renk ayarı
    lazy var outgoingBubble:JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    }()
    //Gelen mesaj renk ayarı
    lazy var incomingBubble:JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        
    }()
    
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
        
//        let ref = Constants.dbRef.childByAutoId() // Uniq id oluşturu
//        let message = ["senderId":senderId, "senderName":senderDisplayName, "mesaj":text]
//        ref.setValue(message)
        
        self.messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
        
        collectionView.reloadData()
        
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
       
        //resim bilgileri alınarak kütüphanenin anlayacağı şekle dönüştürülüyor
        if let resim = info[UIImagePickerControllerOriginalImage] as? UIImage{
            let image = JSQPhotoMediaItem(image:resim)
            self.messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: image))
        }
        //videonun bilgileri kütüphanenin anlayacağı şekle dönüştürülüyor
        else if let video = info[UIImagePickerControllerMediaURL] as? URL{
            let myVideo = JSQVideoMediaItem(fileURL: video, isReadyToPlay: true)
            self.messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: myVideo))
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
    
}

