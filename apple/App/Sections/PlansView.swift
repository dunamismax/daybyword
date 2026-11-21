import ReadingData
import ReadingEngine
import SwiftUI

/// Plans: the reader's own plans, then every plan in the catalog, shortest
/// first (docs/decisions.md E45), each opening its page. Recommendations
/// and grouping by goal come with Phase 9.
struct PlansView: View {
    @Environment(Library.self) private var library

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if let catalog = library.catalog {
                    let mine = library.activeEnrollments.compactMap { enrollment in
                        catalog.plan(enrollment.plan.id).map { (enrollment.id, $0) }
                    }
                    if !mine.isEmpty {
                        Text("My plans")
                            .typeStyle(TypeScale.referenceList)
                            .foregroundStyle(Palette.text)
                            .accessibilityAddTraits(.isHeader)
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
                        Text("Every plan")
                            .typeStyle(TypeScale.referenceList)
                            .foregroundStyle(Palette.text)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, Spacing.s)
                    }
                    ForEach(catalog.listed, id: \.id) { plan in
                        let presented = PlanPresentation(catalog: catalog, plan: plan)
                        NavigationLink(value: Destination.plan(plan.id)) {
                            PlanCard(
                                title: plan.title, kind: presented.kind, summary: plan.summary,
                                workload: presented.typicalWorkload, readings: presented.readings)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(Text("Opens the plan's page."))
                    }
                } else {
                    StateMessage(
                        kind: .empty(
                            title: String(localized: "Plans will appear here."),
                            message: library.problem ?? String(localized: "The plan catalog cannot be read.")))
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(Spacing.m)
        }
        .background(Palette.background)
        .navigationTitle("Plans")
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
            }
            .card(padding: Spacing.m)
        }
        .frame(maxWidth: 720, alignment: .leading)
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

    var body: some View {
        ScrollView {
            if let catalog = library.catalog, let plan = catalog.plan(id) {
                let presented = PlanPresentation(catalog: catalog, plan: plan)
                let from = start.flatMap { try? CivilDate($0) } ?? library.today
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text(verbatim: plan.title)
                        .typeStyle(TypeScale.planTitle)
                        .foregroundStyle(Palette.text)
                        .accessibilityAddTraits(.isHeader)
                    Text(
                        verbatim: plan.schedule == .sequence
                            ? String(
                                localized:
                                    "The plan's first week, begun on \(PlanPresentation.dayText(from)), on the days it is paced for. Your own days may differ."
                            )
                            : String(
                                localized:
                                    "The readings appointed for seven days from \(PlanPresentation.dayText(from)).")
                    )
                    .typeStyle(TypeScale.body)
                    .foregroundStyle(Palette.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(presented.week(from: from), id: \.date) { day in
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(verbatim: PlanPresentation.dayText(day.date))
                                    .typeStyle(TypeScale.caption)
                                    .foregroundStyle(Palette.textMuted)
                                if day.references.isEmpty {
                                    Text("Rest day").typeStyle(TypeScale.body).foregroundStyle(Palette.textMuted)
                                }
                                ForEach(day.references, id: \.display) { reference in
                                    Text(verbatim: reference.unbroken)
                                        .typeStyle(TypeScale.referenceList)
                                        .foregroundStyle(Palette.text)
                                        .accessibilityLabel(reference.spoken)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                            .accessibilityElement(children: .combine)
                            Divider().overlay(Palette.line)
                        }
                    }
                    .card(padding: Spacing.m)
                    SourceNote(text: plan.source)
                }
                .frame(maxWidth: 720, alignment: .leading)
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
        .navigationTitle("Week")
        .navigationBarTitleDisplayMode(.inline)
    }
}
