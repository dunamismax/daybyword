import ReadingData
import ReadingEngine
import SwiftUI

/// Plans: the reader's own plans; a few practical questions and the plans
/// to consider for the answers (BUILD.md P9.1, P9.2); then every plan,
/// grouped by goal (P9.3), each opening its page. The answers are kept only
/// while Plans is open.
struct PlansView: View {
    @Environment(Library.self) private var library
    @State private var hope: Goal?
    @State private var time: Choosing.Time?
    @State private var days: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if let catalog = library.catalog {
                    let mine = library.activeEnrollments.compactMap { enrollment in
                        catalog.plan(enrollment.plan.id).map { (enrollment.id, $0) }
                    }
                    if !mine.isEmpty {
                        heading("My plans")
                        ForEach(mine, id: \.0) { _, plan in
                            NavigationLink(value: Destination.plan(plan.id)) {
                                HStack {
                                    Text(verbatim: plan.title).typeStyle(TypeScale.body)
                                    Spacer()
                                    Image(systemName: "chevron.right").accessibilityHidden(true)
                                }
                                .foregroundStyle(Palette.text)
                                .card(padding: Spacing.m)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    choosing(catalog)
                    heading("Every plan").padding(.top, Spacing.s)
                    if catalog.goals.isEmpty {
                        ForEach(catalog.listed, id: \.id) { card(catalog, $0) }
                    } else {
                        ForEach(catalog.goals, id: \.goal) { group in
                            Text(verbatim: group.goal.label)
                                .typeStyle(TypeStyle(size: 17, weight: .semibold, relativeTo: .headline))
                                .foregroundStyle(Palette.textMuted)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.top, Spacing.xs)
                            ForEach(group.plans, id: \.self) { id in
                                if let plan = catalog.plan(id) { card(catalog, plan) }
                            }
                        }
                    }
                } else {
                    StateMessage(
                        kind: .empty(
                            title: String(localized: "Plans will appear here."),
                            message: library.problem ?? String(localized: "The plan catalog cannot be read.")))
                }
            }
            .frame(maxWidth: ReadableWidth.column, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(Spacing.m)
        }
        .background(Palette.background)
        .navigationTitle("Plans")
    }

    /// The questions, and once one is answered, the plans to consider.
    @ViewBuilder
    private func choosing(_ catalog: Catalog) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Help me choose")
                .typeStyle(TypeScale.referenceList)
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            Text("Answer what you can. Not sure is always an answer.")
                .typeStyle(TypeScale.body)
                .foregroundStyle(Palette.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            question("What do you hope to read?") {
                Picker("What do you hope to read?", selection: $hope) {
                    Text("Not sure").tag(Goal?.none)
                    ForEach(Goal.allCases, id: \.self) { Text(verbatim: $0.label).tag(Goal?.some($0)) }
                }
            }
            question("How long can a reading take?") {
                Picker("How long can a reading take?", selection: $time) {
                    Text("Not sure").tag(Choosing.Time?.none)
                    ForEach(Choosing.Time.allCases, id: \.self) {
                        Text(verbatim: $0.label).tag(Choosing.Time?.some($0))
                    }
                }
            }
            question("How many days a week do you expect to read?") {
                Picker("How many days a week do you expect to read?", selection: $days) {
                    Text("Not sure").tag(Int?.none)
                    ForEach(Catalog.dayChoices, id: \.days) { Text(verbatim: $0.label).tag(Int?.some($0.days)) }
                }
            }
        }
        .card(padding: Spacing.m)

        if hope != nil || time != nil || days != nil {
            heading("Plans to consider").padding(.top, Spacing.s)
            ForEach(catalog.suggestions(for: Choosing.Answers(hope: hope, time: time, days: days))) { suggestion in
                NavigationLink(value: Destination.plan(suggestion.plan.id)) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(verbatim: PlanPresentation(catalog: catalog, plan: suggestion.plan).kind)
                            .typeStyle(TypeScale.label)
                            .foregroundStyle(Palette.textMuted)
                        Text(verbatim: suggestion.plan.title)
                            .typeStyle(TypeStyle(size: 22, weight: .bold, relativeTo: .title2))
                            .foregroundStyle(Palette.text)
                        ForEach(suggestion.reasons, id: \.self) { reason in
                            Text(verbatim: reason)
                                .typeStyle(TypeScale.body)
                                .foregroundStyle(Palette.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .card()
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Opens the plan's page."))
            }
            Text(
                "Chosen by a few fixed rules from what you said, never by popularity. Estimates vary with the reader and the translation."
            )
            .typeStyle(TypeScale.caption)
            .foregroundStyle(Palette.textMuted)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func question<Control: View>(_ title: LocalizedStringKey, @ViewBuilder control: () -> Control)
        -> some View
    {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .typeStyle(TypeScale.body)
                .fontWeight(.semibold)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(true)
            control()
                .pickerStyle(.menu)
                .tint(Palette.accent)
        }
        .padding(.top, Spacing.xs)
    }

    private func heading(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .typeStyle(TypeScale.referenceList)
            .foregroundStyle(Palette.text)
            .accessibilityAddTraits(.isHeader)
    }

    private func card(_ catalog: Catalog, _ plan: Plan) -> some View {
        let presented = PlanPresentation(catalog: catalog, plan: plan)
        return NavigationLink(value: Destination.plan(plan.id)) {
            PlanCard(
                title: plan.title, kind: presented.kind, summary: plan.summary,
                workload: presented.typicalWorkload, readings: presented.readings)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Opens the plan's page."))
    }
}

/// A plan's page: what it is, whom it suits, its workload, a sample week,
/// what it covers, how it works, what it does not do, and where it comes
/// from (BUILD.md P8.2, P9.4), with the way to start it.
struct PlanView: View {
    let id: PlanID
    @Environment(Library.self) private var library
    @Environment(AppNavigation.self) private var navigation
    @State private var starting = false

    var body: some View {
        ScrollView {
            if let catalog = library.catalog, let plan = catalog.plan(id) {
                page(PlanPresentation(catalog: catalog, plan: plan))
            } else {
                StateMessage(
                    kind: .empty(
                        title: String(localized: "This plan isn't in the catalog."),
                        message: String(localized: "It may have been withdrawn, or the link may be mistyped.")))
            }
        }
        .background(Palette.background)
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $starting) {
            if let catalog = library.catalog, let plan = catalog.plan(id) {
                StartPlanView(presentation: PlanPresentation(catalog: catalog, plan: plan)) {
                    starting = false
                    navigation.open(.today)
                }
            }
        }
    }

    private func page(_ presented: PlanPresentation) -> some View {
        let plan = presented.plan
        let following = library.activeEnrollments.contains { $0.plan.id == plan.id }
        return VStack(alignment: .leading, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(verbatim: plan.title)
                    .typeStyle(TypeScale.planTitle)
                    .foregroundStyle(Palette.text)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: "\(presented.byline) · \(presented.kind) · \(presented.readings)")
                    .typeStyle(TypeScale.label)
                    .foregroundStyle(Palette.textMuted)
                Text(verbatim: plan.summary)
                    .typeStyle(TypeScale.body)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if following {
                Text("You're following this plan. Its readings are on Today.")
                    .typeStyle(TypeScale.body)
                    .foregroundStyle(Palette.textMuted)
            }
            Button(following ? "Start it again" : "Start this plan") { starting = true }
                .buttonStyle(PrimaryButtonStyle())

            section("Who it suits") { paragraph(plan.suits) }

            section("How long it takes") {
                ForEach(presented.workloads, id: \.label) { workload in
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: workload.label).foregroundStyle(Palette.textMuted)
                        Spacer(minLength: Spacing.s)
                        Text(verbatim: workload.text).foregroundStyle(Palette.text)
                    }
                    .typeStyle(TypeScale.body)
                    .accessibilityElement(children: .combine)
                }
                caption(String(localized: "Estimates vary with the reader and the translation."))
                caption(presented.paced)
                paragraph(presented.length).padding(.top, Spacing.xxs)
            }

            SampleWeek(readings: presented.sampleWeek, note: presented.sampleNote)
            NavigationLink(value: Destination.planWeek(plan.id, start: nil)) {
                Text("A week's checklist")
                    .typeStyle(TypeScale.body)
                    .foregroundStyle(Palette.accent)
            }

            section("What it covers") { ForEach(presented.covers, id: \.self) { paragraph($0) } }

            section("How it works") {
                paragraph(presented.how)
                paragraph(plan.instructions)
                ForEach(plan.behaviors, id: \.self) { behavior in
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(verbatim: behavior.name).fontWeight(.semibold).foregroundStyle(Palette.text)
                        Text(verbatim: behavior.about).foregroundStyle(Palette.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .typeStyle(TypeScale.body)
                    .padding(.top, Spacing.xs)
                    .accessibilityElement(children: .combine)
                }
            }

            section("What it does not do") { paragraph(plan.limitations) }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                SourceNote(text: plan.source)
                Text("**Review.** \(presented.review)")
                    .typeStyle(TypeScale.caption)
                    .foregroundStyle(Palette.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("**Permissions.** \(presented.permissions)")
                    .typeStyle(TypeScale.caption)
                    .foregroundStyle(Palette.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .card(padding: Spacing.m)
        }
        .frame(maxWidth: ReadableWidth.column, alignment: .leading)
        .frame(maxWidth: .infinity)
        .padding(Spacing.m)
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content)
        -> some View
    {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .typeStyle(TypeStyle(size: 17, weight: .bold, relativeTo: .headline))
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .card(padding: Spacing.m)
    }

    private func paragraph(_ text: String) -> some View {
        Text(verbatim: text)
            .typeStyle(TypeScale.body)
            .foregroundStyle(Palette.text)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func caption(_ text: String) -> some View {
        Text(verbatim: text)
            .typeStyle(TypeScale.caption)
            .foregroundStyle(Palette.textMuted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A plan's week from a start date: the seven days from it for a reader who
/// begins that day, or the sample week without one (the web's printable
/// checklist, P8.10b; the iOS PDF is P13.1).
struct PlanWeekView: View {
    let id: PlanID
    let start: String?
    @Environment(Library.self) private var library
    /// Large print, remembered for the next checklist (P13.1).
    @AppStorage("weekLargePrint") private var large = false
    @State private var failure: String?

    var body: some View {
        ScrollView {
            if let checklist {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Toggle("Large print", isOn: $large)
                        .typeStyle(TypeScale.body)
                        .tint(Palette.accent)
                    checklist.card(padding: Spacing.m)
                    if let failure {
                        Text(verbatim: failure).typeStyle(TypeScale.body).foregroundStyle(Palette.danger)
                    }
                }
                .frame(maxWidth: ReadableWidth.column, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(Spacing.m)
            } else {
                StateMessage(
                    kind: .empty(
                        title: String(localized: "This plan isn't in the catalog."),
                        message: String(localized: "It may have been withdrawn, or the link may be mistyped.")))
            }
        }
        .background(Palette.background)
        .toolbar {
            if let checklist {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share as PDF", systemImage: "square.and.arrow.up") { share(checklist) }
                        .accessibilityHint(Text("Shares this week's checklist as a page to print."))
                }
            }
        }
        .navigationTitle("Week")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The week from the date asked for, or from today.
    private var checklist: WeekChecklist? {
        guard let catalog = library.catalog, let plan = catalog.plan(id) else { return nil }
        let presented = PlanPresentation(catalog: catalog, plan: plan)
        let from = start.flatMap { try? CivilDate($0) } ?? library.today
        let note =
            plan.schedule == .sequence
            ? String(
                localized:
                    "The plan's first week, begun on \(PlanPresentation.dayText(from)), on the days it is paced for. Your own days may differ."
            )
            : String(localized: "The readings appointed for seven days from \(PlanPresentation.dayText(from)).")
        return WeekChecklist(
            title: plan.title, label: "\(presented.byline) · \(presented.kind)", note: note,
            days: presented.week(from: from), source: plan.source, large: large)
    }

    private func share(_ checklist: WeekChecklist) {
        do {
            let name = String(localized: "\(checklist.title), a week")
            ShareSheet.present(try WeekPDF.file(checklist, named: name))
            failure = nil
        } catch {
            failure = String(describing: error)
        }
    }
}
