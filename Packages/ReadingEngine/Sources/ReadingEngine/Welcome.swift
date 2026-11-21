/// The welcome after a gap (docs/engine.md, "Returning after a break"): the
/// choices that apply, each with what it would set. "Welcome back. Here's
/// where you left off." Never a count of days.
public struct Welcome: Hashable, Sendable {
    public struct Offer: Hashable, Sendable {
        public let choice: JournalEvent.Choice
        /// The basis `spread` and `moveFinish` would set, from today.
        public let basis: JournalEvent.Basis?
        /// The most readings on one day under that basis.
        public let most: Int?
    }

    /// In the order the reader is offered them.
    public let offers: [Offer]
    /// The limit spreading would need, when it is not offered only because
    /// it is beyond the reader's limit.
    public let spreadNeeds: Int?

    /// The event that records the reader's answer.
    public func answer(_ offer: Offer, on date: CivilDate) -> JournalEvent.Body {
        .returned(date: date, choice: offer.choice, basis: offer.basis)
    }
}

extension Enrollment {
    /// Whether there is a gap before `date`: two or more reading days
    /// strictly between the anchor and that date. The anchor is the latest
    /// of the day before the start, the last day the reader read, the last
    /// answer to a welcome, and the day before the last resuming.
    public func hasGap(before date: CivilDate) -> Bool {
        var anchor = start.ordinal - 1
        for mark in marks where mark.marked.mark != .skipped && mark.marked.date <= date {
            anchor = max(anchor, mark.marked.date.ordinal)
        }
        var returned: Int?
        var resumed: Int?
        for event in arranging {
            switch event.body {
            case .returned(let day, _, _): returned = day.ordinal
            case .resumed(let from, _): resumed = from.ordinal - 1
            case .changed, .paused, .ended: continue
            }
        }
        anchor = max(anchor, returned ?? anchor, resumed ?? anchor)
        guard let first = try? CivilDate(ordinal: anchor + 1), let last = try? date.adding(days: -1) else {
            return false
        }
        return readingDays(from: first, through: last) >= 2
    }

    /// The welcome to offer on `date`, or nil when there is none: no gap, a
    /// paused day, before the start, or a plan that is finished or ended.
    public func welcome(on date: CivilDate) -> Welcome? {
        guard ended == nil, date >= start, !isPaused(date), hasGap(before: date) else { return nil }
        if plan.schedule == .dayOfMonth {
            return Welcome(offers: [.init(choice: .rejoin, basis: nil, most: nil)], spreadNeeds: nil)
        }
        let unread = plan.assignments.count { state(of: Slot(assignment: $0.id)) == .unread }
        guard unread > 0 else { return nil }
        var offers = [Welcome.Offer(choice: .continue, basis: nil, most: nil)]
        var spreadNeeds: Int?
        let arrangement = arrangement(on: date)
        if arrangement.behavior == .finishDate, let basis {
            // Spread: the unread readings over the reading days left.
            let left = readingDays(from: date, through: basis.finish)
            if left > 0 {
                let most = (unread + left - 1) / left
                if most <= arrangement.limit ?? most {
                    offers.append(
                        .init(choice: .spread, basis: .init(finish: basis.finish, remaining: unread), most: most))
                } else {
                    spreadNeeds = most
                }
            }
            // Move the finish: the present daily amount, from today.
            let scheduled = readingDays(from: basis.first, through: basis.finish)
            var amount = scheduled > 0 ? (basis.remaining + scheduled - 1) / scheduled : basis.remaining
            amount = max(1, min(amount, arrangement.limit ?? amount))
            let days = (unread + amount - 1) / amount
            if let finish = readingDay(days, from: date), finish > basis.finish {
                offers.append(
                    .init(
                        choice: .moveFinish, basis: .init(finish: finish, remaining: unread),
                        most: (unread + days - 1) / days))
            }
        }
        return Welcome(offers: offers, spreadNeeds: spreadNeeds)
    }
}
