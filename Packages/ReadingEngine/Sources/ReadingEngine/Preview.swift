/// Previews (docs/engine.md: "a preview is the fold itself"). Before the
/// reader confirms a return choice or a change, the interface shows the
/// engine's answer for the journal with the candidate event added, beside
/// its answer without. Nothing is written until the reader confirms.
extension Journal {
    /// The journal with a candidate event added after every other. Nothing
    /// is stored; the caller compares this journal's answers with its own.
    /// Nil when no id can follow the last one.
    public func previewing(_ body: JournalEvent.Body, in enrollment: EventID) -> Journal? {
        let after = (events.last?.id.milliseconds ?? -1) + 1
        guard let id = EventID(milliseconds: after, random: [UInt8](repeating: 0, count: 10)) else { return nil }
        let candidate = JournalEvent(
            id: id, enrollment: enrollment, at: "1970-01-01T00:00:00Z", zone: "UTC", device: "preview", body: body)
        return try? Journal(events: events + [candidate], plans: plans)
    }
}

extension Enrollment {
    /// A change to the arrangement from `date` (docs/engine.md, "Changing an
    /// enrollment"). On a finish-date arrangement a change to the reading
    /// days, the finish date, or to that behavior carries a new basis: the
    /// finish given, or else the present one, over the readings unread now.
    /// A change to `finish-date` needs a finish and a limit.
    public func change(
        from date: CivilDate, start: CivilDate? = nil, readingDays: [Int]? = nil, behavior: Plan.Behavior? = nil,
        finish: CivilDate? = nil, limit: Int? = nil, reminder: JournalEvent.Reminder? = nil
    ) -> JournalEvent.Changed {
        var basis: JournalEvent.Basis?
        let isScheduled = (behavior ?? arrangement(on: date).behavior) == .finishDate
        if isScheduled, readingDays != nil || finish != nil || behavior != nil {
            let unread = plan.assignments.count { state(of: Slot(assignment: $0.id)) == .unread }
            if let finish = finish ?? self.basis?.finish, unread > 0 {
                basis = JournalEvent.Basis(finish: finish, remaining: unread)
            }
        }
        return JournalEvent.Changed(
            from: date, start: start, readingDays: readingDays, behavior: behavior, basis: basis, limit: limit,
            reminder: reminder)
    }
}
