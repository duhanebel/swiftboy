//
//  Debugger.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 08/12/2020.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    enum Column {
        case first
        case second
    }
    static var defaultValue: [Column: CGFloat] = [:]

    static func reduce(value: inout [Column: CGFloat], nextValue: () -> [Column: CGFloat]) {
        value.merge(nextValue()) { c, n in
            return c > n ? c : n
        }
    }
}




struct HexReader: View {
    var body: some View {
        List {
            ForEach(0..<20) { i in
                GeometryReader { geometry in
                    HStack {
                        Text("SPACE:00\(i)")
                        Text(" CBDF343465326522CBDF343465326522").layoutPriority(1)
                        Text(".........$........").frame(idealWidth: geometry.size.width/3, alignment: .leading)
                       
                    }
                } .font(.system(.body, design: .monospaced))
            }
        }
    }
}

struct Control: View {
    var body: some View {
        HStack {
            Spacer().frame(maxWidth:20)
            Button(action: {  }) {
               Text("Next")
            }
            Spacer().frame(maxWidth:8)
            Button(action: {  }) {
               Text("Stop")
            }
            Spacer()
            
        }
    }
}

struct CPUState: View {
    var body: some View {
        VStack {
            VStack {
                Text("AF: F410")
                Text("BC: E120")
                Text("DE: F420")
                Text("HL: F430")
                Text("SP: F310")
                Text("PC: 0100")
            }.font(.system(.body, design: .monospaced))
            HStack {
                Text("Z").fontWeight(.bold)
                Spacer()
                Text("N").foregroundColor(.gray)
                Spacer()
                Text("H").fontWeight(.bold)
                Spacer()
                Text("C").foregroundColor(.gray)
            }.padding(.horizontal, 8)
        }
    }
}

struct DebuggerView: View {
    var body: some View {
        GeometryReader { geometry in
            HSplitView() {
                VSplitView() {
                    DisassemblyView()
                    Control()
                    HexReader()
                }.frame(minWidth: geometry.size.width*2/3, idealWidth: geometry.size.width*2/3)
                VSplitView() {
                    CPUState()
                    Rectangle()
                }.frame(minWidth: geometry.size.width*1/3, idealWidth: geometry.size.width*1/3, maxWidth: geometry.size.width*1/3)
            }
        }
    }
}

struct Debugger_Previews: PreviewProvider {
    static var previews: some View {
        DebuggerView().previewLayout(.fixed(width: 800, height: 600))
    }
}
