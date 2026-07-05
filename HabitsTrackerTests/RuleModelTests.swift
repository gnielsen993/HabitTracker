import XCTest
import SwiftData
@testable import HabitsTracker

/// Tests for the `Rule` @Model and the Rule<->Habit stem link (RULE-01, RULE-04, RULE-05).
///
/// RED by design until plan 02-01 creates Rule.swift, adds Habit.originRule, adds Domain.rules,
/// and registers Rule in the container. Do NOT stub the production types to make these green.
final class RuleModelTests: XCTestCase {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Domain.self, Habit.self, DailyEntry.self, HabitState.self, Rule.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return container.mainContext
    }

    /// RULE-01: a Rule built without passing `isArchived` must default to false.
    @MainActor
    func testIsArchivedDefaultsFalse() throws {
        let context = try makeInMemoryContext()

        let rule = Rule(title: "No screens after 10pm")
        context.insert(rule)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Rule>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.isArchived, false)
    }

    /// RULE-05: deleting a rule nullifies `originRule` on all stemmed habits — never cascades.
    @MainActor
    func testDeleteRuleNullifiesStemmedHabits() throws {
        let context = try makeInMemoryContext()

        let rule = Rule(title: "Exercise daily")
        let habitA = Habit(name: "Run", scheduleType: .daily, mode: .required)
        let habitB = Habit(name: "Lift", scheduleType: .daily, mode: .optional)
        habitA.originRule = rule
        habitB.originRule = rule
        context.insert(rule)
        context.insert(habitA)
        context.insert(habitB)
        try context.save()

        context.delete(rule)
        try context.save()

        let habits = try context.fetch(FetchDescriptor<Habit>())
        XCTAssertEqual(habits.count, 2, "Both habits must survive rule deletion (no cascade)")
        XCTAssertTrue(habits.allSatisfy { $0.originRule == nil }, "originRule must be nullified on both habits")

        let rules = try context.fetch(FetchDescriptor<Rule>())
        XCTAssertEqual(rules.count, 0)
    }

    /// RULE-04: assigning two habits' `originRule` to one rule yields rule.stemmedHabits.count == 2.
    @MainActor
    func testStemmedHabitsInverse() throws {
        let context = try makeInMemoryContext()

        let rule = Rule(title: "Sleep hygiene")
        let habitA = Habit(name: "No phone before bed", scheduleType: .daily, mode: .required)
        let habitB = Habit(name: "Lights out by 10pm", scheduleType: .daily, mode: .required)
        habitA.originRule = rule
        habitB.originRule = rule
        context.insert(rule)
        context.insert(habitA)
        context.insert(habitB)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Rule>())
        XCTAssertEqual(fetched.first?.stemmedHabits.count, 2)
    }

    /// Domain.rules inverse: creating two rules with domain == D yields D.rules.count == 2.
    @MainActor
    func testDomainRulesInverse() throws {
        let context = try makeInMemoryContext()

        let domain = Domain(name: "Health", iconName: "heart", colorToken: "maroon", sortIndex: 0)
        let ruleA = Rule(title: "Eat whole foods", domain: domain)
        let ruleB = Rule(title: "Move daily", domain: domain)
        context.insert(domain)
        context.insert(ruleA)
        context.insert(ruleB)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Domain>())
        XCTAssertEqual(fetched.first?.rules.count, 2)
    }
}
