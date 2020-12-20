//
//  DisassemblyView.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 15/12/2020.
//

import SwiftUI

protocol DisassemblyLine {
    var space: String { get }
    var address: String { get }
    var raw: String { get }
    var asm: String { get }
    var comment: String? { get }
}

extension DisassemblyLine {
    var fullAddress: String { "\(space):\(address):" }
}

struct DisassemblyView: View {

    struct DisasseblyRow: View {
        struct ColumnWidthEqualiserView: View {
            @State var columnID: SizePreferenceKey.Column
            var body: some View {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizePreferenceKey.self,
                                    value: [columnID: proxy.size.width])
                }
            }
        }
        @State var line: DisassemblyLine
        @Binding var widths: [SizePreferenceKey.Column:CGFloat]
        @State var isSelected: Bool = false

        var body: some View {
            GeometryReader { geometry in
                HStack {
                    Text("\(line.fullAddress) \(line.raw)")
                        .background(ColumnWidthEqualiserView(columnID: .first))
                        .frame(minWidth: widths[.first] ?? 0, alignment: .leading)
                    Text(line.asm)
                        .background(ColumnWidthEqualiserView(columnID: .second))
                        .frame(minWidth: widths[.second] ?? 0, alignment: .leading)
                    if let comment = line.comment, comment.count > 0 {
                        Text("; \(comment)").frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("").frame(maxWidth: .infinity, alignment: .leading)

                    }
                }.background((isSelected == true) ? Color.blue: Color.clear)
            }
        }
    }
    
    @State var widths: [SizePreferenceKey.Column:CGFloat] = [:]
    @State var selectedLine: Int? = 15
    @State var lines: [DisassemblyLine]
    var body: some View {
        List {
            ForEach(lines.indices) { index in
                GeometryReader { geometry in
                    DisasseblyRow(line: lines[index],
                                  widths: $widths,
                                  isSelected: (selectedLine == index))
                    }.font(.system(.body, design: .monospaced))
                }
        }.onPreferenceChange(SizePreferenceKey.self) { preference in
          self.widths = preference
        }
    }
}

struct DisassemblyView_Previews: PreviewProvider {
    struct MockLine : DisassemblyLine {
        var space: String
        var address: String
        var raw: String
        var asm: String
        var comment: String?
    }
    
    static let lines : [MockLine] = (0..<500).map { i in
        let random = Int.random(in: 0..<50)
        let raws = ["03FDA2", "03", "04FA", "03FDA2", "03", "04DA", "0EEDA2", "09", "03FA", "0F02"]
        let comments = ["xd", "..", ".", "#$", nil, nil, nil, nil, ""]
        let asms = ["JR Z, $FB", "LDH A, ($FF00+$85)", "AND A, A", "JP $020C", "RRA", "JP NZ $0034"]
        return MockLine(space: "ROM",
                         address: UInt16(i).hexString,
                         raw: raws[random%raws.count],
                         asm: asms[random%asms.count],
                         comment: comments[random%comments.count])
    }
    static var previews: some View {
        DisassemblyView(lines: lines)
    }
}
