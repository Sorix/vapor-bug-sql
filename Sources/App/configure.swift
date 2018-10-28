import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
	let databasePath: String = try Environment.getDatabaseURL()
	guard let databaseConfig = PostgreSQLDatabaseConfig(url: databasePath) else {
		throw Abort(.internalServerError, reason: "Invalid database configuration")
	}
	let sql = PostgreSQLDatabase(config: databaseConfig)
	
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sql, as: .psql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .psql)
    services.register(migrations)

}

extension Environment {
	static func getDatabaseURL() throws -> String {
		return try requiredValue(forKey: "DATABASE_URL")
	}
	
	private static func requiredValue(forKey key: String) throws -> String {
		guard let value = get(key) else { throw NoEnvironmentKey(key: key) }
		return value
	}
	
	private struct NoEnvironmentKey: AbortError {
		let status: HTTPResponseStatus = .internalServerError
		var reason: String { return "Server environment key " + key + " is not defined" }
		let identifier = "keyOrValueNotFound"
		let key: String
	}
}
