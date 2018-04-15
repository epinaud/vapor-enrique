import FluentMySQL
import Foundation

final class AcronymCategoryPivot: MySQLUUIDPivot {
    var id: UUID?
    
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    typealias Left = Acronym
    typealias Right = Category
    
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID
    
    init(acronymID: Acronym.ID, categoryID: Category.ID) {
        self.acronymID = acronymID
        self.categoryID = categoryID
    }
}

extension AcronymCategoryPivot: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (builder) in
            try addProperties(to: builder)
            try builder.addReference(from: \AcronymCategoryPivot.acronymID, to: \Acronym.id)
            try builder.addReference(from: \AcronymCategoryPivot.categoryID, to: \Category.id)
        }
    }
}
