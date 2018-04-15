import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")

        acronymsRoutes.get(use: getAllHandler)
        acronymsRoutes.get(Acronym.parameter,
                           use: getHandler)
        acronymsRoutes.post(Acronym.self,
                            use: createHandler)
        acronymsRoutes.put(Acronym.parameter,
                           use: updateHandler)
        acronymsRoutes.delete(Acronym.parameter,
                              use: deleteHandler)
        acronymsRoutes.get("search",
                           use: searchHandler)
        acronymsRoutes.get("first",
                           use: firstHandler)
        acronymsRoutes.get("sorted",
                           use: sortedHandler)
//        acronymsRoutes.get("filter", use: filterHandler)
        acronymsRoutes.get(Acronym.parameter,
                           "user",
                           use: getUserHandler)
        acronymsRoutes.post(Acronym.parameter,
                            "categories",
                            Category.parameter,
                            use: addCategoriesHandler)
        acronymsRoutes.get(Acronym.parameter,
                           "categories",
                           use: getCategoriesHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameter(Acronym.self)
    }
    
    func createHandler(_ req: Request, acronym: Acronym) throws -> Future<Acronym> {
        return acronym.save(on: req)
    }
    
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self,
                           req.parameter(Acronym.self),
                           req.content.decode(Acronym.self)) { (acronym, updatedAcronym) in
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            acronym.userID = updatedAcronym.userID
                            
                            return acronym.save(on: req)
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameter(Acronym.self).flatMap(to: HTTPStatus.self, { (acronym) in
            return acronym.delete(on: req).transform(to: HTTPStatus.noContent)
        })
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
    
        return try Acronym.query(on: req).group(.or) { or in
            try or.filter(\.short == searchTerm)
            try or.filter(\.long == searchTerm)
            }.all()
    }
    
//    func filterHandler(_ req: Request) throws -> Future<[Acronym]> {
//        let qq = try req.query.get(String.self, at: ["term", "otro"])
//        print(qq)
//        throw Abort(.gone)
//    }
    
    func firstHandler(_ req: Request) throws -> Future<Acronym> {
        return Acronym.query(on: req).first().map(to: Acronym.self, { (acronym) -> Acronym in
            guard let first = acronym else {
                throw Abort(.notFound)
            }
            
            return first
        })
    }
    
    func sortedHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try Acronym.query(on: req)
            .sort(\Acronym.short, QuerySortDirection.ascending)
            .all()
    }
    
    func getUserHandler(_ req: Request) throws -> Future<User> {
        return try req.parameter(Acronym.self)
            .flatMap(to: User.self, { (acronym) -> Future<User> in
                try acronym.user.get(on: req)
            })
    }
    
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self,
                           req.parameter(Acronym.self),
                           req.parameter(Category.self), { (acronym, category) -> EventLoopFuture<HTTPStatus> in
                            let pivot = try AcronymCategoryPivot(acronymID: acronym.requireID(), categoryID: category.requireID())
                            return pivot.save(on: req).transform(to: HTTPStatus.created)
        })
    }
    
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameter(Acronym.self)
            .flatMap(to: [Category].self, { (acronym) -> Future<[Category]> in
                try acronym.categories.query(on: req).all()
            })
    }
}
