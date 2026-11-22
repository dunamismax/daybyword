import ReadingData
import ReadingEngine
import SwiftUI

/// The welcome after a gap (docs/product.md, "The return flow"; BUILD.md
/// P8.7): a short welcome, the choices the engine offers for the plan's
/// behavior, each with its effect worked out by folding the journal with
/// the answer added, and nothing written until the reader confirms. Never
/// a count of days, and history is never altered.
struct WelcomeBack: View {
    let welcome: Welcome
    let enrollment: Enrollment
    let journal: Journal
    let plan: Plan
    let today: CivilDate
    let formatter: ReferenceFormatter
    let act: (JournalEvent.Body, EventID, String) -> Void

    @State private var previewing: Choice?

    /// An offer with its preview, ready to show.
    struct Choice: Identifiable {
        let offer: Welcome.Offer
        let title: String
        let effect: String
        var id: JournalEvent.Choice { offer.choice }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(verbatim: plan.title)
                .typeStyle(TypeScale.label)
                .foregroundStyle(Palette.textMuted)
            Text("Welcome back. Here's where you left off.")
                .typeStyle(TypeScale.referenceList)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(choices) { choice in
                Button {
                    previewing = choice
                } label: {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(verbatim: choice.title).fontWeight(.semibold).foregroundStyle(Palette.text)
                        Text(verbatim: choice.effect).foregroundStyle(Palette.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .typeStyle(TypeScale.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.s)
                    .background(Palette.surfaceSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Shows what changes before anything does."))
            }
            if let needs = welcome.spreadNeeds {
                Text(
                    "Spreading the readings you have left before your finish date would need up to \(needs) readings a day, more than the limit you set."
                )
                .typeStyle(TypeScale.caption)
                .foregroundStyle(Palette.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
        .sheet(item: $previewing) { choice in
            ChangePreview(
                title: choice.title, explanation: choice.effect, changes: changes(for: choice),
                confirmLabel: String(localized: "Confirm"),
                onConfirm: {
                    previewing = nil
                    act(welcome.answer(choice.offer, on: today), enrollment.id, confirmation(for: choice))
                },
                onCancel: { previewing = nil }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var choices: [Choice] {
        welcome.offers.compactMap { offer in
            guard let after = answered(offer) else { return nil }
            switch offer.choice {
            case .continue:
                var effect =
                    nextReading(after).map { String(localized: "Your next reading will be \($0).") }
                    ?? String(localized: "Nothing is rescheduled.")
                if let finish = after.today(today).projection?.plan {
                    effect +=
                        " "
                        + String(
                            localized:
                                "At one reading each reading day, you'd finish on \(PlanPresentation.dayText(finish)).")
                }
                return Choice(offer: offer, title: String(localized: "Continue from where I left off"), effect: effect)
            case .spread:
                guard let basis = offer.basis, let most = offer.most else { return nil }
                return Choice(
                    offer: offer, title: String(localized: "Spread the readings over the days ahead"),
                    effect: most == 1
                        ? String(localized: "1 reading a day until \(PlanPresentation.dayText(basis.finish)).")
                        : String(
                            localized: "Up to \(most) readings a day until \(PlanPresentation.dayText(basis.finish))."))
            case .moveFinish:
                guard let basis = offer.basis else { return nil }
                return Choice(
                    offer: offer, title: String(localized: "Move my finish date"),
                    effect: String(localized: "Your finish date moves to \(PlanPresentation.dayText(basis.finish))."))
            case .rejoin:
                let reading = after.today(today).calendar.flatMap { reference($0.appointment) }
                return Choice(
                    offer: offer, title: String(localized: "Rejoin today's readings"),
                    effect: reading.map {
                        String(localized: "Today's reading is \($0). Earlier readings stay in your history.")
                    } ?? String(localized: "Earlier readings stay in your history."))
            }
        }
    }

    /// The enrollment as it would be with this answer added: the fold itself.
    private func answered(_ offer: Welcome.Offer) -> Enrollment? {
        journal.previewing(welcome.answer(offer, on: today), in: enrollment.id)?.enrollments
            .first { $0.id == enrollment.id }
    }

    private func nextReading(_ enrollment: Enrollment) -> String? {
        let day = enrollment.today(today)
        return (day.readings.first ?? day.next).flatMap(reference)
    }

    private func reference(_ slot: Slot) -> String? {
        plan.assignments.first { $0.id == slot.assignment }.map { formatter.string(for: $0.reading) }
    }

    /// What changes, before and after, from the engine's answers with and
    /// without the choice.
    private func changes(for choice: Choice) -> [PreviewedChange] {
        guard let after = answered(choice.offer) else { return [] }
        let before = enrollment.today(today)
        let then = after.today(today)
        var changes: [PreviewedChange] = []
        if let old = before.schedule, let new = then.schedule {
            if old.finish != new.finish {
                changes.append(
                    PreviewedChange(
                        what: String(localized: "Finish date"), before: PlanPresentation.dayText(old.finish),
                        after: PlanPresentation.dayText(new.finish)))
            }
            let oldToday = before.readings.count
            let newToday = then.readings.count
            if oldToday != newToday {
                changes.append(
                    PreviewedChange(
                        what: String(localized: "Readings today"), before: "\(oldToday)", after: "\(newToday)"))
            }
        }
        if let old = before.projection?.plan, let new = then.projection?.plan, old != new {
            changes.append(
                PreviewedChange(
                    what: String(localized: "Finish at the plan's pace"), before: PlanPresentation.dayText(old),
                    after: PlanPresentation.dayText(new)))
        }
        return changes
    }

    private func confirmation(for choice: Choice) -> String {
        switch choice.offer.choice {
        case .continue: String(localized: "Continuing from where you left off.")
        case .spread: String(localized: "The readings are spread over the days ahead.")
        case .moveFinish: String(localized: "Your finish date has moved.")
        case .rejoin: String(localized: "You've rejoined today's readings.")
        }
    }
}
