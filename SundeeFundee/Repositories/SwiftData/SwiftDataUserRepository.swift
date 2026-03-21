import Foundation
import SwiftData

final class SwiftDataUserRepository: UserRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ user: User) throws {
        context.insert(user)
        try context.save()
    }

    func fetchCurrentUser() throws -> User? {
        var descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func delete(_ user: User) throws {
        context.delete(user)
        try context.save()
    }
}
