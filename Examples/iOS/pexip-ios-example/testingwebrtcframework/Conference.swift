//
//  Conference.swift
//  Pexip Native App Example
//
//  Created by Ian Mortimer on 29/11/2016.
//  Copyright © 2016 Pexip. All rights reserved.
//

import Foundation
import WebRTC
import GLKit

// Simple enum to pass back errors to the application
enum ServiceError {
    case ok, pinRequired, guestOnly, invalidPin, badRequest, error
}

class Conference {

    var uri: URI
    var displayName: String = "DemoApp"
    var tokenResp: [String: AnyObject]?
    var token: String?
    var pin: String? = "8276792"
    var rosterList: [Participant] = []
    var call: Call?
    var dyingCall: Call?
//    var queue = DispatchQueue(label: "com.pexip.demoapp")
    var eventSource: EventSource?
    var refreshTimer: Timer?
    var myParticipantUUID: UUID?

    var videoView: RTCEAGLVideoView?
    var localVideoView: IronBowVideoView!

    var queryTimeout: TimeInterval = 7
    var callQueryTimeout: TimeInterval = 62

    var httpAuth: String?

    let baseUri = "/api/client/v2/conferences/"

    init(uriString: String) {
        self.uri = URI(raw: uriString)!

        // Add some http auth if required
        let hash = "user:password"
        let hashData = hash.data(using: String.Encoding.ascii, allowLossyConversion: false)
        let finalHash = NSString(data: hashData!.base64EncodedData(), encoding: String.Encoding.utf8.rawValue)
        self.httpAuth = "Basic \(finalHash!)"
    }

    func tryToJoin(completion: @escaping (ServiceError) -> Void) {
        print("Attempting to join conference \(String(describing: self.uri.conference))")

        self.requestToken() { token in
            guard let token = token else {
                return
            }
            // Documentation https://docs.pexip.com/api_client/api_rest.htm#request_token
            print(token)

            if token["status"] as! String == "success" {
                if let hostPin = token["result"]?["pin"] as? String {

                    // Looks like we need PIN's - check if guests and / or hosts require them
                    // See https://docs.pexip.com/admin/pins_hosts_guests.htm for more information

                    if hostPin.lowercased() == "required" {
                        if let guestPin = token["result"]?["guest_pin"] as? String {
                            // If guest pin is none, they can select guest role and sit in waiting room
                            // otherwise they have to enter their guest pin if its required
                            completion(guestPin.lowercased() == "none" ? ServiceError.guestOnly : ServiceError.pinRequired)
                        } else {
                            completion(ServiceError.pinRequired)
                        }
                    }
                } else {
                    print("OK, we're in")

                    self.tokenResp = token["result"] as! [String : AnyObject]?
                    self.token = self.tokenResp?["token"] as? String

                    // At this point you could store the token information for later usage.
                    // For now let's stash the participant_uuid (needed later for participant operations)

                    let uuidString = self.tokenResp?["participant_uuid"] as! String
                    self.myParticipantUUID = UUID(uuidString: uuidString)

                    // Let's setup a timer to refresh the token
                    // Documentation https://docs.pexip.com/api_client/api_rest.htm#refresh_token
                    if let expires = self.tokenResp?["expires"] as? String,
                        let exp = Int(expires) {
                        DispatchQueue.main.async {
                            self.refreshTimer = Timer.scheduledTimer(timeInterval: TimeInterval(exp/4), target: self, selector: .refreshSelector, userInfo: nil, repeats: true);
                        }
                    } else {
                        print("Failed to create timer")
                    }

                    // And let's connect to the event stream
                    // Documentation https://docs.pexip.com/api_client/api_rest.htm?#server_sent
                    self.listenForEvents(failOnError: false)

                    completion(ServiceError.ok)
                }
            } else {
                print("failed")
                if let result = token["result"] as? String {
                    if result.lowercased() == "invalid pin" {
                        completion(ServiceError.invalidPin)
                    } else {
                        completion(ServiceError.error)
                    }

                }
            }
        }
    }

    func requestToken(completion: @escaping ([String: AnyObject]?) -> Void) {

        // Documentation https://docs.pexip.com/api_client/api_rest.htm#request_token

        // For proper operation, you should perform an SRV lookup as defined here:
        // https://docs.pexip.com/end_user/guide_for_admins/configuring_dns_pexip_app.htm
        // Then connect to the host that is returned from the lookup rather than the domain
        // in the URI

        guard let url = URL(string: "https://\(self.uri.host!)\(self.baseUri)\(self.uri.conference!)/request_token?display_name=\(self.displayName)")  else {
            print("failed to build request token URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = self.queryTimeout
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        if let auth = self.httpAuth {
            request.addValue(auth, forHTTPHeaderField: "Authorization")
        }
        if let pin = self.pin {
            request.addValue(pin, forHTTPHeaderField: "pin")
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            do {
                guard error == nil else {
                    print("error with request: \(String(describing: error))")
                    return
                }
                guard let data = data else {
                    print("no data in response")
                    return
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                    print("error trying to convert data to JSON")
                    return
                }
                completion(json)
            } catch {
                print("Got error with request")
            }
        }
        task.resume()
    }

    @objc func refreshToken(timer: Timer) {

        // Documentation https://docs.pexip.com/api_client/api_rest.htm#refresh_token

        guard let url = URL(string: "https://\(self.uri.host!)\(self.baseUri)\(self.uri.conference!)/refresh_token")  else {
            print("failed to build refresh token URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = self.queryTimeout
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        if let auth = self.httpAuth {
            request.addValue(auth, forHTTPHeaderField: "Authorization")
        }
        if let pin = self.pin {
            request.addValue(pin, forHTTPHeaderField: "pin")
        }
        if let token = self.token {
            request.addValue(token, forHTTPHeaderField: "token")
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            do {
                guard error == nil else {
                    print("error with request: \(String(describing: error))")
                    return
                }
                guard let data = data else {
                    print("no data in response")
                    return
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
                    print("error trying to convert data to JSON")
                    return
                }
                if let status = json["status"] as? String {
                    if status.lowercased() == "success" {
                        if let result = json["result"] as? [String: AnyObject] {
                            self.token = result["token"] as? String
                        }
                    }
                }
                print(" -- token refreshed --")
            } catch {
                print("Got error with refresh")
            }
        }
        task.resume()
    }

    func listenForEvents(failOnError: Bool) {
        //
        // Documentation https://docs.pexip.com/api_client/api_rest.htm?#server_sent
        //
        let path = "/api/client/v2/conferences/\(self.uri.conference!)/events"
        let urlStr = "https://\(self.uri.host!)\(path)"
        var headers: [String: String] = [:]
        if let auth = httpAuth { headers["Authorization"] = auth }
        if let token = token { headers["token"] = token }
        eventSource = EventSource(url: urlStr, headers: headers)
    }
    
    func participantRequest(url: URL) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        // The timeout here is greater as it can take up to 60s for the MCU
        // to timeout the outbound call if it doesn't reach a participant so
        // we need to give it time to return a failure response to us rather
        // than timing out the request ourselves
        // You could use something like:
        //   let action = url.lastPathComponent?.characters.split{$0 == "?"}.map(String.init)
        //   let timeout = action![0] == "calls" ? self.callsQueryTimeout : self.queryTimeout
        // in a generic "request" function for all calls to differentiate
        // between call and non-call API queries
        request.timeoutInterval = callQueryTimeout
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        request.addValues(["Content-type": "application/json",
                           "Authorization": httpAuth,
                           "pin": pin,
                           "token": token])
        return request as NSMutableURLRequest
    }
    
    var participantURLString: String? {
        guard let uuid = myParticipantUUID, let host = uri.host, let conference = uri.conference else { return nil }
        return "https://\(host)\(baseUri)\(conference)/participants/\(uuid.uuidString.lowercased())/calls"
    }
    var participantAcknowledgmentURLString: String? {
        guard let uuid = call?.uuid, let urlString = participantURLString else { return nil }
        return urlString.appending("/\(uuid.uuidString.lowercased())/ack")
    }
    
    // Call the 'participants' REST API to offer the provided SDP to the MCU
    // https://docs.pexip.com/api_client/api_rest.htm?#calls
    //
    func addParticipant(sdp: String, completion: @escaping (ServiceError) -> Void)
    {
        guard let urlString = participantURLString, let url = URL(string: urlString) else { return }
        var request = participantRequest(url: url) as URLRequest
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["call_type": "WEBRTC", "sdp": sdp], options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleParticipantResponse(data: data, response: response, error: error, completion: completion)
        }
        task.resume()
    }
    
    func handleParticipantResponse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (ServiceError) -> Void) {
        guard error == nil, let data = data, let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
            print(error == nil ? "Missing or unreadable data" : "Response error: \(String(describing: error))")
            return
        }
        
        // TODO: use model object instead of dictionary
        guard let status = json["status"] as? String, status.lowercased() == "success",
            let result = json["result"] as? [String: AnyObject],
            let uuidString = result["call_uuid"] as? String,
            let remoteSdp = result["sdp"] as? String else { return }
        
        print("Remote SDP: \(remoteSdp)")
        call?.uuid = UUID(uuidString: uuidString)
        call?.setRemoteSdp(sessionDescription: RTCSessionDescription(type: RTCSdpType.answer, sdp: remoteSdp)) { status in
            
            // check status and ACK the request to start the media flow
            // See https://docs.pexip.com/api_client/api_rest.htm?#ack
            //
            print("Remote SDP status: \(String(describing: status))")
            self.startCall()
            completion(.ok)
        }
    }
    
    func tryToEscalate(video: Bool, resolution: Resolution, completion: @escaping (ServiceError) -> Void) {
        call = Call(videoView: self.videoView!, videoEnabled: video, resolution: resolution) { sessionDescription in
            self.addParticipant(sdp: sessionDescription.sdp, completion: completion)
        }
        call?.localVideoView = localVideoView
    }


    // Start media
    // Documentation: https://docs.pexip.com/api_client/api_rest.htm?#ack
    //
    func startCall() {

        guard let urlString = participantAcknowledgmentURLString, let url = URL(string: urlString),
            let auth = self.httpAuth, let token = token else { return }
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        request.addValues(["Authorization": auth, "token": token])
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            guard error == nil else {
                print("error with request: \(String(describing: error))"); return
            }
        }
        task.resume()
    }

    func disconnectMedia(completion: @escaping (ServiceError) -> Void) {
        print("Tearing down call and media")

        // Bring down the call
        // Documentation: https://docs.pexip.com/api_client/api_rest.htm#call_disconnect

        let uuidString = self.myParticipantUUID!.uuidString.lowercased()
        let callUUIDString = self.call!.uuid!.uuidString.lowercased()
        let urlString = "https://\(self.uri.host!)\(self.baseUri)\(self.uri.conference!)/participants/\(uuidString)/calls/\(callUUIDString)/disconnect"
        guard let url = URL(string: urlString)  else {
            print("failed to build disconnect URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        if let auth = self.httpAuth {
            request.addValue(auth, forHTTPHeaderField: "Authorization")
        }

        if let pin = self.pin {
            request.addValue(pin, forHTTPHeaderField: "pin")
        }
        if let token = self.token {
            request.addValue(token, forHTTPHeaderField: "token")
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("error with request: \(String(describing: error))")
                return
            }
            // ignoring status here, we could parse it if we wanted to
            print("call disconnected")

            DispatchQueue.main.async {
                self.call?.peerConnection?.remove((self.call?.mediaStream)!)
                self.call?.mediaStream = nil
                self.call?.audioTrack = nil
                self.call?.videoTrack = nil

                self.call?.peerConnection?.close()
                self.call?.peerConnection = nil
                self.call?.videoView = nil
                self.call?.factory = nil
                RTCCleanupSSL()
            }
            completion(.ok)
        }
        task.resume()
    }

    func quit(completion: @escaping (ServiceError) -> Void) {

        // Quit the conference by releasing the token
        // Documentation: https://docs.pexip.com/api_client/api_rest.htm?#release_token


        if self.call != nil {
            self.disconnectMedia { status in
                print("Disconnected media stack")
            }
        }

        // Cancel the refresh timer, we're done
        DispatchQueue.main.async {
            print("Cancelled token refresh timer")
            self.refreshTimer?.invalidate()

            // Close down the event source
            self.eventSource!.close()

        }

        let urlString = "https://\(self.uri.host!)\(self.baseUri)\(self.uri.conference!)/release_token"
        guard let url = URL(string: urlString)  else {
            print("failed to build release URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        if let auth = self.httpAuth {
            request.addValue(auth, forHTTPHeaderField: "Authorization")
        }
        if let token = self.token {
            request.addValue(token, forHTTPHeaderField: "token")
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("error with request: \(String(describing: error))")
                return
            }
            print("Token released, event source closed, we're outta here")
            completion(.ok)
        }
        task.resume()
    }
    
    func tryToPresent(completion: @escaping (ServiceError) -> Void) {
        completion(.ok)
    }
    
}

// A small class to store our participants.  You could store much more information
// here that you receive from the API
class Participant {
    var name: String
    var uri: String
    var uuid: UUID

    init(name: String, uri: String, uuid: UUID) {
        self.name = name
        self.uri = uri
        self.uuid = uuid
    }
}

private extension Selector {
    static let refreshSelector =
        #selector(Conference.refreshToken(timer:))    
}

public extension NSMutableURLRequest
{
    public func addValues(_ values: [String: String?]) {
        for (key, value) in values {
            addValueIfNotNil(value, forHTTPHeaderField: key)
        }
    }
    
    public func addValueIfNotNil(_ value: String?, forHTTPHeaderField field: String) {
        guard let value = value else { return }
        addValue(value, forHTTPHeaderField: field)
    }
}
