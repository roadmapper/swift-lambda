//import AWSLambdaRuntime
//
//struct Input: Codable {
//  let number: Double
//}
//
//struct Output: Codable {
//  let result: Double
//}
//
//Lambda.run { (context, input: Input, callback: @escaping (Result<Output, Error>) -> Void) in
//  callback(.success(Output(result: input.number * input.number)))
//}
import AWSLambdaEvents
import AWSLambdaRuntime
import NIO
import Foundation
import PostgresKit

struct Input: Codable {
  let value: String
}

struct Record: Codable {
    var id: String
    var value: String
}


// MARK: - Run Lambda
Lambda.run(APIGatewayProxyLambda())

// MARK: - Handler, Request and Response
// FIXME: Use proper Event abstractions once added to AWSLambdaRuntime
struct APIGatewayProxyLambda: EventLoopLambdaHandler {
    public typealias In = APIGateway.V2.Request
    public typealias Out = APIGateway.V2.Response

    public func handle(context: Lambda.Context, event: APIGateway.V2.Request) -> EventLoopFuture<APIGateway.V2.Response> {
        context.logger.info("hello, from api gateway!")
        
        let value = event.body!
        let jsonData = value.data(using: .utf8)!
        let input = try! JSONDecoder().decode(Input.self, from: jsonData)


        let configuration = PostgresConfiguration(
            hostname: Lambda.env("DB_HOSTNAME")!,
            username: "postgres",
            password: Lambda.env("DB_PASSWORD")!,
            database: "app"
        )

        context.logger.info("use event loop")

        let eventLoopGroup = MultiThreadedEventLoopGroup.init(numberOfThreads: 2)
        let pools = EventLoopGroupConnectionPool(
            source: PostgresConnectionSource(configuration: configuration),
            on: eventLoopGroup
        )
        

        context.logger.info("starting pool")
        let postgres = pools.database(logger: .init(label: "test")) // PostgresDatabase
        let sql = postgres.sql() // SQLDatabase
        context.logger.info("starting connection")

        let id = UUID().description
        let record = Record(id: id, value: input.value)

        return try! sql.insert(into: "record").model(record).run().flatMap { _ in
            try! pools.syncShutdownGracefully()

            let jsonData2 = try! JSONEncoder().encode(record)
            let jsonString = String(data: jsonData2, encoding: .utf8)
            
            let headers: HTTPHeaders = ["Server": "Swift 5.2",
                                       "Content-Type": "application/json"]

            context.logger.info("completing")
            eventLoopGroup.shutdownGracefully{_ in}
            return context.eventLoop.makeSucceededFuture(APIGateway.V2.Response(statusCode: .created, headers: headers, body: jsonString))
        }
    }
}
