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

struct DisassemblyView: View {
    let ins = ["JR Z, $FB", "LDH A, ($FF00+$85)", "AND A, A ; A7", "JP $020C ; C3"]
    @State var widths: [SizePreferenceKey.Column:CGFloat] = [:]
    @State var selectedLine: Int? = 15
    var body: some View {
        List {
            ForEach(7..<70) { i in
                GeometryReader { geometry in
                    HStack {
                        Text("SPACE:Addr: \(i) HEXINSTR")
                            .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: SizePreferenceKey.self,
                                                value: [.first: proxy.size.width])
                            }).frame(minWidth: widths[.first] ?? 0, alignment: .leading)
                        Text(ins[Int.random(in: 0...3)])
                            .background(
                            GeometryReader { proxy in
                                Color.clear
                                    .preference(key: SizePreferenceKey.self,
                                                value: [.second: proxy.size.width])
                            }).frame(minWidth: widths[.second] ?? 0, alignment: .leading)
                        Text("; comment").frame(maxWidth: .infinity, alignment: .leading)
                    }.font(.system(.body, design: .monospaced))
                    .background(selectedLine == i ? Color.blue: Color.clear)
                }
            }
        }.onPreferenceChange(SizePreferenceKey.self) { preference in
            self.widths = preference
        }
    }
}

struct DisassemblyView_Previews: PreviewProvider {
    static var previews: some View {
        DisassemblyView()
    }
}
