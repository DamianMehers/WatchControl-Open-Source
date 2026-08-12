////
////  WatchControl_Complication.swift
////  WatchControl Complication
////
////  Created by Damian Mehers on 03.04.23.
////
//
//import WidgetKit
//import SwiftUI
//
//struct Provider: TimelineProvider {
//    func placeholder(in context: Context) -> SimpleEntry {
//        SimpleEntry(date: Date())
//    }
//
//    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
//        let entry = SimpleEntry(date: Date())
//        completion(entry)
//    }
//
//    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
//        var entries: [SimpleEntry] = []
//
//        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate)
//            entries.append(entry)
//        }
//
//        let timeline = Timeline(entries: entries, policy: .atEnd)
//        completion(timeline)
//    }
//}
//
//struct SimpleEntry: TimelineEntry {
//    let date: Date
//}
//
//struct WatchControl_ComplicationEntryView : View {
//    var entry: Provider.Entry
//
//    var body: some View {
//        Text(entry.date, style: .time)
//    }
//}
//
//@main
//struct WatchControl_Complication: Widget {
//    let kind: String = "WatchControl_Complication"
//
//    var body: some WidgetConfiguration {
//        StaticConfiguration(kind: kind, provider: Provider()) { entry in
//            WatchControl_ComplicationEntryView(entry: entry)
//        }
//        .configurationDisplayName("My Widget")
//        .description("This is an example widget.")
//    }
//}
//
//struct WatchControl_Complication_Previews: PreviewProvider {
//    static var previews: some View {
//        WatchControl_ComplicationEntryView(entry: SimpleEntry(date: Date()))
//            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
//    }
//}

//
//  WatchOSComplicationExtension.swift
//  WatchOSComplicationExtension
//
//  Created by Damian Mehers on 26.12.22.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date())

        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct WatchOSComplicationExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Image("Image")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

@main
struct WatchOSComplicationExtension: Widget {
    let kind: String = "WatchControl_Complication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WatchOSComplicationExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("WatchControl")
        .description("Launches WatchControl")
        .supportedFamilies([.accessoryCircular,.accessoryCorner,.accessoryInline,.accessoryRectangular])
    }
}

struct WatchOSComplicationExtension_Previews: PreviewProvider {
    static var previews: some View {
        WatchOSComplicationExtensionEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
