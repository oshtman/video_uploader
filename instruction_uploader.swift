import Foundation
import Files // marathon:https://github.com/johnsundell/files.git

let semaphore = DispatchSemaphore(value: 0)
let token = ""
let url = URL(string: "http://localhost:3000/api/v1/instructions")!

func getVideoFiles() -> [File] {
    var files = [File]()
    for file in try Folder.current.files {
        if file.name.hasSuffix("mp4") {
            files.append(file)
        }
        files.append(file)
    }
    return files
}

func uploadVideos(_ files: [File]) {

    print("In upload videos")
    guard files.count > 0 else {
        print("🏁 Finished uploading all files")
        semaphore.signal()
        return
    }

    let file = files.first!

    let test = {
        var modified = files
        modified.remove(at: 0)
        uploadVideos(modified)
    }

    var req  = URLRequest(url: url)
    req.httpMethod = "POST"
    let boundary = "Boundary-\(UUID().uuidString)"
    req.addValue(token, forHTTPHeaderField: "X-PREVET-ACCESS-TOKEN")
    req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    req.httpBody = createBody(parameters: ["title": ""],
                        boundary: boundary,
                        data: try! file.read(),
                        mimeType: "video/mp4",
                        filename: "movie.mp4")

    let task = URLSession.shared.dataTask(with: req) { _, _, error in
        guard error == nil else {
            print("💥  Något gick fel\nAnledning: \(error!.localizedDescription)")
            exit(1)
        }
        print("Finished uploading \(file.name)")
        var modified = files
        modified.remove(at: 0)
        uploadVideos(modified)
    }
    task.resume()
}

func createBody(parameters: [String: String],
                boundary: String,
                data: Data,
                mimeType: String,
                filename: String) -> Data {
    let body = NSMutableData()

    let boundaryPrefix = "--\(boundary)\r\n"

    for (key, value) in parameters {
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
        body.appendString("\(value)\r\n")
    }

    body.appendString(boundaryPrefix)
    body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
    body.appendString("Content-Type: \(mimeType)\r\n\r\n")
    body.append(data)
    body.appendString("\r\n")
    body.appendString("--".appending(boundary.appending("--")))

    return body as Data
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

let videos = getVideoFiles()
uploadVideos(videos)
semaphore.wait()
