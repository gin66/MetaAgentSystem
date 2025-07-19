import Foundation
import OpenAPIKit
import NIO
import NIOHTTP1
import NIOFoundationCompat

// Handler to process HTTP responses
final class HTTPResponseHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = HTTPClientResponsePart
    typealias OutboundOut = HTTPClientRequestPart
    
    private let promise: EventLoopPromise<ByteBuffer>
    private var responseBuffer: ByteBuffer
    private var isComplete = false
    
    init(eventLoop: EventLoop) {
        self.promise = eventLoop.makePromise()
        self.responseBuffer = ByteBufferAllocator().buffer(capacity: 1024 * 1024)
    }
    
    deinit {
        if !isComplete {
            promise.fail(ChannelError.alreadyClosed)
        }
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        switch part {
        case .body(let buffer):
            var mutableBuffer = buffer
            responseBuffer.writeBuffer(&mutableBuffer)
        case .end(_):
            isComplete = true
            promise.succeed(responseBuffer)
        default:
            break
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        promise.fail(error)
        context.close(promise: nil)
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        if !isComplete {
            promise.fail(ChannelError.inputClosed)
        }
    }
    
    func getResponse() -> EventLoopFuture<ByteBuffer> {
        return promise.futureResult
    }
}

// Bootstrap method to prompt LLM for next steps
func bootstrapNextSteps() async throws {
    // Define project files and their contents
    let files = [
        "AgilePlan.md": "Agile implementation plan for Meta Agentic AI System using Swift, Ollama with structured output, and containerized agents.",
        "LogBook.md": "Log of project activities and progress.",
        "README.md": "Project overview, features, tech stack, and installation for Meta Agentic AI System with containerized agents.",
        "StakeholderRequirements.md": "Requirements for agent management, task assignment, performance evaluation, with agents in Swift containers.",
        "Vision.md": "High-level vision for the Meta Agentic AI System."
    ]
    
    // Construct prompt for LLM
    let prompt = """
    You are a project manager for a Meta Agentic AI System built in Swift, using Ollama with structured output mode and individual agents running in isolated Swift containers. The project directory contains:
    \(files.map { "- \($0.key): \($0.value)" }.joined(separator: "\n"))
    
    Based on these files, generate the next steps for the project in JSON format. The steps should:
    - Align with the AgilePlan.md for fast, testable sprints.
    - Advance the development of the system described in StakeholderRequirements.md and README.md.
    - Include specific tasks, deliverables, and acceptance criteria for the next sprint.
    - Ensure tasks are actionable, testable, and leverage Swift, Ollama, and containerized agents.
    - Output should be structured JSON with fields: `sprint_number`, `goal`, `tasks` (array of strings), `deliverable`, and `acceptance_criteria` (array of strings).
    """
    
    // Configure Ollama API request
    let ollamaHost = "localhost"
    let ollamaPort = 11434
    let ollamaPath = "/api/generate"
    let requestBody: [String: Any] = [
        "model": "devstral",
        "prompt": prompt,
        "format": "json",
        "stream": false
    ]
    
    // Convert request body to JSON data
    guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize JSON"])
    }
    
    // Set up NIO event loop group
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    // Create HTTP client using ClientBootstrap
    let client = ClientBootstrap(group: eventLoopGroup)
        .channelInitializer { channel in
            channel.pipeline.addHTTPClientHandlers().flatMap {
                channel.pipeline.addHandler(HTTPResponseHandler(eventLoop: channel.eventLoop))
            }
        }
        .connectTimeout(.seconds(30))
    
    // Connect to Ollama
    let channel = try await client.connect(host: ollamaHost, port: ollamaPort).get()
    
    // Create HTTP request
    var headers = HTTPHeaders()
    headers.add(name: "Content-Type", value: "application/json")
    headers.add(name: "Host", value: "\(ollamaHost):\(ollamaPort)")
    
    var requestHead = HTTPRequestHead(
        version: .http1_1,
        method: .POST,
        uri: ollamaPath
    )
    requestHead.headers = headers
    
    // Prepare request body
    var requestBodyBuffer = ByteBufferAllocator().buffer(capacity: jsonData.count)
    requestBodyBuffer.writeBytes(jsonData)
    
    // Send request
    try await channel.writeAndFlush(HTTPClientRequestPart.head(requestHead))
    try await channel.writeAndFlush(HTTPClientRequestPart.body(.byteBuffer(requestBodyBuffer)))
    try await channel.writeAndFlush(HTTPClientRequestPart.end(nil))
    
    // Get response from handler
    guard let handler = try? await channel.pipeline.handler(type: HTTPResponseHandler.self).get() else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve response handler"])
    }
    let responseBuffer = try await handler.getResponse().get()
    
    // Close channel
    try await channel.close()
    
    // Shut down event loop group in a non-blocking way
    let shutdownPromise = eventLoopGroup.next().makePromise(of: Void.self)
    eventLoopGroup.shutdownGracefully { error in
        if let error = error {
            shutdownPromise.fail(error)
        } else {
            shutdownPromise.succeed(())
        }
    }
    try await shutdownPromise.futureResult.get()
    
    // Decode JSON response
    guard let json = try JSONSerialization.jsonObject(with: responseBuffer, options: []) as? [String: Any],
          let responseString = json["response"] as? String,
          let responseData = responseString.data(using: .utf8),
          let nextSteps = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse LLM response"])
    }
    
    // Write response to file
    let outputPath = "NextSteps.json"
    try JSONSerialization.data(withJSONObject: nextSteps, options: .prettyPrinted)
        .write(to: URL(fileURLWithPath: outputPath))
    
    print("Next steps generated and saved to \(outputPath)")
}

// Run bootstrap method
let semaphore = DispatchSemaphore(value: 0)

Task {
    do {
        try await bootstrapNextSteps()
    } catch {
        print("Error: \(error.localizedDescription)")
    }
    semaphore.signal()
}

semaphore.wait()
