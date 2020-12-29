//
//  AlignedColumnList.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 15/12/2020.
//

import SwiftUI

private struct ColumnWidthEqualiserView: View {
    @State var columnID: SizePreferenceKey.Column
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: SizePreferenceKey.self,
                            value: [columnID: proxy.size.width])
        }
    }
}

struct RowItem {
    let items: [String]
    
    init(_ items: [String]) {
        self.items = items
    }
    
    func text(at column: Int) -> String {
        if items.count > column {
            return items[column]
        } else {
            return ""
        }
    }
}

private struct Row: View {
    @State var line: RowItem
    @Binding var widths: [SizePreferenceKey.Column:CGFloat]
    @State var isSelected: Bool = false

    var body: some View {
        GeometryReader { geometry in
            HStack {
                Text(line.text(at: 0))
                    .background(ColumnWidthEqualiserView(columnID: .first))
                    .frame(minWidth: widths[.first] ?? 0, alignment: .leading)
                Text(line.text(at: 1))
                    .background(ColumnWidthEqualiserView(columnID: .second))
                    .frame(minWidth: widths[.second] ?? 0, alignment: .leading)
                Text(line.text(at: 2))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }.background((isSelected == true) ? Color.blue: Color.clear)
    }
}

struct AlignedColumnList: View {
    @State var widths: [SizePreferenceKey.Column:CGFloat] = [:]
    @State var selectedLine: Int? = 15
    @State var lines: [RowItem]
    var body: some View {
        List {
            ForEach(lines.indices) { index in
                GeometryReader { geometry in
                    Row(line: lines[index],
                        widths: $widths,
                        isSelected: (selectedLine == index))
                    }.font(.system(.body, design: .monospaced))
                }
        }.onPreferenceChange(SizePreferenceKey.self) { preference in
          self.widths = preference
        }
    }
}

struct AlignedColumnList_Previews: PreviewProvider {
    static var previews: some View {
        AlignedColumnList(lines: [RowItem(["one", "two", "three"]),
                                  RowItem(["four", "five", "six"]),
                                  RowItem(["seven", "eight", "nine"])])
    }
}
