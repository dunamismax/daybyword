#if DEBUG
    import SwiftUI

    /// Every shared component with sample content, for checking them in the
    /// simulator in light, dark, and large text. Debug builds open it with the
    /// launch argument `-componentGallery`. The content is invented for layout.
    struct ComponentGallery: View {
        @State private var showingPreview = false
        private let mark = ReferenceText(display: "Mark 4:1–20", spoken: "Mark, chapter 4, verses 1 to 20")

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.l) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(verbatim: "Gospels at your pace · Reading 31")
                                .typeStyle(TypeScale.label)
                                .foregroundStyle(Palette.accent)
                            ReferenceBlock(reference: mark)
                            WorkloadLine(minutes: 6)
                            Button("Mark read") {}.buttonStyle(PrimaryButtonStyle()).padding(.top, Spacing.xs)
                            ActionRow {
                                Button("Open in YouVersion") {}.buttonStyle(SecondaryButtonStyle())
                                CopyReferenceButton(reference: mark)
                            }
                        }
                        .card()

                        VStack(alignment: .leading, spacing: 0) {
                            AssignmentRow(label: "Reading 31", reference: mark, status: .unread)
                            AssignmentRow(
                                label: "Reading 30",
                                reference: ReferenceText(
                                    display: "Mark 3:20–35", spoken: "Mark, chapter 3, verses 20 to 35"),
                                status: .read)
                            AssignmentRow(
                                label: "Reading 29",
                                reference: ReferenceText(
                                    display: "Mark 3:1–19", spoken: "Mark, chapter 3, verses 1 to 19"),
                                status: .partlyRead)
                            AssignmentRow(
                                label: "Reading 28",
                                reference: ReferenceText(display: "Mark 2", spoken: "Mark, chapter 2"),
                                status: .skipped)
                        }
                        .card(padding: Spacing.m)

                        PlanCard(
                            title: "Gospels at your pace", kind: "A Day by Word plan",
                            summary: "Matthew, Mark, Luke, and John in readings of about the same length.",
                            minutes: 6, schedule: "Continue at my pace")

                        SampleWeek(readings: [
                            ("Reading 1", ReferenceText(display: "Matthew 1", spoken: "Matthew, chapter 1")),
                            ("Reading 2", ReferenceText(display: "Matthew 2", spoken: "Matthew, chapter 2")),
                            (
                                "Reading 3",
                                ReferenceText(
                                    display: "Matthew 3:1–4:11",
                                    spoken: "Matthew, chapter 3 verse 1 to chapter 4 verse 11")
                            ),
                        ])

                        SourceNote(
                            text: "An original Day by Word plan, built from verse counts and estimated reading time.")

                        Button("Preview a change") { showingPreview = true }.buttonStyle(SecondaryButtonStyle())

                        UndoBanner(message: "Marked Mark 4:1–20 read.") {}

                        StateMessage(
                            kind: .empty(title: "No plan yet", message: "Choose a plan to see your first reading here.")
                        )
                        .card()
                        StateMessage(kind: .loading).card()
                        StateMessage(kind: .offline).card()
                        StateMessage(kind: .error(message: "The plan could not be opened.", retry: {})).card()
                    }
                    .padding(Spacing.m)
                }
                .background(Palette.background)
                .navigationTitle("Components")
                .sheet(isPresented: $showingPreview) {
                    ChangePreview(
                        title: "Welcome back",
                        explanation:
                            "Here is what continuing from where you left off will do. Your history stays as it is.",
                        changes: [
                            PreviewedChange(what: "Next reading", before: "Mark 3:20–35", after: "Mark 4:1–20"),
                            PreviewedChange(what: "Projected finish", before: "2 March", after: "14 March"),
                        ],
                        confirmLabel: "Continue",
                        onConfirm: { showingPreview = false },
                        onCancel: { showingPreview = false }
                    )
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }

    #Preview {
        ComponentGallery()
    }
#endif
