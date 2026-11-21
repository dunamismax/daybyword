/// One of the dates ahead (docs/engine.md, "The days ahead"): what the
/// sample week, the coming week and the printable checklist show.
public struct ComingDay: Hashable, Sendable {
    public let date: CivilDate
    /// Whether it is one of the reader's reading days.
    public let isReadingDay: Bool
    /// The readings expected on it and not yet settled, in reading order.
    public let readings: [Slot]
}

extension Enrollment {
    /// The `count` dates from `date`, each with the readings expected on
    /// it: Today's own answer for each date in turn, supposing the reader
    /// reads what each day shows and nothing more. A calendar enrollment's
    /// dates each have their own appointment, on rest and paused days too.
    /// An ended enrollment has none.
    public func comingDays(from date: CivilDate, count: Int) -> [ComingDay] {
        var days: [ComingDay] = []
        let today = self.today(date)
        var unread = plan.assignments.map { Slot(assignment: $0.id) }.filter { state(of: $0) == .unread }
        var settledCount = plan.assignments.count - unread.count
        var day = date
        for offset in 0..<max(0, count) {
            if offset > 0 {
                guard let next = try? day.adding(days: 1) else { break }
                day = next
            }
            let isReadingDay = self.isReadingDay(day)
            if plan.schedule == .dayOfMonth {
                let slot = Slot(assignment: day.day, appointed: day)
                let isAppointed =
                    ended == nil && day >= start && plan.positions[day.day] != nil && state(of: slot) == .unread
                days.append(ComingDay(date: day, isReadingDay: isReadingDay, readings: isAppointed ? [slot] : []))
                continue
            }

            var take = 0
            if offset == 0 {
                take = today.readings.count
            } else if ended == nil, isReadingDay, !unread.isEmpty {
                take = 1
                if arrangement(on: day).behavior == .finishDate, let basis {
                    let before = (try? day.adding(days: -1)).map { target(after: $0) } ?? 0
                    let after = target(after: day)
                    let share = basis.first <= day && day <= basis.finish ? after - before : 0
                    let quota = share > 0 ? share : (before > settledCount ? 1 : 0)
                    take = min(max(0, after - settledCount), quota, unread.count)
                }
            }
            days.append(ComingDay(date: day, isReadingDay: isReadingDay, readings: Array(unread.prefix(take))))
            unread.removeFirst(take)
            settledCount += take
        }
        return days
    }
}
