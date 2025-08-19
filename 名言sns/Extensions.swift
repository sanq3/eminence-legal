import SwiftUI

extension String: @retroactive Identifiable {
    public var id: String { self }
}