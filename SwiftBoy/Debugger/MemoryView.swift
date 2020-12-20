//
//  MemoryView.swift
//  SwiftBoy
//
//  Created by Fabio Gallonetto on 15/12/2020.
//

import SwiftUI

private extension UnicodeScalar {
    var isTextASCII: Bool {
        self.value >= 32 && self.value <= 126
    }
}

struct MemoryView: View {
    
    struct Row: View {
        struct RowData {
            let line: Int
            let bytes: [Byte]
            func asciiString(at: Int) -> String {
                let scalar = UnicodeScalar(bytes[at])
                return scalar.isTextASCII ? String(Character(scalar)) : "."
            }
            var lineString: String {
                "\(UInt16(line)):"
            }
            func byteString(at: Int) -> String {
                "\(UInt8(bytes[at]), prefix: "")"
            }
        }
        
        @State var data: RowData
        @State var selectedIndex: Int = -1
        let bytesPerRow: Int
        
       // @Binding var widths: [SizePreferenceKey.Column:CGFloat]

        var body: some View {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Text(data.lineString).padding(.trailing, 10)

                    ForEach(data.bytes.indices) { index in
                        Text("\(data.byteString(at: index))")
                            .background(index == selectedIndex ? Color.yellow : Color.clear)
                            .onHover { isOver in selectedIndex = isOver ? index : -1 }
                            .padding(.trailing, 4)
                    }
                    ForEach(data.bytes.count..<bytesPerRow) { _ in
                        Text("  ").padding(.trailing, 4)
                    }
                    ForEach(data.bytes.indices) { index in
                        Text("\(data.asciiString(at: index))")
                            .background(index == selectedIndex ? Color.yellow : Color.clear)
                            .onHover { isOver in selectedIndex = isOver ? index : -1 }
                    }
                }.onHover { isOver in if isOver == false { selectedIndex = -1 } }
            }
        }
    }
    
    let bytesPerRow: Int
    @State var bytes: [UInt8]

    var body: some View {
        List {
            let rows = bytes.count / bytesPerRow
            let hasIncompleteRow = (bytes.count % bytesPerRow) > 0
            ForEach(0..<rows) { index in
                let rowFirstIndex = index * bytesPerRow
                let rowBytes = Array(bytes[index..<index+bytesPerRow])
                Row(data: Row.RowData(line: rowFirstIndex,
                                      bytes: rowBytes),
                                      bytesPerRow: bytesPerRow)
                        .font(.system(.body, design: .monospaced))
            }
            if (hasIncompleteRow) {
                let rowFirstIndex = bytes.count / bytesPerRow*bytesPerRow + 1
                let rowBytes = Array(bytes.suffix(bytes.count%bytesPerRow))
                Row(data: Row.RowData(line: rowFirstIndex,
                                      bytes: rowBytes),
                                      bytesPerRow: bytesPerRow)
                        .font(.system(.body, design: .monospaced))
            }
        }
    }
}

struct MemoryView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryView(bytesPerRow: 16, bytes: [1,5,6,3,7,4,7,4,65,34,78,146,186,15,89,76,78,146,186,15,89,76,244,54,247,56,243,34,56,76,244,54,247,56,243,34,56,76,76,78,146,186,15,89,76,244,54,247,56,243,34,56,76,78,146,186,15,89,76,244,54,247,56,78,78,146,186,15,89,76,244,54,247,56,243,34,56,76,146,186,15,89,78,146,186,15,89,76,244,54,247,56,78,146,186,15,89,76,244,54,247,56,243,34,56,76,243,222])
            .frame(width: 800.0, height: 600.0)
    }
}
