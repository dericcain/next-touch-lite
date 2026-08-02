import SwiftUI

struct DrillCatalogItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: PracticeItemType
    let minutes: Int
    let description: String?
    let setup: String?
    let coachingPoints: String?
    let equipment: String?
    let resourceURL: URL?

    init(id: UUID, name: String, category: PracticeItemType, minutes: Int, description: String? = nil, setup: String? = nil, coachingPoints: String? = nil, equipment: String? = nil, resourceURL: URL? = nil) {
        self.id = id; self.name = name; self.category = category; self.minutes = minutes
        self.description = description; self.setup = setup; self.coachingPoints = coachingPoints; self.equipment = equipment; self.resourceURL = resourceURL
    }
}

private let fallbackStarterDrills: [DrillCatalogItem] = [
    DrillCatalogItem(id: UUID(uuidString: "12e3936f-7b2f-598a-8160-36ec6f19cdbe")!, name: "1. Ball Mastery in a Grid", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "2e4d2e08-2787-58ce-95d1-776f66c73cc4")!, name: "2. Dribbling Through Gates", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "9e0b926d-efa9-5f2d-b78f-f9d43f70b9c8")!, name: "3. Passing Through Windows", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "57a2b892-c839-59aa-8c3f-7fbb45c65296")!, name: "4. Three-Cone Passing Rotation", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "9c72406c-1ca2-5bfd-9713-060a79da8928")!, name: "5. Four-Cone Passing Rotation", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "88fad59f-0990-5276-85e2-28a86f1746c5")!, name: "6. Dynamic Partner Passing", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "419da2fd-2d2e-5327-b2ce-abdc93aab690")!, name: "7. Handling Flighted Serves", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "890c23bb-7439-5a32-80a9-042dc940e79c")!, name: "8. Reaction Gate 1v1", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "92e9b2af-223f-5dff-b869-efcc40464509")!, name: "9. Rondo Activation 3v1", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "1cbbc133-4c99-597d-9864-b5aa53a6927e")!, name: "10. Possession Tag in a Grid", category: .warmUp, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "64e50287-51be-5819-8355-081a1d86897e")!, name: "11. Dribbling With Turns", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "4d5d557e-1cf4-52e9-bda5-22d50fd9d562")!, name: "12. Ball Mastery Through Boxes", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "140d5a77-56a6-5e54-be89-4be6e99dfc13")!, name: "13. Dribbling in Traffic", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "231ef788-77ec-5f8f-8b83-2d0841738772")!, name: "14. Shielding From Pressure", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "c84c1150-17a1-566d-ac95-a07987e3f491")!, name: "15. Turning Away From Pressure", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "c2667549-79a7-5df2-b1ba-0c1a13e993e8")!, name: "16. Moves Against Defender", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "bc6b343e-cbbb-5226-a232-47a874939dce")!, name: "17. First Touch Through Gates", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "8eebcd6e-618b-5f7c-81bf-d2d0e552b53b")!, name: "18. Juggling to Control", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "5f55f142-49a3-5452-822c-fa1aa89b2a51")!, name: "19. Sole Control in Tight Space", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "a245b1f1-ae5f-5381-a4d4-c7fdb1fa77e8")!, name: "20. 1v1 Escape From Behind", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "d69f454e-803e-509a-ad96-07955f61fa78")!, name: "21. Inside-Foot Passing Through Gates", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "626dd0f4-3319-5aac-8dbf-d3621e19bc5f")!, name: "22. Variable Distance Passing", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "f8e2a283-21a2-56fc-a283-c97650551b17")!, name: "23. Fixed Distance Passing", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "7ea9eba6-ea91-5e7f-a57f-991ad80bc11d")!, name: "24. Triangle Combination Passing", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "ede22c4d-c561-55a3-bb01-9978deac73a0")!, name: "25. Wall Pass Combination", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "3051d998-31c3-55e8-8076-fdc9a03afdaf")!, name: "26. One-Touch Passing Pattern", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "10a336e3-9072-5a48-8f7d-9fd00e0561c0")!, name: "27. Four-Corner Switching Passes", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "6b015d16-e991-5338-9d1c-be594f867d52")!, name: "28. Six-Cone Passing Movement", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "e912a97e-bb71-54b9-b787-83fc27e66e07")!, name: "29. Long and Short Passing Sequence", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "aa967bf7-d6f3-538b-8525-0344468dcc7c")!, name: "30. Passing With Moving Targets", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "10f8d1ba-056f-5f65-82b9-ac0b5c19f4f3")!, name: "31. Receiving Across Body", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "165fe0df-2036-5755-8a4e-c814fbaf2b24")!, name: "32. Receiving With Back to Goal", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "b3a9a9dd-a161-5d3d-bd8c-1016a45b283e")!, name: "33. Receiving Facing Defender", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "38d8bb95-0c00-5cb8-820f-0abdb691ffc8")!, name: "34. First Touch Out of Pressure", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "10a87993-4498-55dd-b01c-af67ac70627c")!, name: "35. Aerial Receiving and Return", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "07cde9e8-3ec3-50b0-bc90-aa90d9407136")!, name: "36. Checking Away to Receive", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "731775ed-cdc8-5782-b82e-191e3d05b652")!, name: "37. Receiving Between Lines", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "34c69d85-1ed3-5a23-944e-a2936e1a7c17")!, name: "38. Directional First Touch", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "01a1216a-5bb6-588d-90e9-62215354cffb")!, name: "39. Receiving Under Contact", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "9fcd57d1-d115-5a5e-9778-32590e8f61b9")!, name: "40. Target Receiving and Layoff", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "f36d2901-3811-5593-889c-144138fbd0b5")!, name: "41. 3v3 Plus 3 Possession", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "3f6d5d7b-5b3b-5ba6-8497-806e37b562fe")!, name: "42. 4v4 Endzone Possession", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "6eabbc0d-42db-5f85-ac41-f92eb5089921")!, name: "43. 4v4 Zone Possession", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "be54e577-5597-57ea-b682-d33406426700")!, name: "44. 4v4 Corner Support Possession", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "fd3b18bf-6aee-55ac-ba80-aad10bc16372")!, name: "45. 4v4 Plus Neutral Possession", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "a2dd7c10-39ad-5a49-a058-7f64ad05668e")!, name: "46. Triangle Goal Possession", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "e7fcd65b-029a-5e3b-8c18-31a6c775a9dc")!, name: "47. Four-Corner Possession", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "34eb79f3-1e39-5c92-a69c-948cc556b30e")!, name: "48. Keep-Away With Targets", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "6b7ce780-8f00-5d08-b2a4-af998ade4311")!, name: "49. Possession to Gates", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "a08b079f-c694-552d-a969-8f9babb6647b")!, name: "50. Transition Keep Ball", category: .passing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "df0685ea-f2c2-520f-b4ae-72aca17ba056")!, name: "51. 3v1 Rondo", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "8bcc71d9-619c-5c24-8634-f3cf5dd58fc4")!, name: "52. 4v1 Rondo", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "b9f0b5ec-c987-5d5a-b931-0734c06b6c47")!, name: "53. 4v2 Rondo", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "290397ec-16e9-58ba-aa27-42904e3bc4ac")!, name: "54. 5v2 Rondo", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "4db0ec61-e072-5ada-a071-82fe7733e155")!, name: "55. 4v4 Plus 1 Rondo", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "f6464af5-ebbb-52cb-996f-aa91644c6819")!, name: "56. 4v4 Corner Rondo", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "366ba60f-23e9-54d1-9efb-d2327e12d410")!, name: "57. Directional Rondo to Targets", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "b06ab05d-eddc-53e8-9a0f-f1d5bf964309")!, name: "58. Transition Rondo 4v4 Plus 3", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "e5b62f0a-ff8d-5b4b-8e1b-643b8eb99875")!, name: "59. Rondo With Split Passes", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "2b638db2-4ec8-5de9-b32f-4f90fe885751")!, name: "60. Rondo to Mini Goals", category: .passing, minutes: 15),
    DrillCatalogItem(id: UUID(uuidString: "5817a341-b7f3-5361-b07b-5d6c19276672")!, name: "61. Finishing From Layoffs", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "277b6dd2-cfbb-508b-9273-239dbdbd29db")!, name: "62. 1v1 Finishing to Goal", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "683f97d4-bc59-5e35-bf9c-f9ba669a4137")!, name: "63. Diamond Shooting 1v1", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "0e63f067-ad72-53e0-ba35-e214ff7851b8")!, name: "64. Crossing and Finishing", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "b0b72406-12f8-563c-bc37-e8bcab83f63b")!, name: "65. Combination Finishing", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "7ff43781-e843-55a6-8f98-60a123d19de8")!, name: "66. Small-Sided Shooting Game", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "e0ed546c-210c-524d-ad26-f972f6adb791")!, name: "67. Four-Goal Finishing Game", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "7e461d27-cd82-5fa8-9388-1060e0987925")!, name: "68. Turn and Finish", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "194a1135-7855-52db-9068-9999371a4e65")!, name: "69. Rebound Finishing", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "d92c2fac-819a-5283-97e0-4b7ea80f3275")!, name: "70. Endzone to Finish", category: .finishing, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "81ce0775-d0fc-5b1d-adb4-79ad40fc9588")!, name: "71. First Defender Without Opposition", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "1d2aa429-315a-5387-94bb-431b38e21f7b")!, name: "72. 1v1 Defending the Dribble", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "88803177-4013-5094-9049-f0e1bff0b14f")!, name: "73. Channel Defending 1v1", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "8817ef7c-7c8b-5e48-afdd-32fa8c1d331c")!, name: "74. Recovery Defending 1v1", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "67b3d112-4769-5056-80cb-d437841006de")!, name: "75. Pressure Cover 2v2", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "eecd2b9b-7f7d-51ef-97a7-191a29a0f3d2")!, name: "76. Defending Through Gates", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "63d82b52-0b71-5e88-aece-9c688645146a")!, name: "77. Compact Defending 3v3", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "6a1d779e-0d98-5226-910c-cfabffd45fb3")!, name: "78. Defensive Transition Game", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "dd21d460-e945-5fe3-aa3e-fbccd3550db1")!, name: "79. Blocking Shots in Pairs", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "e201367f-6d80-5dd4-b6f7-11a54bab0b74")!, name: "80. Defending Target Players", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "af5ae7a7-eefc-5b8e-9476-9d623fb28f71")!, name: "81. Width and Depth 4v4", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "931f5f57-4314-5aec-9f0f-320aa41eba96")!, name: "82. Playing Wide From the Back", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "e75a54e6-b6bd-5adc-8a09-727c646a7390")!, name: "83. Switching Play Through Corners", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "5fc5cdbc-e518-5a91-9e4a-3ca2d3e866a4")!, name: "84. Thirds Shape 4v4", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "4afd8beb-420c-5398-8250-0b97534bec5d")!, name: "85. Target Player Build-Up", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "ee5fafb0-ef73-5dfd-8594-d144336149ac")!, name: "86. Overload to Goal 3v2", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "b749f470-19a8-5231-a407-ee9161619725")!, name: "87. Counterattack From Regain", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "e84a6449-0071-5aa7-8634-0a324e53a9ba")!, name: "88. Pressing Trigger 4v4", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "b2572348-5829-5fc0-aeee-f4e27f61a432")!, name: "89. Building Through Zones", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "b1813321-b0d1-5814-b5cf-ae54364772c0")!, name: "90. Rest Defense in Possession", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "dde3102b-ec4d-5bac-8f87-03476120176a")!, name: "91. 4v4 to Small Gates", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "87df34b7-548d-54b1-b710-4ad6e0c6ce29")!, name: "92. 4v4 With Target Players", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "f7086cbd-a04b-543e-847f-2e2c6a1f990e")!, name: "93. 4v4 Zone Game", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "adb65db8-1df4-5eba-a57e-cb8f66e76f74")!, name: "94. 4v4 Shape and Positioning", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "4478614f-0672-594c-8324-ecb0f7fa1d68")!, name: "95. 3v3 Plus 3 Game", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "f40df5ad-68c6-56de-b20e-a7e90e1adb14")!, name: "96. Endzone Small-Sided Game", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "caf976d0-de14-5c55-bc07-f9cd1800283a")!, name: "97. Four-Goal Small-Sided Game", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "f1b3c719-b3f8-51ea-9366-a5068041a205")!, name: "98. Wide Channel Small-Sided Game", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "8894625c-7d32-59c6-bb6b-21e3edb1dbd4")!, name: "99. Transition Small-Sided Game", category: .game, minutes: 20),
    DrillCatalogItem(id: UUID(uuidString: "52475c0c-02c8-5e6c-a578-8d28c15b19d9")!, name: "100. Finish Zone Small-Sided Game", category: .game, minutes: 20),
]

private struct BundledDrill: Decodable {
    let id: UUID
    let name: String
    let category: String
    let plannedDurationMinutes: Int
    let description: String?
    let setup: String?
    let coachingPoints: String?
    let equipment: String?
    let resources: [BundledResource]?
}

private struct BundledResource: Decodable { let url: URL? }
private struct SeededDrillFile: Decodable { let drills: [BundledDrill] }

private func loadStarterDrills() -> [DrillCatalogItem] {
    guard let url = Bundle.main.url(forResource: "seeded-drills", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let file = try? JSONDecoder().decode(SeededDrillFile.self, from: data) else { return fallbackStarterDrills }
    let categories: [String: PracticeItemType] = ["warm_up": .warmUp, "passing": .passing, "possession": .passing, "finishing": .finishing, "defending": .game, "small_sided_games": .game]
    let mapped = file.drills.map { drill in
        DrillCatalogItem(id: drill.id, name: drill.name, category: categories[drill.category] ?? .custom, minutes: drill.plannedDurationMinutes, description: drill.description, setup: drill.setup, coachingPoints: drill.coachingPoints, equipment: drill.equipment, resourceURL: drill.resources?.first?.url)
    }
    return mapped.count == 100 ? mapped : fallbackStarterDrills
}

let starterDrills = loadStarterDrills()

struct DrillPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var category: PracticeItemType?
    let onSelect: (PracticeActivity) -> Void
    private var filtered: [DrillCatalogItem] { starterDrills.filter { (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)) && (category == nil || $0.category == category) } }
    var body: some View { NavigationStack { List { Section { Picker("Category", selection: $category) { Text("All categories").tag(PracticeItemType?.none); ForEach(PracticeItemType.allCases, id: \.self) { Text($0.rawValue).tag(Optional($0)) } } }.listRowBackground(Color.clear); Section { ForEach(filtered) { drill in Button { onSelect(.init(title: drill.name, type: drill.category, minutes: drill.minutes, notes: [])); dismiss() } label: { HStack { VStack(alignment: .leading) { Text(drill.name); Text(drill.category.rawValue).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text("Est. \(drill.minutes)m").monospacedDigit().foregroundStyle(.secondary) } } } } }.listStyle(.plain) .searchable(text: $query, prompt: "Search drills").navigationTitle("Drill Library").navigationBarTitleDisplayMode(.inline) } }
}
