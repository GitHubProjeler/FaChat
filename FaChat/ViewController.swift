//
//  ViewController.swift
//  FaChat
//
//  Created by fatih acar on 29.05.2018.
//  Copyright © 2018 fatih acar. All rights reserved.
//

import UIKit
import JSQMessagesViewController

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
        
        //Kayıtlı resim seçmek için 1. seçenek olarak Resimler ismi çıkar
        let resim = UIAlertAction(title: "Resimler", style: .default){(action) in
            //kaynak savedPhotoAlbum
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.savedPhotosAlbum){
                self.imagePicker.delegate = self // Delegate kod ile bağlanıyor
                self.imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
                self.present(self.imagePicker, animated: true, completion:nil)
            }
        }
        
        //Kameradan seçim yapmak için
        let kamera = UIAlertAction(title: "Kamera", style: .default){(action) in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
                self.imagePicker.delegate = self // Delegate kod ile bağlanıyor
                self.imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                self.present(self.imagePicker, animated: true, completion:nil)
            }
        }
    
        
        //iptal etmek için
        let iptal = UIAlertAction(title:"İptal", style: .default, handler: nil)
        
        
        actionSheet.addAction(resim)
        actionSheet.addAction(kamera)
        actionSheet.addAction(iptal)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    //Resim seçilmesi seçildikten sonra resim albümünün kapanması ve resim olarak görünmesi
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
       
        //seçilen resmin bilgileri alınıyor info ile
        if let resim = info[UIImagePickerControllerOriginalImage] as? UIImage{
            let image = JSQPhotoMediaItem(image:resim)
            self.messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: image))
        }
        dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
    
    
}

