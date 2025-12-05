//
//  XMPPReceiveMessage.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import Foundation
import XMPPFramework

extension XMPPController {
    
    func handel_ChatMessage(_ message: XMPPMessage, withType type : String, withStrem : XMPPStream) {
        
        printLog("handling message \(String(describing: message))")
        if APP_DELEGATE.objEventData == nil {
            print("\(#function) | Nil data of APP_DELEGATE.objEventData")
            return
        }
        
        //TODO: Message - Singal
        var objMess : Message = Message.init()
        objMess.initWithMessage(message: message)
        let vId : String = objMess.id.trim()
        if vId.count == 0 {
            print("\(#function) | Message Id nil")
            return
        }
        
        let customElement : String = message.getCustomElementInfo(withKey: eleCustom.Kay)
        let vMessType : String = type
        let dicDate = ["type" : pluginMessType.Message,
                       "id" : objMess.id,
                       "from" : objMess.senderJid,
                       "body" : objMess.message,
                       "customText" : customElement,
                       "msgtype" : vMessType,
                       "senderJid": objMess.senderJid,
                       "time" : objMess.time] as [String : Any]
        APP_DELEGATE.objEventData!(dicDate)
    }
    
    func handelNormalChatMessage(_ message: XMPPMessage, withStrem : XMPPStream) {
        if message.hasReceiptResponse {
            guard let messId = message.receiptResponseID else {
                print("\(#function) | ReceiptResponseId is empty/nil.")
                return
            }
            self.senAckDeliveryReceipt(withMessageId: messId)
            return
        }
        
        // Check for read receipt (XEP-0333 Chat Markers - displayed element)
        if let displayedElement = message.element(forName: "displayed", xmlns: "urn:xmpp:chat-markers:0") {
            if let displayedId = displayedElement.attributeStringValue(forName: "id"), !displayedId.isEmpty {
                var objMess : Message = Message.init()
                objMess.initWithMessage(message: message)
                let vFrom : String = message.fromStr ?? ""
                
                let dicData = ["type" : pluginMessType.ACK_READ,
                             "id" : displayedId,
                             "from" : vFrom,
                             "body" : objMess.message,
                             "customText" : "",
                             "msgtype" : "normal",
                             "senderJid": vFrom,
                             "time" : ""] as [String : Any]
                
                APP_DELEGATE.objEventData!(dicData)
                self.broadCastMessageToFlutter(dicData: dicData)
                return
            }
        }
        
        var chatStateType : String = ""

        if  message.hasChatState {

            if message.hasComposingChatState {
                chatStateType = "composing"
            } else if message.hasGoneChatState {
                chatStateType = "gone"
            } else if message.hasPausedChatState {
                chatStateType = "paused"
            } else if message.hasActiveChatState {
                chatStateType = "active"
            } else if message.hasInactiveChatState {
                chatStateType = "inactive"
            }
//         return
        }
           var objMess : Message = Message.init()
           objMess.initWithMessage(message: message)

           let vFrom : String = message.fromStr ?? ""

            let dicData = ["type" : "chatstate",
                           "id" : objMess.id,
                           "from" : vFrom,
                           "body" : objMess.message,
                           "customText" : "",
                           "msgtype" : "normal",
                           "senderJid": vFrom,
                           "time" : "",
                           "chatStateType" : chatStateType] as [String : Any]

            APP_DELEGATE.objEventData!(dicData)
            self.broadCastMessageToFlutter(dicData: dicData)

    }
}
